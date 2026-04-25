import RestaurantPrinter from "../models/RestaurantPrinter.js";
import Restaurant from "../models/Restaurant.js";

/**
 * GET /restaurant/admin/printers/:restaurantId
 * Liste les imprimantes d'un restaurant (admin).
 */
export const listByRestaurant = async (req, res, next) => {
  try {
    const { restaurantId } = req.params;
    const printers = await RestaurantPrinter.findAll({
      where: { restaurant_id: restaurantId },
      order: [["created_at", "ASC"]],
      raw: true,
    });
    res.json({ success: true, data: printers });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /restaurant/printers/:id
 */
export const removeForMyRestaurant = async (req, res, next) => {
  try {
    const restaurantId = req.user?.restaurant_id;
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant non trouve dans le token",
      });
    }
    const { id } = req.params;
    const p = await RestaurantPrinter.findByPk(id);
    if (!p || p.restaurant_id !== restaurantId) {
      return res.status(404).json({ success: false, message: "Imprimante introuvable" });
    }
    await p.destroy();
    res.json({ success: true, message: "Imprimante supprimÃ©e" });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /restaurant/printers
 * Liste les imprimantes du restaurant authentifie.
 */
export const listMyRestaurant = async (req, res, next) => {
  try {
    const restaurantId = req.user?.restaurant_id;
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant non trouve dans le token",
      });
    }
    const printers = await RestaurantPrinter.findAll({
      where: { restaurant_id: restaurantId },
      order: [["created_at", "ASC"]],
      raw: true,
    });
    res.json({ success: true, data: printers });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /restaurant/printers
 * Body: { name, type, ip, port?, is_enabled?, paper_width_mm? }
 */
export const createForMyRestaurant = async (req, res, next) => {
  try {
    const restaurantId = req.user?.restaurant_id;
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant non trouve dans le token",
      });
    }
    const { name, type, ip, port, is_enabled, paper_width_mm } = req.body;
    if (!name || !ip || !String(ip).trim()) {
      return res.status(400).json({
        success: false,
        message: "name et ip sont requis",
      });
    }
    const exists = await Restaurant.findByPk(restaurantId, { attributes: ["id"] });
    if (!exists) {
      return res.status(404).json({ success: false, message: "Restaurant introuvable" });
    }
    const p = await RestaurantPrinter.create({
      restaurant_id: restaurantId,
      name: String(name).trim(),
      type: ["general", "caisse", "cuisine", "bar"].includes(String(type || "").toLowerCase())
        ? String(type).toLowerCase()
        : "general",
      ip: String(ip).trim(),
      port: port != null && Number.isFinite(Number(port)) ? Math.max(1, Math.min(65535, Number(port))) : 9100,
      is_enabled: is_enabled !== false,
      paper_width_mm: [58, 80].includes(Number(paper_width_mm)) ? Number(paper_width_mm) : 80,
    });
    res.status(201).json({ success: true, data: p.toJSON ? p.toJSON() : p });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /restaurant/admin/printers
 * Body: { restaurant_id, name, type, ip, port?, is_enabled?, paper_width_mm? }
 */
export const create = async (req, res, next) => {
  try {
    const { restaurant_id, name, type, ip, port, is_enabled, paper_width_mm } = req.body;
    if (!restaurant_id || !name || !ip || !String(ip).trim()) {
      return res.status(400).json({
        success: false,
        message: "restaurant_id, name et ip sont requis",
      });
    }
    const exists = await Restaurant.findByPk(restaurant_id, { attributes: ["id"] });
    if (!exists) {
      return res.status(404).json({ success: false, message: "Restaurant introuvable" });
    }
    const p = await RestaurantPrinter.create({
      restaurant_id,
      name: String(name).trim(),
      type: ["general", "caisse", "cuisine", "bar"].includes(String(type || "").toLowerCase())
        ? String(type).toLowerCase()
        : "general",
      ip: String(ip).trim(),
      port: port != null && Number.isFinite(Number(port)) ? Math.max(1, Math.min(65535, Number(port))) : 9100,
      is_enabled: is_enabled !== false,
      paper_width_mm: [58, 80].includes(Number(paper_width_mm)) ? Number(paper_width_mm) : 80,
    });
    res.status(201).json({ success: true, data: p.toJSON ? p.toJSON() : p });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /restaurant/admin/printers/:id
 */
export const update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const p = await RestaurantPrinter.findByPk(id);
    if (!p) {
      return res.status(404).json({ success: false, message: "Imprimante introuvable" });
    }
    const { name, type, ip, port, is_enabled, paper_width_mm } = req.body;
    if (ip !== undefined && !String(ip).trim()) {
      return res.status(400).json({
        success: false,
        message: "ip ne peut pas etre vide",
      });
    }
    if (name !== undefined) p.name = String(name).trim();
    if (type !== undefined) {
      p.type = ["general", "caisse", "cuisine"].includes(String(type || "").toLowerCase())
        ? String(type).toLowerCase()
        : p.type;
    }
    if (ip !== undefined) p.ip = String(ip).trim();
    if (port !== undefined && Number.isFinite(Number(port))) {
      p.port = Math.max(1, Math.min(65535, Number(port)));
    }
    if (is_enabled !== undefined) {
      if (!!is_enabled && !String(p.ip || "").trim()) {
        return res.status(400).json({
          success: false,
          message: "Impossible d'activer une imprimante sans ip",
        });
      }
      p.is_enabled = !!is_enabled;
    }
    if (paper_width_mm !== undefined && [58, 80].includes(Number(paper_width_mm))) {
      p.paper_width_mm = Number(paper_width_mm);
    }
    await p.save();
    res.json({ success: true, data: p.toJSON ? p.toJSON() : p });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /restaurant/printers/:id
 */
export const updateForMyRestaurant = async (req, res, next) => {
  try {
    const restaurantId = req.user?.restaurant_id;
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant non trouve dans le token",
      });
    }
    const { id } = req.params;
    const p = await RestaurantPrinter.findByPk(id);
    if (!p || p.restaurant_id !== restaurantId) {
      return res.status(404).json({ success: false, message: "Imprimante introuvable" });
    }
    const { name, type, ip, port, is_enabled, paper_width_mm } = req.body;
    if (ip !== undefined && !String(ip).trim()) {
      return res.status(400).json({
        success: false,
        message: "ip ne peut pas etre vide",
      });
    }
    if (name !== undefined) p.name = String(name).trim();
    if (type !== undefined) {
      p.type = ["general", "caisse", "cuisine", "bar"].includes(String(type || "").toLowerCase())
        ? String(type).toLowerCase()
        : p.type;
    }
    if (ip !== undefined) p.ip = String(ip).trim();
    if (port !== undefined && Number.isFinite(Number(port))) {
      p.port = Math.max(1, Math.min(65535, Number(port)));
    }
    if (is_enabled !== undefined) {
      if (!!is_enabled && !String(p.ip || "").trim()) {
        return res.status(400).json({
          success: false,
          message: "Impossible d'activer une imprimante sans ip",
        });
      }
      p.is_enabled = !!is_enabled;
    }
    if (paper_width_mm !== undefined && [58, 80].includes(Number(paper_width_mm))) {
      p.paper_width_mm = Number(paper_width_mm);
    }
    await p.save();
    res.json({ success: true, data: p.toJSON ? p.toJSON() : p });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /restaurant/admin/printers/:id
 */
export const remove = async (req, res, next) => {
  try {
    const { id } = req.params;
    const p = await RestaurantPrinter.findByPk(id);
    if (!p) {
      return res.status(404).json({ success: false, message: "Imprimante introuvable" });
    }
    await p.destroy();
    res.json({ success: true, message: "Imprimante supprimée" });
  } catch (err) {
    next(err);
  }
};

