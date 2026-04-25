// src/routes/cashier.routes.js
import express from "express";
import { protect, isCashier, authorize } from "../middlewares/auth.js";
import { validate } from "../middlewares/validate.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";
import * as cashierCtrl from "../controllers/cashier.controller.js";
import {
  updateCashierValidator,
  cashierStatusValidator
} from "../validators/cashierValidator.js";

const router = express.Router();
router.use(
  invalidateCache([
    "cache:GET:/cashier*",
    "cache:GET:/api/v1/cashiers*",
    "cache:GET:/auth/profile*",
    "cache:GET:/api/v1/auth/profile*"
  ])
);

// ===== PROTECTED ROUTES - CASHIER'S OWN PROFILE =====
router.get("/profile/me", protect, isCashier, cacheMiddleware({ ttl: 30 }), cashierCtrl.getProfile);
router.put("/profile", protect, isCashier, cashierCtrl.updateProfile);
router.patch("/status", protect, isCashier, cashierStatusValidator, validate, cashierCtrl.updateStatus);
router.get("/statistics/me", protect, isCashier, cacheMiddleware({ ttl: 30 }), cashierCtrl.getStatistics);
router.get("/dashboard/today", protect, isCashier, cacheMiddleware({ ttl: 15 }), cashierCtrl.getDashboardToday);
router.get("/printers", protect, isCashier, cacheMiddleware({ ttl: 300 }), cashierCtrl.getPrinters);

// ===== ADMIN/RESTAURANT ROUTES =====
router.get("/getall", protect, authorize('admin', 'restaurant'), cacheMiddleware({ ttl: 60 }), cashierCtrl.getAll);
router.get("/:id", protect, authorize('admin', 'restaurant'), cacheMiddleware({ ttl: 60 }), cashierCtrl.getById);
router.put(
  "/update/:id",
  protect,
  authorize('admin', 'restaurant'),
  updateCashierValidator,
  validate,
  cashierCtrl.update
);
router.delete("/delete/:id", protect, authorize('admin', 'restaurant'), cashierCtrl.remove);

export default router;
