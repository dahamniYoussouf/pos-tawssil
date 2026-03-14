import { Router } from "express";
import { validate } from "../middlewares/validate.js";
import { protect, isClient, requireActiveClient, authorize } from "../middlewares/auth.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";
import * as clientCtrl from "../controllers/client.controller.js";
import {
  updateClientValidator,
  deleteClientValidator,
  getAllClientsValidator, 
  getMyOrdersValidator,
  favoriteAddressCreateValidator,
  favoriteAddressUpdateValidator,
  favoriteAddressIdValidator
} from "../validators/clientValidator.js";
const router = Router();

router.use(
  invalidateCache([
    "cache:GET:/client*",
    "cache:GET:/api/v1/clients*",
    "cache:GET:/auth/profile*",
    "cache:GET:/api/v1/auth/profile*"
  ])
);


// ✅ Protected routes - client's own profile
router.get("/profile/me", protect, isClient, requireActiveClient, clientCtrl.getProfile);
router.put("/profile", protect, isClient, requireActiveClient, updateClientValidator, validate, clientCtrl.updateProfile);

router.get(
  "/orders", 
  protect, 
  isClient, 
  requireActiveClient,
  getMyOrdersValidator, 
  validate, 
  cacheMiddleware({ ttl: 10 }),
  clientCtrl.getMyOrders
);

// Favorite addresses
router.get("/favorite-addresses", protect, isClient, requireActiveClient, clientCtrl.listFavoriteAddresses);
router.post("/favorite-addresses", protect, isClient, requireActiveClient, favoriteAddressCreateValidator, validate, clientCtrl.createFavoriteAddress);
router.put("/favorite-addresses/:id", protect, isClient, requireActiveClient, favoriteAddressIdValidator, favoriteAddressUpdateValidator, validate, clientCtrl.updateFavoriteAddress);
router.delete("/favorite-addresses/:id", protect, isClient, requireActiveClient, favoriteAddressIdValidator, validate, clientCtrl.deleteFavoriteAddress);

// Admin routes
router.get("/getall", protect, authorize('admin'), getAllClientsValidator, validate, cacheMiddleware({ ttl: 60 }), clientCtrl.getAll);
router.put("/update/:id", protect, authorize('admin'), updateClientValidator, validate, clientCtrl.update);
router.delete("/delete/:id", protect, authorize('admin', 'client'), deleteClientValidator, validate, clientCtrl.remove);

export default router;
