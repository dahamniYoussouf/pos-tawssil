import express from "express";
import { protect } from "../middlewares/auth.js";
import {
  registerDeviceToken,
  unregisterDeviceToken
} from "../controllers/notification.controller.js";

const router = express.Router();

router.post("/token", protect, registerDeviceToken);
router.delete("/token", protect, unregisterDeviceToken);

export default router;
