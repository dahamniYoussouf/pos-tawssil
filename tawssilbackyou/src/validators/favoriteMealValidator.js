import { body, param, query } from "express-validator";

export const addFavoriteMealValidator = [
  body("meal_id")
    .notEmpty()
    .withMessage("meal_id is required")
    .isUUID()
    .withMessage("meal_id must be a valid UUID"),

  body("client_id")
    .optional()
    .isUUID()
    .withMessage("client_id must be a valid UUID"),

  body("customizations")
    .optional()
    .isString()
    .withMessage("customizations must be a string")
    .isLength({ max: 500 })
    .withMessage("customizations cannot exceed 500 characters"),

  body("notes")
    .optional()
    .isString()
    .withMessage("notes must be a string")
    .isLength({ max: 1000 })
    .withMessage("notes cannot exceed 1000 characters")
];

export const removeFavoriteMealValidator = [
  param("favorite_uuid")
    .optional()
    .isUUID()
    .withMessage("favorite_uuid must be a valid UUID"),

  body("meal_id")
    .optional()
    .isUUID()
    .withMessage("meal_id must be a valid UUID"),

  query("meal_id")
    .optional()
    .isUUID()
    .withMessage("meal_id must be a valid UUID"),

  body("client_id")
    .optional()
    .isUUID()
    .withMessage("client_id must be a valid UUID"),

  query("client_id")
    .optional()
    .isUUID()
    .withMessage("client_id must be a valid UUID"),

  body().custom((_, { req }) => {
    const favoriteUuid = req.params?.favorite_uuid;
    const mealId = req.body?.meal_id || req.query?.meal_id;
    if (!favoriteUuid && !mealId) {
      throw new Error("favorite_uuid or meal_id is required");
    }
    return true;
  })
];

export const getFavoriteMealsValidator = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("page must be a positive integer"),

  query("pageSize")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("pageSize must be between 1 and 100")
];

export const updateFavoriteMealValidator = [
  param("favorite_uuid")
    .notEmpty()
    .withMessage("favorite_uuid is required")
    .isUUID()
    .withMessage("favorite_uuid must be a valid UUID"),

  body("customizations")
    .optional()
    .isString()
    .withMessage("customizations must be a string")
    .isLength({ max: 500 })
    .withMessage("customizations cannot exceed 500 characters"),

  body("notes")
    .optional()
    .isString()
    .withMessage("notes must be a string")
    .isLength({ max: 1000 })
    .withMessage("notes cannot exceed 1000 characters")
];
