import { sequelize } from "../config/database.js";
import HomeCategory from "../models/HomeCategory.js";
import RestaurantHomeCategory from "../models/RestaurantHomeCategory.js";

export const listHomeCategories = async (options = {}) => {
  const where = {};
  if (options.activeOnly) {
    where.is_active = true;
  }

  const categories = await HomeCategory.findAll({
    where,
    order: [
      ["display_order", "ASC"],
      ["created_at", "ASC"]
    ]
  });

  if (categories.length === 0) {
    return [];
  }

  const categoryIds = categories.map((category) => category.id);
  const countRows = await RestaurantHomeCategory.findAll({
    attributes: [
      "home_category_id",
      [sequelize.fn("COUNT", sequelize.col("restaurant_id")), "restaurants_count"]
    ],
    where: {
      home_category_id: categoryIds
    },
    group: ["home_category_id"],
    raw: true
  });

  const countMap = new Map(
    countRows.map((row) => [
      String(row.home_category_id),
      Number.parseInt(row.restaurants_count, 10) || 0
    ])
  );

  const enhanced = categories.map((category) => ({
    ...category.toJSON(),
    restaurants_count: countMap.get(String(category.id)) || 0
  }));

  return enhanced;
};

export const createHomeCategory = async (payload) => {
  return HomeCategory.create(payload);
};

export const getHomeCategoryById = async (id) => {
  return HomeCategory.findByPk(id);
};

export const updateHomeCategory = async (id, payload) => {
  const category = await getHomeCategoryById(id);
  if (!category) return null;
  await category.update(payload);
  return category;
};

export const deleteHomeCategory = async (id) => {
  return HomeCategory.destroy({ where: { id } });
};
