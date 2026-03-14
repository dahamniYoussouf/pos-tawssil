import OptionGroup from "../models/OptionGroup.js";
import MenuItem from "../models/MenuItem.js";
import FoodCategory from "../models/FoodCategory.js";
import Addition from "../models/Addition.js";

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

export async function createOptionGroup(data, restaurant_id, options = {}) {
  const {
    id,
    menu_item_id,
    nom,
    description,
    is_required = false,
    ordre_affichage = 0
  } = data;

  await ensureMenuItemOwnership(menu_item_id, restaurant_id, options);

  return await OptionGroup.create({
    ...(id ? { id } : {}),
    menu_item_id,
    nom,
    description,
    is_required,
    ordre_affichage
  }, {
    transaction: options.transaction
  });
}

export async function updateOptionGroup(id, updates, restaurant_id, options = {}) {
  const optionGroup = await OptionGroup.findByPk(id, {
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

  if (!optionGroup) throw { status: 404, message: "Option group not found" };

  if (restaurant_id && optionGroup.menu_item.category.restaurant_id !== restaurant_id) {
    throw { status: 403, message: "Option group does not belong to your restaurant" };
  }

  if (updates.menu_item_id && updates.menu_item_id !== optionGroup.menu_item_id) {
    await ensureMenuItemOwnership(updates.menu_item_id, restaurant_id, options);
  }

  await optionGroup.update(updates, {
    transaction: options.transaction
  });
  return optionGroup;
}

export async function deleteOptionGroup(id, restaurant_id, options = {}) {
  const optionGroup = await OptionGroup.findByPk(id, {
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

  if (!optionGroup) throw { status: 404, message: "Option group not found" };

  if (restaurant_id && optionGroup.menu_item.category.restaurant_id !== restaurant_id) {
    throw { status: 403, message: "Option group does not belong to your restaurant" };
  }

  await optionGroup.destroy({
    transaction: options.transaction
  });
  return { message: "Option group deleted successfully" };
}

export async function getOptionGroupsByMenuItem(menu_item_id, restaurant_id) {
  await ensureMenuItemOwnership(menu_item_id, restaurant_id);
  return await OptionGroup.findAll({
    where: { menu_item_id },
    include: [{
      model: Addition,
      as: "options",
      attributes: ["id", "nom", "description", "prix", "is_available", "option_group_id"]
    }],
    order: [
      ["ordre_affichage", "ASC"],
      ["created_at", "DESC"]
    ]
  });
}

export async function getOptionGroupById(id, restaurant_id) {
  const optionGroup = await OptionGroup.findByPk(id, {
    include: [{
      model: MenuItem,
      as: "menu_item",
      include: [{ model: FoodCategory, as: "category", attributes: ["restaurant_id"] }]
    }, {
      model: Addition,
      as: "options",
      attributes: ["id", "nom", "description", "prix", "is_available", "option_group_id"]
    }]
  });

  if (!optionGroup) throw { status: 404, message: "Option group not found" };
  if (restaurant_id && optionGroup.menu_item.category.restaurant_id !== restaurant_id) {
    throw { status: 403, message: "Option group does not belong to your restaurant" };
  }
  return optionGroup;
}
