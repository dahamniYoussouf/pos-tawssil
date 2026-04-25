import { computeRecommendedDishPricing } from "../src/services/homepagePricing.helper.js";

describe("homepage recommended dish pricing", () => {
  test("returns a display price even when there is no promotion", () => {
    expect(
      computeRecommendedDishPricing({
        restaurant_id: "resto-1",
        menu_item_id: "item-1",
        menu_item: {
          id: "item-1",
          prix: 250
        }
      })
    ).toEqual({
      prix: 250,
      old_price: 250,
      promotion_price: null,
      display_price: 250,
      is_on_promotion: false
    });
  });

  test("applies the best matching promotion price", () => {
    expect(
      computeRecommendedDishPricing(
        {
          restaurant_id: "resto-1",
          menu_item_id: "item-1",
          menu_item: {
            id: "item-1",
            prix: 300
          }
        },
        [
          {
            id: "promo-restaurant",
            scope: "restaurant",
            restaurant_id: "resto-1",
            type: "percentage",
            discount_value: 10
          },
          {
            id: "promo-item",
            scope: "menu_item",
            menu_item_ids: ["item-1"],
            type: "amount",
            discount_value: 50
          }
        ]
      )
    ).toEqual({
      prix: 300,
      old_price: 300,
      promotion_price: 250,
      display_price: 250,
      is_on_promotion: true
    });
  });
});
