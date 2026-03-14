import AdminNotification from "../models/AdminNotification.js";
import Order from "../models/Order.js";
import Restaurant from "../models/Restaurant.js";
import Client from "../models/Client.js";
import Driver from "../models/Driver.js";
import OrderItem from "../models/OrderItem.js";
import MenuItem from "../models/MenuItem.js";
import OrderItemAddition from "../models/OrderItemAddition.js";
import Addition from "../models/Addition.js";
import SystemConfig from "../models/SystemConfig.js";
import { notifyRole } from "./notification.service.js";

const mapOrderItemAdditions = (item) => {
  const additions = item?.additions || [];
  return additions.map((add) => ({
    name: add.addition?.nom || "Addition",
    quantity: add.quantite,
    price: parseFloat(add.prix_unitaire || add.addition?.prix || 0),
    total: parseFloat(add.prix_total || 0)
  }));
};

const ADMIN_NOTIFICATION_TITLE = {
  fr: "🚨 Alerte commande",
  en: "🚨 Order alert",
  ar: "🚨 تنبيه الطلب"
};

const buildI18nPayload = (titleMap, bodyMap) => ({
  fr: { title: titleMap.fr, body: bodyMap.fr },
  en: { title: titleMap.en, body: bodyMap.en },
  ar: { title: titleMap.ar, body: bodyMap.ar }
});

const minuteLabel = (value, locale) => {
  const count = Number(value) || 0;
  switch (locale) {
    case "fr":
      return count === 1 ? "minute" : "minutes";
    case "ar":
      return count === 1 ? "دقيقة" : "دقائق";
    default:
      return count === 1 ? "minute" : "minutes";
  }
};

/**
 * Creer une notification admin pour commande non repondue
 */
export const createPendingOrderNotification = async (orderId) => {
  try {
    // Recuperer toutes les infos de la commande
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'email', 'phone_number']
        },
        {
          model: Client,
          as: 'client',
          attributes: ['id', 'first_name', 'last_name', 'phone_number', 'address']
        },
        {
          model: OrderItem,
          as: 'order_items',
          include: [{
            model: MenuItem,
            as: 'menu_item',
            attributes: ['nom', 'prix']
          }, {
            model: OrderItemAddition,
            as: 'additions',
            attributes: ['quantite', 'prix_unitaire', 'prix_total'],
            include: [{
              model: Addition,
              as: 'addition',
              attributes: ['nom', 'prix']
            }]
          }]
        }
      ]
    });

    if (!order) {
      console.error(`Order ${orderId} not found for admin notification`);
      return null;
    }

    // Verifier si encore en pending
    if (order.status !== 'pending') {
      console.log(`Order ${orderId} no longer pending, skipping notification`);
      return null;
    }

    // Preparer les donnees
    const clientName = order.client
      ? `${order.client.first_name || ''} ${order.client.last_name || ''}`.trim() || 'Client inconnu'
      : 'Client inconnu';
    const clientPhone = order.client?.phone_number || 'Non renseigne';
    const clientAddress = order.client?.address || order.delivery_address || 'Non renseigne';

    const restaurantInfo = {
      id: order.restaurant?.id || order.restaurant_id || null,
      name: order.restaurant?.name || 'Restaurant inconnu',
      address: order.restaurant?.address || 'Non renseigne',
      phone: order.restaurant?.phone_number || 'Non renseigne',
      email: order.restaurant?.email || 'Non renseigne'
    };

    const orderDetails = {
      order_number: order.order_number,
      order_type: order.order_type,
      total_amount: parseFloat(order.total_amount || 0),
      delivery_address: order.delivery_address,
      created_at: order.created_at,
      items: (order.order_items || []).map(item => ({
        name: item.menu_item?.nom || 'Plat inconnu',
        quantity: item.quantite,
        price: parseFloat(item.prix_unitaire || 0),
        total: parseFloat(item.prix_total || 0),
        additions: mapOrderItemAdditions(item)
      })),
      client: {
        name: clientName,
        phone: clientPhone,
        address: clientAddress
      }
    };

    const configuredTimeout = await SystemConfig.get('pending_order_timeout', 3);
    const parsedTimeout = Number.parseInt(String(configuredTimeout), 10);
    const timeoutMinutes = Number.isFinite(parsedTimeout)
      ? Math.min(60, Math.max(1, parsedTimeout))
      : 3;
    const timeoutUnit = timeoutMinutes === 1 ? 'minute' : 'minutes';

    const message = `Commande #${order.order_number} sans reponse depuis ${timeoutMinutes} ${timeoutUnit}.\n` +
                    `Restaurant: ${restaurantInfo.name}\n` +
                    `Montant: ${order.total_amount} DA\n` +
                    `Contact restaurant: ${restaurantInfo.phone}`;
    const messageEn = `Order #${order.order_number} has had no response for ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "en")}.\n` +
                      `Restaurant: ${restaurantInfo.name}\n` +
                      `Amount: ${order.total_amount} DA\n` +
                      `Restaurant contact: ${restaurantInfo.phone}`;
    const messageAr = `الطلب رقم #${order.order_number} بدون رد منذ ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "ar")}.\n` +
                      `المطعم: ${restaurantInfo.name}\n` +
                      `المبلغ: ${order.total_amount} دج\n` +
                      `هاتف المطعم: ${restaurantInfo.phone}`;

    // Creer la notification en BDD
    const notification = await AdminNotification.create({
      order_id: orderId,
      restaurant_id: order.restaurant_id,
      type: 'pending_order_timeout',
      message,
      order_details: orderDetails,
      restaurant_info: restaurantInfo
    });

    console.log(`Admin notification created: ${notification.id}`);

    // Envoyer via Socket.IO a tous les admins
    await notifyRole('admin', 'new_notification', {
      id: notification.id,
      type: 'pending_order_timeout',
      message,
      i18n: buildI18nPayload(ADMIN_NOTIFICATION_TITLE, {
        fr: message,
        en: messageEn,
        ar: messageAr
      }),
      order: orderDetails,
      restaurant: restaurantInfo,
      created_at: notification.created_at
    });

    return notification;

  } catch (error) {
    console.error('Error creating admin notification:', error);
    return null;
  }
};


/**
 * Creer une notification admin pour commande non repondue
 */
export const createAcceptedOrderNotification = async (orderId) => {
  try {
    // Recuperer toutes les infos de la commande
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'email', 'phone_number']
        },
        {
          model: Client,
          as: 'client',
          attributes: ['id', 'first_name', 'last_name', 'phone_number', 'address']
        },
        {
          model: OrderItem,
          as: 'order_items',
          include: [{
            model: MenuItem,
            as: 'menu_item',
            attributes: ['nom', 'prix']
          }, {
            model: OrderItemAddition,
            as: 'additions',
            attributes: ['quantite', 'prix_unitaire', 'prix_total'],
            include: [{
              model: Addition,
              as: 'addition',
              attributes: ['nom', 'prix']
            }]
          }]
        }
      ]
    });

    if (!order) {
      console.error(`Order ${orderId} not found for admin notification`);
      return null;
    }

    // Verifier si encore en accepted
    if (order.status !== 'preparing') {
      console.log(`Order ${orderId} no longer accepted, skipping notification`);
      return null;
    }

    // Preparer les donnees
    const clientName = order.client
      ? `${order.client.first_name || ''} ${order.client.last_name || ''}`.trim() || 'Client inconnu'
      : 'Client inconnu';
    const clientPhone = order.client?.phone_number || 'Non renseigne';
    const clientAddress = order.client?.address || order.delivery_address || 'Non renseigne';

    const restaurantInfo = {
      id: order.restaurant?.id || order.restaurant_id || null,
      name: order.restaurant?.name || 'Restaurant inconnu',
      address: order.restaurant?.address || 'Non renseigne',
      phone: order.restaurant?.phone_number || 'Non renseigne',
      email: order.restaurant?.email || 'Non renseigne'
    };

    const orderDetails = {
      order_number: order.order_number,
      order_type: order.order_type,
      total_amount: parseFloat(order.total_amount || 0),
      delivery_address: order.delivery_address,
      created_at: order.created_at,
      items: (order.order_items || []).map(item => ({
        name: item.menu_item?.nom || 'Plat inconnu',
        quantity: item.quantite,
        price: parseFloat(item.prix_unitaire || 0),
        total: parseFloat(item.prix_total || 0),
        additions: mapOrderItemAdditions(item)
      })),
      client: {
        name: clientName,
        phone: clientPhone,
        address: clientAddress
      }
    };

    const timeoutMinutes = 3;
    const message = `Commande #${order.order_number} sans reponse depuis ${timeoutMinutes} minutes.\n` +
                    `Restaurant: ${restaurantInfo.name}\n` +
                    `Montant: ${order.total_amount} DA\n` +
                    `Contact restaurant: ${restaurantInfo.phone}`;
    const messageEn = `Order #${order.order_number} has had no response for ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "en")}.\n` +
                      `Restaurant: ${restaurantInfo.name}\n` +
                      `Amount: ${order.total_amount} DA\n` +
                      `Restaurant contact: ${restaurantInfo.phone}`;
    const messageAr = `الطلب رقم #${order.order_number} بدون رد منذ ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "ar")}.\n` +
                      `المطعم: ${restaurantInfo.name}\n` +
                      `المبلغ: ${order.total_amount} دج\n` +
                      `هاتف المطعم: ${restaurantInfo.phone}`;

    // Creer la notification en BDD
    const notification = await AdminNotification.create({
      order_id: orderId,
      restaurant_id: order.restaurant_id,
      type: 'driver_unresponsive',
      message,
      order_details: orderDetails,
      restaurant_info: restaurantInfo
    });

    console.log(`Admin notification created: ${notification.id}`);

    // Envoyer via Socket.IO a tous les admins
    await notifyRole('admin', 'new_notification', {
      id: notification.id,
      type: 'driver_unresponsive',
      message,
      i18n: buildI18nPayload(ADMIN_NOTIFICATION_TITLE, {
        fr: message,
        en: messageEn,
        ar: messageAr
      }),
      order: orderDetails,
      restaurant: restaurantInfo,
      created_at: notification.created_at
    });

    return notification;

  } catch (error) {
    console.error('Error creating admin notification:', error);
    return null;
  }
};

/**
 * Create admin notification when restaurant preparation time is too long
 */
export const createRestaurantPreparationTimeoutNotification = async (orderId) => {
  try {
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'email', 'phone_number']
        },
        {
          model: Client,
          as: 'client',
          attributes: ['id', 'first_name', 'last_name', 'phone_number', 'address']
        },
        {
          model: OrderItem,
          as: 'order_items',
          include: [{
            model: MenuItem,
            as: 'menu_item',
            attributes: ['nom', 'prix']
          }, {
            model: OrderItemAddition,
            as: 'additions',
            attributes: ['quantite', 'prix_unitaire', 'prix_total'],
            include: [{
              model: Addition,
              as: 'addition',
              attributes: ['nom', 'prix']
            }]
          }]
        }
      ]
    });

    if (!order) {
      console.error(`Order ${orderId} not found for admin notification`);
      return null;
    }

    if (!['accepted', 'preparing'].includes(order.status)) {
      console.log(`Order ${orderId} no longer in preparation window, skipping notification`);
      return null;
    }

    const clientName = order.client
      ? `${order.client.first_name || ''} ${order.client.last_name || ''}`.trim() || 'Client inconnu'
      : 'Client inconnu';
    const clientPhone = order.client?.phone_number || 'Non renseigne';
    const clientAddress = order.client?.address || order.delivery_address || 'Non renseigne';

    const restaurantInfo = {
      id: order.restaurant?.id || order.restaurant_id || null,
      name: order.restaurant?.name || 'Restaurant inconnu',
      address: order.restaurant?.address || 'Non renseigne',
      phone: order.restaurant?.phone_number || 'Non renseigne',
      email: order.restaurant?.email || 'Non renseigne'
    };

    const orderDetails = {
      order_number: order.order_number,
      order_type: order.order_type,
      total_amount: parseFloat(order.total_amount || 0),
      delivery_address: order.delivery_address,
      created_at: order.created_at,
      accepted_at: order.accepted_at,
      preparing_started_at: order.preparing_started_at,
      items: (order.order_items || []).map(item => ({
        name: item.menu_item?.nom || 'Plat inconnu',
        quantity: item.quantite,
        price: parseFloat(item.prix_unitaire || 0),
        total: parseFloat(item.prix_total || 0),
        additions: mapOrderItemAdditions(item)
      })),
      client: {
        name: clientName,
        phone: clientPhone,
        address: clientAddress
      }
    };

    const configuredTimeout = await SystemConfig.get('restaurant_preparation_timeout', 20);
    const parsedTimeout = Number.parseInt(String(configuredTimeout), 10);
    const timeoutMinutes = Number.isFinite(parsedTimeout)
      ? Math.min(180, Math.max(1, parsedTimeout))
      : 20;

    const acceptedAt = order.accepted_at ? new Date(order.accepted_at).getTime() : Date.now();
    const elapsedMinutes = Math.max(1, Math.floor((Date.now() - acceptedAt) / 60000));

    const message = `Commande #${order.order_number} en preparation depuis ${elapsedMinutes} ${elapsedMinutes === 1 ? 'minute' : 'minutes'}.\n` +
                    `Seuil configure: ${timeoutMinutes} ${timeoutMinutes === 1 ? 'minute' : 'minutes'}\n` +
                    `Restaurant: ${restaurantInfo.name}\n` +
                    `Montant: ${order.total_amount} DA\n` +
                    `Contact restaurant: ${restaurantInfo.phone}`;
    const messageEn = `Order #${order.order_number} has been preparing for ${elapsedMinutes} ${minuteLabel(elapsedMinutes, "en")}.\n` +
                      `Configured threshold: ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "en")}\n` +
                      `Restaurant: ${restaurantInfo.name}\n` +
                      `Amount: ${order.total_amount} DA\n` +
                      `Restaurant contact: ${restaurantInfo.phone}`;
    const messageAr = `الطلب رقم #${order.order_number} قيد التحضير منذ ${elapsedMinutes} ${minuteLabel(elapsedMinutes, "ar")}.\n` +
                      `الحد المسموح: ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "ar")}\n` +
                      `المطعم: ${restaurantInfo.name}\n` +
                      `المبلغ: ${order.total_amount} دج\n` +
                      `هاتف المطعم: ${restaurantInfo.phone}`;

    const notification = await AdminNotification.create({
      order_id: orderId,
      restaurant_id: order.restaurant_id,
      type: 'restaurant_preparation_timeout',
      message,
      order_details: orderDetails,
      restaurant_info: restaurantInfo
    });

    console.log(`Admin notification created: ${notification.id}`);

    await notifyRole('admin', 'new_notification', {
      id: notification.id,
      type: 'restaurant_preparation_timeout',
      message,
      i18n: buildI18nPayload(ADMIN_NOTIFICATION_TITLE, {
        fr: message,
        en: messageEn,
        ar: messageAr
      }),
      order: orderDetails,
      restaurant: restaurantInfo,
      created_at: notification.created_at
    });

    return notification;
  } catch (error) {
    console.error('Error creating restaurant preparation notification:', error);
    return null;
  }
};

/**
 * Create admin notification when driver arrival is too late
 */
export const createDriverArrivalTimeoutNotification = async (orderId) => {
  try {
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'email', 'phone_number']
        },
        {
          model: Client,
          as: 'client',
          attributes: ['id', 'first_name', 'last_name', 'phone_number', 'address']
        },
        {
          model: Driver,
          as: 'driver',
          attributes: ['id', 'first_name', 'last_name', 'phone', 'vehicle_type']
        },
        {
          model: OrderItem,
          as: 'order_items',
          include: [{
            model: MenuItem,
            as: 'menu_item',
            attributes: ['nom', 'prix']
          }, {
            model: OrderItemAddition,
            as: 'additions',
            attributes: ['quantite', 'prix_unitaire', 'prix_total'],
            include: [{
              model: Addition,
              as: 'addition',
              attributes: ['nom', 'prix']
            }]
          }]
        }
      ]
    });

    if (!order) {
      console.error(`Order ${orderId} not found for admin notification`);
      return null;
    }

    if (order.status !== 'assigned') {
      console.log(`Order ${orderId} is no longer assigned, skipping notification`);
      return null;
    }

    const clientName = order.client
      ? `${order.client.first_name || ''} ${order.client.last_name || ''}`.trim() || 'Client inconnu'
      : 'Client inconnu';
    const clientPhone = order.client?.phone_number || 'Non renseigne';
    const clientAddress = order.client?.address || order.delivery_address || 'Non renseigne';

    const restaurantInfo = {
      id: order.restaurant?.id || order.restaurant_id || null,
      name: order.restaurant?.name || 'Restaurant inconnu',
      address: order.restaurant?.address || 'Non renseigne',
      phone: order.restaurant?.phone_number || 'Non renseigne',
      email: order.restaurant?.email || 'Non renseigne'
    };

    const driverInfo = order.driver
      ? {
          id: order.driver.id,
          name: `${order.driver.first_name || ''} ${order.driver.last_name || ''}`.trim() || 'Livreur',
          phone: order.driver.phone || 'Non renseigne',
          vehicle: order.driver.vehicle_type || 'Non renseigne'
        }
      : null;

    const orderDetails = {
      order_number: order.order_number,
      order_type: order.order_type,
      total_amount: parseFloat(order.total_amount || 0),
      delivery_address: order.delivery_address,
      created_at: order.created_at,
      assigned_at: order.assigned_at,
      items: (order.order_items || []).map(item => ({
        name: item.menu_item?.nom || 'Plat inconnu',
        quantity: item.quantite,
        price: parseFloat(item.prix_unitaire || 0),
        total: parseFloat(item.prix_total || 0),
        additions: mapOrderItemAdditions(item)
      })),
      client: {
        name: clientName,
        phone: clientPhone,
        address: clientAddress
      },
      driver: driverInfo
    };

    const configuredTimeout = await SystemConfig.get('driver_arrival_timeout', 15);
    const parsedTimeout = Number.parseInt(String(configuredTimeout), 10);
    const timeoutMinutes = Number.isFinite(parsedTimeout)
      ? Math.min(120, Math.max(1, parsedTimeout))
      : 15;

    const assignedAt = order.assigned_at ? new Date(order.assigned_at).getTime() : Date.now();
    const elapsedMinutes = Math.max(1, Math.floor((Date.now() - assignedAt) / 60000));

    const message = `Livreur en retard pour la commande #${order.order_number} (${elapsedMinutes} ${elapsedMinutes === 1 ? 'minute' : 'minutes'}).\n` +
                    `Seuil configure: ${timeoutMinutes} ${timeoutMinutes === 1 ? 'minute' : 'minutes'}\n` +
                    `Restaurant: ${restaurantInfo.name}\n` +
                    `Livreur: ${driverInfo?.name || 'Livreur'}\n` +
                    `Contact livreur: ${driverInfo?.phone || 'Non renseigne'}`;
    const messageEn = `Driver late for order #${order.order_number} (${elapsedMinutes} ${minuteLabel(elapsedMinutes, "en")}).\n` +
                      `Configured threshold: ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "en")}\n` +
                      `Restaurant: ${restaurantInfo.name}\n` +
                      `Driver: ${driverInfo?.name || 'Driver'}\n` +
                      `Driver contact: ${driverInfo?.phone || 'Not provided'}`;
    const messageAr = `تأخر السائق لطلب #${order.order_number} (${elapsedMinutes} ${minuteLabel(elapsedMinutes, "ar")}).\n` +
                      `الحد المسموح: ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "ar")}\n` +
                      `المطعم: ${restaurantInfo.name}\n` +
                      `السائق: ${driverInfo?.name || 'السائق'}\n` +
                      `هاتف السائق: ${driverInfo?.phone || 'غير متوفر'}`;

    const notification = await AdminNotification.create({
      order_id: orderId,
      restaurant_id: order.restaurant_id,
      driver_id: order.livreur_id || driverInfo?.id || null,
      type: 'driver_arrival_timeout',
      message,
      order_details: orderDetails,
      restaurant_info: restaurantInfo
    });

    console.log(`Admin notification created: ${notification.id}`);

    await notifyRole('admin', 'new_notification', {
      id: notification.id,
      type: 'driver_arrival_timeout',
      message,
      i18n: buildI18nPayload(ADMIN_NOTIFICATION_TITLE, {
        fr: message,
        en: messageEn,
        ar: messageAr
      }),
      order: orderDetails,
      restaurant: restaurantInfo,
      driver: driverInfo,
      created_at: notification.created_at
    });

    return notification;
  } catch (error) {
    console.error('Error creating driver arrival notification:', error);
    return null;
  }
};

/**
 * Create admin notification when delivery takes too long
 */
export const createDriverDeliveryTimeoutNotification = async (orderId) => {
  try {
    const order = await Order.findByPk(orderId, {
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'email', 'phone_number']
        },
        {
          model: Client,
          as: 'client',
          attributes: ['id', 'first_name', 'last_name', 'phone_number', 'address']
        },
        {
          model: Driver,
          as: 'driver',
          attributes: ['id', 'first_name', 'last_name', 'phone', 'vehicle_type']
        },
        {
          model: OrderItem,
          as: 'order_items',
          include: [{
            model: MenuItem,
            as: 'menu_item',
            attributes: ['nom', 'prix']
          }, {
            model: OrderItemAddition,
            as: 'additions',
            attributes: ['quantite', 'prix_unitaire', 'prix_total'],
            include: [{
              model: Addition,
              as: 'addition',
              attributes: ['nom', 'prix']
            }]
          }]
        }
      ]
    });

    if (!order) {
      console.error(`Order ${orderId} not found for admin notification`);
      return null;
    }

    if (order.status !== 'delivering') {
      console.log(`Order ${orderId} is no longer delivering, skipping notification`);
      return null;
    }

    const clientName = order.client
      ? `${order.client.first_name || ''} ${order.client.last_name || ''}`.trim() || 'Client inconnu'
      : 'Client inconnu';
    const clientPhone = order.client?.phone_number || 'Non renseigne';
    const clientAddress = order.client?.address || order.delivery_address || 'Non renseigne';

    const restaurantInfo = {
      id: order.restaurant?.id || order.restaurant_id || null,
      name: order.restaurant?.name || 'Restaurant inconnu',
      address: order.restaurant?.address || 'Non renseigne',
      phone: order.restaurant?.phone_number || 'Non renseigne',
      email: order.restaurant?.email || 'Non renseigne'
    };

    const driverInfo = order.driver
      ? {
          id: order.driver.id,
          name: `${order.driver.first_name || ''} ${order.driver.last_name || ''}`.trim() || 'Livreur',
          phone: order.driver.phone || 'Non renseigne',
          vehicle: order.driver.vehicle_type || 'Non renseigne'
        }
      : null;

    const orderDetails = {
      order_number: order.order_number,
      order_type: order.order_type,
      total_amount: parseFloat(order.total_amount || 0),
      delivery_address: order.delivery_address,
      created_at: order.created_at,
      delivering_started_at: order.delivering_started_at,
      items: (order.order_items || []).map(item => ({
        name: item.menu_item?.nom || 'Plat inconnu',
        quantity: item.quantite,
        price: parseFloat(item.prix_unitaire || 0),
        total: parseFloat(item.prix_total || 0),
        additions: mapOrderItemAdditions(item)
      })),
      client: {
        name: clientName,
        phone: clientPhone,
        address: clientAddress
      },
      driver: driverInfo
    };

    const configuredTimeout = await SystemConfig.get('driver_delivery_timeout', 45);
    const parsedTimeout = Number.parseInt(String(configuredTimeout), 10);
    const timeoutMinutes = Number.isFinite(parsedTimeout)
      ? Math.min(240, Math.max(1, parsedTimeout))
      : 45;

    const deliveringStartedAt = order.delivering_started_at
      ? new Date(order.delivering_started_at).getTime()
      : Date.now();
    const elapsedMinutes = Math.max(1, Math.floor((Date.now() - deliveringStartedAt) / 60000));

    const message = `Livraison en retard pour la commande #${order.order_number} (${elapsedMinutes} ${elapsedMinutes === 1 ? 'minute' : 'minutes'}).\n` +
                    `Seuil configure: ${timeoutMinutes} ${timeoutMinutes === 1 ? 'minute' : 'minutes'}\n` +
                    `Restaurant: ${restaurantInfo.name}\n` +
                    `Livreur: ${driverInfo?.name || 'Livreur'}\n` +
                    `Contact livreur: ${driverInfo?.phone || 'Non renseigne'}`;
    const messageEn = `Delivery late for order #${order.order_number} (${elapsedMinutes} ${minuteLabel(elapsedMinutes, "en")}).\n` +
                      `Configured threshold: ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "en")}\n` +
                      `Restaurant: ${restaurantInfo.name}\n` +
                      `Driver: ${driverInfo?.name || 'Driver'}\n` +
                      `Driver contact: ${driverInfo?.phone || 'Not provided'}`;
    const messageAr = `تأخر توصيل الطلب #${order.order_number} (${elapsedMinutes} ${minuteLabel(elapsedMinutes, "ar")}).\n` +
                      `الحد المسموح: ${timeoutMinutes} ${minuteLabel(timeoutMinutes, "ar")}\n` +
                      `المطعم: ${restaurantInfo.name}\n` +
                      `السائق: ${driverInfo?.name || 'السائق'}\n` +
                      `هاتف السائق: ${driverInfo?.phone || 'غير متوفر'}`;

    const notification = await AdminNotification.create({
      order_id: orderId,
      restaurant_id: order.restaurant_id,
      driver_id: order.livreur_id || driverInfo?.id || null,
      type: 'driver_delivery_timeout',
      message,
      order_details: orderDetails,
      restaurant_info: restaurantInfo
    });

    console.log(`Admin notification created: ${notification.id}`);

    await notifyRole('admin', 'new_notification', {
      id: notification.id,
      type: 'driver_delivery_timeout',
      message,
      i18n: buildI18nPayload(ADMIN_NOTIFICATION_TITLE, {
        fr: message,
        en: messageEn,
        ar: messageAr
      }),
      order: orderDetails,
      restaurant: restaurantInfo,
      driver: driverInfo,
      created_at: notification.created_at
    });

    return notification;
  } catch (error) {
    console.error('Error creating driver delivery notification:', error);
    return null;
  }
};
/**
 * Recuperer toutes les notifications (avec filtres)
 */
export const getAllNotifications = async (filters = {}) => {
  const where = {};
  
  if (filters.is_read !== undefined) {
    where.is_read = filters.is_read;
  }
  
  if (filters.is_resolved !== undefined) {
    where.is_resolved = filters.is_resolved;
  }
  
  if (filters.type) {
    where.type = filters.type;
  }

  return AdminNotification.findAll({
    where,
    include: [
      {
        model: Order,
        as: 'order',
        include: [
          {
            model: OrderItem,
            as: 'order_items',
            include: [
              {
                model: MenuItem,
                as: 'menu_item',
                attributes: ['nom', 'prix']
              },
              {
                model: OrderItemAddition,
                as: 'additions',
                attributes: ['quantite', 'prix_unitaire', 'prix_total'],
                include: [
                  {
                    model: Addition,
                    as: 'addition',
                    attributes: ['nom', 'prix']
                  }
                ]
              }
            ]
          }
        ]
      },
      { model: Restaurant, as: 'restaurant' }
    ],
    order: [['created_at', 'DESC']]
  });
};

/**
 * Marquer comme lu
 */
export const markAsRead = async (notificationId) => {
  const notification = await AdminNotification.findByPk(notificationId);
  if (!notification) return null;
  
  await notification.update({ is_read: true });
  return notification;
};

/**
 * Resoudre une notification
 */
export const resolveNotification = async (notificationId, adminId, action, notes) => {
  const notification = await AdminNotification.findByPk(notificationId);
  if (!notification) {
    throw { status: 404, message: "Notification not found" };
  }

  await notification.update({
    is_resolved: true,
    resolved_by: adminId,
    resolved_at: new Date(),
    admin_action: action,
    admin_notes: notes
  });

  return notification;
};

export default {
  createPendingOrderNotification,
  createRestaurantPreparationTimeoutNotification,
  createDriverArrivalTimeoutNotification,
  createDriverDeliveryTimeoutNotification,
  getAllNotifications,
  markAsRead,
  resolveNotification
};





