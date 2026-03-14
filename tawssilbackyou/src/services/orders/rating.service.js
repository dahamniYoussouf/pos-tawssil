import Order from "../../models/Order.js";
import Restaurant from "../../models/Restaurant.js";
import Driver from "../../models/Driver.js";
import { Op } from "sequelize";
import { sequelize } from "../../config/database.js";

const ensureDeliveredOrder = async (orderId) => {
  const order = await Order.findByPk(orderId);
  if (!order) throw { status: 404, message: "Order not found" };
  if (order.status !== "delivered") throw { status: 400, message: "Order must be delivered before rating" };
  return order;
};

const updateRestaurantAverage = async (restaurantId) => {
  if (!restaurantId) return;
  const restaurant = await Restaurant.findByPk(restaurantId);
  if (!restaurant) return;

  const stats = await Order.findOne({
    attributes: [
      [sequelize.fn("AVG", sequelize.col("rating")), "avg_rating"],
      [sequelize.fn("COUNT", sequelize.col("rating")), "rating_count"]
    ],
    where: {
      restaurant_id: restaurantId,
      status: "delivered",
      rating: { [Op.ne]: null }
    },
    raw: true
  });

  const ratingCount = Number.parseInt(stats?.rating_count ?? "0", 10) || 0;
  const avgRatingRaw = stats?.avg_rating !== null && stats?.avg_rating !== undefined ? Number(stats.avg_rating) : 0;
  const avgRating = ratingCount > 0 ? Number(avgRatingRaw.toFixed(1)) : 0;

  await restaurant.update({ rating: avgRating });
};

const updateDriverAverage = async (driverId) => {
  if (!driverId) return;
  const driver = await Driver.findByPk(driverId);
  if (!driver) return;

  const stats = await Order.findOne({
    attributes: [
      [sequelize.fn("AVG", sequelize.col("driver_rating")), "avg_rating"],
      [sequelize.fn("COUNT", sequelize.col("driver_rating")), "rating_count"]
    ],
    where: {
      livreur_id: driverId,
      status: "delivered",
      driver_rating: { [Op.ne]: null }
    },
    raw: true
  });

  const ratingCount = Number.parseInt(stats?.rating_count ?? "0", 10) || 0;
  const avgRatingRaw = stats?.avg_rating !== null && stats?.avg_rating !== undefined ? Number(stats.avg_rating) : 0;
  const avgRating = ratingCount > 0 ? Number(avgRatingRaw.toFixed(1)) : 0;

  await driver.update({ rating: avgRating });
};

export async function addRestaurantRatingService(orderId, restaurantRating, restaurantComment) {
  const order = await ensureDeliveredOrder(orderId);
  if (order.rating !== null && order.rating !== undefined) {
    throw { status: 400, message: "Restaurant rating already submitted" };
  }

  const updates = {
    rating: parseFloat(restaurantRating)
  };
  if (restaurantComment !== undefined) {
    updates.restaurant_review_comment = restaurantComment;
  }

  await order.update(updates);
  await updateRestaurantAverage(order.restaurant_id);
  await order.reload();
  return order;
}

export async function addDriverRatingService(orderId, driverRating, driverComment) {
  const order = await ensureDeliveredOrder(orderId);
  if (order.driver_rating !== null && order.driver_rating !== undefined) {
    throw { status: 400, message: "Driver rating already submitted" };
  }

  const updates = {
    driver_rating: parseFloat(driverRating)
  };
  if (driverComment !== undefined) {
    updates.driver_review_comment = driverComment;
  }

  await order.update(updates);
  await updateDriverAverage(order.livreur_id);
  await order.reload();
  return order;
}
