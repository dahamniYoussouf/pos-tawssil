import { Op } from "sequelize";
import { sequelize } from "../config/database.js";
import DeviceToken from "../models/DeviceToken.js";
import Client from "../models/Client.js";
import Driver from "../models/Driver.js";
import Restaurant from "../models/Restaurant.js";
import Admin from "../models/Admin.js";
import {
  normalizeDataPayload,
  sendToTokens,
  sendToTopic,
  subscribeToTopics,
  unsubscribeFromTopics
} from "./firebaseNotification.service.js";
import { enqueueNotificationTask } from "./notificationQueue.service.js";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES, normalizeLocale } from "../utils/locale.js";

const IS_PRODUCTION = process.env.NODE_ENV === "production";
const FIREBASE_USE_TOPICS =
  process.env.NOTIFICATION_FIREBASE_USE_TOPICS === "true" ||
  (IS_PRODUCTION && process.env.NOTIFICATION_FIREBASE_USE_TOPICS !== "false");
const NOTIFICATION_DEBUG =
  process.env.NOTIFICATION_DEBUG === "true" && !IS_PRODUCTION;
const TOKEN_FAILURE_DEACTIVATION_THRESHOLD = (() => {
  const parsed = Number.parseInt(
    String(process.env.NOTIFICATION_TOKEN_FAILURE_THRESHOLD ?? "3"),
    10
  );
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 3;
})();
const IMMEDIATE_DISABLE_FAILURE_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token"
]);
const RETRY_DISABLE_FAILURE_CODES = new Set([
  "messaging/mismatched-credential"
]);

const debugLog = (...args) => {
  if (NOTIFICATION_DEBUG) {
    console.log("[NOTIF]", ...args);
  }
};

const ROLE_TOPICS = {
  client: "role-clients",
  driver: "role-drivers",
  restaurant: "role-restaurants",
  admin: "role-admins",
  cashier: "role-cashiers"
};


const buildNotificationText = (data = {}) => {
  const title =
    data.title ||
    data.titre ||
    (data.type ? `Notification ${data.type}` : "Notification");

  let body = data.message || data.body || data.contenu || data.description;

  if (!body) {
    if (data.orderNumber || data.orderId) {
      body = `Mise a jour commande #${data.orderNumber || data.orderId}`;
    } else if (data.type) {
      body = `Type: ${data.type}`;
    } else {
      body = "Nouvelle notification";
    }
  }

  return { title, body };
};

const buildFcmMessage = (data = {}, options = {}) => {
  const notification =
    options.notification === null
      ? undefined
      : options.notification || buildNotificationText(data);
  const apns =
    options.apns === null
      ? undefined
      : options.apns || {
          payload: {
            aps: {
              ...(notification
                ? { alert: { title: notification.title, body: notification.body } }
                : {}),
              sound: "default",
              "content-available": 1,
              "mutable-content": 1
            }
          },
          headers: {
            "apns-priority": "10"
          }
        };

  return {
    notification,
    data: normalizeDataPayload(data),
    apns
  };
};

const resolveProfileLocale = async (role, profileId) => {
  if (!role || !profileId) return null;
  switch (role) {
    case "client": {
      const client = await Client.findByPk(profileId, { attributes: ["locale"] });
      return client?.locale || null;
    }
    case "driver": {
      const driver = await Driver.findByPk(profileId, { attributes: ["locale"] });
      return driver?.locale || null;
    }
    case "restaurant": {
      const restaurant = await Restaurant.findByPk(profileId, { attributes: ["locale"] });
      return restaurant?.locale || null;
    }
    case "admin": {
      const admin = await Admin.findByPk(profileId, { attributes: ["locale"] });
      return admin?.locale || null;
    }
    default:
      return null;
  }
};

const resolveProfileLocaleMap = async (role, profileIds = []) => {
  const ids = Array.from(new Set(profileIds.filter(Boolean)));
  if (!ids.length) return new Map();

  let Model = null;
  switch (role) {
    case "client":
      Model = Client;
      break;
    case "driver":
      Model = Driver;
      break;
    case "restaurant":
      Model = Restaurant;
      break;
    case "admin":
      Model = Admin;
      break;
    default:
      return new Map();
  }

  const rows = await Model.findAll({
    where: { id: { [Op.in]: ids } },
    attributes: ["id", "locale"],
    raw: true
  });

  const map = new Map();
  rows.forEach((row) => {
    map.set(String(row.id), normalizeLocale(row.locale));
  });
  return map;
};

const localizePayload = (data = {}, locale) => {
  const normalizedLocale = normalizeLocale(locale);
  const payload = {
    ...data,
    locale: normalizedLocale
  };

  const i18n = data?.i18n;
  if (!i18n || typeof i18n !== "object") {
    return payload;
  }

  const localized = i18n[normalizedLocale] || i18n[DEFAULT_LOCALE];
  if (!localized) {
    return payload;
  }

  if (typeof localized === "string") {
    payload.message = localized;
    payload.body = localized;
    return payload;
  }

  if (localized.title) {
    payload.title = localized.title;
  }

  const body =
    localized.body ??
    localized.message ??
    localized.description ??
    localized.text;

  if (body) {
    payload.body = body;
    payload.message = body;
  }

  if (localized.message) {
    payload.message = localized.message;
  }

  if (localized.description) {
    payload.description = localized.description;
  }

  return payload;
};

const buildRoleTopic = (role) => ROLE_TOPICS[role] || null;

const buildRoleLocaleTopic = (role, locale) => {
  const base = buildRoleTopic(role);
  if (!base) return null;
  const normalizedLocale = normalizeLocale(locale);
  return `${base}-${normalizedLocale}`;
};

export const getTopicsForRole = (role, locale) => {
  const base = buildRoleTopic(role);
  const topics = [];
  if (base) topics.push(base);
  const localeTopic = locale ? buildRoleLocaleTopic(role, locale) : null;
  if (localeTopic) topics.push(localeTopic);
  return topics;
};

const disableInvalidTokens = async (tokens) => {
  if (!tokens || tokens.length === 0) return;
  try {
    await DeviceToken.update(
      {
        is_active: false,
        failure_count: 0,
        last_failure_code: null,
        last_failure_at: null
      },
      { where: { token: { [Op.in]: tokens } } }
    );
  } catch (error) {
    console.error("Failed to disable invalid tokens:", error);
  }
};

const resetDeliveredTokens = async (tokens) => {
  if (!tokens || tokens.length === 0) return;
  try {
    await DeviceToken.update(
      {
        failure_count: 0,
        last_failure_code: null,
        last_failure_at: null
      },
      {
        where: {
          token: { [Op.in]: tokens },
          is_active: true
        }
      }
    );
  } catch (error) {
    console.error("Failed to reset notification token failures:", error);
  }
};

const recordTokenFailures = async (failures = []) => {
  if (!failures.length) return;

  const immediateDisableTokens = [];
  const retriableFailureTokens = [];

  for (const failure of failures) {
    if (!failure?.token || !failure?.code) continue;

    if (IMMEDIATE_DISABLE_FAILURE_CODES.has(failure.code)) {
      immediateDisableTokens.push(failure.token);
      continue;
    }

    if (RETRY_DISABLE_FAILURE_CODES.has(failure.code)) {
      retriableFailureTokens.push(failure);
    }
  }

  if (immediateDisableTokens.length) {
    await disableInvalidTokens(immediateDisableTokens);
  }

  if (!retriableFailureTokens.length) {
    return;
  }

  const now = new Date();
  const tokens = Array.from(new Set(retriableFailureTokens.map((entry) => entry.token)));

  try {
    await DeviceToken.update(
      {
        failure_count: sequelize.literal("COALESCE(failure_count, 0) + 1"),
        last_failure_code: "messaging/mismatched-credential",
        last_failure_at: now
      },
      {
        where: {
          token: { [Op.in]: tokens },
          is_active: true
        }
      }
    );

    await DeviceToken.update(
      {
        is_active: false
      },
      {
        where: {
          token: { [Op.in]: tokens },
          is_active: true,
          failure_count: { [Op.gte]: TOKEN_FAILURE_DEACTIVATION_THRESHOLD }
        }
      }
    );
  } catch (error) {
    console.error("Failed to record notification token failures:", error);
  }
};

export const applyDeviceTokenDeliveryResults = async (result = {}) => {
  const tokenResults = Array.isArray(result.tokenResults) ? result.tokenResults : [];
  const successfulTokens = tokenResults
    .filter((entry) => entry?.success && entry?.token)
    .map((entry) => entry.token);
  const failedTokens = tokenResults
    .filter((entry) => !entry?.success && entry?.token && entry?.code)
    .map((entry) => ({ token: entry.token, code: entry.code }));

  await Promise.all([
    resetDeliveredTokens(successfulTokens),
    recordTokenFailures(failedTokens)
  ]);
};

const sendToDeviceTokens = async (tokens, data, options = {}) => {
  if (!tokens || tokens.length === 0) {
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  try {
    const message = buildFcmMessage(data, options);
    const result = await sendToTokens(tokens, message);
    await applyDeviceTokenDeliveryResults(result);

    return result;
  } catch (error) {
    console.error("Firebase notification error:", error);
    return { successCount: 0, failureCount: tokens.length, invalidTokens: [] };
  }
};

export const registerDeviceTokenForUser = async ({
  userId,
  role,
  profileId,
  token,
  platform,
  deviceId,
  locale
}) => {
  if (!token || !userId || !role) return null;

  const now = new Date();
  const normalizedLocale = normalizeLocale(locale);

  const existing = await DeviceToken.findOne({ where: { token } });
  const previousRole = existing?.role;
  const previousLocale = existing?.locale ? normalizeLocale(existing.locale) : null;

  if (existing) {
    await existing.update({
      user_id: userId,
      role,
      profile_id: profileId || null,
      platform: platform || existing.platform,
      device_id: deviceId || existing.device_id,
      locale: normalizedLocale,
      is_active: true,
      last_seen_at: now,
      failure_count: 0,
      last_failure_code: null,
      last_failure_at: null
    });
    debugLog("Device token updated", { role, profileId });
  } else {
    await DeviceToken.create({
      user_id: userId,
      role,
      profile_id: profileId || null,
      token,
      platform: platform || null,
      device_id: deviceId || null,
      locale: normalizedLocale,
      is_active: true,
      last_seen_at: now,
      failure_count: 0,
      last_failure_code: null,
      last_failure_at: null
    });
    debugLog("Device token created", { role, profileId });
  }

  if (FIREBASE_USE_TOPICS) {
    const topics = getTopicsForRole(role, normalizedLocale);
    const roleChanged = previousRole && previousRole !== role;
    const localeChanged = previousLocale && previousLocale !== normalizedLocale;
    if (roleChanged || localeChanged) {
      const previousTopics = getTopicsForRole(previousRole, previousLocale);
      await unsubscribeFromTopics([token], previousTopics);
    }
    await subscribeToTopics([token], topics);
  }

  return true;
};

export const unregisterDeviceTokenForUser = async ({ userId, token, role }) => {
  if (!token || !userId) return false;

  const record = await DeviceToken.findOne({ where: { token, user_id: userId } });
  if (!record) return false;

  await record.update({ is_active: false });

  if (FIREBASE_USE_TOPICS) {
    const topics = getTopicsForRole(role || record.role, record.locale);
    await unsubscribeFromTopics([token], topics);
  }

  return true;
};

export const getLatestDeviceTokenForProfile = async ({ role, profileId }) => {
  if (!role || !profileId) return null;

  const record = await DeviceToken.findOne({
    where: {
      role,
      profile_id: profileId,
      is_active: true
    },
    order: [
      ["last_seen_at", "DESC"],
      ["updated_at", "DESC"]
    ],
    attributes: ["token"]
  });

  return record?.token || null;
};

export const notifyProfile = async (role, profileId, event, data, options = {}) => {
  if (!profileId) {
    console.warn("notifyProfile skipped: missing profileId");
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  try {
    const locale = await resolveProfileLocale(role, profileId);
    const localizedPayload = localizePayload(data, locale);

    const tokenAttributes = NOTIFICATION_DEBUG ? ["token", "platform"] : ["token"];
    const tokens = await DeviceToken.findAll({
      where: {
        role,
        profile_id: profileId,
        is_active: true
      },
      attributes: tokenAttributes
    });

    const tokenValues = tokens.map((t) => t.token);
    const payload = {
      ...localizedPayload,
      event,
      role,
      profile_id: String(profileId)
    };

    if (NOTIFICATION_DEBUG) {
      const platformCounts = {};
      tokens.forEach((t) => {
        const platform = t.platform || "unknown";
        platformCounts[platform] = (platformCounts[platform] || 0) + 1;
      });
      debugLog("notifyProfile", {
        role,
        event,
        profileId,
        tokens: tokenValues.length,
        platforms: platformCounts
      });
    }

    return sendToDeviceTokens(tokenValues, payload, options);
  } catch (error) {
    console.error("notifyProfile failed:", error);
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }
};

export const notifyProfiles = async (role, profileIds = [], event, data, options = {}) => {
  const uniqueIds = Array.from(new Set(profileIds.filter(Boolean)));
  if (uniqueIds.length === 0) {
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  try {
    const localeMap = await resolveProfileLocaleMap(role, uniqueIds);

    const tokenAttributes = NOTIFICATION_DEBUG ? ["token", "platform"] : ["token"];
    const tokens = await DeviceToken.findAll({
      where: {
        role,
        profile_id: { [Op.in]: uniqueIds },
        is_active: true
      },
      attributes: [...tokenAttributes, "profile_id"]
    });

    const tokensByLocale = new Map();
    tokens.forEach((tokenRecord) => {
      const profileKey = tokenRecord.profile_id ? String(tokenRecord.profile_id) : "";
      const locale = localeMap.get(profileKey) || DEFAULT_LOCALE;
      const bucket = tokensByLocale.get(locale) || [];
      bucket.push(tokenRecord.token);
      tokensByLocale.set(locale, bucket);
    });

    if (NOTIFICATION_DEBUG) {
      const platformCounts = {};
      tokens.forEach((t) => {
        const platform = t.platform || "unknown";
        platformCounts[platform] = (platformCounts[platform] || 0) + 1;
      });
      debugLog("notifyProfiles", {
        role,
        event,
        profiles: uniqueIds.length,
        tokens: tokens.length,
        platforms: platformCounts
      });
    }

    const results = [];
    for (const [locale, tokenValues] of tokensByLocale.entries()) {
      const payload = {
        ...localizePayload(data, locale),
        event,
        role
      };
      results.push(await sendToDeviceTokens(tokenValues, payload, options));
    }

    return results.reduce(
      (acc, result) => ({
        successCount: acc.successCount + (result?.successCount || 0),
        failureCount: acc.failureCount + (result?.failureCount || 0),
        invalidTokens: [...acc.invalidTokens, ...(result?.invalidTokens || [])]
      }),
      { successCount: 0, failureCount: 0, invalidTokens: [] }
    );
  } catch (error) {
    console.error("notifyProfiles failed:", error);
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }
};

export const notifyRole = async (role, event, data, options = {}) => {
  try {
    const payload = {
      ...localizePayload(data, DEFAULT_LOCALE),
      event,
      role
    };

    if (FIREBASE_USE_TOPICS) {
      debugLog("notifyRole using topics", { role, event });
      const i18n = data?.i18n && typeof data.i18n === "object" ? data.i18n : null;
      const locales = i18n
        ? SUPPORTED_LOCALES.filter((locale) => !!i18n[locale])
        : [];

      if (locales.length) {
        for (const locale of locales) {
          const localizedPayload = {
            ...localizePayload(data, locale),
            event,
            role
          };
          const message = buildFcmMessage(localizedPayload, options);
          const topic = buildRoleLocaleTopic(role, locale);
          if (topic) {
            await sendToTopic(topic, message);
          }
        }
        return { successCount: 0, failureCount: 0, invalidTokens: [] };
      }

      const message = buildFcmMessage(payload, options);
      const topics = getTopicsForRole(role);
      for (const topic of topics) {
        await sendToTopic(topic, message);
      }
      return { successCount: 0, failureCount: 0, invalidTokens: [] };
    }

    const tokenAttributes = NOTIFICATION_DEBUG ? ["token", "platform"] : ["token"];
    const tokens = await DeviceToken.findAll({
      where: {
        role,
        is_active: true
      },
      attributes: [...tokenAttributes, "profile_id"]
    });

    const profileIds = tokens
      .map((token) => token.profile_id)
      .filter(Boolean)
      .map((id) => String(id));
    const localeMap = await resolveProfileLocaleMap(role, profileIds);
    const tokensByLocale = new Map();
    tokens.forEach((tokenRecord) => {
      const profileKey = tokenRecord.profile_id ? String(tokenRecord.profile_id) : "";
      const locale = localeMap.get(profileKey) || DEFAULT_LOCALE;
      const bucket = tokensByLocale.get(locale) || [];
      bucket.push(tokenRecord.token);
      tokensByLocale.set(locale, bucket);
    });

    const tokenValues = tokens.map((t) => t.token);
    if (NOTIFICATION_DEBUG) {
      const platformCounts = {};
      tokens.forEach((t) => {
        const platform = t.platform || "unknown";
        platformCounts[platform] = (platformCounts[platform] || 0) + 1;
      });
      debugLog("notifyRole using tokens", {
        role,
        event,
        tokens: tokenValues.length,
        platforms: platformCounts
      });
    }

    const results = [];
    for (const [locale, values] of tokensByLocale.entries()) {
      const localizedPayload = {
        ...localizePayload(data, locale),
        event,
        role
      };
      results.push(await sendToDeviceTokens(values, localizedPayload, options));
    }

    return results.reduce(
      (acc, result) => ({
        successCount: acc.successCount + (result?.successCount || 0),
        failureCount: acc.failureCount + (result?.failureCount || 0),
        invalidTokens: [...acc.invalidTokens, ...(result?.invalidTokens || [])]
      }),
      { successCount: 0, failureCount: 0, invalidTokens: [] }
    );
  } catch (error) {
    console.error("notifyRole failed:", error);
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }
};

export const queueNotifyProfile = (role, profileId, event, data, options = {}) =>
  enqueueNotificationTask(
    `notifyProfile:${role}:${event}`,
    () => notifyProfile(role, profileId, event, data, options)
  );

export const queueNotifyProfiles = (role, profileIds = [], event, data, options = {}) =>
  enqueueNotificationTask(
    `notifyProfiles:${role}:${event}`,
    () => notifyProfiles(role, profileIds, event, data, options)
  );

export const queueNotifyRole = (role, event, data, options = {}) =>
  enqueueNotificationTask(
    `notifyRole:${role}:${event}`,
    () => notifyRole(role, event, data, options)
  );
