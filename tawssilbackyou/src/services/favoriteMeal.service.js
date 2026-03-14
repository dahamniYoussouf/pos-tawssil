import FavoriteMeal from "../models/FavoriteMeal.js";
import MenuItem from "../models/MenuItem.js";
import Restaurant from "../models/Restaurant.js";
import { buildClientVisibleRestaurantWhere } from "../utils/restaurantVisibility.js";

const FAVORITE_MEAL_INCLUDE = [
  {
    model: MenuItem,
    as: "meal",
    required: true,
    attributes: ["id", "nom", "description", "prix", "photo_url", "category_id", "restaurant_id"],
    include: [
      {
        model: Restaurant,
        as: "restaurant",
        required: true,
        where: buildClientVisibleRestaurantWhere(),
        attributes: ["id", "name", "address", "rating", "availability_status", "availability_note"],
      },
    ],
  },
];

const formatFavoriteMeal = (favoriteWithMeal) => ({
  favorite_uuid: favoriteWithMeal.id,
  client_id: favoriteWithMeal.client_id,
  meal_id: favoriteWithMeal.meal_id,
  customizations: favoriteWithMeal.customizations,
  notes: favoriteWithMeal.notes,
  created_at: favoriteWithMeal.created_at,
  meal: favoriteWithMeal.meal,
});

export const addFavoriteMealService = async ({ client_id, meal_id, customizations, notes }) => {
  const meal = await MenuItem.findOne({
    where: { id: meal_id },
    include: [
      {
        model: Restaurant,
        as: "restaurant",
        required: true,
        where: buildClientVisibleRestaurantWhere(),
        attributes: ["id"]
      }
    ]
  });
  if (!meal) {
    return { error: "Meal not found", status: 404 };
  }

  const existingFavorite = await FavoriteMeal.findOne({
    where: { client_id, meal_id },
    order: [["created_at", "DESC"]]
  });

  if (existingFavorite) {
    const favoriteWithMeal = await FavoriteMeal.findByPk(existingFavorite.id, {
      include: FAVORITE_MEAL_INCLUDE,
    });

    return {
      already_exists: true,
      ...formatFavoriteMeal(favoriteWithMeal),
    };
  }

  const favorite = await FavoriteMeal.create({
    client_id,
    meal_id,
    customizations: customizations || null,
    notes: notes || null,
  });

  const favoriteWithMeal = await FavoriteMeal.findByPk(favorite.id, {
    include: FAVORITE_MEAL_INCLUDE,
  });

  return formatFavoriteMeal(favoriteWithMeal);
};

export const removeFavoriteMealService = async ({ favorite_uuid, client_id, meal_id }) => {
  const where = {};

  if (favorite_uuid) {
    where.id = favorite_uuid;
  }
  if (client_id) {
    where.client_id = client_id;
  }
  if (meal_id) {
    where.meal_id = meal_id;
  }

  const favorites = await FavoriteMeal.findAll({ where });
  if (!favorites.length) {
    return { deleted_count: 0 };
  }

  await FavoriteMeal.destroy({ where });
  return {
    deleted_count: favorites.length,
    meal_ids: Array.from(new Set(favorites.map((favorite) => String(favorite.meal_id)).filter(Boolean))),
  };
};

export const getFavoriteMealsService = async (client_id) => {
  return FavoriteMeal.findAll({
    where: { client_id },
    include: [
      {
        model: MenuItem,
        as: "meal",
        required: true,
        attributes: ["id", "nom", "description", "prix", "photo_url", "category_id"],
        include: [
          {
            model: Restaurant,
            as: "restaurant",
            required: true,
            where: buildClientVisibleRestaurantWhere(),
            attributes: [
              "id",
              "name",
              "address",
              "rating",
              "image_url",
              "availability_status",
              "availability_note"
            ],
          },
        ],
      },
    ],
    order: [["created_at", "DESC"]],
  });
};

export const updateFavoriteMealService = async (favorite_uuid, { customizations, notes }) => {
  const favorite = await FavoriteMeal.findByPk(favorite_uuid);
  if (!favorite) return null;

  if (customizations !== undefined) favorite.customizations = customizations;
  if (notes !== undefined) favorite.notes = notes;

  await favorite.save();
  return favorite;
};
