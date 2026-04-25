import Addition from "../models/Addition.js";
import MenuItem from "../models/MenuItem.js";
import FoodCategory from "../models/FoodCategory.js";
import OptionGroup from "../models/OptionGroup.js";

// Ensure menu item belongs to restaurant
async function ensureMenuItemOwnership(menu_item_id, restaurant_id, options = {}) {
  const menuItem = await MenuItem.findOne({
    where: { id: menu_item_id },
    include: [{
      model: FoodCategory,
      as: "category",
      attributes: ["restaurant_id"]
    }],
    transaction: options.transaction
  });

  if (!menuItem) {
    throw { status: 404, message: "Menu item not found" };
  }

  if (restaurant_id && menuItem.category.restaurant_id !== restaurant_id) {
    throw { status: 403, message: "Menu item does not belong to your restaurant" };
  }

  return menuItem;
}

export async function createAddition(data, restaurant_id, options = {}) {
  let {
    id,
    menu_item_id,
    option_group_id,
    nom,
    description,
    prix,
    is_available = true
  } = data;

  if (option_group_id) {
    const optionGroup = await OptionGroup.findByPk(option_group_id, {
      attributes: ["id", "menu_item_id"],
      transaction: options.transaction
    });
    if (!optionGroup) {
      throw { status: 404, message: "Option group not found" };
    }
    if (menu_item_id && String(menu_item_id) !== String(optionGroup.menu_item_id)) {
      throw { status: 400, message: "Option group does not belong to this menu item" };
    }
    menu_item_id = optionGroup.menu_item_id;
  }

  await ensureMenuItemOwnership(menu_item_id, restaurant_id, options);

  return await Addition.create({
    ...(id ? { id } : {}),
    menu_item_id,
    option_group_id: option_group_id || null,
    nom,
    description,
    prix,
    is_available
  }, {
    transaction: options.transaction
  });
}

export async function updateAddition(id, updates, restaurant_id, options = {}) {
  const addition = await Addition.findByPk(id, {
    include: [{
      model: MenuItem,
      as: "menu_item",
      include: [{
        model: FoodCategory,
        as: "category",
        attributes: ["restaurant_id"]
      }]
    }],
    transaction: options.transaction
  });

  if (!addition) throw { status: 404, message: "Addition not found" };

  if (restaurant_id && addition.menu_item.category.restaurant_id !== restaurant_id) {
    throw { status: 403, message: "Addition does not belong to your restaurant" };
  }

  if (updates.option_group_id) {
    const optionGroup = await OptionGroup.findByPk(updates.option_group_id, {
      attributes: ["id", "menu_item_id"],
      transaction: options.transaction
    });
    if (!optionGroup) {
      throw { status: 404, message: "Option group not found" };
    }
    const targetMenuItemId = updates.menu_item_id || addition.menu_item_id;
    if (String(optionGroup.menu_item_id) !== String(targetMenuItemId)) {
      throw { status: 400, message: "Option group does not belong to this menu item" };
    }
  }

  if (updates.menu_item_id && updates.menu_item_id !== addition.menu_item_id) {
    await ensureMenuItemOwnership(updates.menu_item_id, restaurant_id, options);
  }

  await addition.update(updates, {
    transaction: options.transaction
  });
  return addition;
}

export async function deleteAddition(id, restaurant_id, options = {}) {
  const addition = await Addition.findByPk(id, {
    include: [{
      model: MenuItem,
      as: "menu_item",
      include: [{
        model: FoodCategory,
        as: "category",
        attributes: ["restaurant_id"]
      }]
    }],
    transaction: options.transaction
  });

  if (!addition) throw { status: 404, message: "Addition not found" };

  if (restaurant_id && addition.menu_item.category.restaurant_id !== restaurant_id) {
    throw { status: 403, message: "Addition does not belong to your restaurant" };
  }

  await addition.destroy({
    transaction: options.transaction
  });
  return { message: "Addition deleted successfully" };
}

export async function getAdditionsByMenuItem(menu_item_id, restaurant_id) {
  await ensureMenuItemOwnership(menu_item_id, restaurant_id);
  return await Addition.findAll({
    where: { menu_item_id },
    order: [["created_at", "DESC"]]
  });
}

export async function getAdditionById(id, restaurant_id) {
  const addition = await Addition.findByPk(id, {
    include: [{
      model: MenuItem,
      as: "menu_item",
      include: [{ model: FoodCategory, as: "category", attributes: ["restaurant_id"] }]
    }]
  });

  if (!addition) throw { status: 404, message: "Addition not found" };
  if (restaurant_id && addition.menu_item.category.restaurant_id !== restaurant_id) {
    throw { status: 403, message: "Addition does not belong to your restaurant" };
  }
  return addition;
}
