import request from "supertest";
import app from "../src/app.js";
import User from "../src/models/User.js";

describe("Partner password reset flow", () => {
  test("driver can request a reset link, reset the password, and old sessions are revoked", async () => {
    const email = "driver.reset@example.com";
    const oldPassword = "secret123";
    const newPassword = "secret456";

    const registerResponse = await request(app)
      .post("/auth/register")
      .send({
        email,
        password: oldPassword,
        type: "driver",
        first_name: "Ali",
        last_name: "Reset",
        phone: "0557019951",
        vehicle_type: "scooter"
      });

    expect(registerResponse.status).toBe(201);

    const verificationUrl = new URL(registerResponse.body.dev_verification_url);
    await request(app).get(`${verificationUrl.pathname}${verificationUrl.search}`);

    const loginResponse = await request(app)
      .post("/auth/login")
      .send({
        email,
        password: oldPassword,
        type: "driver"
      });

    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body).toHaveProperty("refresh_token");

    const forgotResponse = await request(app)
      .post("/auth/password/forgot")
      .send({ email });

    expect(forgotResponse.status).toBe(200);
    expect(forgotResponse.body).toHaveProperty("dev_reset_url");
    expect(forgotResponse.body.delivery_mode).toBe("dev-fallback");

    const resetUrl = new URL(forgotResponse.body.dev_reset_url);
    const resetToken = resetUrl.searchParams.get("token");
    expect(resetToken).toBeTruthy();

    const htmlPageResponse = await request(app)
      .get(`${resetUrl.pathname}${resetUrl.search}`);

    expect(htmlPageResponse.status).toBe(200);
    expect(htmlPageResponse.text).toContain("Choisissez un nouveau mot de passe");

    const resetResponse = await request(app)
      .post("/auth/password/reset")
      .send({
        token: resetToken,
        password: newPassword
      });

    expect(resetResponse.status).toBe(200);
    expect(resetResponse.body.message).toContain("mis a jour");
    expect(resetResponse.body.revoked_sessions).toBeGreaterThanOrEqual(1);

    const refreshAfterResetResponse = await request(app)
      .post("/auth/refresh")
      .send({
        refresh_token: loginResponse.body.refresh_token
      });

    expect(refreshAfterResetResponse.status).toBe(401);

    const oldPasswordLoginResponse = await request(app)
      .post("/auth/login")
      .send({
        email,
        password: oldPassword,
        type: "driver"
      });

    expect(oldPasswordLoginResponse.status).toBe(401);

    const newPasswordLoginResponse = await request(app)
      .post("/auth/login")
      .send({
        email,
        password: newPassword,
        type: "driver"
      });

    expect(newPasswordLoginResponse.status).toBe(200);

    const reusedTokenResponse = await request(app)
      .post("/auth/password/reset")
      .send({
        token: resetToken,
        password: "anotherPass123"
      });

    expect(reusedTokenResponse.status).toBe(400);
    expect(reusedTokenResponse.body.code).toBe("PASSWORD_RESET_INVALID");

    const updatedUser = await User.findOne({ where: { email } });
    expect(updatedUser.password_reset_token_hash).toBeNull();
    expect(updatedUser.password_reset_expires_at).toBeNull();
  });

  test("forgot password returns the same generic response for unknown emails", async () => {
    const response = await request(app)
      .post("/auth/password/forgot")
      .send({ email: "unknown.partner@example.com" });

    expect(response.status).toBe(200);
    expect(response.body.message).toContain("If an account exists");
    expect(response.body).not.toHaveProperty("dev_reset_url");
  });
});
