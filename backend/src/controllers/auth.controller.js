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
import { normalizeOpeningHours } from "../utils/restaurantOpeningHours.js";
import { registerDeviceTokenForUser } from "../services/notification.service.js";
import {
  storeRefreshToken,
  getRefreshTokenData,
  revokeRefreshToken,
  revokeRefreshTokensForUser
} from "../services/sessionTokenStore.js";
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
import {
  confirmPartnerEmailVerification,
  sendPartnerEmailVerification
} from "../services/partnerEmailVerification.service.js";
import {
  createGoogleMailAuthUrl,
  exchangeGoogleMailAuthCode
} from "../services/googleMailOAuth.service.js";
import {
  PARTNER_PASSWORD_RESET_TTL_SECONDS,
  resetPartnerPassword,
  sendPartnerPasswordReset
} from "../services/passwordReset.service.js";


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

// ============================================
// TOKEN GENERATION (Updated)
// ============================================

// Generate 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const normalizeEmailAddress = (value) =>
  String(value || "").trim().toLowerCase();

const isPartnerEmailVerificationRequired = () =>
  normalizeBooleanConfig(process.env.PARTNER_EMAIL_VERIFICATION_REQUIRED, true);

const normalizeBooleanConfig = (value, fallback = false) => {
  if (value === undefined || value === null) return fallback;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value === 1;

  const normalized = String(value).trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;

  return fallback;
};

const buildPartnerVerificationBaseUrl = (req) => {
  const configuredBaseUrl = process.env.PARTNER_EMAIL_VERIFICATION_BASE_URL?.trim();
  if (configuredBaseUrl) {
    return configuredBaseUrl;
  }

  const forwardedProto = req.get('x-forwarded-proto');
  const forwardedHost = req.get('x-forwarded-host');
  const protocol = forwardedProto
    ? forwardedProto.split(',')[0].trim()
    : req.protocol || 'http';
  const host = forwardedHost || req.get('host');

  if (!host) {
    const error = new Error('Unable to resolve the public verification URL');
    error.status = 500;
    throw error;
  }

  return `${protocol}://${host}${req.baseUrl}/verify-email`;
};

const buildPartnerVerificationEmailResponse = (result) => {
  const response = {
    message: 'Verification email sent successfully',
    email: result.email,
    type: result.type,
    expires_in: result.expiresInSeconds,
    delivery_mode: result.deliveryMode
  };

  if (result.verificationUrl) {
    response.dev_verification_url = result.verificationUrl;
  }

  return response;
};

const loadPartnerRegistrationProfile = async (user) => {
  if (!user || !['driver', 'restaurant'].includes(user.role)) {
    return null;
  }

  if (user.role === 'driver') {
    const driver = await Driver.findOne({ where: { user_id: user.id } });
    return driver ? driver.get({ plain: true }) : null;
  }

  const restaurant = await Restaurant.findOne({
    where: { user_id: user.id },
    include: [{
      model: HomeCategory,
      as: "home_categories",
      attributes: ["id", "name", "slug", "description", "image_url", "display_order"]
    }]
  });

  if (!restaurant) {
    return null;
  }

  const restaurantPlain = restaurant.get({ plain: true });
  const homeCategories = serializeHomeCategories(restaurantPlain.home_categories);
  restaurantPlain.home_categories = homeCategories;
  restaurantPlain.categories = extractHomeCategorySlugs(homeCategories);

  return restaurantPlain;
};

const buildPendingPartnerVerificationRegistrationResponse = ({
  user,
  profile,
  verificationEmailResult = null,
  verificationEmailError = null,
  alreadyRegistered = false
}) => {
  const response = {
    message: verificationEmailError
      ? alreadyRegistered
        ? 'Account already exists but email is not verified, and resending the verification email failed. Request a new confirmation email before logging in.'
        : 'Registration successful, but sending the verification email failed. Request a new confirmation email before logging in.'
      : alreadyRegistered
        ? 'Account already exists and email is not verified. A new verification email has been sent.'
        : 'Registration successful. Please verify your email before logging in.',
    verification_required: true,
    verification_email_sent: !verificationEmailError,
    user: {
      id: user.id,
      email: user.email,
      role: user.role,
      email_verified_at: user.email_verified_at
    },
    profile
  };

  if (alreadyRegistered) {
    response.already_registered = true;
  }

  if (verificationEmailResult) {
    response.verification_expires_in = verificationEmailResult.expiresInSeconds;
    response.delivery_mode = verificationEmailResult.deliveryMode;
    if (verificationEmailResult.verificationUrl) {
      response.dev_verification_url = verificationEmailResult.verificationUrl;
    }
  }

  if (verificationEmailError && process.env.NODE_ENV !== 'production') {
    response.verification_email_error = verificationEmailError.message;
  }

  return response;
};

const buildPartnerPasswordResetBaseUrl = (req) => {
  const configuredBaseUrl = process.env.PARTNER_PASSWORD_RESET_BASE_URL?.trim();
  if (configuredBaseUrl) {
    return configuredBaseUrl;
  }

  const forwardedProto = req.get('x-forwarded-proto');
  const forwardedHost = req.get('x-forwarded-host');
  const protocol = forwardedProto
    ? forwardedProto.split(',')[0].trim()
    : req.protocol || 'http';
  const host = forwardedHost || req.get('host');

  if (!host) {
    const error = new Error('Unable to resolve the public password reset URL');
    error.status = 500;
    throw error;
  }

  return `${protocol}://${host}${req.baseUrl}/password/reset`;
};

const buildPartnerPasswordResetResponse = (result = null) => {
  const response = {
    message: 'If an account exists for this email, a password reset link has been sent.',
    expires_in: PARTNER_PASSWORD_RESET_TTL_SECONDS
  };

  if (result?.resetUrl) {
    response.dev_reset_url = result.resetUrl;
  }

  if (result?.deliveryMode && process.env.NODE_ENV !== 'production') {
    response.delivery_mode = result.deliveryMode;
  }

  return response;
};

const escapeHtml = (value) =>
  String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

const renderVerificationPage = ({ title, message, success }) => `
  <html>
    <body style="font-family:Arial,sans-serif;padding:24px;line-height:1.5;background:#f9fafb;color:#111827;">
      <div style="max-width:560px;margin:40px auto;background:#ffffff;border:1px solid #e5e7eb;border-radius:16px;padding:32px;">
        <div style="font-size:14px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:${success ? '#047857' : '#b91c1c'};margin-bottom:12px;">
          ${success ? 'Verification reussie' : 'Verification impossible'}
        </div>
        <h2 style="margin:0 0 12px;">${escapeHtml(title)}</h2>
        <p style="margin:0;color:#374151;">${escapeHtml(message)}</p>
      </div>
    </body>
  </html>
`;

const renderPasswordResetPage = ({ token, message = '' }) => `
  <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>Tawsil | Reinitialiser le mot de passe</title>
      <style>
        :root {
          --brand: #16a34a;
          --brand-dark: #15803d;
          --brand-soft: #dcfce7;
          --ink: #111827;
          --muted: #4b5563;
          --line: #d1d5db;
          --danger: #b91c1c;
          --surface: rgba(255, 255, 255, 0.96);
        }

        * {
          box-sizing: border-box;
        }

        body {
          margin: 0;
          min-height: 100vh;
          font-family: Arial, sans-serif;
          color: var(--ink);
          background:
            radial-gradient(circle at top left, rgba(34, 197, 94, 0.18), transparent 34%),
            radial-gradient(circle at bottom right, rgba(22, 163, 74, 0.16), transparent 28%),
            linear-gradient(180deg, #f0fdf4 0%, #f8fafc 52%, #ffffff 100%);
        }

        .page {
          min-height: 100vh;
          padding: 24px 16px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .shell {
          width: 100%;
          max-width: 520px;
          border-radius: 24px;
          background: var(--surface);
          border: 1px solid rgba(22, 163, 74, 0.12);
          box-shadow: 0 24px 80px rgba(17, 24, 39, 0.12);
          backdrop-filter: blur(10px);
        }

        .form-panel {
          padding: 36px 28px;
        }

        .card {
          width: 100%;
        }

        .eyebrow {
          margin: 0 0 12px;
          font-size: 12px;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          color: var(--brand-dark);
          font-weight: 700;
        }

        .title {
          margin: 0 0 10px;
          font-size: 30px;
          line-height: 1.1;
        }

        .intro {
          margin: 0 0 28px;
          color: var(--muted);
          font-size: 15px;
          line-height: 1.7;
        }

        .reset-form {
          display: grid;
          gap: 16px;
        }

        .field {
          display: grid;
          gap: 8px;
          font-size: 14px;
          font-weight: 700;
          color: var(--ink);
        }

        .field input {
          width: 100%;
          min-height: 52px;
          padding: 14px 16px;
          border: 1px solid var(--line);
          border-radius: 14px;
          font: inherit;
          color: var(--ink);
          background: #ffffff;
          transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }

        .field input:focus {
          outline: none;
          border-color: var(--brand);
          box-shadow: 0 0 0 4px rgba(34, 197, 94, 0.14);
        }

        .field-hint {
          margin: -2px 0 0;
          color: #6b7280;
          font-size: 13px;
          font-weight: 400;
        }

        .submit-button {
          min-height: 54px;
          border: none;
          border-radius: 16px;
          background: linear-gradient(180deg, #22c55e 0%, #16a34a 100%);
          color: #ffffff;
          font: inherit;
          font-weight: 700;
          cursor: pointer;
          box-shadow: 0 18px 32px rgba(22, 163, 74, 0.24);
          transition: transform 0.18s ease, box-shadow 0.18s ease, opacity 0.18s ease;
        }

        .submit-button:hover {
          transform: translateY(-1px);
          box-shadow: 0 22px 38px rgba(22, 163, 74, 0.3);
        }

        .submit-button:disabled {
          cursor: not-allowed;
          opacity: 0.78;
          transform: none;
          box-shadow: none;
        }

        .status {
          min-height: 24px;
          margin: 4px 0 0;
          font-size: 14px;
          line-height: 1.6;
          color: var(--muted);
        }

        .invalid-note {
          margin: 0;
          padding: 14px 16px;
          border-radius: 16px;
          background: #fef2f2;
          color: var(--danger);
          border: 1px solid #fecaca;
          font-size: 14px;
          line-height: 1.6;
        }

        @media (max-width: 480px) {
          .page {
            padding: 12px;
          }

          .shell {
            border-radius: 22px;
          }

          .form-panel {
            padding-left: 18px;
            padding-right: 18px;
          }

          .title {
            font-size: 26px;
          }
        }
      </style>
    </head>
    <body>
      <main class="page">
        <section class="shell">
          <section class="form-panel">
            <div class="card">
              <p class="eyebrow">Reinitialisation du mot de passe</p>
              <h2 class="title">Choisissez un nouveau mot de passe</h2>
              <p class="intro">${escapeHtml(message || "Saisissez votre nouveau mot de passe pour finaliser la reinitialisation.")}</p>
        ${token ? `
          <form id="reset-form" class="reset-form">
            <label class="field">
              Nouveau mot de passe
              <input id="password" type="password" minlength="6" required autocomplete="new-password" />
            </label>
            <label class="field">
              Confirmer le mot de passe
              <input id="confirm-password" type="password" minlength="6" required autocomplete="new-password" />
            </label>
            <p class="field-hint">Minimum 6 caracteres. Utilisez un mot de passe unique.</p>
            <button id="submit-button" class="submit-button" type="submit">
              Mettre a jour le mot de passe
            </button>
            <p id="status" class="status"></p>
          </form>
          <script>
            const token = ${JSON.stringify(token)};
            const form = document.getElementById("reset-form");
            const passwordInput = document.getElementById("password");
            const confirmPasswordInput = document.getElementById("confirm-password");
            const statusElement = document.getElementById("status");
            const submitButton = document.getElementById("submit-button");

            form.addEventListener("submit", async (event) => {
              event.preventDefault();

              if (passwordInput.value !== confirmPasswordInput.value) {
                statusElement.textContent = "Les mots de passe ne correspondent pas.";
                statusElement.style.color = "#b91c1c";
                return;
              }

              submitButton.disabled = true;
              statusElement.textContent = "Mise a jour en cours...";
              statusElement.style.color = "#374151";
              submitButton.textContent = "Mise a jour...";

              try {
                const response = await fetch(window.location.pathname, {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({
                    token,
                    password: passwordInput.value
                  })
                });
                const data = await response.json().catch(() => ({}));

                if (!response.ok) {
                  statusElement.textContent = data.message || "La reinitialisation a echoue.";
                  statusElement.style.color = "#b91c1c";
                  submitButton.disabled = false;
                  submitButton.textContent = "Mettre a jour le mot de passe";
                  return;
                }

                statusElement.textContent = data.message || "Votre mot de passe a ete mis a jour. Vous pouvez maintenant vous reconnecter.";
                statusElement.style.color = "#047857";
                form.reset();
                submitButton.disabled = true;
                submitButton.textContent = "Mot de passe mis a jour";
              } catch (_error) {
                statusElement.textContent = "Une erreur reseau est survenue. Reessayez.";
                statusElement.style.color = "#b91c1c";
                submitButton.disabled = false;
                submitButton.textContent = "Mettre a jour le mot de passe";
              }
            });
          </script>
        ` : `
          <p class="invalid-note">Le lien de reinitialisation est invalide ou incomplet.</p>
        `}
            </div>
          </section>
        </section>
      </main>
    </body>
  </html>
`;

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

    storeRefreshToken(refreshToken, {
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
    const tokenData = getRefreshTokenData(refresh_token);
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
      revokeRefreshToken(refresh_token);
      console.log('🔓 User logged out, token revoked');
    }

    res.json({ message: 'Logout successful' });

  } catch (error) {
    console.error('logout error:', error);
    res.status(500).json({ message: 'Logout failed' });
  }
};

// ============================================
// DRIVER/RESTAURANT EMAIL VERIFICATION
// ============================================

export const requestRegistrationEmailCode = async (req, res) => {
  try {
    if (!isPartnerEmailVerificationRequired()) {
      return res.status(400).json({
        message: 'Partner email verification is disabled'
      });
    }

    const email = normalizeEmailAddress(req.body.email);
    const { type } = req.body;

    const existingUser = await User.findOne({ where: { email } });
    if (!existingUser || existingUser.role !== type) {
      return res.status(404).json({
        message: 'Account not found',
        errors: [{ field: 'email', message: 'Account not found' }]
      });
    }

    if (existingUser.email_verified_at) {
      return res.status(400).json({
        message: 'Email already verified',
        code: 'EMAIL_ALREADY_VERIFIED'
      });
    }

    const result = await sendPartnerEmailVerification({
      userId: existingUser.id,
      email: existingUser.email,
      type,
      verificationBaseUrl: buildPartnerVerificationBaseUrl(req)
    });

    res.json(buildPartnerVerificationEmailResponse(result));
  } catch (error) {
    console.error('requestRegistrationEmailCode error:', error);
    if (error?.status) {
      return res.status(error.status).json({
        message: error.message,
        code: error.code
      });
    }
    res.status(500).json({
      message: 'Failed to send verification email',
      error: error.message
    });
  }
};

export const verifyPartnerEmail = async (req, res) => {
  try {
    const token = String(req.query.token || '').trim();
    if (!token) {
      return res.status(400).send(renderVerificationPage({
        title: 'Lien invalide',
        message: 'Le lien de confirmation est manquant.',
        success: false
      }));
    }

    const result = await confirmPartnerEmailVerification({ token });
    return res.status(200).send(renderVerificationPage({
      title: result.alreadyVerified ? 'Email deja confirme' : 'Email confirme',
      message: result.alreadyVerified
        ? 'Votre email etait deja confirme. Vous pouvez maintenant vous connecter.'
        : 'Votre email a bien ete confirme. Vous pouvez maintenant vous connecter.',
      success: true
    }));
  } catch (error) {
    if ((error?.status || 500) >= 500) {
      console.error('verifyPartnerEmail error:', error);
    } else {
      console.warn('verifyPartnerEmail warning:', error.message);
    }
    return res.status(error?.status || 400).send(renderVerificationPage({
      title: 'Lien invalide ou expire',
      message: error?.message || 'Le lien de confirmation est invalide ou a expire.',
      success: false
    }));
  }
};

export const requestPartnerPasswordReset = async (req, res) => {
  const genericResponse = buildPartnerPasswordResetResponse();

  try {
    const email = normalizeEmailAddress(req.body.email);
    const user = await User.findOne({ where: { email } });

    if (!user || !user.is_active || !['driver', 'restaurant'].includes(user.role)) {
      return res.json(genericResponse);
    }

    try {
      const result = await sendPartnerPasswordReset({
        user,
        passwordResetBaseUrl: buildPartnerPasswordResetBaseUrl(req)
      });

      return res.json(buildPartnerPasswordResetResponse(result));
    } catch (error) {
      console.error('requestPartnerPasswordReset email error:', error);
      return res.json(genericResponse);
    }
  } catch (error) {
    console.error('requestPartnerPasswordReset error:', error);
    return res.json(genericResponse);
  }
};

export const renderPartnerPasswordResetPage = async (req, res) => {
  const token = String(req.query.token || '').trim();

  if (!token) {
    return res.status(400).send(renderPasswordResetPage({
      token: '',
      message: 'Le lien de reinitialisation est invalide ou incomplet.'
    }));
  }

  return res.status(200).send(renderPasswordResetPage({ token }));
};

export const confirmPartnerPasswordReset = async (req, res) => {
  try {
    const token = String(req.body.token || '').trim();
    const password = req.body.password;

    const result = await resetPartnerPassword({ token, password });
    const revokedSessions = revokeRefreshTokensForUser(result.userId);

    return res.json({
      message: 'Votre mot de passe a ete mis a jour. Vous pouvez maintenant vous reconnecter.',
      revoked_sessions: revokedSessions
    });
  } catch (error) {
    if (error?.status) {
      return res.status(error.status).json({
        message: error.message,
        code: error.code
      });
    }

    console.error('confirmPartnerPasswordReset error:', error);
    return res.status(500).json({
      message: 'Failed to reset password',
      error: error.message
    });
  }
};

export const startGoogleMailOAuth = async (_req, res) => {
  try {
    const url = await createGoogleMailAuthUrl();
    res.redirect(url);
  } catch (error) {
    console.error("startGoogleMailOAuth error:", error);
    res.status(error?.status || 500).json({
      message: error.message || "Failed to start Google OAuth"
    });
  }
};

export const handleGoogleMailOAuthCallback = async (req, res) => {
  try {
    const { code, state, error } = req.query;

    if (error) {
      return res.status(400).send(`
        <html><body style="font-family:Arial,sans-serif;padding:24px;">
          <h2>Google OAuth refused</h2>
          <p>${String(error)}</p>
        </body></html>
      `);
    }

    const tokens = await exchangeGoogleMailAuthCode({
      code: String(code || ""),
      state: String(state || "")
    });

    const refreshToken = tokens.refresh_token || "";

    res.status(200).send(`
      <html>
        <body style="font-family:Arial,sans-serif;padding:24px;line-height:1.5;">
          <h2>Google OAuth completed</h2>
          <p>Copy this refresh token and keep it secret.</p>
          <pre style="white-space:pre-wrap;word-break:break-word;background:#f3f4f6;padding:16px;border-radius:8px;">${refreshToken || "No refresh token returned"}</pre>
          <p>If no refresh token was returned, revoke the app access in your Google account and retry.</p>
        </body>
      </html>
    `);
  } catch (error) {
    console.error("handleGoogleMailOAuthCallback error:", error);
    res.status(error?.status || 500).send(`
      <html>
        <body style="font-family:Arial,sans-serif;padding:24px;line-height:1.5;">
          <h2>Google OAuth failed</h2>
          <p>${error.message || "Unknown error"}</p>
        </body>
      </html>
    `);
  }
};

export const register = async (req, res) => {
  try {
    const {
      email,
      password,
      type,
      device_token,
      device_platform,
      device_id,
      ...profileData
    } = req.body;
    const normalizedEmail = normalizeEmailAddress(email);
    const requiresEmailVerification = isPartnerEmailVerificationRequired();

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

    const existingUser = await User.findOne({ where: { email: normalizedEmail } });
    if (existingUser) {
      if (existingUser.role !== type) {
        return res.status(400).json({
          message: 'Email already registered',
          errors: [{ field: 'email', message: 'Email already registered' }]
        });
      }

      if (existingUser.email_verified_at || !requiresEmailVerification) {
        return res.status(400).json({
          message: 'Email already registered',
          errors: [{ field: 'email', message: 'Email already registered' }]
        });
      }

      const existingProfile = await loadPartnerRegistrationProfile(existingUser);
      if (!existingProfile) {
        return res.status(409).json({
          message: 'Existing account is incomplete. Please contact support.',
          code: 'ACCOUNT_REGISTRATION_INCOMPLETE'
        });
      }

      let verificationEmailResult = null;
      let verificationEmailError = null;

      try {
        verificationEmailResult = await sendPartnerEmailVerification({
          userId: existingUser.id,
          email: existingUser.email,
          type,
          verificationBaseUrl: buildPartnerVerificationBaseUrl(req)
        });
      } catch (error) {
        verificationEmailError = error;
        console.error('Partner verification email resend error during register:', error);
      }

      return res.status(200).json(
        buildPendingPartnerVerificationRegistrationResponse({
          user: existingUser,
          profile: existingProfile,
          verificationEmailResult,
          verificationEmailError,
          alreadyRegistered: true
        })
      );
    }

    // Map type to role for User model
    const role = type;
    const { user, profile } = await sequelize.transaction(async (transaction) => {
      const user = await User.create({
        email: normalizedEmail,
        password,
        role,
        email_verified_at: requiresEmailVerification ? null : new Date()
      }, { transaction });
      let profile;

      switch (type) {
        case 'driver':
          profile = await Driver.create({
            user_id: user.id,
            email: normalizedEmail,
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
            email: profileData.email || normalizedEmail || null,
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
            opening_hours: normalizeOpeningHours(profileData.opening_hours)
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

    if (requiresEmailVerification) {
      let verificationEmailResult = null;
      let verificationEmailError = null;

      try {
        verificationEmailResult = await sendPartnerEmailVerification({
          userId: user.id,
          email: user.email,
          type,
          verificationBaseUrl: buildPartnerVerificationBaseUrl(req)
        });
      } catch (error) {
        verificationEmailError = error;
        console.error('Partner verification email send error:', error);
      }

      return res.status(201).json(
        buildPendingPartnerVerificationRegistrationResponse({
          user,
          profile,
          verificationEmailResult,
          verificationEmailError
        })
      );
    }

    // For driver/restaurant, also use refresh tokens
    const deviceId = device_id || `device-${Date.now()}`;
    const accessPayload = {
      id: user.id,
      role: user.role,
      type: 'access'
    };
    const refreshPayload = {
      id: user.id,
      role: user.role,
      type: 'refresh',
      deviceId
    };

    if (type === 'driver') {
      accessPayload.driver_id = profile?.id || null;
      refreshPayload.driver_id = profile?.id || null;
    }

    if (type === 'restaurant') {
      accessPayload.restaurant_id = profile?.id || null;
      refreshPayload.restaurant_id = profile?.id || null;
    }

    const accessToken = signAccessToken(accessPayload);
    const refreshToken = signRefreshToken(refreshPayload);

    storeRefreshToken(refreshToken, {
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
        role: user.role,
        email_verified_at: user.email_verified_at
      },
      profile
    });

  } catch (error) {
    if (error?.status && error.status < 500) {
      console.warn('Registration warning:', error.message);
    } else {
      console.error('Registration error:', error);
    }
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

    if (
      isPartnerEmailVerificationRequired() &&
      ['driver', 'restaurant'].includes(user.role) &&
      !user.email_verified_at
    ) {
      return res.status(403).json({
        message: 'Email not verified. Please confirm your email before logging in.',
        code: 'EMAIL_NOT_VERIFIED'
      });
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
    storeRefreshToken(refreshToken, {
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


