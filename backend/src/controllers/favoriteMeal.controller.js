import {
  addFavoriteMealService,
  removeFavoriteMealService,
  getFavoriteMealsService,
  updateFavoriteMealService
} from "../services/favoriteMeal.service.js";
import MenuItem from "../models/MenuItem.js";
import cacheService from "../services/cache.service.js";

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

const clearMealFavoriteCaches = async (clientId, mealIds = []) => {
  const normalizedMealIds = Array.from(new Set((mealIds || []).map((id) => String(id)).filter(Boolean)));
  if (!normalizedMealIds.length || !clientId) {
    return;
  }

  const meals = await MenuItem.findAll({
    where: { id: normalizedMealIds },
    attributes: ["id", "restaurant_id"]
  });

  const restaurantIds = Array.from(new Set(meals.map((meal) => String(meal.restaurant_id)).filter(Boolean)));
  await Promise.all(
    restaurantIds.map((restaurantId) =>
      cacheService.del(`restaurant:details:${restaurantId}:client:${clientId}`)
    )
  );
};

export const addFavoriteMeal = async (req, res, next) => {
  try {
    const client_id = resolveClientId(req);
    const accessError = ensureClientAccess(req, client_id);
    if (accessError) {
      return res.status(accessError.status).json(accessError.payload);
    }

    const { meal_id } = req.body;
    if (!meal_id) {
      return res.status(400).json({ success: false, error: "meal_id is required" });
    }

    const result = await addFavoriteMealService({ client_id, meal_id, ...req.body });

    if (result.error) {
      return res.status(result.status).json({
        success: false,
        error: result.error,
        favorite_uuid: result.favorite_uuid
      });
    }

    await clearMealFavoriteCaches(client_id, [result.meal_id]);

    res.status(result.already_exists ? 200 : 201).json({
      success: true,
      message: result.already_exists
        ? "Meal already in favorites"
        : "Meal added to favorites",
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

export const removeFavoriteMeal = async (req, res, next) => {
  try {
    const client_id = req.user?.client_id || null;
    const accessError = ensureClientAccess(req, client_id);
    if (accessError) {
      return res.status(accessError.status).json(accessError.payload);
    }

    const { meal_id } = req.body;

    if (!meal_id) {
      return res.status(400).json({
        success: false,
        error: "meal_id is required"
      });
    }

    const removed = await removeFavoriteMealService({ client_id, meal_id });

    await clearMealFavoriteCaches(client_id, [meal_id]);

    res.json({
      success: true,
      message: removed.deleted_count
        ? "Meal removed from favorites"
        : "Favorite meal relation did not exist",
      deleted_count: removed.deleted_count
    });
  } catch (err) {
    next(err);
  }
};

export const getFavoriteMeals = async (req, res, next) => {
  try {
    const client_id = req.user.client_id;

    const favorites = await getFavoriteMealsService(client_id);

    res.json({
      success: true,
      count: favorites.length,
      data: favorites.map((fav) => ({
        favorite_uuid: fav.id,
        customizations: fav.customizations,
        notes: fav.notes,
        added_at: fav.created_at,
        meal: fav.meal,
      })),
    });
  } catch (err) {
    next(err);
  }
};

export const updateFavoriteMeal = async (req, res, next) => {
  try {
    const { favorite_uuid } = req.params;
    const updated = await updateFavoriteMealService(favorite_uuid, req.body);

    if (!updated) {
      return res.status(404).json({ success: false, error: "Favorite not found" });
    }

    res.json({
      success: true,
      message: "Favorite updated",
      data: {
        favorite_uuid: updated.id,
        customizations: updated.customizations,
        notes: updated.notes,
        updated_at: updated.updated_at,
      },
    });
  } catch (err) {
    next(err);
  }
};
