import Client from "../models/Client.js";
import Driver from "../models/Driver.js";
import Restaurant from "../models/Restaurant.js";
import Admin from "../models/Admin.js";
import Cashier from "../models/Cashier.js";
import {
  registerDeviceTokenForUser,
  unregisterDeviceTokenForUser
} from "../services/notification.service.js";

const getProfileId = (user) =>
  user?.client_id ||
  user?.driver_id ||
  user?.restaurant_id ||
  user?.admin_id ||
  user?.cashier_id ||
  null;

const resolveProfileId = async (user) => {
  const direct = getProfileId(user);
  if (direct) return direct;

  switch (user.role) {
    case "client": {
      const client = await Client.findOne({ where: { user_id: user.id }, attributes: ["id"] });
      return client?.id || null;
    }
    case "driver": {
      const driver = await Driver.findOne({ where: { user_id: user.id }, attributes: ["id"] });
      return driver?.id || null;
    }
    case "restaurant": {
      const restaurant = await Restaurant.findOne({ where: { user_id: user.id }, attributes: ["id"] });
      return restaurant?.id || null;
    }
    case "admin": {
      const admin = await Admin.findOne({ where: { user_id: user.id }, attributes: ["id"] });
      return admin?.id || null;
    }
    case "cashier": {
      const cashier = await Cashier.findOne({ where: { user_id: user.id }, attributes: ["id"] });
      return cashier?.id || null;
    }
    default:
      return null;
  }
};

const resolveProfileLocale = async (user) => {
  if (!user?.role) return null;

  switch (user.role) {
    case "client": {
      const client = await Client.findOne({ where: { user_id: user.id }, attributes: ["locale"] });
      return client?.locale || null;
    }
    case "driver": {
      const driver = await Driver.findOne({ where: { user_id: user.id }, attributes: ["locale"] });
      return driver?.locale || null;
    }
    case "restaurant": {
      const restaurant = await Restaurant.findOne({ where: { user_id: user.id }, attributes: ["locale"] });
      return restaurant?.locale || null;
    }
    case "admin": {
      const admin = await Admin.findOne({ where: { user_id: user.id }, attributes: ["locale"] });
      return admin?.locale || null;
    }
    case "cashier": {
      return null;
    }
    default:
      return null;
  }
};

export const registerDeviceToken = async (req, res) => {
  try {
    const { token, platform, device_id } = req.body || {};

    if (!token || String(token).trim().length === 0) {
      return res.status(400).json({ message: "Device token is required" });
    }

    const role = req.user.role;
    const profileId = await resolveProfileId(req.user);
    const locale = await resolveProfileLocale(req.user);
    const now = new Date();

    await registerDeviceTokenForUser({
      userId: req.user.id,
      role,
      profileId,
      token: String(token).trim(),
      platform: platform || null,
      deviceId: device_id || null,
      locale
    });

    return res.json({
      success: true,
      message: "Device token registered",
      data: {
        token,
        role,
        profile_id: profileId,
        last_seen_at: now
      }
    });
  } catch (error) {
    console.error("registerDeviceToken error:", error);
    return res.status(500).json({ message: "Failed to register device token" });
  }
};

export const unregisterDeviceToken = async (req, res) => {
  try {
    const { token } = req.body || {};

    if (!token || String(token).trim().length === 0) {
      return res.status(400).json({ message: "Device token is required" });
    }

    const updated = await unregisterDeviceTokenForUser({
      userId: req.user.id,
      token: String(token).trim(),
      role: req.user.role
    });

    return res.json({
      success: true,
      message: updated ? "Device token disabled" : "Device token not found"
    });
  } catch (error) {
    console.error("unregisterDeviceToken error:", error);
    return res.status(500).json({ message: "Failed to unregister device token" });
  }
};
