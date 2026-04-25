import { Op } from "sequelize";
import { sequelize } from "../../config/database.js";
import Order from "../../models/Order.js";
import Client from "../../models/Client.js";
import Restaurant from "../../models/Restaurant.js";
import OrderItem from "../../models/OrderItem.js";
import OrderItemAddition from "../../models/OrderItemAddition.js";
import MenuItem from "../../models/MenuItem.js";
import Addition from "../../models/Addition.js";
import AdminNotification from "../../models/AdminNotification.js";
import { notify } from "./notify.helper.js";
import { getAdminReviewRequiredCopy, getRestaurantNewOrderCopy, getClientDeclinedCopy } from "./pushCopy.helper.js";
import { scheduleAdminNotification } from "./scheduling.service.js";
import { createOrderReviewRequiredNotification, resolveNotification, markAsRead } from "../adminNotification.service.js";
import { emitToAdmins } from "../../utils/socketHelpers.js";

const CLIENT_LOCK_TIMEOUT_MINUTES = 15;
const ADMIN_REVIEW_NOTIFICATION_TYPE = "order_admin_review_required";

const includeForReview = [
  {
    model: Client,
    as: "client",
    attributes: [
      "id",
      "first_name",
      "last_name",
      "phone_number",
      "address",
      "review_contact_lock_admin_id",
      "review_contact_lock_order_id",
      "review_contact_locked_at",
      "review_contact_lock_until"
    ]
  },
  {
    model: Restaurant,
    as: "restaurant",
    attributes: ["id", "name", "phone_number", "address", "email"]
  },
  {
    model: OrderItem,
    as: "order_items",
    include: [
      {
        model: MenuItem,
        as: "menu_item",
        attributes: ["nom", "prix"]
      },
      {
        model: OrderItemAddition,
        as: "additions",
        attributes: ["quantite", "prix_unitaire", "prix_total"],
        include: [
          {
            model: Addition,
            as: "addition",
            attributes: ["nom", "prix"]
          }
        ]
      }
    ]
  }
];

const parseCount = (value, fallback) => {
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
};

const nowPlusMinutes = (minutes) => new Date(Date.now() + minutes * 60_000);

const getReviewNotification = async (orderId, transaction = null) => {
  return AdminNotification.findOne({
    where: {
      order_id: orderId,
      type: ADMIN_REVIEW_NOTIFICATION_TYPE
    },
    order: [["created_at", "DESC"]],
    transaction
  });
};

const clearExpiredClientLock = async (client, transaction) => {
  if (!client) return false;

  const lockUntil = client.review_contact_lock_until ? new Date(client.review_contact_lock_until) : null;
  if (!lockUntil || Number.isNaN(lockUntil.getTime()) || lockUntil.getTime() > Date.now()) {
    return false;
  }

  await client.update(
    {
      review_contact_lock_admin_id: null,
      review_contact_lock_order_id: null,
      review_contact_locked_at: null,
      review_contact_lock_until: null
    },
    { transaction }
  );

  return true;
};

const assertReviewableOrder = (order) => {
  if (!order) {
    throw { status: 404, message: "Order not found" };
  }

  if (!order.requires_admin_review || order.status !== "pending_admin_review") {
    throw { status: 400, message: "Order is not awaiting admin review" };
  }
};

const findOrderForReviewMutation = async (orderId, transaction) => {
  const order = await Order.findByPk(orderId, {
    transaction,
    lock: transaction.LOCK.UPDATE
  });

  if (!order) {
    return null;
  }

  await order.reload({
    include: includeForReview,
    transaction
  });

  return order;
};

const buildReviewListItem = (order, currentAdminId = null) => {
  const json = typeof order.toJSON === "function" ? order.toJSON() : order;
  const client = json.client || {};
  const review = {
    ...json.admin_review_metadata,
    claimed_by_me: currentAdminId && String(json.admin_review_claimed_by || "") === String(currentAdminId),
    is_claimed: json.admin_review_status === "claimed",
    is_pending: json.admin_review_status === "pending",
    is_approved: json.admin_review_status === "approved",
    is_rejected: json.admin_review_status === "rejected",
    client_lock_active: !!client.review_contact_lock_until && new Date(client.review_contact_lock_until).getTime() > Date.now()
  };

  return {
    ...json,
    review
  };
};

const releaseClientLock = async (client, transaction) => {
  if (!client) return;
  await client.update(
    {
      review_contact_lock_admin_id: null,
      review_contact_lock_order_id: null,
      review_contact_locked_at: null,
      review_contact_lock_until: null
    },
    { transaction }
  );
};

export async function getReviewQueue(filters = {}, currentAdminId = null) {
  const where = {
    status: "pending_admin_review",
    requires_admin_review: true
  };

  if (filters.review_status && filters.review_status !== "all") {
    where.admin_review_status = filters.review_status;
  }

  if (filters.search) {
    where[Op.or] = [
      { order_number: { [Op.iLike]: `%${filters.search}%` } }
    ];
  }

  const parsedPage = Number.parseInt(String(filters.page ?? 1), 10);
  const page = Number.isFinite(parsedPage) && parsedPage > 0 ? parsedPage : 1;

  const parsedLimit = Number.parseInt(String(filters.limit ?? 20), 10);
  const limit = Number.isFinite(parsedLimit) ? Math.min(100, Math.max(1, parsedLimit)) : 20;
  const offset = (page - 1) * limit;

  const { count, rows } = await Order.findAndCountAll({
    where,
    include: includeForReview,
    order: [["created_at", "DESC"]],
    limit,
    offset,
    distinct: true
  });

  return {
    orders: rows.map((order) => buildReviewListItem(order, currentAdminId)),
    pagination: {
      current_page: page,
      total_pages: Math.ceil(count / limit),
      total_items: count,
      items_in_page: rows.length
    }
  };
}

export async function claimReviewOrder(orderId, adminId) {
  const transaction = await sequelize.transaction();
  try {
    const order = await findOrderForReviewMutation(orderId, transaction);

    assertReviewableOrder(order);

    const client = order.client;
    if (!client) {
      throw { status: 400, message: "Client not found for this order" };
    }

    await clearExpiredClientLock(client, transaction);

    const activeLock = client.review_contact_lock_until && new Date(client.review_contact_lock_until).getTime() > Date.now();
    const lockBelongsToSameOrder = String(client.review_contact_lock_order_id || "") === String(order.id);

    if (activeLock && !lockBelongsToSameOrder) {
      throw {
        status: 409,
        message: "This client is already being contacted by another admin"
      };
    }

    const lockUntil = nowPlusMinutes(CLIENT_LOCK_TIMEOUT_MINUTES);

    await client.update(
      {
        review_contact_lock_admin_id: adminId,
        review_contact_lock_order_id: order.id,
        review_contact_locked_at: new Date(),
        review_contact_lock_until: lockUntil
      },
      { transaction }
    );

    await order.update(
      {
        admin_review_status: "claimed",
        admin_review_claimed_by: adminId,
        admin_review_claimed_at: new Date()
      },
      { transaction }
    );

    const notification = await getReviewNotification(orderId, transaction);
    if (notification && !notification.is_read) {
      await markAsRead(notification.id);
    }

    await transaction.commit();

    emitToAdmins("admin_review_queue_updated", {
      type: "claimed",
      order_id: order.id,
      admin_id: adminId,
      client_id: client.id,
      order_number: order.order_number,
      lock_until: lockUntil.toISOString()
    });

    return {
      ...(typeof order.toJSON === "function" ? order.toJSON() : order),
      review: {
        status: "claimed",
        claimed_by_admin_id: adminId,
        claimed_at: new Date().toISOString(),
        lock_until: lockUntil.toISOString()
      }
    };
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

export async function releaseReviewOrder(orderId, adminId) {
  const transaction = await sequelize.transaction();
  try {
    const order = await findOrderForReviewMutation(orderId, transaction);

    assertReviewableOrder(order);

    const client = order.client;
    if (!client) {
      throw { status: 400, message: "Client not found for this order" };
    }

    const lockOwnedByAdmin = String(client.review_contact_lock_admin_id || "") === String(adminId);
    const lockBelongsToOrder = String(client.review_contact_lock_order_id || "") === String(order.id);

    if (client.review_contact_lock_admin_id && !lockOwnedByAdmin && lockBelongsToOrder) {
      throw { status: 403, message: "You do not own this client contact lock" };
    }

    await releaseClientLock(client, transaction);
    await order.update(
      {
        admin_review_status: "pending",
        admin_review_claimed_by: null,
        admin_review_claimed_at: null
      },
      { transaction }
    );

    await transaction.commit();

    emitToAdmins("admin_review_queue_updated", {
      type: "released",
      order_id: order.id,
      admin_id: adminId,
      order_number: order.order_number
    });

    return order;
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

export async function approveReviewOrder(orderId, adminId, data = {}) {
  const transaction = await sequelize.transaction();
  try {
    const order = await findOrderForReviewMutation(orderId, transaction);

    assertReviewableOrder(order);

    const client = order.client;
    if (!client) {
      throw { status: 400, message: "Client not found for this order" };
    }

    const lockOwnedByAdmin = String(client.review_contact_lock_admin_id || "") === String(adminId);
    const lockBelongsToOrder = String(client.review_contact_lock_order_id || "") === String(order.id);
    if (client.review_contact_lock_admin_id && !lockOwnedByAdmin && lockBelongsToOrder) {
      throw { status: 403, message: "You do not own this client contact lock" };
    }

    const preparationMinutes = parseCount(data?.preparation_time, 15);
    const reviewNotes = String(data?.notes || "").trim() || null;

    await order.update(
      {
        status: "pending",
        requires_admin_review: false,
        admin_review_status: "approved",
        admin_reviewed_by: adminId,
        admin_reviewed_at: new Date(),
        admin_review_notes: reviewNotes,
        restaurant_notified_at: new Date()
      },
      { transaction }
    );

    await releaseClientLock(client, transaction);

    const notification = await getReviewNotification(orderId, transaction);
    if (notification) {
      await resolveNotification(notification.id, adminId, "approved_order", reviewNotes || "Approved and forwarded to restaurant");
    }

    await transaction.commit();

    const restaurantCopy = getRestaurantNewOrderCopy(order.order_type);
    notify("restaurant", order.restaurant_id, {
      type: "new_order",
      orderId: order.id,
      orderNumber: order.order_number,
      orderType: order.order_type,
      total: order.total_amount,
      title: restaurantCopy.title,
      message: restaurantCopy.message,
      i18n: restaurantCopy.i18n,
      preparation_time: preparationMinutes,
      admin_review: {
        approved_by: adminId,
        approved_at: new Date().toISOString()
      }
    });

    scheduleAdminNotification(order.id);

    emitToAdmins("admin_review_queue_updated", {
      type: "approved",
      order_id: order.id,
      admin_id: adminId,
      order_number: order.order_number
    });

    return {
      ...(typeof order.toJSON === "function" ? order.toJSON() : order),
      review: {
        status: "approved",
        approved_by_admin_id: adminId,
        approved_at: new Date().toISOString(),
        preparation_time: preparationMinutes
      }
    };
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

export async function rejectReviewOrder(orderId, adminId, data = {}) {
  const transaction = await sequelize.transaction();
  try {
    const order = await findOrderForReviewMutation(orderId, transaction);

    assertReviewableOrder(order);

    const client = order.client;
    if (!client) {
      throw { status: 400, message: "Client not found for this order" };
    }

    const lockOwnedByAdmin = String(client.review_contact_lock_admin_id || "") === String(adminId);
    const lockBelongsToOrder = String(client.review_contact_lock_order_id || "") === String(order.id);
    if (client.review_contact_lock_admin_id && !lockOwnedByAdmin && lockBelongsToOrder) {
      throw { status: 403, message: "You do not own this client contact lock" };
    }

    const reason = String(data?.reason || "").trim();
    if (!reason) {
      throw { status: 400, message: "A rejection reason is required" };
    }

    await order.update(
      {
        status: "declined",
        requires_admin_review: false,
        admin_review_status: "rejected",
        admin_reviewed_by: adminId,
        admin_reviewed_at: new Date(),
        admin_review_notes: reason,
        decline_reason: `[ADMIN REVIEW] ${reason}`
      },
      { transaction }
    );

    await releaseClientLock(client, transaction);

    const notification = await getReviewNotification(orderId, transaction);
    if (notification) {
      await resolveNotification(notification.id, adminId, "rejected_order", reason);
    }

    await transaction.commit();

    const declinedCopy = getClientDeclinedCopy();
    notify("client", order.client_id, {
      type: "order_declined",
      orderId: order.id,
      orderNumber: order.order_number,
      reason,
      title: declinedCopy.title,
      message: declinedCopy.message,
      i18n: declinedCopy.i18n
    });

    emitToAdmins("admin_review_queue_updated", {
      type: "rejected",
      order_id: order.id,
      admin_id: adminId,
      order_number: order.order_number
    });

    return {
      ...(typeof order.toJSON === "function" ? order.toJSON() : order),
      review: {
        status: "rejected",
        rejected_by_admin_id: adminId,
        rejected_at: new Date().toISOString(),
        reason
      }
    };
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}

export async function routeOrderForAdminReview(order, reviewMetadata = {}) {
  if (!order) return null;

  const payload = {
    reasons: Array.isArray(reviewMetadata.reasons) ? reviewMetadata.reasons : [],
    clientOrderCount: reviewMetadata.clientOrderCount ?? null,
    threshold_amount: reviewMetadata.threshold_amount ?? null,
    threshold_count: reviewMetadata.threshold_count ?? null
  };

  await createOrderReviewRequiredNotification(order.id, payload);
  return payload;
}
