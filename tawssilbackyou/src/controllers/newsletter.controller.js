import { Op } from "sequelize";
import NewsletterSubscriber from "../models/NewsletterSubscriber.js";
import { normalizeLocale } from "../utils/locale.js";

const normalizeEmail = (value) => String(value || "").trim().toLowerCase();

const extractIp = (req) => {
  const forwarded = req.headers["x-forwarded-for"];
  if (forwarded) {
    return String(forwarded).split(",")[0].trim();
  }
  return req.ip || null;
};

export const subscribeNewsletter = async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    const name = req.body.name ? String(req.body.name).trim() : null;
    const source = req.body.source ? String(req.body.source).trim() : "landing";
    const locale = normalizeLocale(req.body.locale);

    const ipAddress = extractIp(req);
    const userAgent = req.headers["user-agent"] ? String(req.headers["user-agent"]).slice(0, 255) : null;

    const existing = await NewsletterSubscriber.findOne({ where: { email } });

    if (existing) {
      const updates = {};
      if (existing.status === "unsubscribed") {
        updates.status = "subscribed";
        updates.unsubscribed_at = null;
      }
      if (name) updates.name = name;
      if (source) updates.source = source;
      if (locale) updates.locale = locale;
      updates.ip_address = ipAddress;
      updates.user_agent = userAgent;

      if (Object.keys(updates).length) {
        await existing.update(updates);
      }

      return res.status(200).json({
        success: true,
        message: existing.status === "unsubscribed" ? "Subscription reactivated" : "Already subscribed",
        data: {
          id: existing.id,
          email: existing.email,
          status: updates.status || existing.status
        }
      });
    }

    const subscriber = await NewsletterSubscriber.create({
      email,
      name,
      locale,
      source,
      status: "subscribed",
      ip_address: ipAddress,
      user_agent: userAgent
    });

    res.status(201).json({
      success: true,
      message: "Subscribed successfully",
      data: {
        id: subscriber.id,
        email: subscriber.email,
        status: subscriber.status
      }
    });
  } catch (err) {
    next(err);
  }
};

export const unsubscribeNewsletter = async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body.email);
    const subscriber = await NewsletterSubscriber.findOne({ where: { email } });

    if (!subscriber) {
      return res.status(404).json({
        success: false,
        message: "Subscriber not found"
      });
    }

    if (subscriber.status === "unsubscribed") {
      return res.json({
        success: true,
        message: "Already unsubscribed"
      });
    }

    await subscriber.update({
      status: "unsubscribed",
      unsubscribed_at: new Date()
    });

    res.json({
      success: true,
      message: "Unsubscribed successfully"
    });
  } catch (err) {
    next(err);
  }
};

export const listNewsletterSubscribers = async (req, res, next) => {
  try {
    const page = Math.max(parseInt(req.query.page || "1", 10), 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit || "50", 10), 1), 500);
    const offset = (page - 1) * limit;

    const where = {};
    const status = req.query.status ? String(req.query.status) : null;
    if (status === "subscribed" || status === "unsubscribed") {
      where.status = status;
    }

    const q = req.query.q ? String(req.query.q).trim() : "";
    if (q) {
      where[Op.or] = [
        { email: { [Op.iLike]: `%${q}%` } },
        { name: { [Op.iLike]: `%${q}%` } }
      ];
    }

    const { count, rows } = await NewsletterSubscriber.findAndCountAll({
      where,
      order: [["created_at", "DESC"]],
      limit,
      offset
    });

    res.json({
      success: true,
      page,
      limit,
      count,
      data: rows
    });
  } catch (err) {
    next(err);
  }
};
