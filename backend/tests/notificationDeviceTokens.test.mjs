import "../src/models/User.js";
import "../src/models/DeviceToken.js";
import { applyDeviceTokenDeliveryResults, registerDeviceTokenForUser } from "../src/services/notification.service.js";
import DeviceToken from "../src/models/DeviceToken.js";
import User from "../src/models/User.js";

const createUser = async (email, role = "client") =>
  User.create({
    email,
    password: "Secret123!",
    role
  });

describe("notification device token delivery tracking", () => {
  test("disables invalid tokens immediately and resets delivered ones", async () => {
    const user = await createUser("device-token-1@example.com");

    await DeviceToken.create({
      user_id: user.id,
      role: "client",
      profile_id: null,
      token: "token-success",
      is_active: true,
      failure_count: 2,
      last_failure_code: "messaging/mismatched-credential",
      last_failure_at: new Date()
    });

    await DeviceToken.create({
      user_id: user.id,
      role: "client",
      profile_id: null,
      token: "token-invalid",
      is_active: true,
      failure_count: 1,
      last_failure_code: "messaging/invalid-registration-token",
      last_failure_at: new Date()
    });

    await applyDeviceTokenDeliveryResults({
      tokenResults: [
        { token: "token-success", success: true, code: null },
        {
          token: "token-invalid",
          success: false,
          code: "messaging/invalid-registration-token"
        }
      ]
    });

    const successToken = await DeviceToken.findOne({ where: { token: "token-success" } });
    const invalidToken = await DeviceToken.findOne({ where: { token: "token-invalid" } });

    expect(successToken.failure_count).toBe(0);
    expect(successToken.last_failure_code).toBeNull();
    expect(successToken.last_failure_at).toBeNull();

    expect(invalidToken.is_active).toBe(false);
    expect(invalidToken.failure_count).toBe(0);
    expect(invalidToken.last_failure_code).toBeNull();
    expect(invalidToken.last_failure_at).toBeNull();
  });

  test("increments mismatched-credential failures and disables token at threshold", async () => {
    const user = await createUser("device-token-2@example.com");

    await DeviceToken.create({
      user_id: user.id,
      role: "driver",
      profile_id: null,
      token: "token-mismatch",
      is_active: true,
      failure_count: 2
    });

    await applyDeviceTokenDeliveryResults({
      tokenResults: [
        {
          token: "token-mismatch",
          success: false,
          code: "messaging/mismatched-credential"
        }
      ]
    });

    const mismatchToken = await DeviceToken.findOne({ where: { token: "token-mismatch" } });

    expect(mismatchToken.failure_count).toBe(3);
    expect(mismatchToken.last_failure_code).toBe("messaging/mismatched-credential");
    expect(mismatchToken.last_failure_at).not.toBeNull();
    expect(mismatchToken.is_active).toBe(false);
  });

  test("registering an existing token reactivates it and clears failure tracking", async () => {
    const user = await createUser("device-token-3@example.com", "restaurant");

    await DeviceToken.create({
      user_id: user.id,
      role: "restaurant",
      profile_id: null,
      token: "token-recover",
      is_active: false,
      failure_count: 5,
      last_failure_code: "messaging/mismatched-credential",
      last_failure_at: new Date()
    });

    await registerDeviceTokenForUser({
      userId: user.id,
      role: "restaurant",
      profileId: null,
      token: "token-recover",
      platform: "android",
      locale: "fr"
    });

    const recoveredToken = await DeviceToken.findOne({ where: { token: "token-recover" } });

    expect(recoveredToken.is_active).toBe(true);
    expect(recoveredToken.failure_count).toBe(0);
    expect(recoveredToken.last_failure_code).toBeNull();
    expect(recoveredToken.last_failure_at).toBeNull();
  });
});
