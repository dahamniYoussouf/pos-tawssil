SELECT 'restaurants' AS label, COUNT(*)::BIGINT AS total FROM restaurants
UNION ALL
SELECT 'restaurant_users', COUNT(*)::BIGINT FROM users u INNER JOIN restaurants r ON r.user_id = u.id
UNION ALL
SELECT 'cashiers', COUNT(*)::BIGINT FROM cashiers
UNION ALL
SELECT 'cashier_users', COUNT(*)::BIGINT FROM users u INNER JOIN cashiers c ON c.user_id = u.id
UNION ALL
SELECT 'food_categories', COUNT(*)::BIGINT FROM food_categories
UNION ALL
SELECT 'menu_items', COUNT(*)::BIGINT FROM menu_items
UNION ALL
SELECT 'option_groups', COUNT(*)::BIGINT FROM option_groups
UNION ALL
SELECT 'additions', COUNT(*)::BIGINT FROM additions
UNION ALL
SELECT 'orders', COUNT(*)::BIGINT FROM orders
UNION ALL
SELECT 'order_items', COUNT(*)::BIGINT FROM order_items
UNION ALL
SELECT 'order_item_additions', COUNT(*)::BIGINT FROM order_item_additions
UNION ALL
SELECT 'favorite_restaurants', COUNT(*)::BIGINT FROM favorite_restaurants
UNION ALL
SELECT 'favorite_meals', COUNT(*)::BIGINT FROM favorite_meals
UNION ALL
SELECT 'promotions', COUNT(*)::BIGINT FROM promotions
UNION ALL
SELECT 'promotion_menu_items', COUNT(*)::BIGINT FROM promotion_menu_items
UNION ALL
SELECT 'daily_deals', COUNT(*)::BIGINT FROM daily_deals
UNION ALL
SELECT 'recommended_dishes', COUNT(*)::BIGINT FROM recommended_dishes
UNION ALL
SELECT 'restaurant_home_categories', COUNT(*)::BIGINT FROM restaurant_home_categories
UNION ALL
SELECT 'restaurant_printers', COUNT(*)::BIGINT FROM restaurant_printers
UNION ALL
SELECT 'printer_templates_exists', CASE WHEN to_regclass('public.printer_templates') IS NULL THEN 0 ELSE 1 END
UNION ALL
SELECT 'print_jobs_exists', CASE WHEN to_regclass('public.print_jobs') IS NULL THEN 0 ELSE 1 END
UNION ALL
SELECT 'admin_notifications_with_restaurant', COUNT(*)::BIGINT FROM admin_notifications WHERE restaurant_id IS NOT NULL
UNION ALL
SELECT 'announcements_with_restaurant', COUNT(*)::BIGINT FROM announcements WHERE restaurant_id IS NOT NULL
ORDER BY label;
