// src/controllers/restaurant.controller.js
import * as restaurantService from "../services/restaurant.service.js";
import cacheService from '../services/cache.service.js';
import { cacheHelpers } from '../middlewares/cache.middleware.js';
import crypto from 'crypto';
import Restaurant from "../models/Restaurant.js";
import User from "../models/User.js";
import Order from "../models/Order.js";
import { getRestaurantOrdersHistory } from "../services/restaurant.service.js";
import { getLatestDeviceTokenForProfile } from "../services/notification.service.js";
import { clearHomepageModulesCache } from "../services/homepage.service.js";


/**
 * Get all restaurants (basic info only - public)
 */
export const getAll = async (req, res, next) => {
  try {
    const restaurants = await restaurantService.getAllRestaurants();
    res.json({
      success: true,
      data: restaurants
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Create a lightweight restaurant stub (used by tests and quick seeds).
 * This endpoint creates an associated restaurant user behind the scenes.
 */
export const createRestaurant = async (req, res, next) => {
  try {
    const restaurant = await restaurantService.createRestaurant(req.body);
    res.status(201).json({
      success: true,
      data: restaurant
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Filter nearby restaurants with advanced options
 * ✅ REQUIRES AUTHENTICATION - client_id from JWT
 * Cached for 3 minutes
 */
export const nearbyFilter = async (req, res, next) => {
  try {
    // Parse categories if it's a string
    if (req.body.categories && typeof req.body.categories === 'string') {
      req.body.categories = req.body.categories.split(',').map(c => c.trim());
    }

    // Parse home_categories if it's a string (comma-separated UUIDs)
    if (req.body.home_categories && typeof req.body.home_categories === 'string') {
      req.body.home_categories = req.body.home_categories.split(',').map(c => c.trim());
    }

    // ✅ Get client_id from JWT token (guaranteed to exist because of isClient middleware)
    const filters = {
      ...req.body,
      client_id: req.user.client_id
    };

    filters.radius = await restaurantService.resolveClientRestaurantSearchRadius(filters.radius);

    // Generate cache key based on filters
    const cacheKeyData = {
      lat: filters.lat,
      lng: filters.lng,
      address: filters.address,
      radius: filters.radius,
      q: filters.q,
      categories: filters.categories ? (Array.isArray(filters.categories) ? filters.categories.sort().join(',') : filters.categories) : null,
      home_categories: filters.home_categories ? (Array.isArray(filters.home_categories) ? filters.home_categories.sort().join(',') : filters.home_categories) : null,
      page: filters.page || 1,
      pageSize: filters.pageSize || 20,
      client_id: filters.client_id
    };
    
    const cacheKeyString = JSON.stringify(cacheKeyData);
    const cacheKey = `restaurant:nearby:${crypto.createHash('md5').update(cacheKeyString).digest('hex')}`;

    // Try to get from cache
    const cached = await cacheService.get(cacheKey);
    if (cached !== null) {
      return res.json({
        ...cached,
        cached: true
      });
    }

    const result = await restaurantService.filterNearbyRestaurants(filters);
    
    const response = {
      success: true,
      count: result.count,
      page: result.page,
      pageSize: result.pageSize,
      radius: result.radius,
      center: result.center,
      data: result.formatted,
      searchType: result.searchType,
      client_id: result.client_id
    };

    // Cache for 3 minutes (180 seconds)
    await cacheService.set(cacheKey, response, 180);
    
    res.json({
      ...response,
      cached: false
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Filter nearby restaurants with advanced options
 * ✅ REQUIRES AUTHENTICATION - client_id from JWT
 */
export const filter = async (req, res, next) => {
  try {
    // Parse categories if it's a string
    if (req.body.categories && typeof req.body.categories === 'string') {
      req.body.categories = req.body.categories.split(',').map(c => c.trim());
    }

    // ✅ Get client_id from JWT token (guaranteed to exist because of isClient middleware)
    const filters = {
      ...req.body
    };

    const result = await restaurantService.filter(filters);
    
    res.json({
      success: true,
      count: result.count,
      page: result.page,
      pageSize: result.pageSize,
      totalPages: result.totalPages,
      data: result.formatted,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Get nearby restaurant names only
 * ✅ REQUIRES AUTHENTICATION
 */
export const getNearbyNames = async (req, res, next) => {
  try {
    const result = await restaurantService.getNearbyRestaurantNames(req.body);

    res.json({
      success: true,
      count: result.count,
      radius: result.radius,
      center: result.center,
      data: result.names,
      searchType: result.searchType
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Update restaurant profile (own profile only)
 */
export const updateProfile = async (req, res, next) => {
  try {
    // Get restaurant_id directly from JWT token
    const restaurantId = req.user.restaurant_id;
    
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        error: "Restaurant profile not found in token"
      });
    }

    // Validate categories if provided
    if (req.body.categories !== undefined) {
      if (!Array.isArray(req.body.categories) || req.body.categories.length === 0) {
        return res.status(400).json({
          success: false,
          error: "Categories must be a non-empty array"
        });
      }
    }

    const updatedRestaurant = await restaurantService.updateRestaurant(restaurantId, req.body);

    // Invalidate cache for this restaurant
    await cacheService.delPattern(`restaurant:details:${restaurantId}:*`);
    await cacheService.delPattern(`restaurant:nearby:*`);
    await clearHomepageModulesCache();

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: updatedRestaurant
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Update restaurant availability status (own profile only)
 */
export const updateAvailabilityStatus = async (req, res, next) => {
  try {
    const restaurantId = req.user.restaurant_id;

    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        error: "Restaurant profile not found in token"
      });
    }

    const updated = await restaurantService.updateRestaurantAvailabilityStatus(
      restaurantId,
      req.body
    );

    await cacheService.delPattern(`restaurant:details:${restaurantId}:*`);
    await cacheService.delPattern(`restaurant:nearby:*`);
    await clearHomepageModulesCache();

    res.json({
      success: true,
      message: "Availability status updated successfully",
      data: updated
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Update restaurant (admin only)
 */
export const update = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Validate categories if provided
    if (req.body.categories !== undefined) {
      if (!Array.isArray(req.body.categories) || req.body.categories.length === 0) {
        return res.status(400).json({
          success: false,
          error: "Categories must be a non-empty array"
        });
      }
    }

    const updatedRestaurant = await restaurantService.updateRestaurant(id, req.body);

    // Invalidate cache for this restaurant
    await cacheService.delPattern(`restaurant:details:${id}:*`);
    await cacheService.delPattern(`restaurant:nearby:*`);
    await clearHomepageModulesCache();

    res.json({
      success: true,
      data: updatedRestaurant
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Disable a restaurant (soft delete)
 */
export const remove = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({
        success: false,
        error: "Restaurant ID is required"
      });
    }

    // Restaurants can only disable their own record
    if (req.user?.role === "restaurant") {
      const tokenRestaurantId = req.user.restaurant_id;
      const profileRestaurantId = tokenRestaurantId
        ? tokenRestaurantId
        : (await Restaurant.findOne({ where: { user_id: req.user.id }, attributes: ["id"] }))?.id;

      if (!profileRestaurantId) {
        return res.status(403).json({
          success: false,
          message: "Restaurant profile not found"
        });
      }

      if (profileRestaurantId !== id) {
        return res.status(403).json({
          success: false,
          message: "Forbidden"
        });
      }
    }

    await restaurantService.deleteRestaurant(id);

    // Invalidate cache for this restaurant
    await cacheService.delPattern(`restaurant:details:${id}:*`);
    await cacheService.delPattern(`restaurant:nearby:*`);
    await clearHomepageModulesCache();

    res.status(200).json({
      success: true,
      message: "Restaurant disabled successfully"
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Permanent delete restaurant (restaurant + associated user).
 * Only allowed for inactive restaurants with no orders.
 */
export const permanentRemove = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        success: false,
        error: "Restaurant ID is required"
      });
    }

    const restaurant = await Restaurant.findByPk(id);
    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: "Restaurant not found"
      });
    }

    const isInactive = restaurant.is_active === false;

    if (!isInactive) {
      return res.status(400).json({
        success: false,
        message: "Only inactive restaurants can be permanently deleted",
        code: "RESTAURANT_NOT_INACTIVE"
      });
    }

    const ordersCount = await Order.count({ where: { restaurant_id: id } });
    if (ordersCount > 0) {
      return res.status(409).json({
        success: false,
        message: "Cannot permanently delete a restaurant that has orders",
        code: "RESTAURANT_HAS_ORDERS",
        orders_count: ordersCount
      });
    }

    const userId = restaurant.user_id;
    if (userId) {
      const user = await User.findByPk(userId);
      if (user && user.role !== "restaurant") {
        return res.status(400).json({
          success: false,
          message: "User role mismatch for this restaurant",
          code: "USER_ROLE_MISMATCH"
        });
      }

      await User.destroy({ where: { id: userId } });
      // Fallback if cascade isn't configured.
      await Restaurant.destroy({ where: { id } });
    } else {
      await Restaurant.destroy({ where: { id } });
    }

    // Invalidate cache for this restaurant
    await cacheService.delPattern(`restaurant:details:${id}:*`);
    await cacheService.delPattern(`restaurant:nearby:*`);
    await clearHomepageModulesCache();

    return res.status(200).json({
      success: true,
      message: "Restaurant permanently deleted"
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Get restaurant menu with categories and items
 * ✅ REQUIRES AUTHENTICATION - shows favorites
 * Cached for 5 minutes
 */
export const getRestaurantMenu = async (req, res) => {
  try {
    const { restaurantId } = req.params;
    
    // ✅ Get client_id from JWT token (guaranteed to exist)
    const client_id = req.user.client_id;

    // Generate cache key
    const cacheKey = `restaurant:details:${restaurantId}:client:${client_id}`;

    // Try to get from cache
    const cached = await cacheService.get(cacheKey);
    if (cached !== null) {
      return res.status(200).json({
        ...cached,
        cached: true
      });
    }

    const menu = await restaurantService.getCategoriesWithMenuItems(restaurantId, client_id, {
      includePromotionCategories: false,
      includeItemPromotions: false,
      includePromotionSummaries: false,
      priceKey: "promo_price",
      groupUngroupedOptions: true
    });

    const response = {
      success: true,
      data: menu
    };

    // Cache for 5 minutes (300 seconds)
    await cacheService.set(cacheKey, response, 300);

    res.status(200).json({
      ...response,
      cached: false
    });
  } catch (error) {
    res.status(error.message === 'Restaurant not found' ? 404 : 500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * Get restaurant menu with categories and items (admin)
 */
export const getRestaurantMenuAdmin = async (req, res, next) => {
  try {
    const { restaurantId } = req.params;
    const menu = await restaurantService.getCategoriesWithMenuItems(restaurantId, null, {
      includeUnavailable: true,
      includePromotionCategories: false,
      isAdmin: true // Activer le groupe "Additions" pour les additions sans groupe
    });
    res.status(200).json({
      success: true,
      data: menu
    });
  } catch (err) {
    next(err);
  }
};


/**
 * Get restaurant statistics
 * GET /api/restaurants/statistics/me (for authenticated restaurant)
 * GET /api/restaurants/:id/statistics (for admin)
 */
export const getRestaurantStatistics = async (req, res, next) => {
  try {
    // Get restaurant_id from JWT token or URL parameter
    const restaurantId = req.user?.restaurant_id || req.params.id;
    
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant ID not found"
      });
    }

    const filters = {
      date_from: req.query.date_from,
      date_to: req.query.date_to
    };

    const stats = await restaurantService.getRestaurantStatistics(restaurantId, filters);

    res.json({
      success: true,
      data: stats
    });
  } catch (err) {
    if (err.message === 'Restaurant not found') {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    next(err);
  }
};


/**
 * Get restaurant's own profile
 * GET /api/restaurants/profile
 */
export const getProfile = async (req, res, next) => {
  try {
    // Get restaurant_id from JWT token
    const restaurantId = req.user.restaurant_id;
    
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        error: "Restaurant profile not found in token"
      });
    }

    const profile = await restaurantService.getRestaurantProfile(restaurantId);
    const fcm_token = await getLatestDeviceTokenForProfile({
      role: "restaurant",
      profileId: restaurantId
    });

    res.json({
      success: true,
      data: {
        ...profile,
        fcm_token
      }
    });
  } catch (err) {
    if (err.message === 'Restaurant not found') {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    next(err);
  }
};



/**
 * GET /restaurant/details
 * Get restaurant's own complete menu with all categories and items
 */
export const getMyRestaurantMenu = async (req, res, next) => {
  try {
    // Get restaurant_id from JWT token
    const restaurantId = req.user.restaurant_id;
    
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant profile not found in token"
      });
    }

    // Get complete menu using existing service
    const menu = await restaurantService.getCategoriesWithMenuItems(restaurantId, null, {
      includeUnavailable: true,
      includePromotionCategories: false
    });

    res.json({
      success: true,
      data: menu
    });
  } catch (err) {
    if (err.message === 'Restaurant not found') {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    next(err);
  }
};

export const getOrdersHistory = async (req, res, next) => {
  try {
    // Get restaurant_id from JWT token
    const restaurantId = req.user.restaurant_id;
    
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant profile not found in token"
      });
    }

    const filters = {
      status: req.query.status,
      date_range: req.query.date_range,
      date_from: req.query.date_from,
      date_to: req.query.date_to,
      min_price: req.query.min_price,
      max_price: req.query.max_price,
      search: req.query.search,
      order_type: req.query.order_type,
      page: req.query.page || 1,
      limit: req.query.limit || 20
    };

    const result = await getRestaurantOrdersHistory(restaurantId, filters);

    res.json({
      success: true,
      pos_orders: result.pos_orders || [],
      app_orders: result.app_orders || [],
      pagination: result.pagination,
      summary: result.summary,
      filters_applied: result.filters_applied
    });
  } catch (err) {
    if (err.status === 404) {
      return res.status(404).json({
        success: false,
        message: err.message
      });
    }
    next(err);
  }
};
