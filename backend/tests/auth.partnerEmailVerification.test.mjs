import request from "supertest";
import app from "../src/app.js";
import User from "../src/models/User.js";
import Driver from "../src/models/Driver.js";

describe("Partner email verification registration flow", () => {
  const previousVerificationRequired = process.env.PARTNER_EMAIL_VERIFICATION_REQUIRED;
  const previousVerificationBaseUrl = process.env.PARTNER_EMAIL_VERIFICATION_BASE_URL;

  beforeAll(() => {
    process.env.PARTNER_EMAIL_VERIFICATION_REQUIRED = "true";
    delete process.env.PARTNER_EMAIL_VERIFICATION_BASE_URL;
  });

  afterAll(() => {
    if (previousVerificationRequired === undefined) {
      delete process.env.PARTNER_EMAIL_VERIFICATION_REQUIRED;
    } else {
      process.env.PARTNER_EMAIL_VERIFICATION_REQUIRED = previousVerificationRequired;
    }

    if (previousVerificationBaseUrl === undefined) {
      delete process.env.PARTNER_EMAIL_VERIFICATION_BASE_URL;
    } else {
      process.env.PARTNER_EMAIL_VERIFICATION_BASE_URL = previousVerificationBaseUrl;
    }
  });

  test("driver registration sends a verification link and blocks login until email confirmation", async () => {
    const email = "driver.verification@example.com";
    const password = "secret123";

    const registerResponse = await request(app)
      .post("/auth/register")
      .send({
        email,
        password,
        type: "driver",
        first_name: "Ali",
        last_name: "Test",
        phone: "0557019946",
        vehicle_type: "scooter"
      });

    expect(registerResponse.status).toBe(201);
    expect(registerResponse.body.verification_required).toBe(true);
    expect(registerResponse.body.verification_email_sent).toBe(true);
    expect(registerResponse.body.user.email).toBe(email);
    expect(registerResponse.body.user.email_verified_at).toBeNull();
    expect(registerResponse.body.profile.email).toBe(email);
    expect(registerResponse.body.delivery_mode).toBe("dev-fallback");
    expect(registerResponse.body).toHaveProperty("dev_verification_url");
    expect(registerResponse.body).not.toHaveProperty("access_token");
    expect(registerResponse.body).not.toHaveProperty("refresh_token");

    const createdUser = await User.findOne({ where: { email } });
    expect(createdUser).not.toBeNull();
    expect(createdUser.email_verified_at).toBeNull();

    const createdDriver = await Driver.findOne({ where: { user_id: createdUser.id } });
    expect(createdDriver).not.toBeNull();
    expect(createdDriver.email).toBe(email);

    const loginBeforeVerification = await request(app)
      .post("/auth/login")
      .send({
        email,
        password,
        type: "driver"
      });

    expect(loginBeforeVerification.status).toBe(403);
    expect(loginBeforeVerification.body.code).toBe("EMAIL_NOT_VERIFIED");

    const verificationUrl = new URL(registerResponse.body.dev_verification_url);
    const verificationResponse = await request(app)
      .get(`${verificationUrl.pathname}${verificationUrl.search}`);

    expect(verificationResponse.status).toBe(200);
    expect(verificationResponse.text).toContain("Email confirme");

    await createdUser.reload();
    expect(createdUser.email_verified_at).not.toBeNull();

    const loginAfterVerification = await request(app)
      .post("/auth/login")
      .send({
        email,
        password,
        type: "driver"
      });

    expect(loginAfterVerification.status).toBe(200);
    expect(loginAfterVerification.body).toHaveProperty("access_token");
    expect(loginAfterVerification.body).toHaveProperty("refresh_token");
  });

  test("resend verification endpoint returns a new confirmation link for an existing unverified partner", async () => {
    const email = "driver.resend@example.com";

    const registerResponse = await request(app)
      .post("/auth/register")
      .send({
        email,
        password: "secret123",
        type: "driver",
        first_name: "Ali",
        last_name: "Resend",
        phone: "0557019947",
        vehicle_type: "scooter"
      });

    expect(registerResponse.status).toBe(201);
    expect(registerResponse.body.verification_required).toBe(true);

    const resendResponse = await request(app)
      .post("/auth/register/email/resend")
      .send({
        email,
        type: "driver"
      });

    expect(resendResponse.status).toBe(200);
    expect(resendResponse.body.delivery_mode).toBe("dev-fallback");
    expect(resendResponse.body).toHaveProperty("dev_verification_url");
  });

  test("register re-sends verification for an existing unverified partner instead of blocking on duplicate email", async () => {
    const email = "driver.reregister@example.com";

    const firstRegisterResponse = await request(app)
      .post("/auth/register")
      .send({
        email,
        password: "secret123",
        type: "driver",
        first_name: "Ali",
        last_name: "Retry",
        phone: "0557019948",
        vehicle_type: "scooter"
      });

    expect(firstRegisterResponse.status).toBe(201);
    expect(firstRegisterResponse.body.verification_required).toBe(true);

    const secondRegisterResponse = await request(app)
      .post("/auth/register")
      .send({
        email,
        password: "another-secret",
        type: "driver",
        first_name: "Ali",
        last_name: "Retry",
        phone: "0557019948",
        vehicle_type: "scooter"
      });

    expect(secondRegisterResponse.status).toBe(200);
    expect(secondRegisterResponse.body.already_registered).toBe(true);
    expect(secondRegisterResponse.body.verification_required).toBe(true);
    expect(secondRegisterResponse.body.verification_email_sent).toBe(true);
    expect(secondRegisterResponse.body.delivery_mode).toBe("dev-fallback");
    expect(secondRegisterResponse.body).toHaveProperty("dev_verification_url");
    expect(secondRegisterResponse.body.user.email).toBe(email);
    expect(secondRegisterResponse.body.user.email_verified_at).toBeNull();

    const matchingUsers = await User.findAll({ where: { email } });
    expect(matchingUsers).toHaveLength(1);

    const matchingDrivers = await Driver.findAll({ where: { email } });
    expect(matchingDrivers).toHaveLength(1);
  });

  test("verification endpoint rejects an invalid token", async () => {
    const response = await request(app)
      .get("/auth/verify-email?token=invalid-token");

    expect(response.status).toBe(400);
    expect(response.text).toContain("Lien invalide ou expire");
  });
});
