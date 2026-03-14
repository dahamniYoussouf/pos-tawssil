import FavoriteRestaurant from "../models/FavoriteRestaurant.js";
import Restaurant from "../models/Restaurant.js";
import { buildClientVisibleRestaurantWhere } from "../utils/restaurantVisibility.js";

const FAVORITE_RESTAURANT_INCLUDE = [
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
];

const formatFavoriteRestaurant = (favoriteWithRestaurant) => ({
  favorite_uuid: favoriteWithRestaurant.id,
  client_id: favoriteWithRestaurant.client_id,
  restaurant_id: favoriteWithRestaurant.restaurant_id,
  notes: favoriteWithRestaurant.notes,
  tags: favoriteWithRestaurant.tags,
  created_at: favoriteWithRestaurant.created_at,
  restaurant: favoriteWithRestaurant.restaurant,
});

export const addFavoriteRestaurantService = async ({ client_id, restaurant_id, notes, tags }) => {
  const restaurant = await Restaurant.findOne({
    where: buildClientVisibleRestaurantWhere({ id: restaurant_id })
  });
  if (!restaurant) {
    return { error: "Restaurant not found", status: 404 };
  }

  const existingFavorite = await FavoriteRestaurant.findOne({
    where: { client_id, restaurant_id },
    order: [["created_at", "DESC"]]
  });
  if (existingFavorite) {
    const favoriteWithRestaurant = await FavoriteRestaurant.findByPk(existingFavorite.id, {
      include: FAVORITE_RESTAURANT_INCLUDE,
    });

    return {
      already_exists: true,
      ...formatFavoriteRestaurant(favoriteWithRestaurant),
    };
  }

  const favorite = await FavoriteRestaurant.create({
    client_id,
    restaurant_id,
    notes: notes || null,
    tags: tags || [],
  });

  const favoriteWithRestaurant = await FavoriteRestaurant.findByPk(favorite.id, {
    include: FAVORITE_RESTAURANT_INCLUDE,
  });

  return formatFavoriteRestaurant(favoriteWithRestaurant);
};

export const removeFavoriteRestaurantService = async ({ favorite_uuid, client_id, restaurant_id }) => {
  const where = {};

  if (favorite_uuid) {
    where.id = favorite_uuid;
  }
  if (client_id) {
    where.client_id = client_id;
  }
  if (restaurant_id) {
    where.restaurant_id = restaurant_id;
  }

  const favorites = await FavoriteRestaurant.findAll({ where });
  if (!favorites.length) {
    return { deleted_count: 0 };
  }

  await FavoriteRestaurant.destroy({ where });
  return {
    deleted_count: favorites.length,
    restaurant_ids: Array.from(new Set(favorites.map((favorite) => String(favorite.restaurant_id)).filter(Boolean))),
  };
};

export const getFavoriteRestaurantsService = async (client_id) => {
  return FavoriteRestaurant.findAll({
    where: { client_id },
    include: [
      {
        model: Restaurant,
        as: "restaurant",
        required: true,
        where: buildClientVisibleRestaurantWhere(),
        attributes: [
          "id",
          "name",
          "description",
          "address",
          "rating",
          "image_url",
          "is_premium",
          "status",
          "availability_status",
          "availability_note",
        ],
      },
    ],
    order: [["created_at", "DESC"]],
  });
};

export const updateFavoriteRestaurantService = async (favorite_uuid, { notes, tags }) => {
  const favorite = await FavoriteRestaurant.findByPk(favorite_uuid);
  if (!favorite) return null;

  if (notes !== undefined) favorite.notes = notes;
  if (tags !== undefined) favorite.tags = tags;

  await favorite.save();
  return favorite;
};
