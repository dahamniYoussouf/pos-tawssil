BEGIN;

CREATE TEMP TABLE purge_restaurants ON COMMIT DROP AS
SELECT id, user_id
FROM restaurants;

CREATE TEMP TABLE purge_cashiers ON COMMIT DROP AS
SELECT id, user_id
FROM cashiers
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

CREATE TEMP TABLE purge_printers ON COMMIT DROP AS
SELECT id
FROM restaurant_printers
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

CREATE TEMP TABLE purge_orders ON COMMIT DROP AS
SELECT id
FROM orders
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

CREATE TEMP TABLE purge_menu_items ON COMMIT DROP AS
SELECT id
FROM menu_items
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

CREATE TEMP TABLE purge_promotions ON COMMIT DROP AS
SELECT p.id
FROM promotions p
LEFT JOIN promotion_menu_items pmi
  ON pmi.promotion_id = p.id
GROUP BY p.id, p.restaurant_id, p.menu_item_id
HAVING
  p.restaurant_id IN (SELECT id FROM purge_restaurants)
  OR p.menu_item_id IN (SELECT id FROM purge_menu_items)
  OR (
    p.restaurant_id IS NULL
    AND p.menu_item_id IS NULL
    AND COUNT(*) FILTER (WHERE pmi.menu_item_id IS NOT NULL) > 0
    AND COUNT(*) FILTER (
      WHERE pmi.menu_item_id NOT IN (SELECT id FROM purge_menu_items)
    ) = 0
  );

SELECT 'target_restaurants|' || COUNT(*) FROM purge_restaurants;
SELECT 'target_restaurant_users|' || COUNT(*) FROM purge_restaurants WHERE user_id IS NOT NULL;
SELECT 'target_cashiers|' || COUNT(*) FROM purge_cashiers;
SELECT 'target_cashier_users|' || COUNT(*) FROM purge_cashiers WHERE user_id IS NOT NULL;
SELECT 'target_printers|' || COUNT(*) FROM purge_printers;
SELECT 'target_orders|' || COUNT(*) FROM purge_orders;
SELECT 'target_menu_items|' || COUNT(*) FROM purge_menu_items;
SELECT 'target_promotions|' || COUNT(*) FROM purge_promotions;

DO $$
BEGIN
  IF to_regclass('public.print_jobs') IS NOT NULL THEN
    EXECUTE '
      DELETE FROM print_jobs
      WHERE restaurant_id IN (SELECT id FROM purge_restaurants)
         OR printer_id IN (SELECT id FROM purge_printers)
         OR order_id IN (SELECT id FROM purge_orders)
    ';
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.printer_templates') IS NOT NULL THEN
    EXECUTE '
      DELETE FROM printer_templates
      WHERE restaurant_id IN (SELECT id FROM purge_restaurants)
         OR printer_id IN (SELECT id FROM purge_printers)
    ';
  END IF;
END $$;

DELETE FROM admin_notifications
WHERE restaurant_id IN (SELECT id FROM purge_restaurants)
   OR order_id IN (SELECT id FROM purge_orders);

DELETE FROM announcements
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

DELETE FROM daily_deals
WHERE promotion_id IN (SELECT id FROM purge_promotions);

DELETE FROM promotion_menu_items
WHERE promotion_id IN (SELECT id FROM purge_promotions)
   OR menu_item_id IN (SELECT id FROM purge_menu_items);

DELETE FROM promotions
WHERE id IN (SELECT id FROM purge_promotions);

DELETE FROM recommended_dishes
WHERE restaurant_id IN (SELECT id FROM purge_restaurants)
   OR menu_item_id IN (SELECT id FROM purge_menu_items);

DELETE FROM favorite_restaurants
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

DELETE FROM favorite_meals
WHERE meal_id IN (SELECT id FROM purge_menu_items);

DELETE FROM restaurant_home_categories
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

DELETE FROM restaurant_printers
WHERE id IN (SELECT id FROM purge_printers);

DELETE FROM orders
WHERE id IN (SELECT id FROM purge_orders);

DELETE FROM option_groups
WHERE menu_item_id IN (SELECT id FROM purge_menu_items);

DELETE FROM additions
WHERE menu_item_id IN (SELECT id FROM purge_menu_items);

DELETE FROM menu_items
WHERE id IN (SELECT id FROM purge_menu_items);

DELETE FROM food_categories
WHERE restaurant_id IN (SELECT id FROM purge_restaurants);

DELETE FROM cashiers
WHERE id IN (SELECT id FROM purge_cashiers);

DELETE FROM restaurants
WHERE id IN (SELECT id FROM purge_restaurants);

DELETE FROM users
WHERE id IN (
  SELECT user_id FROM purge_restaurants WHERE user_id IS NOT NULL
  UNION
  SELECT user_id FROM purge_cashiers WHERE user_id IS NOT NULL
);

COMMIT;
