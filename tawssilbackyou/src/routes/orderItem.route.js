import { Router } from "express";
import { validate } from "../middlewares/validate.js";
import { cacheMiddleware, invalidateCache } from "../middlewares/cache.middleware.js";
import * as orderItemCtrl from "../controllers/orderItem.controller.js";
import {
  createOrderItemValidator,
  updateOrderItemValidator,
  getOrderItemsByOrderValidator,
  orderItemByIdValidator,
  deleteOrderItemValidator,
  bulkCreateOrderItemsValidator
} from "../validators/orderItemValidator.js";

const router = Router();

router.use(
  invalidateCache([
    "cache:GET:/orderitem*",
    "cache:GET:/api/v1/order-items*",
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

// Create a new order item
router.post(
  "/create",
  createOrderItemValidator,
  validate,
  orderItemCtrl.create
);

// Bulk create order items
router.post(
  "/bulk-create",
  bulkCreateOrderItemsValidator,
  validate,
  orderItemCtrl.bulkCreate
);

// Get all order items
router.get(
  "/getall",
  cacheMiddleware({ ttl: 60 }),
  orderItemCtrl.getAll
);

// Get all order items for a specific order
router.get(
  "/order/:order_id",
  getOrderItemsByOrderValidator,
  validate,
  cacheMiddleware({ ttl: 60 }),
  orderItemCtrl.getByOrderId
);

// Get a single order item by ID
router.get(
  "/:id",
  orderItemByIdValidator,
  validate,
  cacheMiddleware({ ttl: 60 }),
  orderItemCtrl.getById
);

// Update an order item
router.put(
  "/update/:id",
  updateOrderItemValidator,
  validate,
  orderItemCtrl.update
);

// Delete an order item
router.delete(
  "/delete/:id",
  deleteOrderItemValidator,
  validate,
  orderItemCtrl.remove
);

export default router;
