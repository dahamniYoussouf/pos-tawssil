import { body, param, query } from "express-validator";

const validateTags = (value) => {
  if (Array.isArray(value)) {
    if (!value.every((tag) => typeof tag === "string")) {
      throw new Error("Each tag must be a string");
    }
    return true;
  }
  if (typeof value !== "string") {
    throw new Error("tags must be a string or an array of strings");
  }
  return true;
};

export const addFavoriteRestaurantValidator = [
  body("restaurant_id")
    .notEmpty()
    .withMessage("restaurant_id is required")
    .isUUID()
    .withMessage("restaurant_id must be a valid UUID"),

  body("client_id")
    .optional()
    .isUUID()
    .withMessage("client_id must be a valid UUID"),

  body("notes")
    .optional()
    .isString()
    .withMessage("notes must be a string")
    .isLength({ max: 1000 })
    .withMessage("notes cannot exceed 1000 characters"),

  body("tags")
    .optional()
    .custom(validateTags)
];

export const removeFavoriteRestaurantValidator = [
  param("favorite_uuid")
    .optional()
    .isUUID()
    .withMessage("favorite_uuid must be a valid UUID"),

  body("restaurant_id")
    .optional()
    .isUUID()
    .withMessage("restaurant_id must be a valid UUID"),

  query("restaurant_id")
    .optional()
    .isUUID()
    .withMessage("restaurant_id must be a valid UUID"),

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
    const restaurantId = req.body?.restaurant_id || req.query?.restaurant_id;
    if (!favoriteUuid && !restaurantId) {
      throw new Error("favorite_uuid or restaurant_id is required");
    }
    return true;
  })
];

export const getFavoriteRestaurantsValidator = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("page must be a positive integer"),

  query("pageSize")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("pageSize must be between 1 and 100")
];

export const updateFavoriteRestaurantValidator = [
  param("favorite_uuid")
    .notEmpty()
    .withMessage("favorite_uuid is required")
    .isUUID()
    .withMessage("favorite_uuid must be a valid UUID"),

  body("notes")
    .optional()
    .isString()
    .withMessage("notes must be a string")
    .isLength({ max: 1000 })
    .withMessage("notes cannot exceed 1000 characters"),

  body("tags")
    .optional()
    .custom(validateTags)
];
