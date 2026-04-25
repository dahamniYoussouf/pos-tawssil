import calculateRouteTime from "../src/services/routingService.js";

describe("routingService direct mode", () => {
  test("uses plain haversine distance without a multiplier", async () => {
    const route = await calculateRouteTime(0, 0, 1, 0, 60, { mode: "direct" });

    expect(route.distanceKm).toBeCloseTo(111.19, 2);
    expect(route.timeMin).toBe(100);
    expect(route.timeMax).toBe(134);
  });
});
