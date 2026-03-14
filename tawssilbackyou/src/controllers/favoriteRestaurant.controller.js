import {
  addFavoriteRestaurantService,
  removeFavoriteRestaurantService,
  getFavoriteRestaurantsService,
  updateFavoriteRestaurantService
} from "../services/favoriteRestaurant.service.js";
import cacheService from "../services/cache.service.js";
import { clearHomepageModulesCache } from "../services/homepage.service.js";

const clearFavoriteRestaurantCaches = async () => {
  await Promise.all([
    cacheService.delPattern("restaurant:nearby:*"),
    cacheService.delPattern("cache:GET:/restaurant*"),
    cacheService.delPattern("cache:GET:/api/v1/restaurants*"),
    clearHomepageModulesCache()
  ]);
};

const resolveClientId = (req) =>
  req.body?.client_id || req.query?.client_id || req.user?.client_id || null;

const ensureClientAccess = (req, clientId) => {
  if (!clientId) {
    return { status: 400, payload: { success: false, error: "client_id is required" } };
  }
  if (req.user?.client_id && String(req.user.client_id) !== String(clientId)) {
    return { status: 403, payload: { success: false, error: "client_id does not match authenticated client" } };
  }
  return null;
};

export const addFavoriteRestaurant = async (req, res, next) => {
  try {
    const client_id = resolveClientId(req);
    const accessError = ensureClientAccess(req, client_id);
    if (accessError) {
      return res.status(accessError.status).json(accessError.payload);
    }

    const { restaurant_id } = req.body;
    if (!restaurant_id) {
      return res.status(400).json({ success: false, error: "restaurant_id is required" });
    }

    const result = await addFavoriteRestaurantService({ client_id, restaurant_id, ...req.body });

    if (result.error) {
      return res.status(result.status).json({
        success: false,
        error: result.error,
        favorite_uuid: result.favorite_uuid,
      });
    }

    await clearFavoriteRestaurantCaches();

    res.status(result.already_exists ? 200 : 201).json({
      success: true,
      message: result.already_exists
        ? "Restaurant already in favorites"
        : "Restaurant added to favorites",
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

export const removeFavoriteRestaurant = async (req, res, next) => {
  try {
    const client_id = resolveClientId(req);
    const accessError = ensureClientAccess(req, client_id);
    if (accessError) {
      return res.status(accessError.status).json(accessError.payload);
    }

    const favorite_uuid = req.params.favorite_uuid || req.body?.favorite_uuid || req.query?.favorite_uuid || null;
    const restaurant_id = req.body?.restaurant_id || req.query?.restaurant_id || null;

    if (!favorite_uuid && !restaurant_id) {
      return res.status(400).json({
        success: false,
        error: "favorite_uuid or restaurant_id is required"
      });
    }

    const removed = await removeFavoriteRestaurantService({ favorite_uuid, client_id, restaurant_id });

    if (!removed.deleted_count) {
      return res.status(404).json({ success: false, error: "Favorite not found" });
    }

    await clearFavoriteRestaurantCaches();

    res.json({
      success: true,
      message: "Restaurant removed from favorites",
      deleted_count: removed.deleted_count
    });
  } catch (err) {
    next(err);
  }
};

export const getFavoriteRestaurants = async (req, res, next) => {
  try {
    const client_id = req.user.client_id;
    const favorites = await getFavoriteRestaurantsService(client_id);

    res.json({
      success: true,
      count: favorites.length,
      data: favorites.map((fav) => ({
        favorite_uuid: fav.id,
        notes: fav.notes,
        tags: fav.tags,
        added_at: fav.created_at,
        restaurant: fav.restaurant,
      })),
    });
  } catch (err) {
    next(err);
  }
};

export const updateFavoriteRestaurant = async (req, res, next) => {
  try {
    const { favorite_uuid } = req.params;
    const updated = await updateFavoriteRestaurantService(favorite_uuid, req.body);

    if (!updated) {
      return res.status(404).json({ success: false, error: "Favorite not found" });
    }

    res.json({
      success: true,
      message: "Updated favorite",
      data: {
        favorite_uuid: updated.id,
        notes: updated.notes,
        tags: updated.tags,
        updated_at: updated.updated_at,
      },
    });
  } catch (err) {
    next(err);
  }
};
