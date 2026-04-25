import sequelize from "../config/database.js";

const statements = [
  `CREATE INDEX IF NOT EXISTS restaurants_location_gix ON restaurants USING GIST (location)`,
  `CREATE INDEX IF NOT EXISTS restaurants_active_approved_location_gix ON restaurants USING GIST (location) WHERE is_active = true AND status = 'approved'`,
  `CREATE INDEX IF NOT EXISTS restaurants_active_approved_premium_location_gix ON restaurants USING GIST (location) WHERE is_active = true AND status = 'approved' AND is_premium = true`,
  `CREATE INDEX IF NOT EXISTS menu_items_restaurant_id_idx ON menu_items (restaurant_id)`,
  `CREATE INDEX IF NOT EXISTS menu_items_restaurant_available_created_idx ON menu_items (restaurant_id, is_available, created_at DESC)`,
  `CREATE INDEX IF NOT EXISTS restaurant_home_categories_restaurant_id_idx ON restaurant_home_categories (restaurant_id)`,
  `CREATE INDEX IF NOT EXISTS restaurant_home_categories_home_category_id_idx ON restaurant_home_categories (home_category_id)`,
  `CREATE INDEX IF NOT EXISTS restaurant_home_categories_home_category_restaurant_idx ON restaurant_home_categories (home_category_id, restaurant_id)`,
  `CREATE INDEX IF NOT EXISTS food_categories_restaurant_id_idx ON food_categories (restaurant_id)`,
  `CREATE INDEX IF NOT EXISTS food_categories_restaurant_order_idx ON food_categories (restaurant_id, ordre_affichage)`,
  `CREATE INDEX IF NOT EXISTS home_categories_active_order_idx ON home_categories (is_active, display_order, created_at)`,
  `CREATE INDEX IF NOT EXISTS thematic_selections_active_created_idx ON thematic_selections (is_active, created_at DESC)`,
  `CREATE INDEX IF NOT EXISTS recommended_dishes_active_created_idx ON recommended_dishes (is_active, created_at DESC)`,
  `CREATE INDEX IF NOT EXISTS daily_deals_active_window_idx ON daily_deals (is_active, start_date, end_date)`,
  `CREATE INDEX IF NOT EXISTS promotions_active_window_idx ON promotions (is_active, start_date, end_date)`,
  `CREATE INDEX IF NOT EXISTS announcements_active_window_idx ON announcements (is_active, start_date, end_date)`,
  `CREATE INDEX IF NOT EXISTS device_tokens_role_active_idx ON device_tokens (role, is_active)`,
  `CREATE INDEX IF NOT EXISTS device_tokens_role_profile_active_idx ON device_tokens (role, profile_id, is_active)`,
  `CREATE INDEX IF NOT EXISTS device_tokens_user_active_idx ON device_tokens (user_id, is_active)`
];

(async () => {
  try {
    await sequelize.authenticate();
    console.log("Database connected");

    for (const sql of statements) {
      await sequelize.query(sql);
    }

    console.log("Performance indexes created/verified");
    process.exit(0);
  } catch (error) {
    console.error("Index creation failed:", error);
    process.exit(1);
  }
})();
