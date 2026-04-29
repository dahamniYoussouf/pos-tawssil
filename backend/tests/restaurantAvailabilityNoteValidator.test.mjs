import { validationResult } from "express-validator";
import { updateRestaurantValidator } from "../src/validators/restaurantValidator.js";

const runValidator = async (validator, { body = {}, params = {}, query = {} } = {}) => {
  const req = { body, params, query };
  await Promise.all(validator.map((validation) => validation.run(req)));
  return validationResult(req).array();
};

describe("restaurant availability note validation", () => {
  test("accepts null availability_note when an admin suspends a restaurant", async () => {
    const errors = await runValidator(updateRestaurantValidator, {
      params: { id: "11111111-1111-4111-8111-111111111111" },
      body: {
        status: "suspended",
        is_active: false,
        availability_note: null
      }
    });

    expect(errors).toEqual([]);
  });
});
