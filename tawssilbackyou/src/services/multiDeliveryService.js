import { sequelize } from "../config/database.js";
import Restaurant from "../models/Restaurant.js";
import Driver from "../models/Driver.js";
import SystemConfig from "../models/SystemConfig.js";

const shouldLog = process.env.LOG_MULTI_DELIVERY === "true";

/**
 * Verifie si deux restaurants sont a moins de MAX_DISTANCE_BETWEEN_RESTAURANTS metres.
 */
export const areRestaurantsNearby = async (restaurant1Id, restaurant2Id) => {
  const maxDistance = await SystemConfig.get("max_distance_between_restaurants", 500);

  const [restaurant1, restaurant2] = await Promise.all([
    Restaurant.findByPk(restaurant1Id),
    Restaurant.findByPk(restaurant2Id)
  ]);

  if (!restaurant1 || !restaurant2) {
    return false;
  }

  const coords1 = restaurant1.location?.coordinates;
  const coords2 = restaurant2.location?.coordinates;

  if (!coords1 || !coords2) {
    return false;
  }

  const result = await sequelize.query(
    `
      SELECT ST_Distance(
        ST_GeogFromText('POINT(${coords1[0]} ${coords1[1]})'),
        ST_GeogFromText('POINT(${coords2[0]} ${coords2[1]})')
      ) as distance
    `,
    { type: sequelize.QueryTypes.SELECT }
  );

  const distance = parseFloat(result[0].distance);
  if (shouldLog) {
    console.log(`Distance entre restaurants ${restaurant1Id} et ${restaurant2Id}: ${distance}m`);
  }

  return distance <= maxDistance;
};

const resolveDriver = async (driverOrId) => {
  if (driverOrId && typeof driverOrId.canAcceptMoreOrders === "function") {
    return driverOrId;
  }

  return driverOrId ? Driver.findByPk(driverOrId) : null;
};

/**
 * Verifie si un livreur a encore de la capacite pour accepter une commande.
 */
export const canDriverAcceptOrder = async (driverOrId) => {
  const driver = await resolveDriver(driverOrId);

  if (!driver || !driver.canAcceptMoreOrders()) {
    return {
      canAccept: false,
      reason: "Driver not available or at max capacity"
    };
  }

  return { canAccept: true };
};

/**
 * Recupere la configuration max de commandes.
 */
export const getMaxOrdersPerDriver = async () => {
  return await SystemConfig.get("max_orders_per_driver", 5);
};

/**
 * Met a jour la configuration max de commandes.
 */
export const updateMaxOrdersPerDriver = async (maxOrders, adminId) => {
  if (maxOrders < 1 || maxOrders > 10) {
    throw new Error("Max orders must be between 1 and 10");
  }

  const config = await SystemConfig.set(
    "max_orders_per_driver",
    maxOrders,
    adminId,
    "Maximum number of orders a driver can handle simultaneously"
  );

  await Driver.update(
    { max_orders_capacity: maxOrders },
    { where: {} }
  );

  return config;
};
