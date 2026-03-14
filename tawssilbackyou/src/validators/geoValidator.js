import { body, param } from "express-validator";

export const createWilayaValidator = [
  body("code")
    .notEmpty()
    .withMessage("Code is required")
    .isLength({ min: 1, max: 10 })
    .withMessage("Code must be between 1 and 10 characters"),

  body("name")
    .notEmpty()
    .withMessage("Name is required")
    .isLength({ min: 2, max: 120 })
    .withMessage("Name must be between 2 and 120 characters"),

  body("name_ar")
    .optional()
    .isLength({ max: 120 })
    .withMessage("Arabic name must be at most 120 characters")
];

export const updateWilayaValidator = [
  param("code")
    .notEmpty()
    .withMessage("Wilaya code is required"),

  body("name")
    .optional()
    .isLength({ min: 2, max: 120 })
    .withMessage("Name must be between 2 and 120 characters"),

  body("name_ar")
    .optional()
    .isLength({ max: 120 })
    .withMessage("Arabic name must be at most 120 characters")
];

export const deleteWilayaValidator = [
  param("code")
    .notEmpty()
    .withMessage("Wilaya code is required")
];

export const createCommuneValidator = [
  body("name")
    .notEmpty()
    .withMessage("Name is required")
    .isLength({ min: 2, max: 120 })
    .withMessage("Name must be between 2 and 120 characters"),

  body("wilaya_code")
    .notEmpty()
    .withMessage("Wilaya code is required")
    .isLength({ min: 1, max: 10 })
    .withMessage("Wilaya code must be between 1 and 10 characters"),

  body("lat")
    .notEmpty()
    .withMessage("lat is required")
    .isFloat({ min: -90, max: 90 })
    .withMessage("lat must be between -90 and 90"),

  body("lng")
    .notEmpty()
    .withMessage("lng is required")
    .isFloat({ min: -180, max: 180 })
    .withMessage("lng must be between -180 and 180"),

  body("code")
    .optional()
    .isLength({ max: 20 })
    .withMessage("Commune code must be at most 20 characters"),

  body("name_ar")
    .optional()
    .isLength({ max: 120 })
    .withMessage("Arabic name must be at most 120 characters")
];

export const updateCommuneValidator = [
  param("id")
    .isUUID()
    .withMessage("Invalid commune id"),

  body("name")
    .optional()
    .isLength({ min: 2, max: 120 })
    .withMessage("Name must be between 2 and 120 characters"),

  body("wilaya_code")
    .optional()
    .isLength({ min: 1, max: 10 })
    .withMessage("Wilaya code must be between 1 and 10 characters"),

  body("lat")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("lat must be between -90 and 90"),

  body("lng")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("lng must be between -180 and 180"),

  body("code")
    .optional()
    .isLength({ max: 20 })
    .withMessage("Commune code must be at most 20 characters"),

  body("name_ar")
    .optional()
    .isLength({ max: 120 })
    .withMessage("Arabic name must be at most 120 characters"),

  body().custom((value, { req }) => {
    const hasLat = req.body.lat !== undefined;
    const hasLng = req.body.lng !== undefined;
    if (hasLat !== hasLng) {
      throw new Error("lat and lng are required together");
    }
    return true;
  })
];

export const deleteCommuneValidator = [
  param("id")
    .isUUID()
    .withMessage("Invalid commune id")
];
