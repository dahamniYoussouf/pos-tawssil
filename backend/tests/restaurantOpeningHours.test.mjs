import { getDateStampInAppTimeZone } from "../src/utils/appTime.js";
import { isRestaurantOpenNow, normalizeOpeningHours } from "../src/utils/restaurantOpeningHours.js";

describe("restaurantOpeningHours", () => {
  test("uses the business timezone instead of the server local timezone", () => {
    expect(
      isRestaurantOpenNow({
        openingHours: {
          sun: { open: 1200, close: 2000 }
        },
        now: new Date("2026-04-05T11:30:00Z")
      })
    ).toBe(true);
  });

  test("accepts legacy day keys with different casing or full names", () => {
    expect(
      isRestaurantOpenNow({
        openingHours: {
          Sunday: { open: 1200, close: 2000 }
        },
        now: new Date("2026-04-05T11:30:00Z")
      })
    ).toBe(true);
  });

  test("normalizes opening hours and drops incomplete day entries", () => {
    expect(
      normalizeOpeningHours({
        Sunday: { open: 1200, close: 2000 },
        mon: { open: 900 },
        tue: { close: 1800 }
      })
    ).toEqual({
      sun: { open: 1200, close: 2000 }
    });
  });

  test("returns false when availability_status is not open", () => {
    expect(
      isRestaurantOpenNow({
        openingHours: {
          sun: { open: 1200, close: 2000 }
        },
        availabilityStatus: "closed",
        now: new Date("2026-04-05T11:30:00Z")
      })
    ).toBe(false);
  });

  test("keeps overnight schedules open after midnight using the previous day slot", () => {
    const openingHours = {
      sat: { open: 1800, close: 200 }
    };

    expect(
      isRestaurantOpenNow({
        openingHours,
        now: new Date("2026-04-04T22:30:00Z")
      })
    ).toBe(true);

    expect(
      isRestaurantOpenNow({
        openingHours,
        now: new Date("2026-04-05T00:30:00Z")
      })
    ).toBe(true);

    expect(
      isRestaurantOpenNow({
        openingHours,
        now: new Date("2026-04-05T01:30:00Z")
      })
    ).toBe(false);
  });

  test("derives business dates in Africa/Algiers instead of UTC", () => {
    expect(getDateStampInAppTimeZone(new Date("2026-04-05T23:30:00Z"))).toBe("20260406");
  });
});
