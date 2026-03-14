import User from '../models/User.js';
import Client from '../models/Client.js';
import Driver from '../models/Driver.js';
import Restaurant from '../models/Restaurant.js';
import Commune from '../models/Commune.js';
import Admin from '../models/Admin.js';
import Cashier from '../models/Cashier.js';
import HomeCategory from '../models/HomeCategory.js';
import { normalizeCategoryList } from '../utils/slug.js';
import { CASHIER_STATUS_VALUES } from "../validators/cashierValidator.js";
import { normalizePhoneNumber } from "../utils/phoneNormalizer.js";
import { normalizeLocale } from "../utils/locale.js";
import { registerDeviceTokenForUser } from "../services/notification.service.js";
import {
  serializeHomeCategories,
  extractHomeCategorySlugs,
  syncRestaurantHomeCategories
} from '../services/restaurantCategory.service.js';
import * as favoriteAddressService from '../services/favoriteAddress.service.js';
import {
  ACCESS_TOKEN_TTL_SECONDS,
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken
} from '../config/security.js';
import cacheService from '../services/cache.service.js';
import { sendGupshupTemplate } from '../services/gupshup.service.js';
import { sequelize } from '../config/database.js';
import SystemConfig from '../models/SystemConfig.js';


// OTP Store (shared via Redis when enabled)
const OTP_TTL_SECONDS = 5 * 60;
const OTP_REQUEST_USE_PAID_SERVICE_KEY = 'otp_request_use_paid_service';
const buildOtpKey = (phone) => `otp:phone:${phone}`;
const setOtp = async (phone, payload) =>
  cacheService.set(buildOtpKey(phone), payload, OTP_TTL_SECONDS);
const getOtp = async (phone) =>
  cacheService.get(buildOtpKey(phone));
const delOtp = async (phone) =>
  cacheService.del(buildOtpKey(phone));

const formatSequelizeErrors = (err) => {
  if (!err || !Array.isArray(err.errors)) return null;
  return err.errors.map(e => ({
    field: e.path,
    message: e.message,
    value: e.value
  }));
};

const isCashierCodeConflict = (err) => {
  if (!err || err.name !== 'SequelizeUniqueConstraintError') return false;
  if (Array.isArray(err.errors) && err.errors.some(e => e.path === 'cashier_code')) {
    return true;
  }
  if (err.fields && err.fields.cashier_code) return true;
  return false;
};

// Device tokens for "remember me" functionality
const deviceTokens = new Map(); // Store refresh tokens per device

// ============================================
// TOKEN GENERATION (Updated)
// ============================================

// Generate SHORT-LIVED access token (15 minutes)
const generateAccessToken = (userId, role) =>
  signAccessToken({ id: userId, role, type: 'access' });

// Generate LONG-LIVED refresh token (30 days)
const generateRefreshToken = (userId, role, deviceId) =>
  signRefreshToken({ id: userId, role, type: 'refresh', deviceId });

// Generate 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const normalizeBooleanConfig = (value, fallback = false) => {
  if (value === undefined || value === null) return fallback;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value === 1;

  const normalized = String(value).trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;

  return fallback;
};

const shouldUsePaidOtpService = async () => {
  try {
    const configuredValue = await SystemConfig.get(OTP_REQUEST_USE_PAID_SERVICE_KEY, false);
    return normalizeBooleanConfig(configuredValue, false);
  } catch (error) {
    console.error('Failed to read OTP request mode config:', error);
    return false;
  }
};

const storeOtpForPhone = async (phone_number, client) => {
  const otp = generateOTP();
  await setOtp(phone_number, {
    code: otp,
    clientId: client.id,
    userId: client.user_id,
    expiresAt: Date.now() + OTP_TTL_SECONDS * 1000
  });

  return otp;
};

const buildOtpRequestResponse = ({ phone_number, isNewUser, otp, usePaidService }) => {
  const response = {
    message: usePaidService ? 'OTP sent successfully' : 'OTP generated successfully',
    phone_number,
    is_new_user: isNewUser,
    otp_mode: usePaidService ? 'paid' : 'free'
  };

  if (usePaidService) {
    if (process.env.NODE_ENV !== 'production') {
      response.dev_otp = otp;
    }
  } else {
    response.otp = otp;
    response.dev_otp = otp;
  }

  return response;
};

const ensureClientForPhone = async (phone_number) => {
  // Check if client exists
  let client = await Client.findOne({ where: { phone_number } });
  let isNewUser = false;

  // Create new client if doesn't exist
  if (!client) {
    const tempEmail = `${phone_number}@temp.local`;

    // Use findOrCreate to avoid duplicates
    const [user] = await User.findOrCreate({
      where: { email: tempEmail },
      defaults: {
        email: tempEmail,
        password: Math.random().toString(36),
        role: 'client'
      }
    });

    // Check if client exists for this user (use phone_number OR user_id)
    const [foundClient, clientCreated] = await Client.findOrCreate({
      where: {
        phone_number: phone_number
      },
      defaults: {
        user_id: user.id,
        email: tempEmail,
        phone_number,
        first_name: '',
        last_name: ''
      }
    });

    client = foundClient;
    isNewUser = clientCreated;

    if (isNewUser) {
      console.log(`New client registered: ${phone_number}`);
    } else {
      console.log(`Existing client found: ${phone_number}`);
    }
  }

  return { client, isNewUser };
};

const buildGupshupOtpParams = (otp) => {
  if (Array.isArray(otp)) return otp;
  return [String(otp)];
};

// Send OTP via Gupshup paid service
const sendOTP = async (phoneNumber, otp) => {
  const templateId = process.env.GUPSHUP_OTP_TEMPLATE_ID;

  if (!templateId) {
    throw new Error('GUPSHUP_OTP_TEMPLATE_ID missing');
  }

  const response = await sendGupshupTemplate({
    to: phoneNumber,
    templateId,
    params: buildGupshupOtpParams(otp)
  });

  console.log(`OTP sent via Gupshup to ${phoneNumber}`);
  return response;
};

// ============================================
// CLIENT AUTHENTICATION FLOW
// ============================================

// STEP 1: Request OTP (First time or when token expired)

export const requestOTP = async (req, res) => {
  try {
    let { phone_number } = req.body;

    if (!phone_number) {
      return res.status(400).json({ message: 'Phone number is required' });
    }

    // Normalize phone number
    phone_number = normalizePhoneNumber(phone_number);
    if (!phone_number) {
      return res.status(400).json({ message: 'Invalid phone number format' });
    }

    const { client, isNewUser } = await ensureClientForPhone(phone_number);
    const usePaidService = await shouldUsePaidOtpService();

    const otp = await storeOtpForPhone(phone_number, client);

    if (usePaidService) {
      await sendOTP(phone_number, otp);
    }

    res.json(buildOtpRequestResponse({
      phone_number,
      isNewUser,
      otp,
      usePaidService
    }));

  } catch (error) {
    console.error('requestOTP error:', error);
    res.status(500).json({ message: 'Failed to send OTP', error: error.message });
  }
};

export const requestOTPDirect = async (req, res) => {
  try {
    let { phone_number } = req.body;

    if (!phone_number) {
      return res.status(400).json({ message: 'Phone number is required' });
    }

    // Normalize phone number
    phone_number = normalizePhoneNumber(phone_number);
    if (!phone_number) {
      return res.status(400).json({ message: 'Invalid phone number format' });
    }

    const { client, isNewUser } = await ensureClientForPhone(phone_number);

    const otp = await storeOtpForPhone(phone_number, client);

    res.json(buildOtpRequestResponse({
      phone_number,
      isNewUser,
      otp,
      usePaidService: false
    }));
  } catch (error) {
    console.error('requestOTPDirect error:', error);
    res.status(500).json({ message: 'Failed to generate OTP', error: error.message });
  }
};

// STEP 2: Verify OTP and get LONG-LIVED tokens
export const verifyOTP = async (req, res) => {
  try {
    let { phone_number, otp, device_id, device_token, device_platform } = req.body;

    if (!phone_number || !otp) {
      return res.status(400).json({ message: 'Phone number and OTP are required' });
    }

    // Normaliser le numéro de téléphone
    phone_number = normalizePhoneNumber(phone_number);
    if (!phone_number) {
      return res.status(400).json({ message: 'Invalid phone number format' });
    }

    const storedData = await getOtp(phone_number);

    if (!storedData) {
      return res.status(400).json({ message: 'OTP not found or expired' });
    }

    if (Date.now() > storedData.expiresAt) {
      await delOtp(phone_number);
      return res.status(400).json({ message: 'OTP expired' });
    }

    if (storedData.code !== otp) {
      return res.status(400).json({ message: 'Invalid OTP' });
    }

    await delOtp(phone_number);

    const user = await User.findByPk(storedData.userId);
    const client = await Client.findByPk(storedData.clientId);

    user.last_login = new Date();
    await user.save();

    const deviceIdentifier = device_id || `device-${Date.now()}-${Math.random()}`;

    // ===== Generate tokens WITH client_id =====
    const accessToken = signAccessToken({
      id: user.id,
      role: user.role,
      client_id: client.id,
      type: 'access'
    });

    const refreshToken = signRefreshToken({
      id: user.id,
      role: user.role,
      client_id: client.id,
      type: 'refresh',
      deviceId: deviceIdentifier
    });

    deviceTokens.set(refreshToken, {
      userId: user.id,
      deviceId: deviceIdentifier,
      createdAt: Date.now()
    });

    if (device_token) {
      try {
        await registerDeviceTokenForUser({
          userId: user.id,
          role: user.role,
          profileId: client.id,
          token: String(device_token).trim(),
          platform: device_platform || null,
          deviceId: deviceIdentifier,
          locale: client?.locale
        });
      } catch (tokenError) {
        console.error("Device token registration failed:", tokenError);
      }
    }

    const favoriteAddresses = client
      ? await favoriteAddressService.listFavoriteAddresses(client.id)
      : [];

    res.json({
      message: 'Login successful',
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_in: ACCESS_TOKEN_TTL_SECONDS,
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      },
      profile: client,
      favorite_addresses: favoriteAddresses
    });

  } catch (error) {
    console.error('verifyOTP error:', error);
    res.status(500).json({ message: 'Failed to verify OTP', error: error.message });
  }
};

// NEW: Refresh access token (called automatically by frontend)
export const refreshAccessToken = async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return res.status(400).json({ message: 'Refresh token is required' });
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = verifyRefreshToken(refresh_token);
    } catch (error) {
      return res.status(401).json({ message: 'Invalid or expired refresh token' });
    }

    if (decoded.type !== 'refresh') {
      return res.status(401).json({ message: 'Invalid refresh token type' });
    }

    // Check if token exists in store
    const tokenData = deviceTokens.get(refresh_token);
    if (!tokenData) {
      return res.status(401).json({ message: 'Refresh token revoked' });
    }

    // Load user
    const user = await User.findByPk(decoded.id);
    if (!user || !user.is_active) {
      return res.status(401).json({ message: 'Invalid user' });
    }

    // Build access token payload with profile IDs
    const payload = {
      id: user.id,
      role: user.role,
      type: 'access'
    };

    if (decoded.client_id) payload.client_id = decoded.client_id;
    if (decoded.driver_id) payload.driver_id = decoded.driver_id;
    if (decoded.restaurant_id) payload.restaurant_id = decoded.restaurant_id;
    if (decoded.admin_id) payload.admin_id = decoded.admin_id;
    if (decoded.cashier_id) payload.cashier_id = decoded.cashier_id;

    // Fallback to DB if profile ids are missing
    if (user.role === 'client' && !payload.client_id) {
      const client = await Client.findOne({ where: { user_id: user.id }, attributes: ['id'] });
      if (client) payload.client_id = client.id;
    }

    if (user.role === 'driver' && !payload.driver_id) {
      const driver = await Driver.findOne({ where: { user_id: user.id }, attributes: ['id'] });
      if (driver) payload.driver_id = driver.id;
    }

    if (user.role === 'restaurant' && !payload.restaurant_id) {
      const restaurant = await Restaurant.findOne({ where: { user_id: user.id }, attributes: ['id'] });
      if (restaurant) payload.restaurant_id = restaurant.id;
    }

    if (user.role === 'admin' && !payload.admin_id) {
      const admin = await Admin.findOne({ where: { user_id: user.id }, attributes: ['id'] });
      if (admin) payload.admin_id = admin.id;
    }

    if (user.role === 'cashier' && !payload.cashier_id) {
      const cashier = await Cashier.findOne({
        where: { user_id: user.id },
        attributes: ['id', 'restaurant_id']
      });
      if (cashier) {
        payload.cashier_id = cashier.id;
        payload.restaurant_id = payload.restaurant_id || cashier.restaurant_id || null;
      }
    }

    // Generate new access token (refresh token stays the same)
    const newAccessToken = signAccessToken(payload);

    res.json({
      message: 'Token refreshed successfully',
      access_token: newAccessToken,
      expires_in: ACCESS_TOKEN_TTL_SECONDS
    });

  } catch (error) {
    console.error('refreshAccessToken error:', error);
    res.status(500).json({ message: 'Failed to refresh token' });
  }
};

// NEW: Logout (revoke refresh token)
export const logout = async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (refresh_token) {
      // Remove refresh token from store
      deviceTokens.delete(refresh_token);
      console.log('🔓 User logged out, token revoked');
    }

    res.json({ message: 'Logout successful' });

  } catch (error) {
    console.error('logout error:', error);
    res.status(500).json({ message: 'Logout failed' });
  }
};

// ============================================
// DRIVER/RESTAURANT LOGIN (Unchanged)
// ============================================

export const register = async (req, res) => {
  try {
    const { email, password, type, device_token, device_platform, device_id, ...profileData } = req.body;

    if (!['driver', 'restaurant'].includes(type)) {
      return res.status(400).json({
        message: 'Invalid type. Must be driver or restaurant'
      });
    }

    const badRequest = (message, field) => {
      const err = new Error(message);
      err.status = 400;
      if (field) err.field = field;
      throw err;
    };

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({
        message: 'Email already registered',
        errors: [{ field: 'email', message: 'Email already registered' }]
      });
    }

    // Map type to role for User model
    const role = type;
    const { user, profile } = await sequelize.transaction(async (transaction) => {
      const user = await User.create({ email, password, role }, { transaction });
      let profile;

      switch (type) {
        case 'driver':
          profile = await Driver.create({
            user_id: user.id,
            email: email,
            first_name: profileData.first_name || '',
            last_name: profileData.last_name || '',
            phone: normalizePhoneNumber(profileData.phone) || '',
            driver_code: `DRV-${String(Date.now()).slice(-6)}`,
            locale: normalizeLocale(profileData.locale),
            vehicle_type: profileData.vehicle_type || 'scooter',
            vehicle_plate: profileData.vehicle_plate || null,
            license_number: profileData.license_number || null
          }, { transaction });
          break;

        case 'restaurant': {
          const { lat, lng } = profileData;
          const latitude = parseFloat(lat);
          const longitude = parseFloat(lng);

          if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            badRequest('Valid latitude and longitude are required', 'lat');
          }

          let resolvedCommuneId = profileData.commune_id || null;
          if (resolvedCommuneId) {
            const communeExists = await Commune.findByPk(resolvedCommuneId, { transaction });
            if (!communeExists) {
              badRequest('Invalid commune_id', 'commune_id');
            }
          }

          const rawCategories = Array.isArray(profileData.categories)
            ? profileData.categories
            : profileData.categories
              ? [profileData.categories]
              : [];
          const categories = normalizeCategoryList(rawCategories);
          if (categories.length === 0) {
            badRequest('At least one category is required', 'categories');
          }

          const isActive =
            profileData.is_active === undefined
              ? true
              : typeof profileData.is_active === 'string'
              ? profileData.is_active === 'true'
              : profileData.is_active;

          const isPremium =
            profileData.is_premium === undefined
              ? false
              : typeof profileData.is_premium === 'string'
              ? profileData.is_premium === 'true'
              : profileData.is_premium;

          let rating = 0.0;
          if (profileData.rating !== undefined && profileData.rating !== null) {
            rating = parseFloat(profileData.rating);
            if (!Number.isFinite(rating) || rating < 0 || rating > 5) {
              badRequest('Rating must be between 0 and 5', 'rating');
            }
          }

          profile = await Restaurant.create({
            user_id: user.id,
            name: profileData.name || 'New Restaurant',
            description: profileData.description || null,
            address: profileData.address || null,
            phone_number: profileData.phone_number || profileData.phone || null,
            email: profileData.email || email || null,
            locale: normalizeLocale(profileData.locale),
            commune_id: resolvedCommuneId,
            location: {
              type: 'Point',
              coordinates: [longitude, latitude]
            },
            rating: rating,
            image_url: profileData.image_url || null,
            is_active: isActive,
            is_premium: isPremium,
            status: 'pending',
            opening_hours: profileData.opening_hours || null
          }, { transaction });

          try {
            await syncRestaurantHomeCategories(profile, categories, { transaction });
          } catch (err) {
            badRequest(err?.message || 'Invalid categories', 'categories');
          }
          await profile.reload({
            include: [{
              model: HomeCategory,
              as: "home_categories",
              attributes: ["id", "name", "slug", "description", "image_url", "display_order"]
            }],
            transaction
          });

          const homeCategories = serializeHomeCategories(profile.home_categories);
          const profilePlain = profile.get({ plain: true });
          profilePlain.home_categories = homeCategories;
          profilePlain.categories = extractHomeCategorySlugs(homeCategories);
          profile = profilePlain;
          break;
        }
      }

      return { user, profile };
    });

    // For driver/restaurant, also use refresh tokens
    const deviceId = device_id || `device-${Date.now()}`;
    const accessToken = generateAccessToken(user.id, user.role);
    const refreshToken = generateRefreshToken(user.id, user.role, deviceId);

    deviceTokens.set(refreshToken, {
      userId: user.id,
      deviceId: deviceId,
      createdAt: Date.now()
    });

    if (device_token) {
      try {
        const profileId =
          type === "driver"
            ? profile?.id
            : type === "restaurant"
            ? profile?.id
            : null;
        await registerDeviceTokenForUser({
          userId: user.id,
          role: user.role,
          profileId: profileId || null,
          token: String(device_token).trim(),
          platform: device_platform || null,
          deviceId,
          locale: profile?.locale
        });
      } catch (tokenError) {
        console.error("Device token registration failed:", tokenError);
      }
    }

    res.status(201).json({
      message: 'Registration successful',
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_in: ACCESS_TOKEN_TTL_SECONDS,
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      },
      profile
    });

  } catch (error) {
    console.error('Registration error:', error);
    const formattedErrors = formatSequelizeErrors(error);
    if (formattedErrors) {
      return res.status(400).json({
        message: 'Validation error',
        errors: formattedErrors
      });
    }
    if (error?.status) {
      return res.status(error.status).json({
        message: error.message,
        errors: error.field ? [{ field: error.field, message: error.message }] : undefined
      });
    }
    res.status(500).json({ message: 'Registration failed', error: error.message });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password, type, device_id, device_token, device_platform } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    if (!type) {
      return res.status(400).json({ message: 'Type is required' });
    }

    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (!user.is_active) {
      return res.status(403).json({ message: 'Account is deactivated' });
    }

    // ✅ Check if type matches user's role
    if (user.role !== type) {
      return res.status(401).json({ 
        message: `Invalid credentials. This account is registered as ${user.role}` 
      });
    }

    const isValid = await user.comparePassword(password);
    if (!isValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // ✅ Load the profile
    let profile;
    let driver_id = null;
    let restaurant_id = null;
    let admin_id = null;
    let cashier_id = null; // ✅ NEW

    switch (user.role) {
      case 'driver':
        profile = await Driver.findOne({ where: { user_id: user.id } });
        driver_id = profile?.id || null;
        break;

      case 'restaurant':
        profile = await Restaurant.findOne({ where: { user_id: user.id } });
        restaurant_id = profile?.id || null;
        break;

      case 'admin':
        profile = await Admin.findOne({ where: { user_id: user.id } });
        admin_id = profile?.id || null;
        break;

      case 'cashier': // ✅ NEW
        profile = await Cashier.findOne({ 
          where: { user_id: user.id },
          include: [{
            model: Restaurant,
            as: 'restaurant',
            attributes: ['id', 'name']
          }]
        });
        cashier_id = profile?.id || null;
        restaurant_id = profile?.restaurant_id || null; // ✅ Cashier has access to restaurant
        break;
    }

    user.last_login = new Date();
    await user.save();

    // ✅ Generate tokens with cashier_id
    const deviceIdentifier = device_id || `device-${Date.now()}`;

        const accessToken = signAccessToken({
      id: user.id,
      role: user.role,
      driver_id,
      restaurant_id,
      admin_id,
      cashier_id, // ? NEW
      type: 'access'
    });    const refreshToken = signRefreshToken({
      id: user.id,
      role: user.role,
      driver_id,
      restaurant_id,
      admin_id,
      cashier_id, // ? NEW
      type: 'refresh',
      deviceId: deviceIdentifier
    });// ✅ Store refresh token
    deviceTokens.set(refreshToken, {
      userId: user.id,
      deviceId: deviceIdentifier,
      createdAt: Date.now()
    });

    if (device_token) {
      try {
        const profileId =
          driver_id || restaurant_id || admin_id || cashier_id || profile?.id || null;
        await registerDeviceTokenForUser({
          userId: user.id,
          role: user.role,
          profileId,
          token: String(device_token).trim(),
          platform: device_platform || null,
          deviceId: deviceIdentifier,
          locale: profile?.locale
        });
      } catch (tokenError) {
        console.error("Device token registration failed:", tokenError);
      }
    }

    let favoriteAddresses = [];
    if (user.role === 'client' && profile?.id) {
      favoriteAddresses = await favoriteAddressService.listFavoriteAddresses(profile.id);
    }

    // ✅ Response
    res.json({
      message: 'Login successful',
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_in: ACCESS_TOKEN_TTL_SECONDS,
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      },
      profile,
      favorite_addresses: favoriteAddresses
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Login failed', error: error.message });
  }
};

// ✅ Nouvelle fonction pour créer un compte cashier (par admin ou restaurant)
export const registerCashier = async (req, res) => {
  try {
    const { 
      email, 
      password, 
      first_name, 
      last_name, 
      phone, 
      restaurant_id,
      permissions,
      profile_image_url,
      status,
      is_active,
      notes
    } = req.body;

    const isRestaurantUser = req.user?.role === 'restaurant';
    const enforcedRestaurantId = isRestaurantUser ? req.user?.restaurant_id : restaurant_id;

    // Validate required fields
    if (!email || !password || !first_name || !last_name || !phone || !enforcedRestaurantId) {
      return res.status(400).json({
        message: 'Missing required fields'
      });
    }

    // Check if email already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({
        message: 'Email already registered',
        errors: [{ field: 'email', message: 'Email already registered' }]
      });
    }

    const MAX_CODE_ATTEMPTS = 5;
    let lastError;

    for (let attempt = 0; attempt < MAX_CODE_ATTEMPTS; attempt += 1) {
      try {
        const { user, cashier, restaurant } = await sequelize.transaction(async (transaction) => {
          // Verify restaurant exists
          const restaurant = await Restaurant.findByPk(enforcedRestaurantId, { transaction });
          if (!restaurant) {
            const err = new Error('Restaurant not found');
            err.status = 404;
            throw err;
          }

          // Create user account
          const user = await User.create({
            email,
            password,
            role: 'cashier'
          }, { transaction });

          // Generate cashier code
          const cashierCode = await Cashier.generateCashierCode();

          // Create cashier profile
          const parsedPermissions = (() => {
            if (typeof permissions === "string") {
              try {
                return JSON.parse(permissions);
              } catch (_err) {
                return null;
              }
            }
            return permissions;
          })();

          const defaultPermissions = {
            can_create_orders: true
          };

          const normalizedPermissions =
            parsedPermissions && typeof parsedPermissions === "object"
              ? { can_create_orders: Boolean(parsedPermissions.can_create_orders) }
              : {};

          const finalPermissions = {
            ...defaultPermissions,
            ...normalizedPermissions
          };

          const finalStatus = CASHIER_STATUS_VALUES.includes(status) ? status : "offline";
          const isActiveFlag = typeof is_active === "boolean" ? is_active : true;

          const cashier = await Cashier.create({
            user_id: user.id,
            restaurant_id: enforcedRestaurantId,
            cashier_code: cashierCode,
            first_name,
            last_name,
            phone: normalizePhoneNumber(phone),
            email,
            permissions: finalPermissions,
            profile_image_url: profile_image_url || null,
            status: finalStatus,
            is_active: isActiveFlag,
            notes: notes || null
          }, { transaction });

          return { user, cashier, restaurant };
        });

        res.status(201).json({
          message: 'Cashier registered successfully',
          data: {
            user_id: user.id,
            cashier_id: cashier.id,
            cashier_code: cashier.cashier_code,
            email: user.email,
            restaurant: {
              id: restaurant.id,
              name: restaurant.name
            }
          }
        });
        return;
      } catch (error) {
        if (isCashierCodeConflict(error) && attempt < MAX_CODE_ATTEMPTS - 1) {
          lastError = error;
          continue;
        }
        throw error;
      }
    }

    throw lastError || new Error('Failed to generate cashier code');

  } catch (error) {
    console.error('Register cashier error:', error);
    const formattedErrors = formatSequelizeErrors(error);
    if (formattedErrors) {
      return res.status(400).json({
        message: 'Validation error',
        errors: formattedErrors
      });
    }
    if (error?.status) {
      return res.status(error.status).json({
        message: error.message
      });
    }
    res.status(500).json({ 
      message: 'Registration failed', 
      error: error.message 
    });
  }
};

export const getProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] }
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    let profile;
    switch (user.role) {
      case 'client':
        profile = await Client.findOne({ where: { user_id: user.id } });
        break;
      case 'driver':
        profile = await Driver.findOne({ where: { user_id: user.id } });
        break;
      case 'restaurant':
        profile = await Restaurant.findOne({ where: { user_id: user.id } });
        break;
    }

    res.json({ user, profile });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Failed to get profile' });
  }
};


