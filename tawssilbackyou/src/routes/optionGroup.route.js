import { Router } from "express";
import { validate } from "../middlewares/validate.js";
import { protect, isRestaurant, isAdmin } from "../middlewares/auth.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";
import * as optionGroupCtrl from "../controllers/optionGroup.controller.js";
import {
  createOptionGroupValidator,
  updateOptionGroupValidator,
  deleteOptionGroupValidator,
  getOptionGroupsByMenuItemValidator
} from "../validators/optionGroupValidator.js";
import { body, query } from "express-validator";

const router = Router();

router.use(
  invalidateCache([
    "cache:GET:/option-group*",
    "cache:GET:/api/v1/option-groups*",
    "cache:GET:/menuitem*",
    "cache:GET:/api/v1/menu-items*",
    "cache:GET:/restaurant/details*",
    "cache:GET:/api/v1/restaurants/details*",
    "cache:GET:/restaurant/admin/details*",
    "cache:GET:/api/v1/restaurants/admin/details*",
    "restaurant:details:*"
  ])
);

const requireRestaurantIdBody = body("restaurant_id")
  .notEmpty()
  .withMessage("restaurant_id is required")
  .isUUID()
  .withMessage("restaurant_id must be a valid UUID");

const requireRestaurantIdQuery = query("restaurant_id")
  .notEmpty()
  .withMessage("restaurant_id is required")
  .isUUID()
  .withMessage("restaurant_id must be a valid UUID");

const adminCreateOptionGroupValidator = [
  ...createOptionGroupValidator,
  requireRestaurantIdBody
];

const adminUpdateOptionGroupValidator = [
  ...updateOptionGroupValidator,
  requireRestaurantIdBody
];

const adminDeleteOptionGroupValidator = [
  ...deleteOptionGroupValidator,
  requireRestaurantIdBody
];

const adminGetOptionGroupsByMenuItemValidator = [
  ...getOptionGroupsByMenuItemValidator,
  requireRestaurantIdQuery
];

router.post(
  "/create",
  protect,
  isRestaurant,
  createOptionGroupValidator,
  validate,
  optionGroupCtrl.create
);

router.put(
  "/update/:id",
  protect,
  isRestaurant,
  updateOptionGroupValidator,
  validate,
  optionGroupCtrl.update
);

router.delete(
  "/delete/:id",
  protect,
  isRestaurant,
  deleteOptionGroupValidator,
  validate,
  optionGroupCtrl.remove
);

router.get(
  "/by-menu-item/:menu_item_id",
  protect,
  isRestaurant,
  getOptionGroupsByMenuItemValidator,
  validate,
  cacheMiddleware({ ttl: 60 }),
  optionGroupCtrl.getByMenuItem
);

router.post(
  "/admin/create",
  protect,
  isAdmin,
  adminCreateOptionGroupValidator,
  validate,
  optionGroupCtrl.create
);

router.put(
  "/admin/update/:id",
  protect,
  isAdmin,
  adminUpdateOptionGroupValidator,
  validate,
  optionGroupCtrl.update
);

router.delete(
  "/admin/delete/:id",
  protect,
  isAdmin,
  adminDeleteOptionGroupValidator,
  validate,
  optionGroupCtrl.remove
);

router.get(
  "/admin/by-menu-item/:menu_item_id",
  protect,
  isAdmin,
  adminGetOptionGroupsByMenuItemValidator,
  validate,
  cacheMiddleware({ ttl: 60 }),
  optionGroupCtrl.getByMenuItem
);

export default router;
