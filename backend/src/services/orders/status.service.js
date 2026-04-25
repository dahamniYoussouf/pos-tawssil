import { sequelize } from "../../config/database.js";
import Order from "../../models/Order.js";
import Restaurant from "../../models/Restaurant.js";
import Client from "../../models/Client.js";
import Driver from "../../models/Driver.js";
import SystemConfig from "../../models/SystemConfig.js";
import { queueNotifyNearbyDrivers } from "../driverNotification.service.js";
import calculateRouteTime from "../routingService.js";
import { canDriverAcceptOrder } from "../multiDeliveryService.js";
import { notify } from "./notify.helper.js";
import {
  getClientAcceptedCopy,
  getClientDeclinedCopy,
  getClientDeliveredCopy,
  getClientDeliveryStartedCopy,
  getClientReadyForPickupCopy
} from "./pushCopy.helper.js";
import {
  scheduleAdminNotificationDriver,
  scheduleRestaurantPreparationTimeout,
  scheduleDriverArrivalTimeout,
  scheduleDriverDeliveryTimeout,
  addExtraPreparationTime
} from "./scheduling.service.js";

// ✅ Award loyalty points to client (1 point per 100 DZD)
async function awardLoyaltyPoints(clientId, orderTotal, orderId) {
  try {
    if (!clientId || !orderTotal) return;
    
    const client = await Client.findByPk(clientId);
    if (!client) return;
    
    // 1 point for every 100 DZD spent
    const points = Math.floor(parseFloat(orderTotal) / 100);
    
    if (points <= 0) return;
    
    const newTotal = (client.loyalty_points || 0) + points;
    await client.update({ loyalty_points: newTotal });
    
    console.log(`✅ Awarded ${points} loyalty points to client ${clientId} (Order: ${orderId}). New total: ${newTotal}`);
    
    return newTotal;
  } catch (error) {
    console.error('Error awarding loyalty points:', error);
  }
}

export async function acceptOrder(orderId, actor, data = {}) {
  const order = await Order.findByPk(orderId, {
    include: [{ model: Client, as: "client" }, { model: Restaurant, as: "restaurant" }],
  });
  
  if (!order) throw { status: 404, message: "Order not found" };
  if (!actor || !["restaurant", "cashier", "admin"].includes(actor.role)) {
    throw { status: 403, message: "Access restricted to restaurants" };
  }
  if (actor.role !== "admin") {
    const restaurantId = actor.restaurantId;
    if (!restaurantId) {
      throw { status: 403, message: "Restaurant profile not found in token" };
    }
    if (order.restaurant_id !== restaurantId) {
      throw { status: 403, message: "You are not allowed to manage this order" };
    }
  }
  if (!order.canTransitionTo("accepted")) {
    throw { status: 400, message: `Cannot accept order in ${order.status} status` };
  }

  let preparationMinutes = Number.parseInt(String(data?.preparation_time ?? ''), 10);
  if (!Number.isFinite(preparationMinutes) || preparationMinutes <= 0) {
    const configuredDefault = await SystemConfig.get('default_preparation_time', 15);
    const parsedConfigured = Number.parseInt(String(configuredDefault), 10);
    preparationMinutes = Number.isFinite(parsedConfigured)
      ? Math.min(120, Math.max(5, parsedConfigured))
      : 15;
  } else {
    preparationMinutes = Math.min(120, Math.max(5, preparationMinutes));
  }

  let deliveryTimeMinutes = preparationMinutes;
  let deliveryDistanceKm = order.delivery_distance;
  let estimatedDeliveryTime = new Date(Date.now() + preparationMinutes * 60 * 1000);

  if (order.order_type === "delivery") {
    const restaurantCoords = order.restaurant?.getCoordinates?.();
    const deliveryCoords = order.delivery_location?.coordinates;

    if (restaurantCoords && deliveryCoords && deliveryCoords.length === 2) {
      const [deliveryLng, deliveryLat] = deliveryCoords;

      try {
        const route = await calculateRouteTime(
          restaurantCoords.longitude,
          restaurantCoords.latitude,
          deliveryLng,
          deliveryLat,
          40
        );

        deliveryTimeMinutes = preparationMinutes + route.timeMax;
        deliveryDistanceKm = route.distanceKm;
        estimatedDeliveryTime = new Date(Date.now() + deliveryTimeMinutes * 60 * 1000);

        console.log(`📍 Route Restaurant→Client: ${route.distanceKm} km, ~${route.timeMax} min`);
        console.log(`⏱️ Temps total: ${preparationMinutes} min (préparation) + ${route.timeMax} min (trajet) = ${deliveryTimeMinutes} min`);
      } catch (error) {
        console.error("Route calculation failed:", error?.message || error);
        const defaultDeliveryTime = 20;
        deliveryTimeMinutes = preparationMinutes + defaultDeliveryTime;
        estimatedDeliveryTime = new Date(Date.now() + deliveryTimeMinutes * 60 * 1000);
        console.warn(`⚠️ Utilisation estimation par défaut: ${defaultDeliveryTime} min pour le trajet`);
      }
    } else {
      console.warn(`⚠️ Coordonnées manquantes pour calculer le trajet (order ${orderId})`);
    }
  }

  await order.update({
    status: "accepted",
    preparation_time: preparationMinutes,
    accepted_at: new Date(),
    estimated_delivery_time: estimatedDeliveryTime,
    ...(deliveryDistanceKm && { delivery_distance: deliveryDistanceKm }),
  });

  const restaurantName = order.restaurant?.name || "Restaurant";
  const deliverySegmentMinutes = Math.max(0, deliveryTimeMinutes - preparationMinutes);
  let messageEn = `${restaurantName} accepted your order.`;
  let messageFr = `${restaurantName} a accepte votre commande.`;
  let messageAr = `قبل مطعم ${restaurantName} طلبك.`;

  if (order.order_type === "delivery") {
    messageEn += ` Estimated delivery time: ${deliveryTimeMinutes} min (${preparationMinutes} min preparation + ${deliverySegmentMinutes} min delivery)`;
    messageFr += ` Temps estime: ${deliveryTimeMinutes} min (${preparationMinutes} min preparation + ${deliverySegmentMinutes} min livraison)`;
    messageAr += ` الوقت المقدر: ${deliveryTimeMinutes} دقيقة (${preparationMinutes} دقيقة تحضير + ${deliverySegmentMinutes} دقيقة توصيل)`;
  } else {
    messageEn += ` Estimated preparation time: ${preparationMinutes} min`;
    messageFr += ` Temps de preparation estime: ${preparationMinutes} min`;
    messageAr += ` وقت التحضير المقدر: ${preparationMinutes} دقيقة`;
  }

  const acceptedCopy = getClientAcceptedCopy(order.order_type);

  notify("client", order.client_id, {
    type: "order_accepted",
    orderId: order.id,
    orderNumber: order.order_number,
    restaurant: order.restaurant.name,
    title: acceptedCopy.title,
    message: acceptedCopy.message,
    i18n: acceptedCopy.i18n,
    preparation_time: preparationMinutes,
    ...(order.order_type === "delivery" && {
      delivery_time: deliveryTimeMinutes - preparationMinutes,
      total_delivery_time: deliveryTimeMinutes,
      estimated_delivery_time: estimatedDeliveryTime
    })
  });

  if (order.order_type === "delivery") {
    const restaurantCoords = order.restaurant?.getCoordinates?.();
    
    if (restaurantCoords) {
      const { latitude: lat, longitude: lng } = restaurantCoords;
      const configuredRadius = await SystemConfig.get('driver_nearby_search_radius', 5000);
      const parsedRadius = Number.parseInt(String(configuredRadius), 10);
      const radiusMeters = Number.isFinite(parsedRadius) ? parsedRadius : 5000;
      const radiusKm = radiusMeters / 1000;
      
      console.log(`🚀 Notifying drivers for order ${order.order_number}`);
      console.log(`📍 Restaurant location: [${lat}, ${lng}]`);
      
      try {
        const queueResult = queueNotifyNearbyDrivers(
          lat,
          lng,
          {
            orderId: order.id,
            orderNumber: order.order_number,
            restaurant: order.restaurant.name,
            restaurantAddress: order.restaurant.address,
            deliveryAddress: order.delivery_address,
            fee: parseFloat(order.delivery_fee || 0),
            estimatedTime: estimatedDeliveryTime,
            totalAmount: parseFloat(order.total_amount || 0),
          },
          radiusKm
        );
        
      if (!queueResult?.accepted) {
          console.warn(`⚠️ No drivers notified for order ${order.order_number}`);
        }
        
      } catch (error) {
        console.error(`❌ Error notifying drivers for order ${order.order_number}:`, error);
      }
    } else {
      console.warn(`⚠️ No valid restaurant coordinates for order ${orderId}`);
    }
  }

  scheduleAdminNotificationDriver(orderId);
  scheduleRestaurantPreparationTimeout(orderId);
  setTimeout(() => {
    startPreparing(orderId).catch((error) => {
      console.error("❌ Error auto-starting preparation for order", orderId, error);
    });
  }, 60_000);
  setTimeout(() => {
    addExtraPreparationTime(orderId).catch((error) => {
      console.error("❌ Error auto-extending preparation time for order", orderId, error);
    });
  }, preparationMinutes * 60_000);

      

  return order;
}

export async function startPreparing(orderId, actor = null) {
  const transaction = await sequelize.transaction();
  try {
  const order = await Order.findByPk(orderId, {
    include: [{ model: Client, as: "client" }, { model: Restaurant, as: "restaurant" }],
    transaction,
  });

  if (!order) {
    await transaction.rollback();
    return null;
  }

  if (actor && actor.role !== "admin") {
    if (!["restaurant", "cashier"].includes(actor.role)) {
      await transaction.rollback();
      throw { status: 403, message: "Access restricted to restaurants" };
    }

    const restaurantId = actor.restaurantId;
    if (!restaurantId) {
      await transaction.rollback();
      throw { status: 403, message: "Restaurant profile not found in token" };
    }

    if (order.restaurant_id !== restaurantId) {
      await transaction.rollback();
      throw { status: 403, message: "You are not allowed to manage this order" };
    }
  }

  if (order.status !== "accepted") {
    await transaction.rollback();
    return null;
  }

  await order.update({ status: "preparing" }, { transaction });
  await transaction.commit();

  return order;
  } catch (error) {
    try {
      await transaction.rollback();
    } catch (rollbackError) {
      console.error("❌ Failed to rollback startPreparing transaction:", rollbackError);
    }
    throw error;
  }
}

export async function assignDriverOrComplete(orderId, driverId = null, actor = null) {
  const order = await Order.findByPk(orderId, {
    include: [{ model: Client, as: "client" }, { model: Restaurant, as: "restaurant" }],
  });
  if (!order) throw { status: 404, message: "Order not found" };

  if (order.order_type === "pickup") {
    if (!actor || !["restaurant", "cashier", "admin"].includes(actor.role)) {
      throw { status: 403, message: "Access restricted to restaurants" };
    }
    if (actor.role !== "admin") {
      const restaurantId = actor.restaurantId;
      if (!restaurantId) {
        throw { status: 403, message: "Restaurant profile not found in token" };
      }
      if (order.restaurant_id !== restaurantId) {
        throw { status: 403, message: "You are not allowed to manage this order" };
      }
    }
    if (!order.canTransitionTo("delivered")) {
      throw { status: 400, message: `Cannot complete pickup order in ${order.status} status` };
    }

    await order.update({ status: "delivered", livreur_id: null, delivered_at: new Date() });
    
    // ✅ Award loyalty points for pickup orders
    if (order.client_id && order.total_amount) {
      await awardLoyaltyPoints(order.client_id, order.total_amount, order.id);
    }
    
    const readyCopy = getClientReadyForPickupCopy();

    notify("client", order.client_id, {
      type: "order_ready",
      orderId: order.id,
      title: readyCopy.title,
      message: readyCopy.message,
      i18n: readyCopy.i18n
    });
    return order;
  }

  if (!order.canTransitionTo("assigned")) {
    throw { status: 400, message: `Cannot assign driver in ${order.status} status` };
  }

  if (order.livreur_id) throw { status: 400, message: "Order already assigned" };

  let effectiveDriverId = driverId;

  if (actor?.role === "driver") {
    effectiveDriverId = actor.driverId || driverId;
    if (!effectiveDriverId) {
      throw { status: 403, message: "Driver profile not found in token" };
    }
  } else {
    if (!actor || !["cashier", "admin"].includes(actor.role)) {
      throw { status: 403, message: "Access restricted to drivers" };
    }

    if (actor.role === "cashier") {
      const restaurantId = actor.restaurantId;
      if (!restaurantId) {
        throw { status: 403, message: "Restaurant profile not found in token" };
      }
      if (order.restaurant_id !== restaurantId) {
        throw { status: 403, message: "You are not allowed to manage this order" };
      }
    }

    if (!effectiveDriverId) {
      throw { status: 400, message: "driver_id is required" };
    }
  }

  const driver = await Driver.findByPk(effectiveDriverId);
  if (!driver) throw { status: 400, message: "Driver not found" };
  if (!driver.is_active || driver.status === "suspended") {
    throw {
      status: 403,
      message: "Driver account is suspended. Please contact an administrator.",
      code: "DRIVER_SUSPENDED"
    };
  }
  if (!driver.is_verified) throw { status: 400, message: "Driver account is not verified" };

  const canAccept = await canDriverAcceptOrder(driver);
  if (!canAccept.canAccept) {
    throw { status: 400, message: canAccept.reason || "Driver cannot accept this order" };
  }

  let routeInfo = null;
  
  try {
    const restaurantCoords = order.restaurant.getCoordinates();
    const driverCoords = driver.getCurrentCoordinates();
    
    if (restaurantCoords && driverCoords) {
      const route = await calculateRouteTime(
        driverCoords.longitude,
        driverCoords.latitude,
        restaurantCoords.longitude,
        restaurantCoords.latitude,
        40
      );
      
      routeInfo = {
        distance_km: route.distanceKm,
        estimated_time_min: route.timeMin
      };
      
      console.log(`📍 Route Driver→Restaurant: ${route.distanceKm} km, ~${route.timeMax} min`);
    } else {
      console.warn('⚠️ Missing coordinates for driver or restaurant');
    }
  } catch (error) {
    console.error('Route calculation failed:', error.message);
  }

  await order.update({ status: "assigned", livreur_id: effectiveDriverId });
  await driver.addActiveOrder(orderId);
  scheduleDriverArrivalTimeout(orderId);

  return {
    ...order.toJSON(),
    driver_to_restaurant_distance_km: routeInfo?.distance_km,          
    driver_to_restaurant_estimated_time_min: routeInfo?.estimated_time_min
  };
}

export async function startDelivering(orderId, actor = null) {
  const order = await Order.findByPk(orderId, {
    include: [{ model: Client, as: "client" }, { model: Driver, as: "driver" }],
  });
  if (!order) throw { status: 404, message: "Order not found" };
  if (order.order_type !== "delivery") {
    throw { status: 400, message: "Cannot start delivery for pickup orders" };
  }
  if (!actor || actor.role !== "driver") {
    throw { status: 403, message: "Access restricted to drivers" };
  }
  const actorDriverId = actor.driverId;
  if (!actorDriverId) {
    throw { status: 403, message: "Driver profile not found in token" };
  }
  if (order.livreur_id !== actorDriverId) {
    throw { status: 403, message: "You are not assigned to this order" };
  }
  if (!order.canTransitionTo("delivering")) {
    throw { status: 400, message: `Cannot start delivery from ${order.status} status` };
  }

  await order.update({ status: "delivering" });
  scheduleDriverDeliveryTimeout(orderId);

  const deliveryStartedCopy = getClientDeliveryStartedCopy();

  notify("client", order.client_id, {
    type: "delivery_started",
    orderId: order.id,
    title: deliveryStartedCopy.title,
    message: deliveryStartedCopy.message,
    i18n: deliveryStartedCopy.i18n
  });

  return order;
}

export async function driverArrived(orderId, actor = null) {
  const order = await Order.findByPk(orderId, {
    include: [
      { model: Restaurant, as: "restaurant" },
      { model: Client, as: "client" },
      { model: Driver, as: "driver" },
    ],
  });
  if (!order) throw { status: 404, message: "Order not found" };
  if (order.order_type !== "delivery") {
    throw { status: 400, message: "Cannot mark arrived for pickup orders" };
  }
  if (!actor || actor.role !== "driver") {
    throw { status: 403, message: "Access restricted to drivers" };
  }
  const actorDriverId = actor.driverId;
  if (!actorDriverId) {
    throw { status: 403, message: "Driver profile not found in token" };
  }
  if (order.livreur_id !== actorDriverId) {
    throw { status: 403, message: "You are not assigned to this order" };
  }
  if (!order.canTransitionTo("arrived")) {
    throw { status: 400, message: `Cannot mark arrived from ${order.status} status` };
  }

  await order.update({ status: "arrived", arrived_at: new Date() });

  const rest = order.restaurant?.getCoordinates?.();
  const dest = order.delivery_location?.coordinates
    ? { longitude: order.delivery_location.coordinates[0], latitude: order.delivery_location.coordinates[1] }
    : null;

  let route = null;
  if (rest && dest) route = await calculateRouteTime(rest.longitude, rest.latitude, dest.longitude, dest.latitude);

  return { ...order.toJSON(), route };
}

export async function completeDelivery(orderId, actor = null) {
  const order = await Order.findByPk(orderId, {
    include: [{ model: Client, as: "client" }, { model: Driver, as: "driver" }],
  });
  if (!order) throw { status: 404, message: "Order not found" };
  if (order.order_type !== "delivery") {
    throw { status: 400, message: "Cannot complete delivery for pickup orders" };
  }
  if (!actor || actor.role !== "driver") {
    throw { status: 403, message: "Access restricted to drivers" };
  }
  const actorDriverId = actor.driverId;
  if (!actorDriverId) {
    throw { status: 403, message: "Driver profile not found in token" };
  }
  if (order.livreur_id !== actorDriverId) {
    throw { status: 403, message: "You are not assigned to this order" };
  }
  if (!order.canTransitionTo("delivered")) {
    throw { status: 400, message: `Cannot complete from ${order.status} status` };
  }
  
  const driverId = order.livreur_id;
  
  await order.update({ status: "delivered", delivered_at: new Date() });

  // ✅ Award loyalty points for delivery orders
  if (order.client_id && order.total_amount) {
    await awardLoyaltyPoints(order.client_id, order.total_amount, order.id);
  }

  if (driverId) {
    const driver = await Driver.findByPk(driverId);
    if (driver) {
      await driver.removeActiveOrder(orderId);
      driver.total_deliveries += 1;
      await driver.save();
    }
  }

  const deliveredCopy = getClientDeliveredCopy();

  notify("client", order.client_id, {
    type: "order_delivered",
    orderId: order.id,
    title: deliveredCopy.title,
    message: deliveredCopy.message,
    i18n: deliveredCopy.i18n
  });

  return order;
}

export async function declineOrder(orderId, reason, actor = null) {
  const order = await Order.findByPk(orderId, { include: [{ model: Client, as: "client" }] });
  if (!order) throw { status: 404, message: "Order not found" };
  if (!actor || !["restaurant", "cashier", "admin"].includes(actor.role)) {
    throw { status: 403, message: "Access restricted to restaurants" };
  }
  if (actor.role !== "admin") {
    const restaurantId = actor.restaurantId;
    if (!restaurantId) {
      throw { status: 403, message: "Restaurant profile not found in token" };
    }
    if (order.restaurant_id !== restaurantId) {
      throw { status: 403, message: "You are not allowed to manage this order" };
    }
  }
  if (!order.canTransitionTo("declined")) {
    throw { status: 400, message: `Cannot decline order in ${order.status} status` };
  }

  await order.update({ status: "declined", decline_reason: reason });

  const declinedCopy = getClientDeclinedCopy();

  notify("client", order.client_id, {
    type: "order_declined",
    orderId: order.id,
    reason,
    title: declinedCopy.title,
    message: declinedCopy.message,
    i18n: declinedCopy.i18n
  });

  return order;
}

