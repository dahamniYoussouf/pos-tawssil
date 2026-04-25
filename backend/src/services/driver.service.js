import Driver from "../models/Driver.js";
import Order from "../models/Order.js";
import User from "../models/User.js";
import { sequelize } from "../config/database.js";
import { Op } from "sequelize";
import { normalizePhoneNumber } from "../utils/phoneNormalizer.js";

export const getAllDrivers = async (filters = {}) => {
  const {
    page = 1,
    limit = 20,
    status,
    is_active,
    is_verified,
    search
  } = filters;

  const offset = (parseInt(page, 10) - 1) * parseInt(limit, 10);
  const where = {};

  if (status) {
    where.status = status;
  }

  if (is_active !== undefined) {
    where.is_active = is_active === "true" || is_active === true;
  }

  if (is_verified !== undefined) {
    where.is_verified = is_verified === "true" || is_verified === true;
  }

  if (search) {
    where[Op.or] = [
      { first_name: { [Op.iLike]: `%${search}%` } },
      { last_name: { [Op.iLike]: `%${search}%` } },
      { phone: { [Op.iLike]: `%${search}%` } },
      { email: { [Op.iLike]: `%${search}%` } },
      { driver_code: { [Op.iLike]: `%${search}%` } },
      { license_number: { [Op.iLike]: `%${search}%` } }
    ];
  }

  const { count, rows } = await Driver.findAndCountAll({
    where,
    include: [
      {
        model: User,
        as: "user",
        attributes: ["email_verified_at"]
      }
    ],
    order: [["created_at", "DESC"]],
    limit: parseInt(limit, 10),
    offset,
    distinct: true
  });

  const drivers = rows.map((driver) => {
    const driverJson = driver.toJSON();
    const { user, ...driverData } = driverJson;

    return {
      ...driverData,
      email_verified_at: user?.email_verified_at ?? null
    };
  });

  return {
    drivers,
    pagination: {
      current_page: parseInt(page, 10),
      total_pages: Math.ceil(count / parseInt(limit, 10)),
      total_items: count,
      items_per_page: parseInt(limit, 10)
    }
  };
};

export const getDriverById = async (id) => {
  return Driver.findByPk(id);
};

export const getDriverByUserId = async (user_id) => {
  return Driver.findOne({ where: { user_id } });
};

export const updateDriver = async (id, updateData) => {
  return sequelize.transaction(async (transaction) => {
    const driver = await Driver.findByPk(id, { transaction });
    if (!driver) return null;

    const { email, password, ...driverUpdates } = updateData || {};

    if (driverUpdates.phone) {
      driverUpdates.phone = normalizePhoneNumber(driverUpdates.phone);
    }

    if (Object.keys(driverUpdates).length > 0) {
      await driver.update(driverUpdates, { transaction });
    }

    if (driver.user_id && (email !== undefined || password)) {
      const user = await User.findByPk(driver.user_id, { transaction });
      if (user) {
        const userUpdates = {};
        if (email !== undefined && String(email).trim() !== "") {
          userUpdates.email = email;
        }
        if (password && String(password).trim() !== "") {
          userUpdates.password = password;
        }
        if (Object.keys(userUpdates).length > 0) {
          await user.update(userUpdates, { transaction });
        }
      }
    }

    return Driver.findByPk(id, { transaction });
  });
};

export const deleteDriver = async (id) => {
  const driver = await Driver.findByPk(id);
  if (!driver) return false;

  await driver.destroy();
  return true;
};

export const updateDriverStatus = async (id, status) => {
  const driver = await Driver.findByPk(id);
  if (!driver) return null;

  if (driver.status === "suspended" && status !== "suspended") {
    throw {
      status: 403,
      message: "Driver account is suspended and cannot change status",
      code: "DRIVER_SUSPENDED"
    };
  }

  driver.status = status;
  if (status === "available" || status === "busy") {
    driver.last_active_at = new Date();
  }

  await driver.save();
  return driver;
};

export const getDriverStatistics = async (driver_id) => {
  const driver = await Driver.findByPk(driver_id);
  if (!driver) return null;

  const totalRevenue = await Order.sum("delivery_fee", {
    where: { livreur_id: driver_id, status: "delivered" }
  });

  return {
    total_deliveries: driver.total_deliveries,
    total_revenue: Number.isFinite(totalRevenue) ? totalRevenue : 0,
    rating: driver.rating,
    status: driver.status,
    is_verified: driver.is_verified,
    vehicle_type: driver.vehicle_type
  };
};
