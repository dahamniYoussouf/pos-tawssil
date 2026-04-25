import { createHash, randomBytes } from "crypto";
import User from "../models/User.js";
import { sendEmail } from "./email.service.js";

const DEFAULT_TTL_SECONDS = 60 * 60;
const PASSWORD_RESET_TOKEN_BYTES = 32;

const parseInteger = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
};

export const PARTNER_PASSWORD_RESET_TTL_SECONDS = parseInteger(
  process.env.PARTNER_PASSWORD_RESET_TTL_SECONDS,
  DEFAULT_TTL_SECONDS
);

const buildPasswordResetError = (
  message,
  status = 400,
  code = "PASSWORD_RESET_INVALID"
) => {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
};

const normalizeEmailAddress = (value) =>
  String(value || "").trim().toLowerCase();

const getTypeLabel = (role) => (role === "driver" ? "livreur" : "restaurant");

const hashPasswordResetToken = (token) =>
  createHash("sha256").update(String(token || "")).digest("hex");

const generatePasswordResetToken = () =>
  randomBytes(PASSWORD_RESET_TOKEN_BYTES).toString("hex");

const buildPasswordResetLink = ({ passwordResetBaseUrl, token }) => {
  const url = new URL(String(passwordResetBaseUrl || ""));
  url.searchParams.set("token", token);
  return url.toString();
};

const buildPasswordResetEmailContent = ({ resetUrl, role }) => {
  const ttlMinutes = Math.max(
    1,
    Math.ceil(PARTNER_PASSWORD_RESET_TTL_SECONDS / 60)
  );
  const typeLabel = getTypeLabel(role);

  return {
    subject: "Reinitialisez votre mot de passe Tawsil",
    text: [
      "Bonjour,",
      "",
      `Une demande de reinitialisation du mot de passe a ete recue pour votre compte ${typeLabel} Tawsil.`,
      "Cliquez sur ce lien pour choisir un nouveau mot de passe :",
      resetUrl,
      "",
      `Ce lien expire dans ${ttlMinutes} minute(s).`,
      "",
      "Si vous n'etes pas a l'origine de cette demande, ignorez cet email."
    ].join("\n"),
    html: [
      "<div style=\"font-family:Arial,sans-serif;line-height:1.5;color:#111827;\">",
      "<h2 style=\"margin:0 0 16px;\">Reinitialisez votre mot de passe</h2>",
      `<p>Une demande de reinitialisation a ete recue pour votre compte <strong>${typeLabel}</strong> Tawsil.</p>`,
      `<p style=\"margin:24px 0;\"><a href=\"${resetUrl}\" style=\"display:inline-block;background:#111827;color:#ffffff;text-decoration:none;padding:12px 20px;border-radius:8px;font-weight:700;\">Choisir un nouveau mot de passe</a></p>`,
      `<p>Ou copiez ce lien dans votre navigateur :<br><a href=\"${resetUrl}\">${resetUrl}</a></p>`,
      `<p>Ce lien expire dans <strong>${ttlMinutes} minute(s)</strong>.</p>`,
      "<p>Si vous n'etes pas a l'origine de cette demande, ignorez cet email.</p>",
      "</div>"
    ].join("")
  };
};

export const sendPartnerPasswordReset = async ({
  user,
  passwordResetBaseUrl
}) => {
  if (!user || !["driver", "restaurant"].includes(user.role)) {
    throw buildPasswordResetError(
      "Password reset is only available for driver and restaurant accounts",
      400,
      "PASSWORD_RESET_ROLE_INVALID"
    );
  }

  const rawToken = generatePasswordResetToken();
  const tokenHash = hashPasswordResetToken(rawToken);
  const expiresAt = new Date(
    Date.now() + PARTNER_PASSWORD_RESET_TTL_SECONDS * 1000
  );

  user.password_reset_token_hash = tokenHash;
  user.password_reset_expires_at = expiresAt;
  await user.save({
    fields: ["password_reset_token_hash", "password_reset_expires_at"]
  });

  const resetUrl = buildPasswordResetLink({
    passwordResetBaseUrl,
    token: rawToken
  });

  try {
    const deliveryInfo = await sendEmail({
      to: normalizeEmailAddress(user.email),
      ...buildPasswordResetEmailContent({
        resetUrl,
        role: user.role
      })
    });

    return {
      email: normalizeEmailAddress(user.email),
      role: user.role,
      expiresInSeconds: PARTNER_PASSWORD_RESET_TTL_SECONDS,
      deliveryMode: deliveryInfo.deliveryMode,
      ...(deliveryInfo.deliveryMode === "dev-fallback"
        ? { resetUrl }
        : {})
    };
  } catch (error) {
    user.password_reset_token_hash = null;
    user.password_reset_expires_at = null;
    await user
      .save({
        fields: ["password_reset_token_hash", "password_reset_expires_at"]
      })
      .catch(() => null);
    throw error;
  }
};

export const resetPartnerPassword = async ({ token, password }) => {
  const tokenHash = hashPasswordResetToken(token);
  const user = await User.findOne({
    where: { password_reset_token_hash: tokenHash }
  });

  if (!user || !["driver", "restaurant"].includes(user.role)) {
    throw buildPasswordResetError(
      "Password reset link is invalid or expired",
      400,
      "PASSWORD_RESET_INVALID"
    );
  }

  if (!user.password_reset_expires_at || user.password_reset_expires_at < new Date()) {
    user.password_reset_token_hash = null;
    user.password_reset_expires_at = null;
    await user.save({
      fields: ["password_reset_token_hash", "password_reset_expires_at"]
    });

    throw buildPasswordResetError(
      "Password reset link is invalid or expired",
      400,
      "PASSWORD_RESET_INVALID"
    );
  }

  if (!user.is_active) {
    throw buildPasswordResetError(
      "Account is deactivated",
      403,
      "ACCOUNT_DEACTIVATED"
    );
  }

  user.password = password;
  user.password_reset_token_hash = null;
  user.password_reset_expires_at = null;
  await user.save({
    fields: ["password", "password_reset_token_hash", "password_reset_expires_at"]
  });

  return {
    userId: user.id,
    email: normalizeEmailAddress(user.email),
    role: user.role
  };
};
