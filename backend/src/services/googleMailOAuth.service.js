import crypto from "crypto";
import cacheService from "./cache.service.js";

const GOOGLE_OAUTH_STATE_TTL_SECONDS = 10 * 60;
const GOOGLE_MAIL_SCOPE = "https://www.googleapis.com/auth/gmail.send";
const GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";

const buildStateKey = (state) => `otp:google-mail-oauth:${state}`;

const requireEnv = (name) => {
  const value = process.env[name]?.trim();
  if (!value) {
    const error = new Error(`${name} is required`);
    error.status = 500;
    throw error;
  }
  return value;
};

export const getGoogleMailOAuthConfig = () => ({
  clientId: requireEnv("GOOGLE_CLIENT_ID"),
  clientSecret: requireEnv("GOOGLE_CLIENT_SECRET"),
  redirectUri:
    process.env.GOOGLE_REDIRECT_URI?.trim()
    || "https://tawsilapp.com/api/auth/callback"
});

export const createGoogleMailAuthUrl = async () => {
  const state = crypto.randomBytes(24).toString("hex");
  await cacheService.set(
    buildStateKey(state),
    { createdAt: Date.now() },
    GOOGLE_OAUTH_STATE_TTL_SECONDS
  );

  const { clientId, redirectUri } = getGoogleMailOAuthConfig();
  const url = new URL(GOOGLE_AUTH_URL);
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", GOOGLE_MAIL_SCOPE);
  url.searchParams.set("access_type", "offline");
  url.searchParams.set("prompt", "consent");
  url.searchParams.set("include_granted_scopes", "true");
  url.searchParams.set("state", state);

  return url.toString();
};

export const exchangeGoogleMailAuthCode = async ({ code, state }) => {
  if (!code) {
    const error = new Error("Authorization code is required");
    error.status = 400;
    throw error;
  }

  if (!state) {
    const error = new Error("OAuth state is required");
    error.status = 400;
    throw error;
  }

  const isKnownState = await cacheService.get(buildStateKey(state));
  if (!isKnownState) {
    const error = new Error("Invalid or expired OAuth state");
    error.status = 400;
    throw error;
  }

  await cacheService.del(buildStateKey(state));

  const { clientId, clientSecret, redirectUri } = getGoogleMailOAuthConfig();
  const body = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    code,
    grant_type: "authorization_code",
    redirect_uri: redirectUri
  });

  const response = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body
  });

  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const error = new Error(payload?.error_description || payload?.error || "Failed to exchange OAuth code");
    error.status = 502;
    error.details = payload;
    throw error;
  }

  return payload;
};
