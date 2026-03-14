import { Router } from "express";
import {
  createOrderValidator,
  getAllOrdersValidator,
  getOrderByIdValidator,
  addRestaurantRatingValidator,
  addDriverRatingValidator,
  getClientOrdersValidator,
  createOrderWithItemsValidator,
  declineOrderValidator,
  assignDriverValidator,
  updateDriverGPSValidator,
  driverCancelOrderValidator 
} from "../validators/orderValidator.js";
import { validate } from "../middlewares/validate.js";
import { protect, isClient, requireActiveClient, isRestaurant, isDriver, isCashier  } from "../middlewares/auth.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";
import * as orderController from "../controllers/order.controller.js";

const router = Router();

const requireDriverRestaurantCashierOrAdmin = (req, res, next) => {
  const role = req.user?.role;

  if (role === "driver") return isDriver(req, res, next);
  if (role === "restaurant") return isRestaurant(req, res, next);
  if (role === "cashier") return isCashier(req, res, next);
  if (role === "admin") return next();

  return res.status(403).json({ message: "Access restricted" });
};

const requireRestaurantCashierOrAdmin = (req, res, next) => {
  const role = req.user?.role;

  if (role === "restaurant") return isRestaurant(req, res, next);
  if (role === "cashier") return isCashier(req, res, next);
  if (role === "admin") return next();

  return res.status(403).json({ message: "Access restricted" });
};

const requireRestaurantOrAdmin = (req, res, next) => {
  const role = req.user?.role;

  if (role === "restaurant") return isRestaurant(req, res, next);
  if (role === "admin") return next();

  return res.status(403).json({ message: "Access restricted" });
};

router.use(
  invalidateCache([
    "cache:GET:/order*",
    "cache:GET:/api/v1/orders*",
    "cache:GET:/client/orders*",
    "cache:GET:/api/v1/clients/orders*",
    "cache:GET:/driver/active-orders*",
    "cache:GET:/api/v1/drivers/active-orders*",
    "cache:GET:/driver/statistics*",
    "cache:GET:/api/v1/drivers/statistics*",
    "cache:GET:/cashier/statistics*",
    "cache:GET:/api/v1/cashiers/statistics*",
    "cache:GET:/cashier/dashboard*",
    "cache:GET:/api/v1/cashiers/dashboard*",
    "cache:GET:/restaurant*/orders/history*",
    "cache:GET:/api/v1/restaurants*/orders/history*",
    "cache:GET:/restaurant*/statistics*",
    "cache:GET:/api/v1/restaurants*/statistics*"
  ])
);

// ==================== ORDER CRUD ====================

// Create order - only authenticated clients
router.post('/', protect, isClient, requireActiveClient, createOrderWithItemsValidator, validate, orderController.createOrder);
router.post('/create-from-pos',protect, isCashier, createOrderWithItemsValidator, validate, orderController.createOrderFromPOS);
router.post('/create', protect, isClient, requireActiveClient, createOrderValidator, validate, orderController.createOrder);

// Get all orders - protected (admin/restaurant use)
router.get('/', protect, getAllOrdersValidator, validate, cacheMiddleware({ ttl: 10 }), orderController.getAllOrders);

// ==================== SPECIFIC ROUTES ====================

router.get('/nearby', protect, isDriver, cacheMiddleware({ ttl: 5 }), orderController.getNearbyOrders);
router.get('/client/:clientId', protect, isClient, requireActiveClient, getClientOrdersValidator, validate, cacheMiddleware({ ttl: 10 }), orderController.getClientOrders);
router.get('/restaurant/orders', protect, isRestaurant, cacheMiddleware({ ttl: 10 }), orderController.getRestaurantOrders);
router.get('/cashier/history', protect, isCashier, cacheMiddleware({ ttl: 10 }), orderController.getCashierOrders);
router.put('/drivers/:driverId/gps', protect, isDriver, updateDriverGPSValidator, validate, orderController.updateDriverGPS);

// ==================== ORDER BY ID & TRACKING ====================

router.get('/:id', protect, getOrderByIdValidator, validate, cacheMiddleware({ ttl: 10 }), orderController.getOrderById);
router.get('/:id/tracking', protect, getOrderByIdValidator, validate, cacheMiddleware({ ttl: 5 }), orderController.getOrderTracking);

// ==================== STATUS TRANSITIONS ====================

router.post('/:id/accept', protect, requireRestaurantOrAdmin, getOrderByIdValidator, validate, orderController.acceptOrder);
router.post('/:id/preparing', protect, requireRestaurantCashierOrAdmin, getOrderByIdValidator, validate, orderController.startPreparingOrder);
router.post('/:id/decline', protect, requireRestaurantOrAdmin, declineOrderValidator, validate, orderController.declineOrder);
router.post('/:id/assign-driver', protect, requireDriverRestaurantCashierOrAdmin, assignDriverValidator, validate, orderController.assignDriverOrComplete);
router.post('/:id/start-delivery', protect, isDriver, getOrderByIdValidator, validate, orderController.startDelivering);
router.post('/:id/arrived', protect, isDriver, getOrderByIdValidator, validate, orderController.driverArrived);
router.get('/:id/route-preview', protect, isDriver, getOrderByIdValidator, validate, cacheMiddleware({ ttl: 30 }), orderController.getRoutePreview);
router.post('/:id/complete-delivery', protect, isDriver, getOrderByIdValidator, validate, orderController.completeDelivery);
router.post('/:id/driver-cancel', protect, isDriver, driverCancelOrderValidator,validate, orderController.driverCancelOrder);
// ==================== RATING ====================

router.post('/:id/restaurant-rating', protect, isClient, requireActiveClient, addRestaurantRatingValidator, validate, orderController.addRestaurantRating);
router.post('/:id/driver-rating', protect, isClient, requireActiveClient, addDriverRatingValidator, validate, orderController.addDriverRating);

export default router;
