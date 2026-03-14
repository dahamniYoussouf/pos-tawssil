// src/services/homepage.service.js
import { QueryTypes } from "sequelize";
import { sequelize } from "../config/database.js";
import {
  listHomeCategories
} from "./homeCategory.service.js";
import {
  listThematicSelections
} from "./thematicSelection.service.js";
import {
  listRecommendedDishes
} from "./recommendedDish.service.js";
import {
  listDailyDeals
} from "./dailyDeal.service.js";
import {
  listPromotions
} from "./promotion.service.js";
import {
  getActiveAnnouncements
} from "./announcement.service.js";
import {
  getFeaturedPremiumRestaurants
} from "./featuredRestaurants.service.js";
import cacheService from "./cache.service.js";

const HOMEPAGE_BASE_CACHE_KEY = "homepage:modules:base:v1";
const HOMEPAGE_FEATURED_CACHE_KEY = "homepage:modules:featured:v1";
const HOMEPAGE_BASE_CACHE_TTL = 120; // seconds
const HOMEPAGE_FEATURED_CACHE_TTL = 45; // seconds
const HOMEPAGE_FEATURED_CACHE_TTL_GLOBAL = 120; // seconds
const FEATURED_COORD_PRECISION = 3;
const FEATURED_RADIUS_STEP = 100;
const THEMATIC_RESTAURANTS_LIMIT = 10;

const toPlainObject = (value) =>
  value && typeof value.toJSON === "function" ? value.toJSON() : value;

const normalizeCoordinate = (value, precision, min, max) => {
  if (value === null || value === undefined) return null;
  if (typeof value === "string" && value.trim() === "") return null;
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  if (num < min || num > max) return null;
  const rounded = Number(num.toFixed(precision));
  return Number.isFinite(rounded) ? rounded : null;
};

const normalizeRadius = (value, fallback, step) => {
  const num = Number(value);
  if (!Number.isFinite(num) || num <= 0) return fallback;
  const rounded = Math.round(num / step) * step;
  return rounded > 0 ? rounded : fallback;
};

const normalizeLimit = (value, fallback) => {
  const num = parseInt(value, 10);
  return Number.isInteger(num) && num > 0 ? num : fallback;
};

const normalizeFeaturedOptions = ({ lat, lng, featuredRadius, featuredLimit }) => {
  const normalizedLat = normalizeCoordinate(lat, FEATURED_COORD_PRECISION, -90, 90);
  const normalizedLng = normalizeCoordinate(lng, FEATURED_COORD_PRECISION, -180, 180);
  const hasLocation = normalizedLat !== null && normalizedLng !== null;
  const radius = normalizeRadius(featuredRadius, 10000, FEATURED_RADIUS_STEP);
  const limit = normalizeLimit(featuredLimit, 6);

  return {
    lat: hasLocation ? normalizedLat : null,
    lng: hasLocation ? normalizedLng : null,
    radius,
    limit,
    hasLocation
  };
};

const buildFeaturedCacheKey = ({ lat, lng, radius, limit, hasLocation }) => {
  if (!hasLocation) {
    return `${HOMEPAGE_FEATURED_CACHE_KEY}:global:limit:${limit}`;
  }
  return `${HOMEPAGE_FEATURED_CACHE_KEY}:lat:${lat}:lng:${lng}:radius:${radius}:limit:${limit}`;
};

const parseOpeningHours = (value) => {
  if (!value) return null;
  if (typeof value === "string") {
    try {
      return JSON.parse(value);
    } catch (err) {
      return null;
    }
  }
  return value;
};

const isRestaurantOpen = (openingHours) => {
  const hours = parseOpeningHours(openingHours);
  if (!hours) return false;

  const now = new Date();
  const day = now.toLocaleDateString("en-US", { weekday: "short" }).toLowerCase();
  const todayHours = hours[day];
  if (!todayHours) return false;

  const currentTime = now.getHours() * 100 + now.getMinutes();
  const open = Number(todayHours.open);
  const close = Number(todayHours.close);
  if (!Number.isFinite(open) || !Number.isFinite(close)) return false;

  return currentTime >= open && currentTime <= close;
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

const attachPromotionsToRestaurant = (restaurant, promotionsByRestaurantId, options = {}) => {
  if (!restaurant) return restaurant;
  const { excludePromotionId, includePromotions = true } = options;
  const rest = { ...restaurant };
  if ("promotions" in rest) {
    delete rest.promotions;
  }
  if (!includePromotions) {
    return rest;
  }
  const restaurantId = restaurant.id || restaurant.restaurant_id;
  let promotions = restaurantId
    ? promotionsByRestaurantId.get(String(restaurantId)) || []
    : [];
  if (excludePromotionId) {
    const excludedId = String(excludePromotionId);
    promotions = promotions.filter((promo) => String(promo?.id ?? "") !== excludedId);
  }
  return { ...rest, promotions };
};

const attachPromotionsToRestaurants = (restaurants, promotionsByRestaurantId) => {
  if (!Array.isArray(restaurants)) return restaurants;
  return restaurants.map((restaurant) =>
    attachPromotionsToRestaurant(restaurant, promotionsByRestaurantId)
  );
};

const enrichThematicSelectionsWithRestaurants = async (thematicSelections) => {
  if (!thematicSelections || thematicSelections.length === 0) {
    return [];
  }

  const { serializeHomeCategories, extractHomeCategorySlugs } = await import("./restaurantCategory.service.js");

  // Get all unique home_category_ids from thematic selections
  const categoryIds = [...new Set(
    thematicSelections
      .map(selection => selection.home_category_id)
      .filter(Boolean)
  )];

  if (categoryIds.length === 0) {
    return thematicSelections;
  }

  const restaurantsMap = new Map();
  const dialect = sequelize.getDialect();

  if (dialect !== "postgres") {
    const { default: Restaurant } = await import("../models/Restaurant.js");
    const { default: HomeCategory } = await import("../models/HomeCategory.js");

    const restaurantsByCategory = await Promise.all(
      categoryIds.map(async (categoryId) => {
        const restaurants = await Restaurant.findAll({
          attributes: [
            'id',
            'name',
            'description',
            'address',
            'location',
            'rating',
            'image_url',
            'is_premium',
            'status',
            'opening_hours',
            'email',
            'phone_number'
          ],
          include: [
            {
              model: HomeCategory,
              as: "home_categories",
              where: { id: categoryId },
              attributes: ["id", "name", "slug", "description", "image_url", "display_order"],
              through: { attributes: [] }
            }
          ],
          where: {
            is_active: true,
            status: 'approved'
          },
          limit: THEMATIC_RESTAURANTS_LIMIT,
          order: [
            ['is_premium', 'DESC'],
            ['rating', 'DESC']
          ]
        });

        return {
          categoryId,
          restaurants: restaurants.map((restaurant) => {
            const restaurantJson = restaurant.toJSON();
            const coords = restaurantJson.location?.coordinates || [];
            const homeCategories = serializeHomeCategories(restaurantJson.home_categories || []);

            return {
              id: restaurantJson.id,
              name: restaurantJson.name,
              description: restaurantJson.description,
              address: restaurantJson.address,
              lat: coords[1] || null,
              lng: coords[0] || null,
              rating: restaurantJson.rating ? parseFloat(restaurantJson.rating) : 0,
              image_url: restaurantJson.image_url,
              is_premium: restaurantJson.is_premium,
              status: restaurantJson.status,
              is_open: typeof restaurant.isOpen === 'function' ? restaurant.isOpen() : true,
              home_categories: homeCategories,
              categories: extractHomeCategorySlugs(homeCategories),
              email: restaurantJson.email || null,
              phone_number: restaurantJson.phone_number || null
            };
          })
        };
      })
    );

    restaurantsByCategory.forEach(({ categoryId, restaurants }) => {
      restaurantsMap.set(String(categoryId), restaurants);
    });
  } else {
    // Fetch restaurants for all categories in one query
    const sql = `
      WITH ranked AS (
        SELECT
          r.id,
          r.name,
          r.description,
          r.address,
          r.rating,
          r.image_url,
          r.is_premium,
          r.status,
          r.opening_hours,
          r.email,
          r.phone_number,
          ST_Y(r.location::geometry) AS lat,
          ST_X(r.location::geometry) AS lng,
          rhc.home_category_id AS selection_category_id,
          hc.id AS home_category_id,
          hc.name AS home_category_name,
          hc.slug AS home_category_slug,
          hc.description AS home_category_description,
          hc.image_url AS home_category_image_url,
          hc.display_order AS home_category_display_order,
          ROW_NUMBER() OVER (
            PARTITION BY rhc.home_category_id
            ORDER BY r.is_premium DESC, r.rating DESC
          ) AS rn
        FROM restaurants r
        JOIN restaurant_home_categories rhc ON rhc.restaurant_id = r.id
        JOIN home_categories hc ON hc.id = rhc.home_category_id
        WHERE r.is_active = true
          AND r.status = 'approved'
          AND rhc.home_category_id = ANY(ARRAY[:categoryIds]::uuid[])
      )
      SELECT *
      FROM ranked
      WHERE rn <= :limit
      ORDER BY selection_category_id, rn ASC
    `;

    const rows = await sequelize.query(sql, {
      type: QueryTypes.SELECT,
      replacements: {
        categoryIds,
        limit: THEMATIC_RESTAURANTS_LIMIT
      }
    });

    rows.forEach((row) => {
      const categoryId = String(row.selection_category_id);
      const list = restaurantsMap.get(categoryId) || [];
      const lat = row.lat !== null && row.lat !== undefined ? parseFloat(row.lat) : null;
      const lng = row.lng !== null && row.lng !== undefined ? parseFloat(row.lng) : null;
      const ratingValue = Number.parseFloat(row.rating);
      const rating = Number.isFinite(ratingValue) ? ratingValue : 0;
      const homeCategory = {
        id: row.home_category_id,
        name: row.home_category_name,
        slug: row.home_category_slug,
        description: row.home_category_description,
        image_url: row.home_category_image_url,
        display_order: row.home_category_display_order
      };
      const homeCategories = serializeHomeCategories([homeCategory]);

      list.push({
        id: row.id,
        name: row.name,
        description: row.description,
        address: row.address,
        lat,
        lng,
        rating,
        image_url: row.image_url,
        is_premium: row.is_premium,
        status: row.status,
        is_open: isRestaurantOpen(row.opening_hours),
        home_categories: homeCategories,
        categories: extractHomeCategorySlugs(homeCategories),
        email: row.email || null,
        phone_number: row.phone_number || null
      });

      restaurantsMap.set(categoryId, list);
    });
  }

  // Enrich thematic selections with restaurants
  // ✅ Convert selections to plain JSON to avoid circular references
  return thematicSelections.map(selection => {
    const selectionJson = typeof selection.toJSON === 'function' ? selection.toJSON() : selection;
    const selectionCategoryId = String(selectionJson.home_category_id || "");
    const restaurants = restaurantsMap.get(selectionCategoryId) || [];
    
    return {
      ...selectionJson,
      restaurants,
      restaurants_count: restaurants.length
    };
  });
};

/**
 * Get homepage modules with optional location for featured restaurants
 * @param {Object} options - Configuration options
 * @param {number} options.lat - User latitude (optional)
 * @param {number} options.lng - User longitude (optional)
 * @param {number} options.featuredRadius - Radius for featured restaurants (default: 10000m)
 * @param {number} options.featuredLimit - Max featured restaurants (default: 6)
 * @param {boolean} options.includeFeaturedRestaurants - Whether to include featured restaurants module (default: true)
 * @returns {Promise<Object>} Homepage modules
 */
export const getHomepageModules = async (options = {}) => {
  const {
    lat,
    lng,
    featuredRadius = 10000,
    featuredLimit = 6,
    includeFeaturedRestaurants = true
  } = options;

  const normalizedFeatured = normalizeFeaturedOptions({
    lat,
    lng,
    featuredRadius,
    featuredLimit
  });

  const baseCacheKey = HOMEPAGE_BASE_CACHE_KEY;
  const featuredCacheKey = buildFeaturedCacheKey(normalizedFeatured);

  const [cachedBase, cachedFeatured] = await Promise.all([
    cacheService.get(baseCacheKey),
    includeFeaturedRestaurants ? cacheService.get(featuredCacheKey) : Promise.resolve(null)
  ]);

  let baseModules = cachedBase;
  if (baseModules === null) {
    const now = new Date().toISOString();

    const [
      homeCategories,
      thematicSelections,
      recommendedDishes,
      dailyDeals,
      promotions,
      announcements
    ] = await Promise.all([
      listHomeCategories({ activeOnly: true }),
      listThematicSelections({ activeOnly: true }),
      listRecommendedDishes({ activeOnly: true }),
      listDailyDeals({ activeOnly: true }),
      listPromotions({
        is_active: true,
        active_on: now
      }),
      getActiveAnnouncements()
    ]);

    const enrichedThematicSelections = await enrichThematicSelectionsWithRestaurants(thematicSelections);

    const promotionsPlain = (promotions || []).map(toPlainObject);
    const promotionsByRestaurantId = buildPromotionsByRestaurantId(promotionsPlain);

    const promotionsWithRestaurants = promotionsPlain.map((promo) => {
      if (!promo?.restaurant) {
        return promo;
      }
      return {
        ...promo,
        restaurant: attachPromotionsToRestaurant(
          promo.restaurant,
          promotionsByRestaurantId,
          { excludePromotionId: promo.id, includePromotions: false }
        )
      };
    });

    const recommendedWithRestaurants = (recommendedDishes || []).map((dish) => {
      const dishPlain = toPlainObject(dish);
      return {
        ...dishPlain,
        restaurant: dishPlain?.restaurant
          ? attachPromotionsToRestaurant(dishPlain.restaurant, promotionsByRestaurantId)
          : dishPlain?.restaurant
      };
    });

    const dailyDealsWithRestaurants = (dailyDeals || []).map((deal) => {
      const dealPlain = toPlainObject(deal);
      const promo = dealPlain?.promotion;
      if (!promo) {
        return dealPlain;
      }
      return {
        ...dealPlain,
        promotion: {
          ...promo,
          restaurant: promo.restaurant
            ? attachPromotionsToRestaurant(
                promo.restaurant,
                promotionsByRestaurantId,
                { excludePromotionId: promo.id, includePromotions: false }
              )
            : promo.restaurant
        }
      };
    });

    const announcementsWithRestaurants = (announcements || []).map((announcement) => {
      const announcementPlain = toPlainObject(announcement);
      return {
        ...announcementPlain,
        restaurant: announcementPlain?.restaurant
          ? attachPromotionsToRestaurant(announcementPlain.restaurant, promotionsByRestaurantId)
          : announcementPlain?.restaurant
      };
    });

    const thematicWithRestaurants = (enrichedThematicSelections || []).map((selection) => ({
      ...selection,
      restaurants: attachPromotionsToRestaurants(selection.restaurants, promotionsByRestaurantId)
    }));

    baseModules = {
      homeCategories,
      thematicSelections: thematicWithRestaurants,
      recommendedDishes: recommendedWithRestaurants,
      dailyDeals: dailyDealsWithRestaurants,
      promotions: promotionsWithRestaurants,
      announcements: announcementsWithRestaurants
    };

    await cacheService.set(baseCacheKey, baseModules, HOMEPAGE_BASE_CACHE_TTL);
  }

  const promotionsForMap = Array.isArray(baseModules?.promotions) ? baseModules.promotions : [];
  const promotionsByRestaurantId = buildPromotionsByRestaurantId(promotionsForMap);

  let featuredRestaurants = [];
  if (includeFeaturedRestaurants) {
    featuredRestaurants = cachedFeatured;
    if (featuredRestaurants === null) {
      const fetchedFeatured = await getFeaturedPremiumRestaurants({
        lat: normalizedFeatured.lat,
        lng: normalizedFeatured.lng,
        radius: normalizedFeatured.radius,
        limit: normalizedFeatured.limit
      });

      featuredRestaurants = attachPromotionsToRestaurants(
        (fetchedFeatured || []).map(toPlainObject),
        promotionsByRestaurantId
      );

      const featuredTtl = normalizedFeatured.hasLocation
        ? HOMEPAGE_FEATURED_CACHE_TTL
        : HOMEPAGE_FEATURED_CACHE_TTL_GLOBAL;

      await cacheService.set(featuredCacheKey, featuredRestaurants, featuredTtl);
    }
  }

  return {
    ...baseModules,
    featuredRestaurants
  };
};

/**
 * Clear homepage modules cache
 * Clears all cached versions (with and without location)
 */
export const clearHomepageModulesCache = async () => {
  await Promise.all([
    cacheService.delPattern('homepage:modules:*'),
    cacheService.delPattern('cache:GET:/admin/homepage*'),
    cacheService.delPattern('cache:GET:/api/v1/admin/homepage*'),
    cacheService.delPattern('cache:GET:/homepage*'),
    cacheService.delPattern('cache:GET:/api/v1/homepage*'),
    cacheService.delPattern('cache:GET:/api/v2/homepage*')
  ]);
};
