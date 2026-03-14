// src/controllers/homepage.controller.js
import * as restaurantService from "../services/restaurant.service.js";
import { getHomepageModules } from "../services/homepage.service.js";

const normalizeCategories = (categories) => {
  if (!categories) return undefined;
  if (Array.isArray(categories)) return categories;
  if (typeof categories === "string") {
    return categories.split(',').map((item) => item.trim()).filter(Boolean);
  }
  return undefined;
};

const parseNumberParam = (value) => {
  if (value === undefined || value === null) return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
};

const parseIntegerParam = (value) => {
  if (value === undefined || value === null) return undefined;
  const parsed = parseInt(value, 10);
  return Number.isInteger(parsed) ? parsed : undefined;
};

const roundMoney = (value) => Number(Number(value ?? 0).toFixed(2));

const toDecimal = (value) => {
  if (value === null || value === undefined || Number.isNaN(Number(value))) {
    return 0;
  }
  return Number(value);
};

const computePromotionPrice = (basePrice, promotion) => {
  const discountValue = toDecimal(promotion?.discount_value);
  let newPrice = basePrice;

  if (promotion?.type === "percentage" && discountValue > 0) {
    newPrice = basePrice * (1 - discountValue / 100);
  } else if (promotion?.type === "amount" && discountValue > 0) {
    newPrice = basePrice - discountValue;
  }

  if (newPrice < 0) newPrice = 0;
  return roundMoney(newPrice);
};

const getPromotionMenuItem = (promo = {}) => {
  if (promo?.menu_item && typeof promo.menu_item === "object") {
    return promo.menu_item;
  }
  if (Array.isArray(promo?.menu_items) && promo.menu_items.length > 0) {
    const [first] = promo.menu_items;
    return first && typeof first === "object" ? first : null;
  }
  return null;
};

const nowNs = () => process.hrtime.bigint();
const msSince = (start) => Number(process.hrtime.bigint() - start) / 1e6;
const roundMs = (value) => Math.round(value * 10) / 10;

const setTimingHeaders = (res, label, timings) => {
  const headerValue = Object.entries(timings)
    .filter(([, value]) => Number.isFinite(value))
    .map(([name, value]) => `${name};dur=${value.toFixed(1)}`)
    .join(", ");

  if (headerValue) {
    res.set("Server-Timing", headerValue);
  }

  if (process.env.HOME_TIMING_LOG === "true") {
    const payload = { route: label };
    Object.entries(timings).forEach(([key, value]) => {
      if (Number.isFinite(value)) {
        payload[key] = roundMs(value);
      }
    });
    console.info("homepage_timing", payload);
  }
};

const DEFAULT_HOME_COORDS = { lat: 36.747385, lng: 6.27404 };
const DEFAULT_RADIUS = 5000;
const DEFAULT_PAGE = 1;
const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;

const buildNearbyFilters = (source = {}) => {
  const lat = parseNumberParam(source.lat);
  const lng = parseNumberParam(source.lng);
  const address = typeof source.address === "string" && source.address.trim()
    ? source.address.trim()
    : undefined;
  const radius = parseIntegerParam(source.radius) || DEFAULT_RADIUS;
  const pageRaw = parseIntegerParam(source.page);
  const pageSizeRaw = parseIntegerParam(source.pageSize);
  const page = Math.max(DEFAULT_PAGE, pageRaw || DEFAULT_PAGE);
  const pageSize = Math.min(MAX_PAGE_SIZE, Math.max(1, pageSizeRaw || DEFAULT_PAGE_SIZE));
  const q = typeof source.q === "string" && source.q.trim() ? source.q.trim() : undefined;
  const categories = normalizeCategories(source.categories);
  const homeCategories = source.home_categories;

  const filters = {
    radius,
    client_id: source.client_id ?? null,
    page,
    pageSize
  };

  if (address) {
    filters.address = address;
  } else {
    filters.lat = lat ?? DEFAULT_HOME_COORDS.lat;
    filters.lng = lng ?? DEFAULT_HOME_COORDS.lng;
  }

  if (q) {
    filters.q = q;
  }

  if (categories?.length) {
    filters.categories = categories;
  }

  if (homeCategories !== undefined) {
    filters.home_categories = homeCategories;
  }

  return filters;
};

const buildNearbyResponse = (nearby, dataOverride) => ({
  count: nearby.count,
  page: nearby.page,
  pageSize: nearby.pageSize,
  radius: nearby.radius,
  center: nearby.center,
  searchType: nearby.searchType,
  data: dataOverride ?? nearby.formatted
});

const simplifyPromotionForRestaurant = (promo = {}) => {
  const menuItemIds = Array.isArray(promo.menu_items)
    ? promo.menu_items
        .map((item) => item?.id ?? item?.menu_item_id ?? item)
        .filter(Boolean)
    : [];
  const menuItem = getPromotionMenuItem(promo);
  const hasPrice = menuItem && menuItem.prix !== null && menuItem.prix !== undefined
    && !Number.isNaN(Number(menuItem.prix));
  const basePrice = hasPrice ? toDecimal(menuItem.prix) : null;

  return {
    id: promo.id,
    title: promo.title,
    description: promo.description,
    type: promo.type,
    scope: promo.scope,
    restaurant_id: promo.restaurant_id,
    menu_item_id: promo.menu_item_id ?? null,
    menu_item_ids: menuItemIds.length ? menuItemIds : undefined,
    item_name: menuItem?.nom ?? null,
    item_image_url: menuItem?.photo_url ?? null,
    item_category: menuItem?.category?.nom ?? null,
    old_price: basePrice !== null ? roundMoney(basePrice) : null,
    promotion_price: basePrice !== null ? computePromotionPrice(basePrice, promo) : null,
    discount_value: promo.discount_value ?? null,
    currency: promo.currency,
    badge_text: promo.badge_text,
    custom_message: promo.custom_message ?? null,
    buy_quantity: promo.buy_quantity ?? null,
    free_quantity: promo.free_quantity ?? null,
    start_date: promo.start_date ?? null,
    end_date: promo.end_date ?? null,
    is_active: promo.is_active ?? null
  };
};

const buildPromotionsByRestaurantId = (promotions = []) => {
  const map = new Map();
  promotions.forEach((promo) => {
    if (!promo) return;
    const restaurantId = promo.restaurant_id || promo.restaurant?.id;
    if (!restaurantId) return;
    const key = String(restaurantId);
    const promoWithoutRestaurant = simplifyPromotionForRestaurant(promo);
    const list = map.get(key) || [];
    list.push(promoWithoutRestaurant);
    map.set(key, list);
  });
  return map;
};

const attachPromotionsToRestaurants = (restaurants, promotionsByRestaurantId) => {
  if (!Array.isArray(restaurants)) return [];
  return restaurants.map((restaurant) => {
    if (!restaurant) return restaurant;
    const rest = { ...restaurant };
    if ("promotions" in rest) {
      delete rest.promotions;
    }
    const restaurantId = restaurant.id || restaurant.restaurant_id;
    const promotions = restaurantId
      ? promotionsByRestaurantId.get(String(restaurantId)) || []
      : [];
    return {
      ...rest,
      promotions
    };
  });
};

const getRestaurantId = (restaurant) => {
  if (!restaurant) return null;
  return restaurant.id || restaurant.restaurant_id || null;
};

const toOptionalNumber = (value) => {
  if (value === null || value === undefined) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const getMenuItemId = (dish) => dish?.menu_item_id ?? dish?.menu_item?.id ?? null;

const getMenuItemBasePrice = (menuItem) => {
  if (!menuItem || menuItem.prix === null || menuItem.prix === undefined) {
    return null;
  }
  const parsed = Number(menuItem.prix);
  return Number.isFinite(parsed) ? roundMoney(parsed) : null;
};

const isPromotionApplicableToItem = (promotion, itemId, restaurantId) => {
  if (!promotion || !itemId) return false;
  const normalizedItemId = String(itemId);
  const scope = promotion.scope ? String(promotion.scope) : "";

  switch (scope) {
    case "menu_item":
      if (promotion.menu_item_id && String(promotion.menu_item_id) === normalizedItemId) {
        return true;
      }
      if (Array.isArray(promotion.menu_item_ids)) {
        return promotion.menu_item_ids.some((id) => String(id) === normalizedItemId);
      }
      if (Array.isArray(promotion.menu_items)) {
        return promotion.menu_items.some((item) => {
          const id = item?.id ?? item?.menu_item_id ?? item;
          return id && String(id) === normalizedItemId;
        });
      }
      return false;
    case "restaurant":
      return Boolean(
        promotion.restaurant_id &&
        restaurantId &&
        String(promotion.restaurant_id) === String(restaurantId)
      );
    case "global":
      return true;
    default:
      if (
        promotion.restaurant_id &&
        restaurantId &&
        String(promotion.restaurant_id) === String(restaurantId) &&
        !promotion.menu_item_id &&
        (!Array.isArray(promotion.menu_item_ids) || promotion.menu_item_ids.length === 0) &&
        (!Array.isArray(promotion.menu_items) || promotion.menu_items.length === 0)
      ) {
        return true;
      }
      return false;
  }
};

const computeRecommendedDishPrices = (dish, promotions = []) => {
  const basePrice = getMenuItemBasePrice(dish?.menu_item);
  if (basePrice === null) {
    return { old_price: null, promotion_price: null };
  }

  const itemId = getMenuItemId(dish);
  const restaurantId = dish?.restaurant_id ?? getRestaurantId(dish?.restaurant);
  const applicablePromotions = Array.isArray(promotions)
    ? promotions.filter((promotion) =>
        isPromotionApplicableToItem(promotion, itemId, restaurantId)
      )
    : [];

  if (applicablePromotions.length === 0) {
    return { old_price: basePrice, promotion_price: null };
  }

  const promoPrices = applicablePromotions
    .map((promotion) => computePromotionPrice(basePrice, promotion))
    .filter((price) => Number.isFinite(price));
  const bestPromoPrice = promoPrices.length ? Math.min(basePrice, ...promoPrices) : basePrice;

  return {
    old_price: basePrice,
    promotion_price: bestPromoPrice < basePrice ? roundMoney(bestPromoPrice) : null
  };
};

const buildRestaurantMetaMap = (restaurants = []) => {
  const map = new Map();
  if (!Array.isArray(restaurants)) return map;

  restaurants.forEach((restaurant) => {
    if (!restaurant) return;
    const restaurantId = getRestaurantId(restaurant);
    if (!restaurantId) return;
    map.set(String(restaurantId), {
      name: restaurant.name ?? null,
      rating: toOptionalNumber(restaurant.rating),
      distance: toOptionalNumber(restaurant.distance),
      delivery_time_min: toOptionalNumber(restaurant.delivery_time_min),
      delivery_time_max: toOptionalNumber(restaurant.delivery_time_max)
    });
  });

  return map;
};

const enrichRecommendedDishes = (recommendedDishes, restaurantMetaMap, promotions = []) => {
  if (!Array.isArray(recommendedDishes)) return recommendedDishes;
  return recommendedDishes.map((dish) => {
    const restaurantId = dish?.restaurant_id ?? getRestaurantId(dish?.restaurant);
    const restaurantMeta = restaurantId ? restaurantMetaMap.get(String(restaurantId)) : null;
    const pricing = computeRecommendedDishPrices(dish, promotions);

    return {
      ...dish,
      restaurant_name: restaurantMeta?.name ?? dish?.restaurant?.name ?? null,
      rating: restaurantMeta?.rating ?? null,
      distance: restaurantMeta?.distance ?? null,
      delivery_time_min: restaurantMeta?.delivery_time_min ?? null,
      delivery_time_max: restaurantMeta?.delivery_time_max ?? null,
      old_price: pricing.old_price,
      promotion_price: pricing.promotion_price
    };
  });
};

const stripRestaurantRef = (entry) => {
  if (!entry || typeof entry !== "object") return entry;
  if (!Object.prototype.hasOwnProperty.call(entry, "restaurant")) {
    return entry;
  }
  const restaurantId = entry.restaurant_id ?? getRestaurantId(entry.restaurant) ?? null;
  const { restaurant, ...rest } = entry;
  if (restaurantId && rest.restaurant_id === undefined) {
    return { ...rest, restaurant_id: restaurantId };
  }
  return rest;
};

const stripPromotionRestaurantRef = (promotion) => {
  if (!promotion || typeof promotion !== "object") return promotion;
  if (!Object.prototype.hasOwnProperty.call(promotion, "restaurant")) {
    return promotion;
  }
  const restaurantId = promotion.restaurant_id ?? getRestaurantId(promotion.restaurant) ?? null;
  const { restaurant, ...rest } = promotion;
  if (restaurantId && rest.restaurant_id === undefined) {
    return { ...rest, restaurant_id: restaurantId };
  }
  return rest;
};

const getPromotionRestaurantId = (promotion) => {
  if (!promotion || typeof promotion !== "object") return null;
  return promotion.restaurant_id ?? getRestaurantId(promotion.restaurant) ?? null;
};

const buildDailyDealRestaurantIds = (dailyDeals = []) => {
  if (!Array.isArray(dailyDeals)) return dailyDeals;
  const ids = [];
  const seen = new Set();
  dailyDeals.forEach((deal) => {
    const restaurantId = getPromotionRestaurantId(deal?.promotion);
    if (!restaurantId) return;
    const key = String(restaurantId);
    if (seen.has(key)) return;
    seen.add(key);
    ids.push(key);
  });
  return ids;
};

const buildSelectionRestaurantIds = (selection) => {
  if (!selection || typeof selection !== "object") return [];
  if (Array.isArray(selection.restaurant_ids)) {
    const ids = [];
    const seen = new Set();
    selection.restaurant_ids.forEach((id) => {
      if (!id) return;
      const key = String(id);
      if (seen.has(key)) return;
      seen.add(key);
      ids.push(key);
    });
    return ids;
  }
  if (!Array.isArray(selection.restaurants)) return [];
  const ids = [];
  const seen = new Set();
  selection.restaurants.forEach((restaurant) => {
    const restaurantId = getRestaurantId(restaurant);
    if (!restaurantId) return;
    const key = String(restaurantId);
    if (seen.has(key)) return;
    seen.add(key);
    ids.push(key);
  });
  return ids;
};

const buildSelectionCategoryPayload = (selection) => {
  const category = selection?.category ?? selection?.home_category ?? null;
  if (category && typeof category === "object") {
    const payload = {
      id: category.id ?? selection?.home_category_id ?? null,
      name: category.name ?? category.title ?? null,
      slug: category.slug ?? null,
      description: category.description ?? null,
      image_url: category.image_url ?? null
    };
    return payload;
  }
  if (selection?.home_category_id) {
    return { id: selection.home_category_id };
  }
  return null;
};

const simplifyThematicSelection = (selection) => {
  if (!selection || typeof selection !== "object") return selection;
  const titleSource = selection.title ?? selection.name ?? null;
  const descriptionSource = selection.description ?? null;
  const restaurantIds = buildSelectionRestaurantIds(selection);

  return {
    id: selection.id,
    title: titleSource,
    description: descriptionSource,
    category: buildSelectionCategoryPayload(selection),
    restaurant_ids: restaurantIds
  };
};

const simplifyHomepageModules = (modules = {}) => {
  if (!modules || typeof modules !== "object") return modules;
  return {
    ...modules,
    homeCategories: modules.homeCategories,
    recommendedDishes: Array.isArray(modules.recommendedDishes)
      ? modules.recommendedDishes.map((dish) => {
          const stripped = stripRestaurantRef(dish);
          return stripped;
        })
      : modules.recommendedDishes,
    dailyDeals: buildDailyDealRestaurantIds(modules.dailyDeals),
    promotions: [],
    announcements: Array.isArray(modules.announcements)
      ? modules.announcements.map((announcement) => stripRestaurantRef(announcement))
      : modules.announcements,
    thematicSelections: Array.isArray(modules.thematicSelections)
      ? modules.thematicSelections.map(simplifyThematicSelection)
      : modules.thematicSelections,
    featuredRestaurants: Array.isArray(modules.featuredRestaurants)
      ? modules.featuredRestaurants
          .map(getRestaurantId)
          .filter(Boolean)
      : modules.featuredRestaurants
  };
};

/**
 * ✅ Filter homepage modules to show only items from nearby restaurants
 */
const filterModulesByNearbyRestaurants = (modules, nearbyRestaurantIds) => {
  const restaurantIdSet = new Set((nearbyRestaurantIds || []).map(id => String(id)));
  const filterThematicSelections = (selections) => {
    if (!Array.isArray(selections)) return [];
    return selections.map((selection) => {
      const restaurants = Array.isArray(selection.restaurants)
        ? selection.restaurants.filter((restaurant) => {
            const restaurantId = getRestaurantId(restaurant);
            return restaurantId && restaurantIdSet.has(String(restaurantId));
          })
        : [];
      return {
        ...selection,
        restaurants,
        restaurants_count: restaurants.length
      };
    });
  };

  if (!nearbyRestaurantIds || nearbyRestaurantIds.length === 0) {
    return {
      homeCategories: modules.homeCategories || [],
      thematicSelections: filterThematicSelections(modules.thematicSelections || []),
      recommendedDishes: [],
      dailyDeals: [],
      promotions: [],
      announcements: [],
      featuredRestaurants: [] // Also filter featured restaurants
    };
  }

  // Filter recommended dishes
  const recommendedDishes = (modules.recommendedDishes || []).filter(dish => {
    return dish.restaurant_id && restaurantIdSet.has(String(dish.restaurant_id));
  });

  // Filter daily deals
  const dailyDeals = (modules.dailyDeals || []).filter(deal => {
    const promotionRestaurantId = deal.promotion?.restaurant_id;
    return promotionRestaurantId && restaurantIdSet.has(String(promotionRestaurantId));
  });

  // Filter promotions
  const promotions = (modules.promotions || []).filter(promo => {
    // Include global promotions (no restaurant_id)
    if (!promo.restaurant_id && promo.scope === 'global') return true;
    
    // Include promotions from nearby restaurants
    if (promo.restaurant_id && restaurantIdSet.has(String(promo.restaurant_id))) return true;
    
    return false;
  });

  // Filter announcements
  const announcements = (modules.announcements || []).filter(announcement => {
    // Include global announcements (no restaurant_id)
    if (!announcement.restaurant_id) return true;
    
    // Include announcements from nearby restaurants
    if (announcement.restaurant_id && restaurantIdSet.has(String(announcement.restaurant_id))) {
      return true;
    }
    
    return false;
  });

  // Filter featured restaurants to only show nearby ones
  const featuredRestaurants = (modules.featuredRestaurants || []).filter(restaurant => {
    const restaurantId = getRestaurantId(restaurant);
    return restaurantId && restaurantIdSet.has(String(restaurantId));
  });

  return {
    homeCategories: modules.homeCategories || [],
    thematicSelections: filterThematicSelections(modules.thematicSelections || []),
    recommendedDishes,
    dailyDeals,
    promotions,
    announcements,
    featuredRestaurants // Filtered featured restaurants
  };
};

const buildHomepagePayload = (modules, nearby) => {
  // Extract nearby restaurant IDs
  const nearbyRestaurantIds = (nearby.formatted || []).map(restaurant => restaurant.id);
  
  // Filter modules to show only items from nearby restaurants
  const filteredModules = filterModulesByNearbyRestaurants(modules, nearbyRestaurantIds);
  const promotionsByRestaurantId = buildPromotionsByRestaurantId(filteredModules.promotions || []);
  const nearbyWithPromotions = attachPromotionsToRestaurants(
    nearby.formatted || [],
    promotionsByRestaurantId
  );
  const featuredRestaurants = nearbyWithPromotions
    .filter((restaurant) => restaurant?.is_premium)
    .map(getRestaurantId)
    .filter(Boolean);
  const restaurantMetaMap = buildRestaurantMetaMap(nearbyWithPromotions);
  const enrichedRecommendedDishes = enrichRecommendedDishes(
    filteredModules.recommendedDishes,
    restaurantMetaMap,
    filteredModules.promotions || []
  );
  const modulesWithRecommended = {
    ...filteredModules,
    recommendedDishes: enrichedRecommendedDishes
  };

  return {
    ...simplifyHomepageModules(modulesWithRecommended),
    featuredRestaurants,
    nearby: buildNearbyResponse(nearby, nearbyWithPromotions)
  };
};

/**
 * ✅ UPDATED: Get homepage overview with featured restaurants
 * POST /api/homepage/overview
 */
export const getHomepageOverview = async (req, res, next) => {
  try {
    const overallStart = nowNs();
    const body = {
      ...req.body,
      categories: normalizeCategories(req.body.categories),
      client_id: req.user?.client_id
    };

    if (!body.client_id) {
      return res.status(400).json({
        success: false,
        message: "Client profile not found"
      });
    }
    const nearbyFilters = buildNearbyFilters(body);

    const timings = {};
    const modulesStart = nowNs();
    const modulesPromise = getHomepageModules({ includeFeaturedRestaurants: false }).then((result) => {
      timings.modules = msSince(modulesStart);
      return result;
    });

    const nearbyStart = nowNs();
    const nearbyPromise = restaurantService.filterNearbyRestaurants(nearbyFilters);

    const [modules, nearby] = await Promise.all([
      modulesPromise,
      nearbyPromise.then((result) => {
        timings.nearby = msSince(nearbyStart);
        return result;
      })
    ]);

    const payloadStart = nowNs();
    const payload = buildHomepagePayload(modules, nearby);
    timings.payload = msSince(payloadStart);
    timings.total = msSince(overallStart);
    setTimingHeaders(res, "overview", timings);

    res.json({
      success: true,
      data: payload
    });
  } catch (err) {
    next(err);
  }
};

const respondWithModules = async (filters, res, next) => {
  try {
    const overallStart = nowNs();
    const nearbyFilters = buildNearbyFilters(filters);
    const timings = {};
    const modulesStart = nowNs();
    const nearbyStart = nowNs();
    const [modules, nearby] = await Promise.all([
      getHomepageModules({ includeFeaturedRestaurants: false }).then((result) => {
        timings.modules = msSince(modulesStart);
        return result;
      }),
      restaurantService.filterNearbyRestaurants(nearbyFilters).then((result) => {
        timings.nearby = msSince(nearbyStart);
        return result;
      })
    ]);

    const payloadStart = nowNs();
    const payload = buildHomepagePayload(modules, nearby);
    timings.payload = msSince(payloadStart);
    timings.total = msSince(overallStart);
    setTimingHeaders(res, "modules", timings);

    res.json({
      success: true,
      data: payload
    });
  } catch (err) {
    next(err);
  }
};

export const getHomepageModulesForClient = async (req, res, next) => {
  const client_id = req.user?.client_id ?? req.query.client_id ?? null;
  return respondWithModules({ ...req.query, client_id }, res, next);
};

export const postHomepageModulesForClient = async (req, res, next) => {
  const client_id = req.user?.client_id ?? req.body.client_id ?? null;
  return respondWithModules({ ...req.body, client_id }, res, next);
};

export { normalizeCategories, buildNearbyFilters, buildHomepagePayload };
