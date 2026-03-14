import User from '../models/User.js';
import Client from '../models/Client.js';
import { verifyAccessToken } from '../config/security.js';

// Protect routes - verify access token
export const protect = async (req, res, next) => {
  try {
    let token;

    // Get token from Authorization header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ message: 'Unauthorized - Missing token' });
    }

    // Verify access token
    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (error) {
      // Token expired or invalid
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          message: 'Token expired',
          code: 'TOKEN_EXPIRED',
          expired: true
        });
      }
      return res.status(401).json({ message: 'Invalid token' });
    }

    // Must be an access token
    if (decoded.type !== 'access') {
      return res.status(401).json({ message: 'Invalid token type' });
    }

    // Load user
    req.user = await User.findByPk(decoded.id, {
      attributes: { exclude: ['password'] }
    });

    if (!req.user) {
      return res.status(401).json({ message: 'User not found' });
    }

    if (!req.user.is_active) {
      return res.status(403).json({ message: 'Account disabled' });
    }

    // Add profile IDs from token (no DB query needed!)
    if (decoded.client_id) {
      req.user.client_id = decoded.client_id;
    }

    if (decoded.driver_id) {
      req.user.driver_id = decoded.driver_id;
    }

    if (decoded.restaurant_id) {
      req.user.restaurant_id = decoded.restaurant_id;
    }

    if (decoded.admin_id) {
      req.user.admin_id = decoded.admin_id;
    }

    // ✅ FIX: Add cashier_id from token
    if (decoded.cashier_id) {
      req.user.cashier_id = decoded.cashier_id;
    }

    next();

  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(401).json({ message: 'Not authorized' });
  }
};

// Optional auth (uses token if provided, but doesn't require it)
export const optionalProtect = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return next();
    }

    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          message: 'Token expired',
          code: 'TOKEN_EXPIRED',
          expired: true
        });
      }
      return res.status(401).json({ message: 'Invalid token' });
    }

    if (decoded.type !== 'access') {
      return res.status(401).json({ message: 'Invalid token type' });
    }

    req.user = await User.findByPk(decoded.id, {
      attributes: { exclude: ['password'] }
    });

    if (!req.user) {
      return res.status(401).json({ message: 'User not found' });
    }

    if (!req.user.is_active) {
      return res.status(403).json({ message: 'Account disabled' });
    }

    if (decoded.client_id) req.user.client_id = decoded.client_id;
    if (decoded.driver_id) req.user.driver_id = decoded.driver_id;
    if (decoded.restaurant_id) req.user.restaurant_id = decoded.restaurant_id;
    if (decoded.admin_id) req.user.admin_id = decoded.admin_id;
    if (decoded.cashier_id) req.user.cashier_id = decoded.cashier_id;

    next();
  } catch (error) {
    console.error('Optional auth middleware error:', error);
    return res.status(401).json({ message: 'Not authorized' });
  }
};

// Verify role
export const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        message: `Role ${req.user.role} not authorized for this action`
      });
    }
    next();
  };
};

// Role-specific middlewares
export const isClient = (req, res, next) => {
  if (req.user.role !== 'client') {
    return res.status(403).json({ message: 'Access restricted to customers' });
  }
  next();
};

export const isDriver = (req, res, next) => {
  if (req.user.role !== 'driver') {
    return res.status(403).json({ message: 'Access restricted to drivers' });
  }
  next();
};

export const requireActiveClient = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (req.user.role !== 'client') {
      return res.status(403).json({
        success: false,
        message: 'Access restricted to customers'
      });
    }

    const tokenClientId = req.user.client_id;
    const client = tokenClientId
      ? await Client.findByPk(tokenClientId)
      : await Client.findOne({ where: { user_id: req.user.id } });

    if (!client) {
      return res.status(403).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    // Keep req.user.client_id consistent even if token was missing/outdated.
    req.user.client_id = client.id;
    req.client = client;

    if (!client.is_active) {
      return res.status(403).json({
        success: false,
        message: 'Client account is disabled. Please contact an administrator.',
        code: 'CLIENT_DISABLED',
        client: {
          id: client.id,
          is_active: client.is_active
        }
      });
    }

    next();
  } catch (error) {
    console.error('requireActiveClient middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

export const isRestaurant = (req, res, next) => {
  if (req.user.role !== 'restaurant') {
    return res.status(403).json({ message: 'Access restricted to restaurants' });
  }
  next();
};

export const isAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access restricted to administrators' });
  }
  next();
};


export const isCashier = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (req.user.role !== 'cashier') {
      return res.status(403).json({
        success: false,
        message: 'This route is only accessible to cashiers'
      });
    }

    // Verify cashier profile exists
    if (!req.user.cashier_id) {
      return res.status(403).json({
        success: false,
        message: 'Cashier profile not found'
      });
    }

    next();
  } catch (error) {
    console.error('isCashier middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};
