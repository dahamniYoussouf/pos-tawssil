import crypto from "crypto";
import { sequelize } from "../config/database.js";
import User from "../models/User.js";
import Client from "../models/Client.js";
import Driver from "../models/Driver.js";
import Restaurant from "../models/Restaurant.js";
import Cashier from "../models/Cashier.js";
import DeviceToken from "../models/DeviceToken.js";
import FavoriteAddress from "../models/FavoriteAddress.js";
import FavoriteMeal from "../models/FavoriteMeal.js";
import FavoriteRestaurant from "../models/FavoriteRestaurant.js";
import { revokeRefreshTokensForUser } from "./sessionTokenStore.js";

const buildDeletionTag = (prefix) => {
  const random = crypto.randomBytes(4).toString("hex");
  return `${prefix}-${Date.now()}-${random}`;
};

const buildDeletedEmail = (prefix) => `${buildDeletionTag(prefix)}@deleted.local`;
const buildDeletedPassword = () => crypto.randomBytes(24).toString("hex");
const buildDeletedPhone = () =>
  `2139${crypto.randomInt(0, 100000000).toString().padStart(8, "0")}`;

const appendDeletionNote = (existingNote) => {
  const lines = [];
  if (typeof existingNote === "string" && existingNote.trim()) {
    lines.push(existingNote.trim());
  }
  lines.push(`Self-deleted on ${new Date().toISOString()}`);
  return lines.join("\n");
};

const createNotFoundError = (message) => {
  const error = new Error(message);
  error.status = 404;
  return error;
};

const deactivateDeviceTokens = async (userIds, transaction) => {
  const uniqueUserIds = Array.from(new Set(userIds.filter(Boolean)));
  if (!uniqueUserIds.length) return;

  await DeviceToken.update(
    { is_active: false },
    {
      where: { user_id: uniqueUserIds },
      transaction
    }
  );
};

const deactivateUserAccount = async (user, emailPrefix, transaction) => {
  if (!user) return null;

  const deletedEmail = buildDeletedEmail(emailPrefix);
  await user.update(
    {
      email: deletedEmail,
      password: buildDeletedPassword(),
      is_active: false,
      last_login: null
    },
    { transaction }
  );

  return deletedEmail;
};

const resolveClient = async (userId, clientId, transaction) => {
  if (clientId) {
    const client = await Client.findByPk(clientId, { transaction });
    if (client) return client;
  }

  return Client.findOne({
    where: { user_id: userId },
    transaction
  });
};

const resolveDriver = async (userId, driverId, transaction) => {
  if (driverId) {
    const driver = await Driver.findByPk(driverId, { transaction });
    if (driver) return driver;
  }

  return Driver.findOne({
    where: { user_id: userId },
    transaction
  });
};

const resolveRestaurant = async (userId, restaurantId, transaction) => {
  if (restaurantId) {
    const restaurant = await Restaurant.findByPk(restaurantId, { transaction });
    if (restaurant) return restaurant;
  }

  return Restaurant.findOne({
    where: { user_id: userId },
    transaction
  });
};

export const deleteOwnClientAccount = async ({ userId, clientId }) => {
  const result = await sequelize.transaction(async (transaction) => {
    const client = await resolveClient(userId, clientId, transaction);
    if (!client) {
      throw createNotFoundError("Client profile not found");
    }

    const user = await User.findByPk(client.user_id || userId, { transaction });
    if (!user) {
      throw createNotFoundError("User not found");
    }

    const deletedEmail = await deactivateUserAccount(user, "client", transaction);
    await deactivateDeviceTokens([user.id], transaction);

    await Promise.all([
      FavoriteAddress.destroy({ where: { client_id: client.id }, transaction }),
      FavoriteMeal.destroy({ where: { client_id: client.id }, transaction }),
      FavoriteRestaurant.destroy({ where: { client_id: client.id }, transaction })
    ]);

    await client.update(
      {
        first_name: "Deleted",
        last_name: "User",
        email: deletedEmail,
        phone_number: null,
        address: null,
        location: null,
        profile_image_url: null,
        loyalty_points: 0,
        is_active: false,
        status: "deleted"
      },
      { transaction }
    );

    return {
      userIdsToRevoke: [user.id],
      message: "Client account deleted successfully"
    };
  });

  const revokedSessions = result.userIdsToRevoke.reduce(
    (count, currentUserId) => count + revokeRefreshTokensForUser(currentUserId),
    0
  );

  return {
    message: result.message,
    revokedSessions
  };
};

export const deleteOwnDriverAccount = async ({ userId, driverId }) => {
  const result = await sequelize.transaction(async (transaction) => {
    const driver = await resolveDriver(userId, driverId, transaction);
    if (!driver) {
      throw createNotFoundError("Driver profile not found");
    }

    const user = await User.findByPk(driver.user_id || userId, { transaction });
    if (!user) {
      throw createNotFoundError("User not found");
    }

    await deactivateUserAccount(user, "driver", transaction);
    await deactivateDeviceTokens([user.id], transaction);

    await driver.update(
      {
        first_name: "Deleted",
        last_name: "Driver",
        phone: buildDeletedPhone(),
        email: null,
        vehicle_plate: null,
        license_number: null,
        status: "suspended",
        current_location: null,
        is_verified: false,
        is_active: false,
        last_active_at: null,
        notes: appendDeletionNote(driver.notes),
        cancellation_count: 0,
        profile_image_url: null,
        active_orders: []
      },
      { transaction }
    );

    return {
      userIdsToRevoke: [user.id],
      message: "Driver account deleted successfully"
    };
  });

  const revokedSessions = result.userIdsToRevoke.reduce(
    (count, currentUserId) => count + revokeRefreshTokensForUser(currentUserId),
    0
  );

  return {
    message: result.message,
    revokedSessions
  };
};

export const deleteOwnRestaurantAccount = async ({ userId, restaurantId }) => {
  const result = await sequelize.transaction(async (transaction) => {
    const restaurant = await resolveRestaurant(userId, restaurantId, transaction);
    if (!restaurant) {
      throw createNotFoundError("Restaurant profile not found");
    }

    const user = await User.findByPk(restaurant.user_id || userId, { transaction });
    if (!user) {
      throw createNotFoundError("User not found");
    }

    const cashiers = await Cashier.findAll({
      where: { restaurant_id: restaurant.id },
      transaction
    });

    const cashierUserIds = [];
    for (const cashier of cashiers) {
      if (cashier.user_id) {
        const cashierUser = await User.findByPk(cashier.user_id, { transaction });
        if (cashierUser) {
          cashierUserIds.push(cashierUser.id);
          await deactivateUserAccount(cashierUser, `cashier-${cashier.id}`, transaction);
        }
      }

      await cashier.update(
        {
          first_name: "Deleted",
          last_name: "Cashier",
          phone: buildDeletedPhone(),
          email: null,
          profile_image_url: null,
          is_active: false,
          status: "suspended",
          shift_start: null,
          shift_end: null,
          last_active_at: null,
          notes: appendDeletionNote(cashier.notes),
          permissions: {
            can_create_orders: false
          }
        },
        { transaction }
      );
    }

    await deactivateUserAccount(user, "restaurant", transaction);
    await deactivateDeviceTokens([user.id, ...cashierUserIds], transaction);

    await restaurant.update(
      {
        name: `Deleted restaurant ${restaurant.id.slice(0, 8)}`,
        description: null,
        address: null,
        phone_number: null,
        email: null,
        image_url: null,
        is_active: false,
        is_premium: false,
        status: "archived",
        availability_status: "closed",
        availability_note: "Account deleted",
        opening_hours: null,
        commune_id: null
      },
      { transaction }
    );

    return {
      userIdsToRevoke: [user.id, ...cashierUserIds],
      message: "Restaurant account deleted successfully"
    };
  });

  const revokedSessions = Array.from(new Set(result.userIdsToRevoke)).reduce(
    (count, currentUserId) => count + revokeRefreshTokensForUser(currentUserId),
    0
  );

  return {
    message: result.message,
    revokedSessions
  };
};
