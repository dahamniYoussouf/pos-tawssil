import { body, param } from "express-validator";

export const createOptionGroupValidator = [
  body("menu_item_id")
    .notEmpty().withMessage("menu_item_id is required")
    .isUUID().withMessage("menu_item_id must be a valid UUID"),

  body("nom")
    .notEmpty().withMessage("nom is required")
    .isString().withMessage("nom must be a string")
    .isLength({ min: 2, max: 255 }).withMessage("nom must be between 2 and 255 characters"),

  body("description")
    .optional()
    .isString().withMessage("description must be a string")
    .isLength({ max: 1000 }).withMessage("description must be less than 1000 characters"),

  body("is_required")
    .optional()
    .isBoolean().withMessage("is_required must be true or false"),

  body("ordre_affichage")
    .optional()
    .isInt({ min: 0 }).withMessage("ordre_affichage must be a positive integer"),
];

export const updateOptionGroupValidator = [
  param("id")
    .notEmpty().withMessage("Option group ID is required")
    .isUUID().withMessage("Option group ID must be a valid UUID"),

  body("menu_item_id")
    .optional()
    .isUUID().withMessage("menu_item_id must be a valid UUID"),

  body("nom")
    .optional()
    .isString().withMessage("nom must be a string")
    .isLength({ min: 2, max: 255 }).withMessage("nom must be between 2 and 255 characters"),

  body("description")
    .optional()
    .isString().withMessage("description must be a string")
    .isLength({ max: 1000 }).withMessage("description must be less than 1000 characters"),

  body("is_required")
    .optional()
    .isBoolean().withMessage("is_required must be true or false"),

  body("ordre_affichage")
    .optional()
    .isInt({ min: 0 }).withMessage("ordre_affichage must be a positive integer"),
];

export const deleteOptionGroupValidator = [
  param("id")
    .notEmpty().withMessage("Option group ID is required")
    .isUUID().withMessage("Option group ID must be a valid UUID"),
];

export const getOptionGroupsByMenuItemValidator = [
  param("menu_item_id")
    .notEmpty().withMessage("menu_item_id is required")
    .isUUID().withMessage("menu_item_id must be a valid UUID"),
];
