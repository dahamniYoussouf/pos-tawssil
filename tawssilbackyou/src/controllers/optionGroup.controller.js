import * as optionGroupService from "../services/optionGroup.service.js";

const resolveRestaurantId = (req) => {
  if (req.user.role === "admin") {
    const candidate =
      req.body?.restaurant_id || req.query?.restaurant_id;
    if (!candidate) {
      const error = new Error("restaurant_id is required for admin operations");
      error.status = 400;
      throw error;
    }
    return candidate;
  }

  if (!req.user.restaurant_id) {
    const error = new Error("Restaurant ID not found in token");
    error.status = 403;
    throw error;
  }

  return req.user.restaurant_id;
};

export const create = async (req, res, next) => {
  try {
    const restaurant_id = resolveRestaurantId(req);
    const optionGroup = await optionGroupService.createOptionGroup(req.body, restaurant_id);
    res.status(201).json({ success: true, data: optionGroup });
  } catch (err) {
    const status = err.status || 500;
    res.status(status).json({ success: false, message: err.message || "Failed to create option group" });
  }
};

export const update = async (req, res, next) => {
  try {
    const restaurant_id = resolveRestaurantId(req);
    const updated = await optionGroupService.updateOptionGroup(req.params.id, req.body, restaurant_id);
    res.json({ success: true, data: updated });
  } catch (err) {
    const status = err.status || 500;
    res.status(status).json({ success: false, message: err.message || "Failed to update option group" });
  }
};

export const remove = async (req, res, next) => {
  try {
    const restaurant_id = resolveRestaurantId(req);
    const result = await optionGroupService.deleteOptionGroup(req.params.id, restaurant_id);
    res.json({ success: true, data: result });
  } catch (err) {
    const status = err.status || 500;
    res.status(status).json({ success: false, message: err.message || "Failed to delete option group" });
  }
};

export const getByMenuItem = async (req, res, next) => {
  try {
    const restaurant_id = resolveRestaurantId(req);
    const groups = await optionGroupService.getOptionGroupsByMenuItem(req.params.menu_item_id, restaurant_id);
    res.json({ success: true, data: groups });
  } catch (err) {
    const status = err.status || 500;
    res.status(status).json({ success: false, message: err.message || "Failed to fetch option groups" });
  }
};
