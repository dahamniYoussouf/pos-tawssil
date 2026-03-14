import {
  getAllDrivers,
  getDriverById,
  updateDriver,
  deleteDriver,
  updateDriverStatus,
  getDriverStatistics
} from "../services/driver.service.js";
import Driver from "../models/Driver.js";
import User from "../models/User.js";
import Order from "../models/Order.js";
import { getDriverActiveOrders, getDriverDeliveredOrdersHistory } from '../services/order.service.js';
import { getNearbyCommunes } from "../services/commune.service.js";
import { getDriverNearbyZones } from "../services/zone.service.js";
import { getLatestDeviceTokenForProfile } from "../services/notification.service.js";



// Get all drivers with filters and pagination
export const getAll = async (req, res, next) => {
  try {
    const filters = {
      page: req.query.page || 1,
      limit: req.query.limit || req.query.pageSize || 20,
      status: req.query.status,
      is_active: req.query.is_active,
      is_verified: req.query.is_verified,
      search: req.query.search
    };
    
    const result = await getAllDrivers(filters);
    res.json({ 
      success: true, 
      data: result.drivers,
      pagination: result.pagination
    });
  } catch (err) {
    next(err);
  }
};

// Get driver by ID
export const getById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const driver = await getDriverById(id);

    if (!driver) {
      return res.status(404).json({ 
        success: false, 
        message: "Driver not found" 
      });
    }

    res.json({ success: true, data: driver });
  } catch (err) {
    next(err);
  }
};

// Update driver
export const update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const driver = await updateDriver(id, req.body);

    if (!driver) {
      return res.status(404).json({ 
        success: false, 
        message: "Driver not found" 
      });
    }

    res.json({ 
      success: true, 
      message: "Driver updated successfully",
      data: driver
    });
  } catch (err) {
    if (err.name === "SequelizeUniqueConstraintError") {
      return res.status(400).json({
        success: false,
        message: "This phone number or email is already registered",
        field: err.errors[0].path,
        value: err.errors[0].value
      });
    }

    if (err.name === "SequelizeValidationError") {
      return res.status(400).json({
        success: false,
        message: "Validation error",
        errors: err.errors.map(e => ({
          field: e.path,
          message: e.message
        }))
      });
    }

    next(err);
  }
};

// Delete driver
export const remove = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deleted = await deleteDriver(id);

    if (!deleted) {
      return res.status(404).json({ 
        success: false, 
        message: "Driver not found" 
      });
    }

    res.status(200).json({ 
      success: true, 
      message: "Driver deleted successfully" 
    });
  } catch (err) {
    next(err);
  }
};

// Permanent delete rejected driver (driver + associated user)
export const permanentRemove = async (req, res, next) => {
  try {
    const { id } = req.params;

    const driver = await Driver.findByPk(id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: "Driver not found"
      });
    }

    const notes = typeof driver.notes === "string" ? driver.notes.trim().toLowerCase() : "";
    const isRejected =
      driver.status === "suspended" &&
      !driver.is_verified &&
      !driver.is_active &&
      notes.startsWith("rejete:");

    if (!isRejected) {
      return res.status(400).json({
        success: false,
        message: "Only rejected drivers can be permanently deleted",
        code: "DRIVER_NOT_REJECTED"
      });
    }

    const ordersCount = await Order.count({ where: { livreur_id: id } });
    if (ordersCount > 0) {
      return res.status(409).json({
        success: false,
        message: "Cannot permanently delete a driver that has orders",
        code: "DRIVER_HAS_ORDERS",
        orders_count: ordersCount
      });
    }

    const userId = driver.user_id;
    if (userId) {
      const user = await User.findByPk(userId);
      if (user && user.role !== "driver") {
        return res.status(400).json({
          success: false,
          message: "User role mismatch for this driver",
          code: "USER_ROLE_MISMATCH"
        });
      }

      await User.destroy({ where: { id: userId } });
      // Fallback if cascade isn't configured.
      await Driver.destroy({ where: { id } });
    } else {
      await driver.destroy();
    }

    return res.status(200).json({
      success: true,
      message: "Driver permanently deleted"
    });
  } catch (err) {
    next(err);
  }
};

// ✅ NEW: Get authenticated driver's profile
export const getProfile = async (req, res, next) => {
  try {
    // Get driver_id directly from JWT token
    const driverId = req.user.driver_id;
    
    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    const driver = await getDriverById(driverId);

    if (!driver) {
      return res.status(404).json({ 
        success: false, 
        message: "Driver profile not found" 
      });
    }

    // Remove sensitive data if needed
    const driverData = driver.toJSON();
    const fcm_token = await getLatestDeviceTokenForProfile({
      role: "driver",
      profileId: driverId
    });
    
    res.json({ 
      success: true, 
      data: {
        ...driverData,
        fcm_token
      }
    });
  } catch (err) {
    next(err);
  }
};

// ✅ NEW: Update authenticated driver's own profile
export const updateProfile = async (req, res, next) => {
  try {
    // Get driver_id directly from JWT token
    const driverId = req.user.driver_id;
    
    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    const driver = await updateDriver(driverId, req.body);

    if (!driver) {
      return res.status(404).json({ 
        success: false, 
        message: "Driver not found" 
      });
    }

    res.json({ 
      success: true, 
      message: "Profile updated successfully",
      data: driver
    });
  } catch (err) {
    if (err.name === "SequelizeUniqueConstraintError") {
      return res.status(400).json({
        success: false,
        message: "This phone number or email is already registered",
        field: err.errors[0].path,
        value: err.errors[0].value
      });
    }

    if (err.name === "SequelizeValidationError") {
      return res.status(400).json({
        success: false,
        message: "Validation error",
        errors: err.errors.map(e => ({
          field: e.path,
          message: e.message
        }))
      });
    }

    next(err);
  }
};

// ✅ UPDATED: Update status without ID parameter
export const updateStatus = async (req, res, next) => {
  try {
    // Get driver_id directly from JWT token
    const driverId = req.user.driver_id;
    const { status } = req.body;

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    if (!status) {
      return res.status(400).json({
        success: false,
        message: "Status is required"
      });
    }

    const driver = await updateDriverStatus(driverId, status);

    if (!driver) {
      return res.status(404).json({ 
        success: false, 
        message: "Driver not found" 
      });
    }

    res.json({ 
      success: true, 
      message: "Driver status updated successfully",
      data: driver
    });
  } catch (err) {
    if (err?.status === 403 && err?.code === "DRIVER_SUSPENDED") {
      return res.status(403).json({
        success: false,
        message: err.message || "Driver account is suspended",
        code: "DRIVER_SUSPENDED"
      });
    }
    next(err);
  }
};

// ✅ UPDATED: Get statistics without ID parameter
export const getStatistics = async (req, res, next) => {
  try {
    // Get driver_id directly from JWT token
    const driverId = req.user.driver_id;
    
    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    const stats = await getDriverStatistics(driverId);

    if (!stats) {
      return res.status(404).json({ 
        success: false, 
        message: "Driver not found" 
      });
    }

    res.json({ success: true, data: stats });
  } catch (err) {
    next(err);
  }
};


/**
 * GET /driver/active-orders
 * Récupérer toutes les commandes actives du livreur connecté
 */
export const getActiveOrders = async (req, res, next) => {
  try {
    const driverId = req.user.driver_id;
    
    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    const result = await getDriverActiveOrders(driverId);

    res.json({
      success: true,
      data: result
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /driver/orders/history
 * Récupérer l'historique des commandes livrées du livreur connecté
 */
export const getDeliveredOrdersHistory = async (req, res, next) => {
  try {
    const driverId = req.user.driver_id;

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    const result = await getDriverDeliveredOrdersHistory(driverId, req.query);

    res.json({
      success: true,
      data: result.orders,
      pagination: result.pagination
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /driver/communes/nearby
 * Récupérer les communes proches de la position du livreur
 */
export const getNearbyDriverCommunes = async (req, res, next) => {
  try {
    const driverId = req.user.driver_id;
    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    const driver = await getDriverById(driverId);
    if (!driver || !driver.current_location) {
      return res.status(400).json({
        success: false,
        message: "Driver location not available. Please enable GPS."
      });
    }

    const coords = driver.getCurrentCoordinates?.();
    if (!coords) {
      return res.status(400).json({
        success: false,
        message: "Invalid driver location"
      });
    }

    const parsedRadius = req.query.radius ? parseInt(req.query.radius, 10) : NaN;
    const parsedLimit = req.query.limit ? parseInt(req.query.limit, 10) : NaN;
    const radius = Number.isFinite(parsedRadius) ? parsedRadius : undefined;
    const limit = Number.isFinite(parsedLimit) ? parsedLimit : undefined;

    const result = await getNearbyCommunes({
      lat: coords.latitude,
      lng: coords.longitude,
      radius,
      limit
    });

    res.json({
      success: true,
      ...result
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /driver/zones/nearby
 * Recuperer les zones proches avec le nombre de commandes
 */
export const getNearbyDriverZones = async (req, res, next) => {
  try {
    const driverId = req.user.driver_id;
    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: "Driver profile not found in token"
      });
    }

    const parsedRadius = req.query.radius ? parseInt(req.query.radius, 10) : NaN;
    const parsedLimit = req.query.limit ? parseInt(req.query.limit, 10) : NaN;
    const radius = Number.isFinite(parsedRadius) ? parsedRadius : undefined;
    const limit = Number.isFinite(parsedLimit) ? parsedLimit : undefined;

    const status = req.query.status
      ? String(req.query.status)
          .split(",")
          .map((value) => value.trim())
          .filter(Boolean)
      : undefined;

    const result = await getDriverNearbyZones(driverId, {
      radius,
      limit,
      status
    });

    res.json({
      success: true,
      count: result.count,
      data: result.data,
      center: result.center,
      radius_m: result.radius_m
    });
  } catch (err) {
    next(err);
  }
};
