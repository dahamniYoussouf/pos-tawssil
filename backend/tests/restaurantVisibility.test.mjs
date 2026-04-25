import {
  assertRestaurantClientVisible,
  buildClientVisibleRestaurantWhere,
  isRestaurantClientVisible
} from "../src/utils/restaurantVisibility.js";

describe("restaurantVisibility", () => {
  test("buildClientVisibleRestaurantWhere enforces active approved restaurants", () => {
    expect(buildClientVisibleRestaurantWhere({ id: "resto-1" })).toEqual({
      id: "resto-1",
      is_active: true,
      status: "approved"
    });
  });

  test("isRestaurantClientVisible returns true only for active approved restaurants", () => {
    expect(isRestaurantClientVisible({ is_active: true, status: "approved" })).toBe(true);
    expect(isRestaurantClientVisible({ is_active: false, status: "approved" })).toBe(false);
    expect(isRestaurantClientVisible({ is_active: true, status: "pending" })).toBe(false);
    expect(isRestaurantClientVisible(null)).toBe(false);
  });

  test("assertRestaurantClientVisible throws a 404-style error for hidden restaurants", () => {
    expect(() =>
      assertRestaurantClientVisible({ is_active: false, status: "approved" })
    ).toThrow("Restaurant not found");

    try {
      assertRestaurantClientVisible({ is_active: true, status: "pending" });
    } catch (error) {
      expect(error.status).toBe(404);
    }
  });
});
