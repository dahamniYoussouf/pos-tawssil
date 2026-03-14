import { Op } from "sequelize";
import { sequelize } from "../config/database.js";
import MenuItem from "../models/MenuItem.js";
import Addition from "../models/Addition.js";
import OptionGroup from "../models/OptionGroup.js";
import FoodCategory from "../models/FoodCategory.js";
import Restaurant from "../models/Restaurant.js";
import FavoriteMeal from "../models/FavoriteMeal.js";
import { buildClientVisibleRestaurantWhere } from "../utils/restaurantVisibility.js";
import * as optionGroupService from "./optionGroup.service.js";
import * as additionService from "./addition.service.js";

const MENU_ITEM_ATTRIBUTES = [
  "category_id",
  "nom",
  "description",
  "prix",
  "photo_url",
  "temps_preparation",
  "is_available"
];

function hasOwnProperty(target, key) {
  return Object.prototype.hasOwnProperty.call(target, key);
}

function pickMenuItemPayload(data = {}) {
  return MENU_ITEM_ATTRIBUTES.reduce((payload, field) => {
    if (hasOwnProperty(data, field)) {
      payload[field] = data[field];
    }
    return payload;
  }, {});
}

function getNestedPayload(data = {}) {
  return {
    additions: hasOwnProperty(data, "additions")
      ? data.additions
      : hasOwnProperty(data, "options")
        ? data.options
        : undefined,
    option_groups: hasOwnProperty(data, "option_groups")
      ? data.option_groups
      : hasOwnProperty(data, "group_options")
        ? data.group_options
        : undefined
  };
}

function hasNestedField(target, key) {
  return target && typeof target === "object" && hasOwnProperty(target, key);
}

function getGroupOptionsPayload(group = {}) {
  if (hasNestedField(group, "options")) {
    return group.options;
  }
  if (hasNestedField(group, "additions")) {
    return group.additions;
  }
  return undefined;
}

function hasGroupOptionsPayload(group = {}) {
  return hasNestedField(group, "options") || hasNestedField(group, "additions");
}

function buildMenuItemInclude({ clientVisibleOnly = false } = {}) {
  return [
    { model: FoodCategory, as: "category" },
    {
      model: Restaurant,
      as: "restaurant",
      ...(clientVisibleOnly
        ? {
            required: true,
            where: buildClientVisibleRestaurantWhere()
          }
        : {})
    },
    {
      model: Addition,
      as: "additions",
      attributes: ["id", "nom", "description", "prix", "is_available", "option_group_id"]
    },
    {
      model: OptionGroup,
      as: "option_groups",
      attributes: ["id", "nom", "description", "is_required", "ordre_affichage"],
      include: [{
        model: Addition,
        as: "options",
        attributes: ["id", "nom", "description", "prix", "is_available", "option_group_id"]
      }]
    }
  ];
}

async function getMenuItemDetails(id, { clientVisibleOnly = false, transaction } = {}) {
  const item = await MenuItem.findByPk(id, {
    include: buildMenuItemInclude({ clientVisibleOnly }),
    transaction
  });

  if (!item) {
    throw { status: 404, message: "Menu item not found" };
  }

  return item;
}

async function upsertNestedMenuItemData(menuItemId, restaurantId, nestedPayload, transaction) {
  if (Array.isArray(nestedPayload.option_groups)) {
    const existingGroups = await OptionGroup.findAll({
      where: { menu_item_id: menuItemId },
      attributes: ["id"],
      transaction
    });
    const processedGroupIds = new Set();

    for (const rawGroup of nestedPayload.option_groups) {
      const { id, ...groupPayload } = rawGroup || {};
      const groupId = id ? String(id) : null;
      const optionGroupPayload = {
        ...groupPayload,
        menu_item_id: menuItemId
      };

      let optionGroup;
      if (groupId) {
        try {
          optionGroup = await optionGroupService.updateOptionGroup(id, optionGroupPayload, restaurantId, { transaction });
        } catch (error) {
          if (error?.status !== 404) {
            throw error;
          }
          optionGroup = await optionGroupService.createOptionGroup({
            id,
            ...optionGroupPayload
          }, restaurantId, { transaction });
        }
      } else {
        optionGroup = await optionGroupService.createOptionGroup(optionGroupPayload, restaurantId, { transaction });
      }

      processedGroupIds.add(String(optionGroup.id));

      if (hasGroupOptionsPayload(rawGroup)) {
        const groupOptions = getGroupOptionsPayload(rawGroup);
        const existingOptions = await Addition.findAll({
          where: {
            menu_item_id: menuItemId,
            option_group_id: optionGroup.id
          },
          attributes: ["id"],
          transaction
        });
        const processedOptionIds = new Set();

        for (const rawOption of Array.isArray(groupOptions) ? groupOptions : []) {
          const { id: optionId, ...optionPayload } = rawOption || {};
          const normalizedOptionId = optionId ? String(optionId) : null;
          const additionPayload = {
            ...optionPayload,
            menu_item_id: menuItemId,
            option_group_id: optionGroup.id
          };

          let syncedOption;
          if (normalizedOptionId) {
            try {
              syncedOption = await additionService.updateAddition(optionId, additionPayload, restaurantId, { transaction });
            } catch (error) {
              if (error?.status !== 404) {
                throw error;
              }
              syncedOption = await additionService.createAddition({
                id: optionId,
                ...additionPayload
              }, restaurantId, { transaction });
            }
          } else {
            syncedOption = await additionService.createAddition(additionPayload, restaurantId, { transaction });
          }

          processedOptionIds.add(String(syncedOption.id));
        }

        for (const existingOption of existingOptions) {
          if (!processedOptionIds.has(String(existingOption.id))) {
            await additionService.deleteAddition(existingOption.id, restaurantId, { transaction });
          }
        }
      }
    }

    for (const existingGroup of existingGroups) {
      if (processedGroupIds.has(String(existingGroup.id))) {
        continue;
      }

      const staleGroupAdditions = await Addition.findAll({
        where: {
          menu_item_id: menuItemId,
          option_group_id: existingGroup.id
        },
        attributes: ["id"],
        transaction
      });

      for (const addition of staleGroupAdditions) {
        await additionService.deleteAddition(addition.id, restaurantId, { transaction });
      }

      await optionGroupService.deleteOptionGroup(existingGroup.id, restaurantId, { transaction });
    }
  }

  if (Array.isArray(nestedPayload.additions)) {
    const existingAdditions = await Addition.findAll({
      where: {
        menu_item_id: menuItemId,
        option_group_id: null
      },
      attributes: ["id"],
      transaction
    });
    const processedAdditionIds = new Set();

    for (const rawAddition of nestedPayload.additions) {
      const { id, ...additionPayload } = rawAddition || {};
      const additionId = id ? String(id) : null;
      const payload = {
        ...additionPayload,
        menu_item_id: menuItemId,
        option_group_id: hasOwnProperty(additionPayload, "option_group_id")
          ? additionPayload.option_group_id
          : null
      };

      let syncedAddition;
      if (additionId) {
        try {
          syncedAddition = await additionService.updateAddition(id, payload, restaurantId, { transaction });
        } catch (error) {
          if (error?.status !== 404) {
            throw error;
          }
          syncedAddition = await additionService.createAddition({
            id,
            ...payload
          }, restaurantId, { transaction });
        }
      } else {
        syncedAddition = await additionService.createAddition(payload, restaurantId, { transaction });
      }

      if (!syncedAddition.option_group_id) {
        processedAdditionIds.add(String(syncedAddition.id));
      }
    }

    for (const existingAddition of existingAdditions) {
      if (!processedAdditionIds.has(String(existingAddition.id))) {
        await additionService.deleteAddition(existingAddition.id, restaurantId, { transaction });
      }
    }
  }
}

// CREATE MENU ITEM
export async function createMenuItem(data) {
  const menuItemPayload = pickMenuItemPayload(data);
  const nestedPayload = getNestedPayload(data);

  return await sequelize.transaction(async (transaction) => {
    const category = await FoodCategory.findByPk(menuItemPayload.category_id, { transaction });
    if (!category) throw { status: 404, message: "Category not found" };

    const item = await MenuItem.create({
      restaurant_id: category.restaurant_id,
      ...menuItemPayload,
      temps_preparation: menuItemPayload.temps_preparation || 20,
      is_available: hasOwnProperty(menuItemPayload, "is_available") ? menuItemPayload.is_available : true
    }, { transaction });

    await upsertNestedMenuItemData(item.id, category.restaurant_id, nestedPayload, transaction);

    return await getMenuItemDetails(item.id, { transaction });
  });
}

// GET ALL MENU ITEMS
export async function getAllMenuItems(filters = {}) {
  const {
    page = 1,
    limit = 20,
    category_id,
    restaurant_id,
    is_available,
    search
  } = filters;

  const offset = (page - 1) * limit;
  const where = {};

  if (category_id) {
    where.category_id = category_id;
  }
  if (is_available !== undefined) {
    where.is_available = is_available;
  }
  if (search) {
    where.nom = { [Op.iLike]: `%${search}%` };
  }

  const categoryInclude = {
    model: FoodCategory,
    as: 'category',
    attributes: ['id', 'nom']
  };

  if (restaurant_id) {
    categoryInclude.where = { restaurant_id };
    categoryInclude.required = true;
  }

  const optionGroupInclude = {
    model: OptionGroup,
    as: "option_groups",
    attributes: ["id", "nom", "description", "is_required", "ordre_affichage"],
    include: [{
      model: Addition,
      as: "options",
      attributes: ["id", "nom", "description", "prix", "is_available", "option_group_id"]
    }]
  };

  const include = [
    categoryInclude,
    { model: Restaurant, as: 'restaurant', attributes: ['id', 'name', 'image_url', 'email'] },
    { model: Addition, as: 'additions', attributes: ['id', 'nom', 'description', 'prix', 'is_available', 'option_group_id'] },
    optionGroupInclude
  ];

  const { count, rows } = await MenuItem.findAndCountAll({
    where,
    include,
    order: [['created_at', 'DESC']],
    limit: +limit,
    offset: +offset
  });

  return {
    items: rows,
    pagination: {
      current_page: +page,
      total_pages: Math.ceil(count / limit),
      total_items: count
    }
  };
}

// GET MENU ITEM BY ID
export async function getMenuItemById(id) {
  return await getMenuItemDetails(id, { clientVisibleOnly: true });
}

export async function getMenuItemByIdForManagement(id, options = {}) {
  return await getMenuItemDetails(id, options);
}

// GET MENU ITEMS BY CATEGORY (with favorites support)
export async function getMenuItemsByCategory(filters) {
  const { client_id, category_id, is_available = true } = filters;
  const where = {};

  // Only show available items by default
  if (is_available !== undefined) where.is_available = is_available;
  if (category_id) where.category_id = category_id;

  const items = await MenuItem.findAll({
    where,
    include: [
      { model: FoodCategory, as: "category", attributes: ["id", "nom"] },
      {
        model: Restaurant,
        as: "restaurant",
        required: true,
        where: buildClientVisibleRestaurantWhere(),
        attributes: ["id", "name", "email"]
      },
      { model: Addition, as: "additions", attributes: ["id", "nom", "description", "prix", "is_available", "option_group_id"] },
      {
        model: OptionGroup,
        as: "option_groups",
        attributes: ["id", "nom", "description", "is_required", "ordre_affichage"],
        include: [{
          model: Addition,
          as: "options",
          attributes: ["id", "nom", "description", "prix", "is_available", "option_group_id"]
        }]
      }
    ],
    order: [['nom', 'ASC']]
  });

  // Get user favorites if client_id provided
  const favoritesMap = new Map();
  if (client_id) {
    const favorites = await FavoriteMeal.findAll({
      where: {
        client_id,
        meal_id: { [Op.in]: items.map(i => i.id) }
      },
      attributes: ["meal_id", "id"]
    });

    favorites.forEach(fav => favoritesMap.set(fav.meal_id, fav.id));
  }

  // Format response with favorite status
  const formatted = items.map(item => ({
    ...item.toJSON(),
    is_favorite: favoritesMap.has(item.id),
    favorite_id: favoritesMap.get(item.id) || null
  }));

  return {
    items: formatted,
    count: formatted.length
  };
}


// UPDATE MENU ITEM
export async function updateMenuItem(id, updates) {
  const menuItemPayload = pickMenuItemPayload(updates);
  const nestedPayload = getNestedPayload(updates);

  return await sequelize.transaction(async (transaction) => {
    const item = await MenuItem.findByPk(id, { transaction });
    if (!item) throw { status: 404, message: "Menu item not found" };

    let restaurantId = item.restaurant_id;

    if (menuItemPayload.category_id) {
      const category = await FoodCategory.findByPk(menuItemPayload.category_id, { transaction });
      if (!category) throw { status: 404, message: "Category not found" };
      menuItemPayload.restaurant_id = category.restaurant_id;
      restaurantId = category.restaurant_id;
    }

    if (Object.keys(menuItemPayload).length > 0) {
      await item.update(menuItemPayload, { transaction });
    }

    await upsertNestedMenuItemData(item.id, restaurantId, nestedPayload, transaction);

    return await getMenuItemDetails(id, { transaction });
  });
}

// DELETE MENU ITEM
export async function deleteMenuItem(id) {
  const item = await MenuItem.findByPk(id);
  if (!item) throw { status: 404, message: "Menu item not found" };

  await item.destroy();
  return { message: "Menu item deleted successfully" };
}

// TOGGLE AVAILABILITY
export async function toggleAvailability(id) {
  const item = await MenuItem.findByPk(id);
  if (!item) throw { status: 404, message: "Menu item not found" };

  item.is_available = !item.is_available;
  await item.save();

  return {
    id: item.id,
    nom: item.nom,
    is_available: item.is_available,
    message: `Menu item is now ${item.is_available ? 'available' : 'unavailable'}`
  };
}

// BULK UPDATE AVAILABILITY
export async function bulkUpdateAvailability(menu_item_ids, is_available) {
  const updated = await MenuItem.update(
    { is_available },
    {
      where: { id: { [Op.in]: menu_item_ids } },
      returning: true
    }
  );

  return {
    updated_count: updated[0],
    message: `${updated[0]} items marked as ${is_available ? 'available' : 'unavailable'}`
  };
}
