// src/routes/driver.routes.js
import express from "express";
import { protect, isDriver, authorize } from "../middlewares/auth.js";
import { validate } from "../middlewares/validate.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";
import {
  getAll,
  getById,
  update,
  remove,
  permanentRemove,
  updateStatus,
  getStatistics, 
  getProfile, 
  updateProfile, 
  getActiveOrders,
  getDeliveredOrdersHistory,
  getNearbyDriverCommunes,
  getNearbyDriverZones
} from "../controllers/driver.controller.js";

import {
  getAllDriversValidator,
  getDriverByIdValidator,
  updateDriverValidator,
  deleteDriverValidator,
  updateStatusValidator,
  getDriverDeliveredHistoryValidator,
  getNearbyCommunesValidator,
  getNearbyZonesValidator
} from "../validators/driverValidator.js";

const router = express.Router();

router.use(
  invalidateCache([
    "cache:GET:/driver*",
    "cache:GET:/api/v1/drivers*",
    "cache:GET:/auth/profile*",
    "cache:GET:/api/v1/auth/profile*"
  ])
);

// ===== PUBLIC/ADMIN ROUTES =====
router.get("/getall", protect, getAllDriversValidator, validate, cacheMiddleware({ ttl: 60 }), getAll);

// ===== PROTECTED ROUTES - DRIVER'S OWN PROFILE =====
router.get("/profile/me", protect, isDriver, cacheMiddleware({ ttl: 30 }), getProfile);
router.put("/profile", protect, isDriver, updateDriverValidator, validate, updateProfile);
router.patch("/status", protect, isDriver, updateStatusValidator, validate, updateStatus);
router.get("/statistics/me", protect, isDriver, cacheMiddleware({ ttl: 30 }), getStatistics);
router.get("/communes/nearby", protect, isDriver, getNearbyCommunesValidator, validate, cacheMiddleware({ ttl: 60 }), getNearbyDriverCommunes);
router.get("/zones/nearby", protect, isDriver, getNearbyZonesValidator, validate, cacheMiddleware({ ttl: 60 }), getNearbyDriverZones);

// Commandes actives du livreur
router.get('/active-orders', protect, isDriver, cacheMiddleware({ ttl: 5 }), getActiveOrders);
// Historique des commandes livrées du livreur
router.get('/orders/history', protect, isDriver, getDriverDeliveredHistoryValidator, validate, cacheMiddleware({ ttl: 30 }), getDeliveredOrdersHistory);

// ===== ROUTES WITH :id PARAMETER (Must come after specific routes) =====
router.get("/:id", protect, getDriverByIdValidator, validate, cacheMiddleware({ ttl: 60 }), getById);

// ===== ADMIN ROUTES =====
router.put("/update/:id", protect, authorize('admin'), updateDriverValidator, validate, update);
router.delete("/delete/:id", protect, authorize('admin', 'driver'), deleteDriverValidator, validate, remove);
router.delete("/permanent-delete/:id", protect, authorize('admin'), deleteDriverValidator, validate, permanentRemove);

export default router;
