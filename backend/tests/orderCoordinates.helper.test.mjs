import { attachDeliveryCoordinates, buildCoordinatePayload } from "../src/services/orders/orderCoordinates.helper.js";

describe("order coordinate serialization", () => {
  test("buildCoordinatePayload normalizes lat/lng and latitude/longitude", () => {
    expect(
      buildCoordinatePayload({
        type: "Point",
        coordinates: [3.0588, 36.7538]
      })
    ).toEqual({
      lat: 36.7538,
      lng: 3.0588,
      latitude: 36.7538,
      longitude: 3.0588
    });
  });

  test("attachDeliveryCoordinates appends top-level lat/lng and delivery_coordinates", () => {
    expect(
      attachDeliveryCoordinates({
        id: "order-1",
        delivery_location: {
          type: "Point",
          coordinates: [3.0588, 36.7538]
        }
      })
    ).toEqual({
      id: "order-1",
      delivery_location: {
        type: "Point",
        coordinates: [3.0588, 36.7538]
      },
      lat: 36.7538,
      lng: 3.0588,
      delivery_coordinates: {
        lat: 36.7538,
        lng: 3.0588,
        latitude: 36.7538,
        longitude: 3.0588
      }
    });
  });

  test("attachDeliveryCoordinates keeps nulls when no delivery coordinates are available", () => {
    expect(
      attachDeliveryCoordinates({
        id: "order-2",
        delivery_location: null
      })
    ).toEqual({
      id: "order-2",
      delivery_location: null,
      lat: null,
      lng: null,
      delivery_coordinates: null
    });
  });
});
