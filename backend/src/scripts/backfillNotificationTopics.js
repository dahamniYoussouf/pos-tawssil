import sequelize from "../config/database.js";
import DeviceToken from "../models/DeviceToken.js";
import { subscribeToTopics } from "../services/firebaseNotification.service.js";
import { getTopicsForRole } from "../services/notification.service.js";

const groupTokensByTopic = (rows = []) => {
  const topicMap = new Map();

  rows.forEach((row) => {
    const topics = getTopicsForRole(row.role, row.locale);
    topics.forEach((topic) => {
      if (!topic) return;
      const bucket = topicMap.get(topic) || new Set();
      bucket.add(row.token);
      topicMap.set(topic, bucket);
    });
  });

  return topicMap;
};

(async () => {
  try {
    await sequelize.authenticate();

    const rows = await DeviceToken.findAll({
      where: {
        is_active: true
      },
      attributes: ["token", "role", "locale"],
      raw: true
    });

    const topicMap = groupTokensByTopic(rows);
    let subscribedTopics = 0;
    let subscribedTokens = 0;

    for (const [topic, tokens] of topicMap.entries()) {
      const tokenList = Array.from(tokens);
      if (!tokenList.length) continue;
      await subscribeToTopics(tokenList, [topic]);
      subscribedTopics += 1;
      subscribedTokens += tokenList.length;
      console.log(`[TOPIC_BACKFILL] ${topic}: ${tokenList.length} tokens`);
    }

    console.log(
      `[TOPIC_BACKFILL] Completed. topics=${subscribedTopics} token_subscriptions=${subscribedTokens}`
    );
    process.exit(0);
  } catch (error) {
    console.error("[TOPIC_BACKFILL] Failed:", error);
    process.exit(1);
  }
})();
