import {
  formatIsoInAppTimeZone,
  serializeDatesInAppTimeZone
} from "../src/utils/appTime.js";

describe("app time serialization", () => {
  test("formats UTC timestamps in the application timezone", () => {
    expect(formatIsoInAppTimeZone("2026-04-20T21:44:53.996Z")).toBe(
      "2026-04-20T22:44:53.996+01:00"
    );
  });

  test("converts nested Date instances and ISO strings before JSON responses", () => {
    const serialized = serializeDatesInAppTimeZone({
      timestamp: "2026-04-20T21:44:53.996Z",
      created_at: new Date("2026-04-20T21:44:53.996Z"),
      nested: {
        delivered_at: "2026-04-20T21:44:53.996Z"
      },
      items: [
        {
          updated_at: new Date("2026-04-20T21:44:53.996Z")
        }
      ],
      untouched: "not-a-date"
    });

    expect(serialized).toEqual({
      timestamp: "2026-04-20T22:44:53.996+01:00",
      created_at: "2026-04-20T22:44:53.996+01:00",
      nested: {
        delivered_at: "2026-04-20T22:44:53.996+01:00"
      },
      items: [
        {
          updated_at: "2026-04-20T22:44:53.996+01:00"
        }
      ],
      untouched: "not-a-date"
    });
  });
});
