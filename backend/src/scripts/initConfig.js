// src/scripts/initConfig.js
import { sequelize } from "../config/database.js";
import SystemConfig from "../models/SystemConfig.js";
import Driver from "../models/Driver.js";

const isProd = process.env.NODE_ENV === "production";

const parsePositiveInt = (value, fallback) => {
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
};

const initializeConfiguration = async () => {
  try {
    await sequelize.authenticate();
    console.log("✅ Database connected");

    // Liste complète des configurations par défaut
    const defaultConfigs = [
      {
        key: 'max_orders_per_driver',
        value: 5,
        description: 'Maximum number of orders a driver can handle simultaneously'
      },
      {
        key: 'max_distance_between_restaurants',
        value: 500,
        description: 'Maximum distance (in meters) between restaurants for multi-delivery'
      },
      {
        key: 'client_restaurant_search_radius',
        value: 2000,
        description: 'Default search radius (in meters) for clients to find nearby restaurants'
      },
      {
        key: 'default_preparation_time',
        value: 15,
        description: 'Default preparation time (in minutes) used when not provided by a restaurant'
      },
      {
        key: 'client_order_review_threshold',
        value: 3,
        description: 'Minimum number of previous client orders before routing directly to the restaurant'
      },
      {
        key: 'high_value_order_review_threshold',
        value: 10000,
        description: 'Order total (in DA) above which an order must be reviewed by an admin'
      },
      {
        key: 'pending_order_timeout',
        value: 3,
        description: 'Delay (in minutes) before notifying admins about a pending order without response'
      },
      {
        key: 'restaurant_preparation_timeout',
        value: 20,
        description: 'Delay (in minutes) before notifying admins about long restaurant preparation'
      },
      {
        key: 'driver_arrival_timeout',
        value: 15,
        description: 'Delay (in minutes) before notifying admins about late driver arrival'
      },
      {
        key: 'driver_delivery_timeout',
        value: 45,
        description: 'Delay (in minutes) before notifying admins about long deliveries'
      },
      {
        key: 'default_delivery_fee',
        value: 200,
        description: 'Default delivery fee (in DA) applied when not provided for delivery orders'
      },
      {
        key: 'delivery_fee_base',
        value: 200,
        description: 'Base delivery fee (in DA) used in the formula base + (distance_km x price_per_km)'
      },
      {
        key: 'delivery_fee_per_km',
        value: 0,
        description: 'Delivery price per kilometer (in DA/km) used in the formula base + (distance_km x price_per_km)'
      },
      {
        key: 'max_driver_cancellations',
        value: 3,
        description: 'Maximum cancellations allowed before notifying admins about a driver'
      },
      {
        key: 'driver_nearby_search_radius',
        value: 5000,
        description: 'Default radius (in meters) for drivers to see nearby orders and receive notifications'
      },
      {
        key: 'otp_request_use_paid_service',
        value: false,
        description: 'Use the paid OTP sender for /auth/otp/request instead of returning the OTP directly'
      },
      {
        key: 'OTP_RATE_LIMIT_MAX',
        value: parsePositiveInt(process.env.OTP_RATE_LIMIT_MAX, isProd ? 10 : 50),
        description: 'Maximum number of OTP requests allowed per 15 minutes'
      }
    ];

    // Créer ou mettre à jour toutes les configurations
    console.log("⚙️  Initializing system configurations...");
    for (const config of defaultConfigs) {
      const existing = await SystemConfig.findOne({ where: { config_key: config.key } });
      if (!existing) {
        await SystemConfig.set(
          config.key,
          config.value,
          null,
          config.description
        );
        console.log(`✅ Created config: ${config.key} = ${config.value}`);
      } else {
        console.log(`ℹ️  Config already exists: ${config.key} = ${existing.config_value}`);
      }
    }

    console.log(`✅ ${defaultConfigs.length} configurations initialized`);

    // Mettre à jour la capacité de tous les livreurs existants
    const maxOrders = await SystemConfig.get('max_orders_per_driver', 5);
    const driversUpdated = await Driver.update(
      { max_orders_capacity: maxOrders },
      { where: {} }
    );

    console.log(`✅ Updated ${driversUpdated[0]} drivers with max_orders_capacity = ${maxOrders}`);

    process.exit(0);
  } catch (error) {
    console.error("❌ Initialization failed:", error);
    process.exit(1);
  }
};

initializeConfiguration();
