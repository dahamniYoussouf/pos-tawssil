// src/routes/restaurant.route.js
import { Router } from "express";
import { protect, isClient, requireActiveClient, isRestaurant, authorize, isAdmin } from "../middlewares/auth.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";
import * as restaurantCtrl from "../controllers/restaurant.controller.js";
import * as printerCtrl from "../controllers/restaurantPrinter.controller.js";
import { 
  nearbyRestaurantValidator, 
  deleteRestaurantValidator, 
  updateRestaurantValidator, 
  getRestaurantOrdersHistoryValidator,
  nearbyFilterValidator , 
  getRestaurantStatisticsValidator,
  updateRestaurantAvailabilityStatusValidator
} from "../validators/restaurantValidator.js";
import { validate } from "../middlewares/validate.js";

const router = Router();

router.use(
  invalidateCache([
    "cache:GET:/restaurant*",
    "cache:GET:/api/v1/restaurants*",
    "cache:GET:/menuitem*",
    "cache:GET:/api/v1/menu-items*",
    "cache:GET:/favoriterestaurant*",
    "cache:GET:/api/v1/favorite-restaurants*",
    "cache:GET:/favoritemeal*",
    "cache:GET:/api/v1/favorite-meals*",
    "cache:GET:/announcement*",
    "cache:GET:/api/v1/announcements*",
    "cache:GET:/cashier/printers*",
    "cache:GET:/api/v1/cashier/printers*",
    "cache:GET:/auth/profile*",
    "cache:GET:/api/v1/auth/profile*"
  ])
);

// Public routes (no auth needed for browsing basic info)
router.get("/getall", cacheMiddleware({ ttl: 300 }), restaurantCtrl.getAll);
router.post("/create", restaurantCtrl.createRestaurant);
// Add this line with other restaurant management routes
router.get("/profile/me", protect, isRestaurant, cacheMiddleware({ ttl: 60 }), restaurantCtrl.getProfile);

// Protected routes - require client authentication
router.post("/nearbyfilter", protect, isClient, requireActiveClient, nearbyFilterValidator, validate, restaurantCtrl.nearbyFilter);
router.post("/filter", protect, isAdmin, restaurantCtrl.filter);
router.post("/getnearbynames", protect, isClient, requireActiveClient, nearbyFilterValidator, validate, restaurantCtrl.getNearbyNames);
router.get("/details", protect, isRestaurant, cacheMiddleware({ ttl: 60 }), restaurantCtrl.getMyRestaurantMenu);
// Add this route with other restaurant management routes
router.get(
  "/orders/history", 
  protect, 
  isRestaurant, 
  getRestaurantOrdersHistoryValidator, 
  validate, 
  cacheMiddleware({ ttl: 30 }),
  restaurantCtrl.getOrdersHistory
);
router.get('/details/:restaurantId', protect, isClient, requireActiveClient, restaurantCtrl.getRestaurantMenu);
router.get('/admin/details/:restaurantId', protect, authorize('admin'), cacheMiddleware({ ttl: 60 }), restaurantCtrl.getRestaurantMenuAdmin);

// Configuration imprimantes (admin) — ESC/POS, déclenchée à la réception de commande
router.get('/printers', protect, isRestaurant, printerCtrl.listMyRestaurant);
router.post('/printers', protect, isRestaurant, printerCtrl.createForMyRestaurant);
router.put('/printers/:id', protect, isRestaurant, printerCtrl.updateForMyRestaurant);
router.delete('/printers/:id', protect, isRestaurant, printerCtrl.removeForMyRestaurant);

router.get('/admin/printers/:restaurantId', protect, authorize('admin'), printerCtrl.listByRestaurant);
router.post('/admin/printers', protect, authorize('admin', 'cashier'), printerCtrl.create);
router.put('/admin/printers/:id', protect, authorize('admin', 'cashier'), printerCtrl.update);
router.delete('/admin/printers/:id', protect, authorize('admin', 'cashier'), printerCtrl.remove);


// Restaurant management routes
router.put("/profile", protect, isRestaurant, updateRestaurantValidator, validate, restaurantCtrl.updateProfile);
router.patch("/status", protect, isRestaurant, updateRestaurantAvailabilityStatusValidator, validate, restaurantCtrl.updateAvailabilityStatus);
router.put("/update/:id", protect, authorize('admin'), updateRestaurantValidator, validate, restaurantCtrl.update);
router.delete("/delete/:id", protect, authorize('admin', 'restaurant'), deleteRestaurantValidator, validate, restaurantCtrl.remove);
router.delete("/permanent-delete/:id", protect, authorize('admin'), deleteRestaurantValidator, validate, restaurantCtrl.permanentRemove);
router.get("/statistics/me", protect, isRestaurant, getRestaurantStatisticsValidator,  validate, cacheMiddleware({ ttl: 30 }), restaurantCtrl.getRestaurantStatistics);
router.get(  "/:id/statistics", protect, authorize('admin'),  getRestaurantStatisticsValidator,  validate,  cacheMiddleware({ ttl: 30 }), restaurantCtrl.getRestaurantStatistics);
export default router;
