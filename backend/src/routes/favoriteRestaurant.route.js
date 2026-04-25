import express from "express";
import {
  addFavoriteRestaurant,
  removeFavoriteRestaurant,
  getFavoriteRestaurants,
  updateFavoriteRestaurant
} from "../controllers/favoriteRestaurant.controller.js";
import {
  addFavoriteRestaurantValidator,
  removeFavoriteRestaurantValidator,
  getFavoriteRestaurantsValidator,
  updateFavoriteRestaurantValidator
} from "../validators/favoriteRestaurantValidator.js";
import { validate } from "../middlewares/validate.js";
import { protect, isClient, requireActiveClient } from "../middlewares/auth.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";

const router = express.Router();

router.use(
  invalidateCache([
    "cache:GET:/favoriterestaurant*",
    "cache:GET:/api/v1/favorite-restaurants*",
    // Favorites affect restaurant cards across the app
    "cache:GET:/restaurant*",
    "cache:GET:/api/v1/restaurants*",
    // Custom caches
    "restaurant:nearby:*",
    "restaurant:details:*"
  ])
);

router.post("/create", protect, isClient, requireActiveClient, addFavoriteRestaurantValidator, validate, addFavoriteRestaurant);
router.delete("/delete", protect, isClient, requireActiveClient, removeFavoriteRestaurantValidator, validate, removeFavoriteRestaurant);
router.delete("/delete/:favorite_uuid", protect, isClient, requireActiveClient, removeFavoriteRestaurantValidator, validate, removeFavoriteRestaurant);
router.get("/getclientfavorites", protect, isClient, requireActiveClient, getFavoriteRestaurantsValidator, validate, cacheMiddleware({ ttl: 30 }), getFavoriteRestaurants);
router.patch("/updatefavorite/:favorite_uuid", protect, isClient, requireActiveClient, updateFavoriteRestaurantValidator, validate, updateFavoriteRestaurant);

export default router;
