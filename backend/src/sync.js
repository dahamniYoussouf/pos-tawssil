// src/sync.js
import { DataTypes } from "sequelize";
import sequelize from "./config/database.js";
import "./models/Order.js";
import "./models/Restaurant.js";
import "./models/Wilaya.js";
import "./models/Commune.js";
import "./models/Client.js";
import "./models/MenuItem.js";
import "./models/Addition.js";
import "./models/OptionGroup.js";
import "./models/FoodCategory.js";
import "./models/OrderItem.js";
import "./models/OrderItemAddition.js";
import "./models/FavoriteMeal.js";
import "./models/FavoriteRestaurant.js";
import "./models/FavoriteAddress.js";
import "./models/Announcement.js";
import "./models/HomeCategory.js";
import "./models/ThematicSelection.js";
import "./models/RecommendedDish.js";
import "./models/Promotion.js";
import "./models/PromotionMenuItem.js";
import "./models/DailyDeal.js";
import "./models/Driver.js";
import "./models/User.js";
import "./models/Admin.js";
import "./models/AdminNotification.js";
import "./models/SystemConfig.js";
import "./models/Cashier.js";
import "./models/RestaurantPrinter.js";
import "./models/DatabaseBackup.js";
import "./models/DeviceToken.js";
import "./models/NewsletterSubscriber.js";

// Import associations
import "./models/index.js";

(async () => {
  try {
    await sequelize.authenticate();
    console.log("Database connected");

    const requestedMode = (process.env.DB_SYNC_MODE || "safe").toLowerCase();
    const allowedModes = new Set(["safe", "alter", "force"]);
    const syncMode = allowedModes.has(requestedMode) ? requestedMode : "safe";

    if (syncMode !== requestedMode) {
      console.warn(`Unknown DB_SYNC_MODE="${requestedMode}", defaulting to "safe"`);
    }

    const syncOptions =
      syncMode === "force" ? { force: true } : syncMode === "alter" ? { alter: true } : undefined;

    if (syncMode === "safe") {
      const queryInterface = sequelize.getQueryInterface();
      const ensureColumn = async (table, column, definition) => {
        try {
          const tableDefinition = await queryInterface.describeTable(table);
          if (!tableDefinition[column]) {
            await queryInterface.addColumn(table, column, definition);
          }
        } catch (err) {
          // Table does not exist yet; sync will create it.
        }
      };

      await ensureColumn("additions", "option_group_id", {
        type: DataTypes.UUID,
        allowNull: true,
      });

      // Ensure restaurant availability status columns exist (safe mode)
      await sequelize.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_restaurants_availability_status') THEN
            CREATE TYPE enum_restaurants_availability_status AS ENUM ('open', 'closed', 'vacation', 'saturated', 'other');
          END IF;
        END$$;
      `);

      await ensureColumn("restaurants", "availability_status", {
        type: DataTypes.ENUM('open', 'closed', 'vacation', 'saturated', 'other'),
        allowNull: false,
        defaultValue: 'open'
      });

      await ensureColumn("restaurants", "availability_note", {
        type: DataTypes.TEXT,
        allowNull: true
      });

      await ensureColumn("database_backups", "stats", {
        type: DataTypes.JSONB,
        allowNull: true
      });

      await ensureColumn("clients", "locale", {
        type: DataTypes.STRING(5),
        allowNull: false,
        defaultValue: "fr"
      });

      await ensureColumn("clients", "review_contact_lock_admin_id", {
        type: DataTypes.UUID,
        allowNull: true
      });

      await ensureColumn("clients", "review_contact_lock_order_id", {
        type: DataTypes.UUID,
        allowNull: true
      });

      await ensureColumn("clients", "review_contact_locked_at", {
        type: DataTypes.DATE,
        allowNull: true
      });

      await ensureColumn("clients", "review_contact_lock_until", {
        type: DataTypes.DATE,
        allowNull: true
      });

      await ensureColumn("users", "email_verified_at", {
        type: DataTypes.DATE,
        allowNull: true
      });

      await ensureColumn("users", "password_reset_token_hash", {
        type: DataTypes.STRING(128),
        allowNull: true
      });

      await ensureColumn("users", "password_reset_expires_at", {
        type: DataTypes.DATE,
        allowNull: true
      });

      await ensureColumn("drivers", "locale", {
        type: DataTypes.STRING(5),
        allowNull: false,
        defaultValue: "fr"
      });

      await ensureColumn("restaurants", "locale", {
        type: DataTypes.STRING(5),
        allowNull: false,
        defaultValue: "fr"
      });

      await ensureColumn("restaurants", "commune_id", {
        type: DataTypes.UUID,
        allowNull: true
      });

      await ensureColumn("admins", "locale", {
        type: DataTypes.STRING(5),
        allowNull: false,
        defaultValue: "fr"
      });

      await ensureColumn("device_tokens", "locale", {
        type: DataTypes.STRING(5),
        allowNull: false,
        defaultValue: "fr"
      });

      await ensureColumn("device_tokens", "failure_count", {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0
      });

      await ensureColumn("device_tokens", "last_failure_code", {
        type: DataTypes.STRING(120),
        allowNull: true
      });

      await ensureColumn("device_tokens", "last_failure_at", {
        type: DataTypes.DATE,
        allowNull: true
      });

      await ensureColumn("orders", "requires_admin_review", {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
      });

      await ensureColumn("orders", "admin_review_status", {
        type: DataTypes.STRING(20),
        allowNull: false,
        defaultValue: "none"
      });

      await ensureColumn("orders", "admin_review_metadata", {
        type: DataTypes.JSONB,
        allowNull: true
      });

      await ensureColumn("orders", "admin_review_claimed_by", {
        type: DataTypes.UUID,
        allowNull: true
      });

      await ensureColumn("orders", "admin_review_claimed_at", {
        type: DataTypes.DATE,
        allowNull: true
      });

      await ensureColumn("orders", "admin_reviewed_by", {
        type: DataTypes.UUID,
        allowNull: true
      });

      await ensureColumn("orders", "admin_reviewed_at", {
        type: DataTypes.DATE,
        allowNull: true
      });

      await ensureColumn("orders", "admin_review_notes", {
        type: DataTypes.TEXT,
        allowNull: true
      });

      await ensureColumn("orders", "restaurant_notified_at", {
        type: DataTypes.DATE,
        allowNull: true
      });

      // Ensure admin notification enum values exist (safe mode)
      await sequelize.query(`
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_admin_notifications_type') THEN
            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_type'
                AND e.enumlabel = 'restaurant_preparation_timeout'
            ) THEN
              ALTER TYPE enum_admin_notifications_type ADD VALUE 'restaurant_preparation_timeout';
            END IF;

            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_type'
                AND e.enumlabel = 'driver_arrival_timeout'
            ) THEN
              ALTER TYPE enum_admin_notifications_type ADD VALUE 'driver_arrival_timeout';
            END IF;

            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_type'
                AND e.enumlabel = 'driver_delivery_timeout'
            ) THEN
              ALTER TYPE enum_admin_notifications_type ADD VALUE 'driver_delivery_timeout';
            END IF;

            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_type'
                AND e.enumlabel = 'order_admin_review_required'
            ) THEN
              ALTER TYPE enum_admin_notifications_type ADD VALUE 'order_admin_review_required';
            END IF;

            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_admin_action'
                AND e.enumlabel = 'contacted_client'
            ) THEN
              ALTER TYPE enum_admin_notifications_admin_action ADD VALUE 'contacted_client';
            END IF;

            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_admin_action'
                AND e.enumlabel = 'approved_order'
            ) THEN
              ALTER TYPE enum_admin_notifications_admin_action ADD VALUE 'approved_order';
            END IF;

            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_admin_action'
                AND e.enumlabel = 'released_lock'
            ) THEN
              ALTER TYPE enum_admin_notifications_admin_action ADD VALUE 'released_lock';
            END IF;

            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_admin_notifications_admin_action'
                AND e.enumlabel = 'rejected_order'
            ) THEN
              ALTER TYPE enum_admin_notifications_admin_action ADD VALUE 'rejected_order';
            END IF;
          END IF;
        END$$;
      `);

      await sequelize.query(`
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_orders_status') THEN
            IF NOT EXISTS (
              SELECT 1
              FROM pg_enum e
              JOIN pg_type t ON t.oid = e.enumtypid
              WHERE t.typname = 'enum_orders_status'
                AND e.enumlabel = 'pending_admin_review'
            ) THEN
              ALTER TYPE enum_orders_status ADD VALUE 'pending_admin_review';
            END IF;
          END IF;
        END$$;
      `);

      // Create restaurant_printers if not exists (impression ESC/POS)
      await sequelize.query(`
        CREATE TABLE IF NOT EXISTS restaurant_printers (
          id UUID PRIMARY KEY,
          restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE ON UPDATE CASCADE,
          name VARCHAR(255) NOT NULL,
          type VARCHAR(50) NOT NULL DEFAULT 'general',
          ip VARCHAR(45) NOT NULL,
          port INTEGER NOT NULL DEFAULT 9100,
          is_enabled BOOLEAN NOT NULL DEFAULT true,
          paper_width_mm INTEGER NOT NULL DEFAULT 80,
          created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
        );
      `);

    }

    await sequelize.sync(syncOptions);
    console.log(`Database synchronized (mode: ${syncMode})`);

    if (syncMode === "safe") {
      await sequelize.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (
            SELECT 1
            FROM information_schema.table_constraints
            WHERE constraint_name = 'restaurants_commune_id_fkey'
              AND table_name = 'restaurants'
          ) THEN
            ALTER TABLE restaurants
              ADD CONSTRAINT restaurants_commune_id_fkey
              FOREIGN KEY (commune_id)
              REFERENCES communes(id)
              ON DELETE SET NULL
              ON UPDATE CASCADE;
          END IF;
        END$$;
      `);

      await sequelize.query(`
        CREATE INDEX IF NOT EXISTS restaurants_commune_id_idx
        ON restaurants (commune_id);
      `);

      await sequelize.query(`
        CREATE INDEX IF NOT EXISTS users_password_reset_token_hash_idx
        ON users (password_reset_token_hash);
      `);

      await sequelize.query(`
        CREATE INDEX IF NOT EXISTS device_tokens_role_active_idx
        ON device_tokens (role, is_active);
      `);

      await sequelize.query(`
        CREATE INDEX IF NOT EXISTS device_tokens_role_profile_active_idx
        ON device_tokens (role, profile_id, is_active);
      `);

      await sequelize.query(`
        CREATE INDEX IF NOT EXISTS device_tokens_user_active_idx
        ON device_tokens (user_id, is_active);
      `);
    }

    process.exit(0);
  } catch (error) {
    console.error("Sync failed:", error);
    process.exit(1);
  }
})();
