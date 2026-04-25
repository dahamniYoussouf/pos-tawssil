import sequelize from "../config/database.js";

const logStep = (message) => console.log(`\n\u25B6\uFE0F  ${message}`);

(async () => {
  try {
    await sequelize.authenticate();
    console.log("✅ Connected to database");

    logStep("Updating drivers.rating default to 0");
    await sequelize.query(`ALTER TABLE IF EXISTS drivers ALTER COLUMN rating SET DEFAULT 0;`);

    logStep("Recalculating restaurants ratings from delivered orders");
    await sequelize.query(`
      UPDATE restaurants r
      SET rating = COALESCE(s.avg_rating, 0)
      FROM (
        SELECT restaurant_id, ROUND(AVG(rating)::numeric, 1) AS avg_rating
        FROM orders
        WHERE status = 'delivered' AND rating IS NOT NULL
        GROUP BY restaurant_id
      ) s
      WHERE r.id = s.restaurant_id;
    `);

    await sequelize.query(`
      UPDATE restaurants r
      SET rating = 0
      WHERE NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.restaurant_id = r.id
          AND o.status = 'delivered'
          AND o.rating IS NOT NULL
      );
    `);

    logStep("Recalculating drivers ratings from delivered orders");
    await sequelize.query(`
      UPDATE drivers d
      SET rating = COALESCE(s.avg_rating, 0)
      FROM (
        SELECT livreur_id AS driver_id, ROUND(AVG(driver_rating)::numeric, 1) AS avg_rating
        FROM orders
        WHERE status = 'delivered' AND driver_rating IS NOT NULL AND livreur_id IS NOT NULL
        GROUP BY livreur_id
      ) s
      WHERE d.id = s.driver_id;
    `);

    await sequelize.query(`
      UPDATE drivers d
      SET rating = 0
      WHERE NOT EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.livreur_id = d.id
          AND o.status = 'delivered'
          AND o.driver_rating IS NOT NULL
      );
    `);

    console.log("\n✅ Ratings recalculated successfully");
  } catch (err) {
    console.error("❌ Failed to recalculate ratings:", err);
    process.exitCode = 1;
  }

  await sequelize.close();
  process.exit();
})();

