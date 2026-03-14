import { body, param, query } from "express-validator";

const nestedAdditionValidators = (path) => [
  body(`${path}.*.id`)
    .optional()
    .isUUID().withMessage(`${path}.*.id must be a valid UUID`),

  body(`${path}.*.option_group_id`)
    .optional({ nullable: true })
    .isUUID().withMessage(`${path}.*.option_group_id must be a valid UUID`),

  body(`${path}.*.nom`)
    .optional()
    .isString().withMessage(`${path}.*.nom must be a string`)
    .isLength({ min: 1, max: 255 }).withMessage(`${path}.*.nom must be between 1 and 255 characters`),

  body(`${path}.*.description`)
    .optional({ nullable: true })
    .isString().withMessage(`${path}.*.description must be a string`)
    .isLength({ max: 1000 }).withMessage(`${path}.*.description must be less than 1000 characters`),

  body(`${path}.*.prix`)
    .optional()
    .isFloat({ min: 0 }).withMessage(`${path}.*.prix must be a positive number`),

  body(`${path}.*.is_available`)
    .optional()
    .isBoolean().withMessage(`${path}.*.is_available must be true or false`)
];

const nestedOptionGroupValidators = (path) => [
  body(path)
    .optional()
    .isArray().withMessage(`${path} must be an array`),

  body(`${path}.*.id`)
    .optional()
    .isUUID().withMessage(`${path}.*.id must be a valid UUID`),

  body(`${path}.*.nom`)
    .optional()
    .isString().withMessage(`${path}.*.nom must be a string`)
    .isLength({ min: 1, max: 255 }).withMessage(`${path}.*.nom must be between 1 and 255 characters`),

  body(`${path}.*.description`)
    .optional({ nullable: true })
    .isString().withMessage(`${path}.*.description must be a string`)
    .isLength({ max: 1000 }).withMessage(`${path}.*.description must be less than 1000 characters`),

  body(`${path}.*.is_required`)
    .optional()
    .isBoolean().withMessage(`${path}.*.is_required must be true or false`),

  body(`${path}.*.ordre_affichage`)
    .optional()
    .isInt({ min: 0 }).withMessage(`${path}.*.ordre_affichage must be a positive integer`),

  body(`${path}.*.options`)
    .optional()
    .isArray().withMessage(`${path}.*.options must be an array`),

  body(`${path}.*.additions`)
    .optional()
    .isArray().withMessage(`${path}.*.additions must be an array`),

  ...nestedAdditionValidators(`${path}.*.options`),
  ...nestedAdditionValidators(`${path}.*.additions`)
];

const nestedMenuItemValidators = [
  body("additions")
    .optional()
    .isArray().withMessage("additions must be an array"),

  body("options")
    .optional()
    .isArray().withMessage("options must be an array"),

  ...nestedAdditionValidators("additions"),
  ...nestedAdditionValidators("options"),
  ...nestedOptionGroupValidators("option_groups"),
  ...nestedOptionGroupValidators("group_options")
];

export const createMenuItemValidator = [
  body("category_id")
    .notEmpty().withMessage("category_id is required")
    .isUUID().withMessage("category_id must be a valid UUID"),

  body("nom")
    .notEmpty().withMessage("nom is required")
    .isString().withMessage("nom must be a string")
    .isLength({ min: 2, max: 255 }).withMessage("nom must be between 2 and 255 characters"),

  body("description")
    .optional()
    .isString().withMessage("description must be a string")
    .isLength({ max: 1000 }).withMessage("description must be less than 1000 characters"),

  body("prix")
    .notEmpty().withMessage("prix is required")
    .isFloat({ min: 0 }).withMessage("prix must be a positive number"),

  body("photo_url")
    .optional()
    .isString().withMessage("photo_url must be a string")
    .isURL().withMessage("photo_url must be a valid URL"),

  body("temps_preparation")
    .optional()
    .isInt({ min: 1, max: 300 }).withMessage("temps_preparation must be between 1 and 300 minutes"),

  body("is_available")
    .optional()
    .isBoolean().withMessage("is_available must be true or false"),

  ...nestedMenuItemValidators
];

export const updateMenuItemValidator = [
  param("id")
    .notEmpty().withMessage("Menu item ID is required")
    .isUUID().withMessage("Menu item ID must be a valid UUID"),

  body("category_id")
    .optional()
    .isUUID().withMessage("category_id must be a valid UUID"),

  body("nom")
    .optional()
    .isString().withMessage("nom must be a string")
    .isLength({ min: 2, max: 255 }).withMessage("nom must be between 2 and 255 characters"),

  body("description")
    .optional()
    .isString().withMessage("description must be a string")
    .isLength({ max: 1000 }).withMessage("description must be less than 1000 characters"),

  body("prix")
    .optional()
    .isFloat({ min: 0 }).withMessage("prix must be a positive number"),

  body("photo_url")
    .optional()
    .isString().withMessage("photo_url must be a string")
    .isURL().withMessage("photo_url must be a valid URL"),

  body("temps_preparation")
    .optional()
    .isInt({ min: 1, max: 300 }).withMessage("temps_preparation must be between 1 and 300 minutes"),

  body("is_available")
    .optional()
    .isBoolean().withMessage("is_available must be true or false"),

  ...nestedMenuItemValidators
];

export const getMenuItemByIdValidator = [
  param("id")
    .notEmpty().withMessage("Menu item ID is required")
    .isUUID().withMessage("Menu item ID must be a valid UUID")
];

export const getMyMenuItemsValidator = [
  query("page")
    .optional()
    .isInt({ min: 1 }).withMessage("page must be a positive integer"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 1000 }).withMessage("limit must be between 1 and 1000"),

  query("category_id")
    .optional()
    .isUUID().withMessage("category_id must be a valid UUID"),

  query("is_available")
    .optional()
    .isBoolean().withMessage("is_available must be true or false"),

  query("search")
    .optional()
    .isString().withMessage("search must be a string")
    .isLength({ min: 2, max: 100 }).withMessage("search must be between 2 and 100 characters"),

  query("sort")
    .optional()
    .isIn(["nom", "prix", "created_at"])
    .withMessage("sort must be one of: nom, prix, created_at")
];

export const getAllMenuItemsValidator = [
  query("page")
    .optional()
    .isInt({ min: 1 }).withMessage("page must be a positive integer"),

  query("limit")
    .optional()
    .isInt({ min: 1, max: 1000 }).withMessage("limit must be between 1 and 1000"),

  query("category_id")
    .optional()
    .isUUID().withMessage("category_id must be a valid UUID"),

  query("is_available")
    .optional()
    .isBoolean().withMessage("is_available must be true or false"),

  query("search")
    .optional()
    .isString().withMessage("search must be a string")
    .isLength({ min: 2, max: 100 }).withMessage("search must be between 2 and 100 characters")
];

export const getByCategoryValidator = [
  body("client_id")
    .optional()
    .isUUID().withMessage("client_id must be a valid UUID"),

  body("category_id")
    .optional()
    .isUUID().withMessage("category_id must be a valid UUID"),

  body("is_available")
    .optional()
    .isBoolean().withMessage("is_available must be true or false")
];

export const deleteMenuItemValidator = [
  param("id")
    .notEmpty().withMessage("Menu item ID is required")
    .isUUID().withMessage("Menu item ID must be a valid UUID")
];

export const toggleAvailabilityValidator = [
  param("id")
    .notEmpty().withMessage("Menu item ID is required")
    .isUUID().withMessage("Menu item ID must be a valid UUID")
];

export const bulkUpdateAvailabilityValidator = [
  body("menu_item_ids")
    .isArray({ min: 1 }).withMessage("menu_item_ids must be a non-empty array")
    .custom((value) => {
      if (!value.every((id) => typeof id === "string")) {
        throw new Error("All menu_item_ids must be valid UUIDs");
      }
      return true;
    }),

  body("is_available")
    .notEmpty().withMessage("is_available is required")
    .isBoolean().withMessage("is_available must be true or false")
];
