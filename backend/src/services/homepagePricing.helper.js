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

const getRestaurantId = (restaurant) => {
  if (!restaurant) return null;
  return restaurant.id || restaurant.restaurant_id || null;
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

export const computeRecommendedDishPricing = (dish, promotions = []) => {
  const basePrice = getMenuItemBasePrice(dish?.menu_item);
  if (basePrice === null) {
    return {
      prix: null,
      old_price: null,
      promotion_price: null,
      display_price: null,
      is_on_promotion: false
    };
  }

  const itemId = getMenuItemId(dish);
  const restaurantId = dish?.restaurant_id ?? getRestaurantId(dish?.restaurant);
  const applicablePromotions = Array.isArray(promotions)
    ? promotions.filter((promotion) =>
        isPromotionApplicableToItem(promotion, itemId, restaurantId)
      )
    : [];

  const promoPrices = applicablePromotions
    .map((promotion) => computePromotionPrice(basePrice, promotion))
    .filter((price) => Number.isFinite(price));
  const bestPromoPrice = promoPrices.length ? Math.min(basePrice, ...promoPrices) : basePrice;
  const promotionPrice = bestPromoPrice < basePrice ? roundMoney(bestPromoPrice) : null;

  return {
    prix: basePrice,
    old_price: basePrice,
    promotion_price: promotionPrice,
    display_price: promotionPrice ?? basePrice,
    is_on_promotion: promotionPrice !== null
  };
};
