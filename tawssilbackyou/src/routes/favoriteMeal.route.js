import express from "express";
import {
  addFavoriteMeal,
  removeFavoriteMeal,
  getFavoriteMeals,
  updateFavoriteMeal
} from "../controllers/favoriteMeal.controller.js";
import {
  addFavoriteMealValidator,
  removeFavoriteMealValidator,
  getFavoriteMealsValidator,
  updateFavoriteMealValidator
} from "../validators/favoriteMealValidator.js";
import { validate } from "../middlewares/validate.js";
import { protect, isClient, requireActiveClient } from "../middlewares/auth.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";

const router = express.Router();

router.use(
  invalidateCache([
    "cache:GET:/favoritemeal*",
    "cache:GET:/api/v1/favorite-meals*",
    // Favorites affect menu items & restaurant details
    "cache:GET:/menuitem*",
    "cache:GET:/api/v1/menu-items*",
    "cache:GET:/restaurant/details*",
    "cache:GET:/api/v1/restaurants/details*",
    "cache:GET:/restaurant/admin/details*",
    "cache:GET:/api/v1/restaurants/admin/details*",
    // Custom caches
    "restaurant:details:*"
  ])
);

router.post("/create", protect, isClient, requireActiveClient, addFavoriteMealValidator, validate, addFavoriteMeal);
router.delete("/delete", protect, isClient, requireActiveClient, removeFavoriteMealValidator, validate, removeFavoriteMeal);
router.delete("/delete/:favorite_uuid", protect, isClient, requireActiveClient, removeFavoriteMealValidator, validate, removeFavoriteMeal);
router.get("/getclientfavorites", protect, isClient, requireActiveClient, getFavoriteMealsValidator, validate, cacheMiddleware({ ttl: 30 }), getFavoriteMeals);
router.patch("/updatefavorite/:favorite_uuid", protect, isClient, requireActiveClient, updateFavoriteMealValidator, validate, updateFavoriteMeal);

export default router;
