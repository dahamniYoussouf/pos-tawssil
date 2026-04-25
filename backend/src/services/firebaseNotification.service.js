import admin from "firebase-admin";
import fs from "node:fs";

let firebaseInitialized = false;

const NOTIFICATION_DEBUG =
  process.env.NOTIFICATION_DEBUG === "true" &&
  process.env.NODE_ENV !== "production";
const TOPIC_BATCH_SIZE = 1000;
const debugLog = (...args) => {
  if (NOTIFICATION_DEBUG) {
    console.log("[FCM]", ...args);
  }
};

const loadServiceAccountFromEnv = () => {
  const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (rawJson) {
    debugLog("Using service account from FIREBASE_SERVICE_ACCOUNT_JSON");
    return JSON.parse(rawJson);
  }

  const base64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (base64) {
    const decoded = Buffer.from(base64, "base64").toString("utf8");
    debugLog("Using service account from FIREBASE_SERVICE_ACCOUNT_BASE64");
    return JSON.parse(decoded);
  }

  const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (filePath && fs.existsSync(filePath)) {
    const fileContents = fs.readFileSync(filePath, "utf8");
    debugLog("Using service account from FIREBASE_SERVICE_ACCOUNT_PATH:", filePath);
    return JSON.parse(fileContents);
  }

  return null;
};

export const initFirebase = () => {
  if (firebaseInitialized) return admin.app();

  if (admin.apps.length > 0) {
    firebaseInitialized = true;
    debugLog("Firebase already initialized (admin.apps > 0)");
    return admin.app();
  }

  const serviceAccount = loadServiceAccountFromEnv();
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    debugLog("Firebase initialized with service account");
  } else {
    admin.initializeApp({
      credential: admin.credential.applicationDefault()
    });
    debugLog("Firebase initialized with applicationDefault()");
  }

  firebaseInitialized = true;
  return admin.app();
};

export const normalizeDataPayload = (data = {}) => {
  const payload = {};

  Object.entries(data || {}).forEach(([key, value]) => {
    if (value === undefined) return;
    if (value === null) {
      payload[key] = "";
      return;
    }
    if (typeof value === "string") {
      payload[key] = value;
      return;
    }
    if (typeof value === "number" || typeof value === "boolean") {
      payload[key] = String(value);
      return;
    }
    try {
      payload[key] = JSON.stringify(value);
    } catch (_err) {
      payload[key] = String(value);
    }
  });

  return payload;
};

export const sendToTopic = async (topic, message = {}) => {
  if (!topic) {
    return { success: false };
  }

  if (process.env.NOTIFICATION_FIREBASE_ENABLED === "false") {
    return { success: false };
  }

  initFirebase();

  try {
    debugLog("sendToTopic", { topic });
    const messageId = await admin.messaging().send({
      topic,
      ...message
    });
    debugLog("sendToTopic success", { topic, messageId });
    return { success: true, messageId };
  } catch (error) {
    debugLog("sendToTopic error", {
      topic,
      message: error?.message,
      code: error?.code
    });
    console.error("Firebase topic send error:", error);
    return { success: false, error };
  }
};

export const subscribeToTopics = async (tokens = [], topics = []) => {
  if (!Array.isArray(tokens) || tokens.length === 0) return;
  if (!Array.isArray(topics) || topics.length === 0) return;
  if (process.env.NOTIFICATION_FIREBASE_ENABLED === "false") return;

  initFirebase();

  const uniqueTokens = Array.from(new Set(tokens.filter(Boolean)));

  for (const topic of topics) {
    if (!topic) continue;
    for (let i = 0; i < uniqueTokens.length; i += TOPIC_BATCH_SIZE) {
      const chunk = uniqueTokens.slice(i, i + TOPIC_BATCH_SIZE);
      try {
        debugLog("subscribeToTopics", {
          topic,
          tokens: chunk.length
        });
        await admin.messaging().subscribeToTopic(chunk, topic);
      } catch (error) {
        debugLog("subscribeToTopics error", {
          topic,
          message: error?.message,
          code: error?.code
        });
        console.error(`Firebase subscribe error for topic ${topic}:`, error);
      }
    }
  }
};

export const unsubscribeFromTopics = async (tokens = [], topics = []) => {
  if (!Array.isArray(tokens) || tokens.length === 0) return;
  if (!Array.isArray(topics) || topics.length === 0) return;
  if (process.env.NOTIFICATION_FIREBASE_ENABLED === "false") return;

  initFirebase();

  const uniqueTokens = Array.from(new Set(tokens.filter(Boolean)));

  for (const topic of topics) {
    if (!topic) continue;
    for (let i = 0; i < uniqueTokens.length; i += TOPIC_BATCH_SIZE) {
      const chunk = uniqueTokens.slice(i, i + TOPIC_BATCH_SIZE);
      try {
        debugLog("unsubscribeFromTopics", {
          topic,
          tokens: chunk.length
        });
        await admin.messaging().unsubscribeFromTopic(chunk, topic);
      } catch (error) {
        debugLog("unsubscribeFromTopics error", {
          topic,
          message: error?.message,
          code: error?.code
        });
        console.error(`Firebase unsubscribe error for topic ${topic}:`, error);
      }
    }
  }
};

export const sendToTokens = async (tokens = [], message = {}) => {
  if (!Array.isArray(tokens) || tokens.length === 0) {
    debugLog("sendToTokens skipped: empty token list");
    return { successCount: 0, failureCount: 0, invalidTokens: [], tokenResults: [] };
  }

  if (process.env.NOTIFICATION_FIREBASE_ENABLED === "false") {
    debugLog("sendToTokens skipped: NOTIFICATION_FIREBASE_ENABLED=false");
    return { successCount: 0, failureCount: 0, invalidTokens: [], tokenResults: [] };
  }

  initFirebase();

  const uniqueTokens = Array.from(new Set(tokens.filter(Boolean)));
  const batchSize = 500;

  let successCount = 0;
  let failureCount = 0;
  const invalidTokens = [];
  const tokenResults = [];

  debugLog("sendToTokens", {
    tokens: uniqueTokens.length,
    batchSize
  });

  for (let i = 0; i < uniqueTokens.length; i += batchSize) {
    const chunk = uniqueTokens.slice(i, i + batchSize);

    try {
      debugLog("sendEachForMulticast chunk", {
        index: Math.floor(i / batchSize) + 1,
        size: chunk.length
      });
      const response = await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        ...message
      });

      successCount += response.successCount;
      failureCount += response.failureCount;

      debugLog("sendEachForMulticast result", {
        successCount: response.successCount,
        failureCount: response.failureCount
      });

      if (NOTIFICATION_DEBUG && response.failureCount > 0) {
        const errorSummary = {};
        const errorSamples = [];
        response.responses.forEach((res, idx) => {
          if (res.success) return;
          const code = res.error?.code || "unknown";
          errorSummary[code] = (errorSummary[code] || 0) + 1;
          if (errorSamples.length < 5) {
            errorSamples.push({
              code,
              message: res.error?.message || "",
              tokenSuffix: String(chunk[idx]).slice(-12)
            });
          }
        });
        debugLog("sendEachForMulticast errors", {
          summary: errorSummary,
          samples: errorSamples
        });
      }

      response.responses.forEach((res, idx) => {
        const token = chunk[idx];
        tokenResults.push({
          token,
          success: !!res.success,
          code: res.success ? null : res.error?.code || "unknown"
        });

        if (res.success) return;
        const code = res.error?.code || "";
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(chunk[idx]);
        }
      });
    } catch (error) {
      debugLog("sendEachForMulticast error", {
        message: error?.message,
        code: error?.code
      });
      console.error("Firebase multicast error:", error);
      failureCount += chunk.length;
    }
  }

  debugLog("sendToTokens summary", {
    successCount,
    failureCount,
    invalidTokens: invalidTokens.length
  });

  return { successCount, failureCount, invalidTokens, tokenResults };
};
