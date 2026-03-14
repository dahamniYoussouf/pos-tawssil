import { body } from "express-validator";
import { SUPPORTED_LOCALES } from "../utils/locale.js";

export const subscribeNewsletterValidator = [
  body("email")
    .trim()
    .notEmpty()
    .withMessage("Email is required")
    .isEmail()
    .withMessage("Invalid email format")
    .normalizeEmail(),
  body("name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 120 })
    .withMessage("Name must be between 2 and 120 characters"),
  body("locale")
    .optional()
    .trim()
    .isIn(SUPPORTED_LOCALES)
    .withMessage("Locale must be one of: ar, fr, en"),
  body("source")
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage("Source must be 50 characters or less")
];

export const unsubscribeNewsletterValidator = [
  body("email")
    .trim()
    .notEmpty()
    .withMessage("Email is required")
    .isEmail()
    .withMessage("Invalid email format")
    .normalizeEmail()
];
