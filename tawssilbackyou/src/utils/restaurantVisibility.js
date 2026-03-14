export const CLIENT_VISIBLE_RESTAURANT_STATUS = "approved";

export const buildClientVisibleRestaurantWhere = (extra = {}) => ({
  ...extra,
  is_active: true,
  status: CLIENT_VISIBLE_RESTAURANT_STATUS
});

export const isRestaurantClientVisible = (restaurant) =>
  Boolean(
    restaurant &&
    restaurant.is_active === true &&
    restaurant.status === CLIENT_VISIBLE_RESTAURANT_STATUS
  );

export const assertRestaurantClientVisible = (restaurant) => {
  if (isRestaurantClientVisible(restaurant)) {
    return restaurant;
  }

  const error = new Error("Restaurant not found");
  error.status = 404;
  throw error;
};
