import { sequelize } from "../../config/database.js";
import Order from "../../models/Order.js";
import Restaurant from "../../models/Restaurant.js";
import Client from "../../models/Client.js";
import Driver from "../../models/Driver.js";
import AdminNotification from "../../models/AdminNotification.js";
import SystemConfig from "../../models/SystemConfig.js";
import { queueNotifyNearbyDrivers } from "../driverNotification.service.js";
import { notify } from "./notify.helper.js";
import { queueNotifyRole } from "../notification.service.js";
import { getClientDeliveryCancelledCopy } from "./pushCopy.helper.js";

const ADMIN_ALERT_TITLE = {
  fr: "⚠️ Alerte livreur",
  en: "⚠️ Driver alert",
  ar: "⚠️ تنبيه السائق"
};

const buildI18nPayload = (titleMap, bodyMap) => ({
  fr: { title: titleMap.fr, body: bodyMap.fr },
  en: { title: titleMap.en, body: bodyMap.en },
  ar: { title: titleMap.ar, body: bodyMap.ar }
});

export async function driverCancelOrder(orderId, driverId, reason) {
  const order = await Order.findByPk(orderId, {
    include: [{ model: Client, as: "client" }, { model: Restaurant, as: "restaurant" }, { model: Driver, as: "driver" }],
  });
  if (!order) throw { status: 404, message: "Order not found" };
  if (order.livreur_id !== driverId) throw { status: 403, message: "You are not assigned to this order" };
  if (!["assigned", "arrived", "delivering"].includes(order.status)) {
    throw { status: 400, message: `Cannot cancel order in ${order.status} status` };
  }

  const driver = await Driver.findByPk(driverId);
  if (!driver) throw { status: 404, message: "Driver not found" };

  const previousStatus = order.status;
  const transaction = await sequelize.transaction();

  try {
    const newCancellationCount = driver.cancellation_count + 1;
    const newActiveOrders = driver.active_orders.filter((id) => id !== orderId);
    const newStatus = newActiveOrders.length === 0 ? "available" : driver.status;

    await driver.update(
      { cancellation_count: newCancellationCount, active_orders: newActiveOrders, status: newStatus },
      { transaction }
    );

    await order.update(
      { status: "preparing", livreur_id: null, decline_reason: `[DRIVER CANCELLED] ${reason}` },
      { transaction }
    );

    await transaction.commit();

    await driver.reload();
    const deliveryCancelledCopy = getClientDeliveryCancelledCopy();

    notify("client", order.client_id, {
      type: "delivery_cancelled",
      orderId: order.id,
      orderNumber: order.order_number,
      title: deliveryCancelledCopy.title,
      message: deliveryCancelledCopy.message,
      i18n: deliveryCancelledCopy.i18n,
      reason,
    });

    if (previousStatus === "delivering") {
      const restaurantCoords = order.restaurant?.getCoordinates?.();
      if (restaurantCoords) {
        const { latitude: lat, longitude: lng } = restaurantCoords;
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
            estimatedTime: order.estimated_delivery_time,
            totalAmount: parseFloat(order.total_amount || 0),
            urgent: true,
          },
          10
        );

        if (!queueResult?.accepted) {
          console.warn(
            `Nearby driver notification queue dropped order ${order.order_number}`,
            queueResult
          );
        }
      }
    }

    let maxDriverCancellations = 3;
    try {
      const configuredMax = await SystemConfig.get('max_driver_cancellations', 3);
      const parsedMax = Number.parseInt(String(configuredMax), 10);
      if (Number.isFinite(parsedMax) && parsedMax >= 1 && parsedMax <= 20) {
        maxDriverCancellations = parsedMax;
      }
    } catch (error) {
      console.error("❌ Error reading max_driver_cancellations config:", error);
    }

    if (newCancellationCount >= maxDriverCancellations) {
      createDriverCancellationNotification(driverId, newCancellationCount, order.id, order.restaurant_id).catch((err) =>
        console.error("Error creating admin notification:", err)
      );
    }

    return {
      order,
      driver: { id: driver.id, name: driver.getFullName(), cancellation_count: newCancellationCount, active_orders_count: newActiveOrders.length },
    };
  } catch (error) {
    await transaction.rollback();
    console.error("❌ Transaction rolled back for order", orderId, error);
    throw error;
  }
}

export async function createDriverCancellationNotification(driverId, cancellationCount, orderId, restaurantId) {
  try {
    const driver = await Driver.findByPk(driverId);
    if (!driver) return null;

    const message =
      `⚠️ ALERTE: Le livreur ${driver.getFullName()} (${driver.driver_code}) a annulé ${cancellationCount} commandes.\n\n` +
      `📞 Contact: ${driver.phone}\n` +
      `📧 Email: ${driver.email || "Non renseigné"}\n\n` +
      `Action requise: Vérifier le comportement du livreur.`;

    const driverInfo = {
      id: driver.id,
      driver_code: driver.driver_code,
      name: driver.getFullName(),
      phone: driver.phone,
      email: driver.email,
      cancellation_count: cancellationCount,
      total_deliveries: driver.total_deliveries,
      rating: driver.rating,
      status: driver.status,
      created_at: driver.created_at,
    };

    const notification = await AdminNotification.create({
      order_id: orderId || null,
      restaurant_id: restaurantId || null,
      type: "driver_excessive_cancellations",
      message,
      order_details: { driver_info: driverInfo, cancellation_count: cancellationCount },
      driver_id: driver.id,
      is_read: false,
      is_resolved: false,
    });

    const messageEn =
      `ALERT: Driver ${driver.getFullName()} (${driver.driver_code}) has cancelled ${cancellationCount} orders.\n\n` +
      `Contact: ${driver.phone}\n` +
      `Email: ${driver.email || "Not provided"}\n\n` +
      `Action required: Review driver behavior.`;
    const messageAr =
      `تنبيه: السائق ${driver.getFullName()} (${driver.driver_code}) ألغى ${cancellationCount} طلبًا.\n\n` +
      `الهاتف: ${driver.phone}\n` +
      `البريد الإلكتروني: ${driver.email || "غير متوفر"}\n\n` +
      `الإجراء المطلوب: مراجعة سلوك السائق.`;

    queueNotifyRole("admin", "driver_alert", {
      id: notification.id,
      type: "driver_excessive_cancellations",
      message,
      i18n: buildI18nPayload(ADMIN_ALERT_TITLE, {
        fr: message,
        en: messageEn,
        ar: messageAr
      }),
      driver: driverInfo,
      cancellation_count: cancellationCount,
      created_at: notification.created_at,
    });

    return notification;
  } catch (error) {
    console.error("❌ Error creating driver cancellation notification:", error);
    return null;
  }
}
