import express from 'express';
import { 
  requestRegistrationEmailCode,
  verifyPartnerEmail,
  requestPartnerPasswordReset,
  renderPartnerPasswordResetPage,
  confirmPartnerPasswordReset,
  startGoogleMailOAuth,
  handleGoogleMailOAuthCallback,
  register, 
  login, 
  getProfile,
  requestOTP,
  requestOTPDirect,
  verifyOTP,
  refreshAccessToken,  
  logout, 
  registerCashier        
} from '../controllers/auth.controller.js';
import { protect, authorize } from '../middlewares/auth.js';
import { cacheMiddleware, invalidateCache } from '../middlewares/cache.middleware.js';
import { validate } from '../middlewares/validate.js';
import { authRateLimiter, otpRateLimiter } from '../middlewares/security.js';
import {
  requestOTPValidator,
  requestRegistrationEmailCodeValidator,
  requestPasswordResetValidator,
  resetPasswordValidator,
  verifyOTPValidator,
  registerValidator,
  loginValidator,
  refreshTokenValidator,
  logoutValidator
} from '../validators/authValidator.js';
import { registerCashierValidator } from '../validators/cashierValidator.js';

const router = express.Router();
router.use(
  invalidateCache([
    'cache:GET:/auth*',
    'cache:GET:/api/v1/auth*'
  ])
);

/**
 * Request an OTP for passwordless login.
 * Sends an OTP to the user's phone number.
 */
router.post('/otp/request', otpRateLimiter, requestOTPValidator, validate, requestOTP);
router.post('/otp/request-direct', otpRateLimiter, requestOTPValidator, validate, requestOTPDirect);

/**
 * Verify the OTP and log the user in.
 * Returns access and refresh tokens on success.
 */
router.post('/otp/verify', otpRateLimiter, verifyOTPValidator, validate, verifyOTP);

/**
 * Send or resend the email verification link for driver/restaurant registration.
 */
router.post(
  '/register/email/request-code',
  otpRateLimiter,
  requestRegistrationEmailCodeValidator,
  validate,
  requestRegistrationEmailCode
);
router.post(
  '/register/email/resend',
  otpRateLimiter,
  requestRegistrationEmailCodeValidator,
  validate,
  requestRegistrationEmailCode
);
router.get('/verify-email', verifyPartnerEmail);

router.post(
  '/password/forgot',
  otpRateLimiter,
  requestPasswordResetValidator,
  validate,
  requestPartnerPasswordReset
);
router.get('/password/reset', renderPartnerPasswordResetPage);
router.post(
  '/password/reset',
  authRateLimiter,
  resetPasswordValidator,
  validate,
  confirmPartnerPasswordReset
);

router.get('/google-mail/start', startGoogleMailOAuth);
router.get('/callback', handleGoogleMailOAuthCallback);

/**
 * Register a new user account.
 * Can be used for drivers or restaurants.
 */
router.post('/register', authRateLimiter, registerValidator, validate, register);

/**
 * Log in using email and password.
 * Returns access and refresh tokens for authenticated users.
 */
router.post('/login', authRateLimiter, loginValidator, validate, login);

/**
 * Refresh the access token using a valid refresh token.
 */
router.post('/refresh', authRateLimiter, refreshTokenValidator, validate, refreshAccessToken);

/**
 * Log out and revoke the refresh token.
 * Effectively ends the session on the device.
 */
router.post('/logout', authRateLimiter, logoutValidator, validate, logout);

/**
 * Retrieve the current authenticated user's profile.
 * Requires a valid bearer token.
 */
router.get('/profile', protect, cacheMiddleware({ ttl: 30 }), getProfile);

/**
 * Register a new cashier account.
 * Can only be done by admins or restaurant owners.
 */
router.post(
  '/register/cashier',
  protect,
  authorize('admin', 'restaurant'),
  registerCashierValidator,
  validate,
  registerCashier
);

export default router;
