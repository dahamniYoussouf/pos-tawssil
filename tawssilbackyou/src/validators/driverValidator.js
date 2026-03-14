// src/validators/driverValidator.js
import { body, param , query} from "express-validator";
import { normalizePhoneNumber } from "../utils/phoneNormalizer.js";
import { SUPPORTED_LOCALES } from "../utils/locale.js";

export const createDriverValidator = [
  body("first_name")
    .notEmpty()
    .withMessage("First name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("First name must be between 2 and 100 characters"),

  body("last_name")
    .notEmpty()
    .withMessage("Last name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("Last name must be between 2 and 100 characters"),

  body("phone")
    .notEmpty()
    .withMessage("Phone is required")
    .customSanitizer((value) => normalizePhoneNumber(value))
    .matches(/^213\d{9,}$/)
    .withMessage("Invalid phone number format (must start with 213)"),

  body("email")
    .optional()
    .isEmail()
    .withMessage("Email must be valid"),

  body("password")
    .optional()
    .isLength({ min: 6 })
    .withMessage("Password must be at least 6 characters"),

  body("locale")
    .optional()
    .isIn(SUPPORTED_LOCALES)
    .withMessage("Locale must be one of: ar, fr, en"),

  body("vehicle_type")
    .notEmpty()
    .withMessage("Vehicle type is required")
    .isIn(['motorcycle', 'car', 'bicycle', 'scooter'])
    .withMessage("Vehicle type must be one of: motorcycle, car, bicycle, scooter"),

  body("vehicle_plate")
    .optional()
    .isString()
    .withMessage("Vehicle plate must be a string"),

  body("license_number")
    .optional()
    .isString()
    .withMessage("License number must be a string")
];

export const updateDriverValidator = [
  body("first_name")
    .optional()
    .notEmpty()
    .withMessage("First name cannot be empty")
    .isLength({ min: 2, max: 100 })
    .withMessage("First name must be between 2 and 100 characters"),

  body("last_name")
    .optional()
    .notEmpty()
    .withMessage("Last name cannot be empty")
    .isLength({ min: 2, max: 100 })
    .withMessage("Last name must be between 2 and 100 characters"),

  body("phone")
    .optional()
    .customSanitizer((value) => value ? normalizePhoneNumber(value) : value)
    .matches(/^213\d{9,}$/)
    .withMessage("Invalid phone number format (must start with 213)"),

  body("email")
    .optional()
    .isEmail()
    .withMessage("Email must be valid"),

  body("password")
    .optional()
    .isLength({ min: 6 })
    .withMessage("Password must be at least 6 characters"),

  body("locale")
    .optional()
    .isIn(SUPPORTED_LOCALES)
    .withMessage("Locale must be one of: ar, fr, en"),

  body("vehicle_type")
    .optional()
    .isIn(['motorcycle', 'car', 'bicycle', 'scooter'])
    .withMessage("Vehicle type must be one of: motorcycle, car, bicycle, scooter"),

  body("vehicle_plate")
    .optional()
    .isString()
    .withMessage("Vehicle plate must be a string"),

  body("license_number")
    .optional()
    .isString()
    .withMessage("License number must be a string"),

  body("is_verified")
    .optional()
    .isBoolean()
    .withMessage("is_verified must be true or false"),

  body("is_active")
    .optional()
    .isBoolean()
    .withMessage("is_active must be true or false")
];

export const deleteDriverValidator = [
  param("id")
    .isUUID()
    .withMessage("Invalid driver UUID")
];

export const updateStatusValidator = [
  body("status")
    .notEmpty()
    .withMessage("Status is required")
    .isIn(['available', 'busy', 'offline', 'suspended'])
    .withMessage("Status must be one of: available, busy, offline, suspended")
];


// ===== GET DRIVER BY ID =====
export const getDriverByIdValidator = [
  param("id")
    .notEmpty()
    .withMessage("Driver ID is required")
    .isUUID()
    .withMessage("Invalid driver UUID")
];

// ===== GET ALL DRIVERS (with filters and pagination) =====
export const getAllDriversValidator = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("Page must be a positive integer"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("Limit must be between 1 and 100"),

  query("pageSize")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("PageSize must be between 1 and 100"),

  query("status")
    .optional()
    .isIn(['available', 'busy', 'offline', 'suspended'])
    .withMessage("Status must be one of: available, busy, offline, suspended"),

  query("is_active")
    .optional()
    .isBoolean()
    .withMessage("is_active must be true or false"),

  query("is_verified")
    .optional()
    .isBoolean()
    .withMessage("is_verified must be true or false"),

  query("search")
    .optional()
    .isString()
    .withMessage("Search must be a string")
    .isLength({ min: 2, max: 100 })
    .withMessage("Search must be between 2 and 100 characters")
];

// ===== GET DRIVER DELIVERED ORDERS HISTORY =====
export const getDriverDeliveredHistoryValidator = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("Page must be a positive integer"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("Limit must be between 1 and 100"),

  query("date_from")
    .optional()
    .isISO8601()
    .withMessage("Invalid date format for date_from"),

  query("date_to")
    .optional()
    .isISO8601()
    .withMessage("Invalid date format for date_to")
];

// ===== GET NEARBY COMMUNES =====
export const getNearbyCommunesValidator = [
  query("radius")
    .optional()
    .isInt({ min: 100, max: 50000 })
    .withMessage("Radius must be between 100 and 50000 meters"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage("Limit must be between 1 and 50")
];

// ===== GET NEARBY ZONES WITH ORDERS =====
export const getNearbyZonesValidator = [
  query("radius")
    .optional()
    .isInt({ min: 100, max: 50000 })
    .withMessage("Radius must be between 100 and 50000 meters"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage("Limit must be between 1 and 50"),

  query("status")
    .optional()
    .custom((value) => {
      const allowed = [
        "pending",
        "accepted",
        "preparing",
        "assigned",
        "arrived",
        "delivering",
        "delivered",
        "declined"
      ];
      const statuses = String(value)
        .split(",")
        .map((status) => status.trim())
        .filter(Boolean);
      if (!statuses.length) return true;
      return statuses.every((status) => allowed.includes(status));
    })
    .withMessage(
      "Status must be one of: pending, accepted, preparing, assigned, arrived, delivering, delivered, declined"
    )
];
