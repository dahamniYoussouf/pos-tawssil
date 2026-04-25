import jwt from "jsonwebtoken";
import User from "../models/User.js";
import { getJwtSecret } from "../config/security.js";
import { sendEmail } from "./email.service.js";

const DEFAULT_TTL_SECONDS = 24 * 60 * 60;
const EMAIL_VERIFICATION_TOKEN_PURPOSE = "partner-email-verification";

const parseInteger = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
};

const EMAIL_VERIFICATION_TTL_SECONDS = parseInteger(
  process.env.PARTNER_EMAIL_VERIFICATION_TTL_SECONDS,
  DEFAULT_TTL_SECONDS
);

const normalizeRegistrationEmail = (email) =>
  String(email || "").trim().toLowerCase();

const getTypeLabel = (type) => (type === "driver" ? "livreur" : "restaurant");

const getEmailVerificationSecret = () =>
  process.env.PARTNER_EMAIL_VERIFICATION_SECRET?.trim() || getJwtSecret();

const signPartnerEmailVerificationToken = ({ userId, email, type }) =>
  jwt.sign(
    {
      sub: String(userId),
      email: normalizeRegistrationEmail(email),
      role: type,
      purpose: EMAIL_VERIFICATION_TOKEN_PURPOSE
    },
    getEmailVerificationSecret(),
    { expiresIn: EMAIL_VERIFICATION_TTL_SECONDS }
  );

const verifyPartnerEmailVerificationToken = (token) =>
  jwt.verify(String(token || ""), getEmailVerificationSecret());

const buildVerificationLink = ({ verificationBaseUrl, token }) => {
  const url = new URL(String(verificationBaseUrl || ""));
  url.searchParams.set("token", token);
  return url.toString();
};

const buildVerificationEmailContent = ({ verificationUrl, type }) => {
  const ttlHours = Math.max(
    1,
    Math.ceil(EMAIL_VERIFICATION_TTL_SECONDS / (60 * 60))
  );
  const typeLabel = getTypeLabel(type);

  return {
    subject: "Confirmez votre email Tawsil",
    text: [
      "Bonjour,",
      "",
      `Cliquez sur ce lien pour confirmer votre email et finaliser votre inscription ${typeLabel} sur Tawsil :`,
      verificationUrl,
      "",
      `Ce lien expire dans ${ttlHours} heure(s).`,
      "",
      "Si vous n'etes pas a l'origine de cette demande, ignorez cet email."
    ].join("\n"),
    html: [
      "<div style=\"font-family:Arial,sans-serif;line-height:1.5;color:#111827;\">",
      "<h2 style=\"margin:0 0 16px;\">Confirmez votre email</h2>",
      `<p>Votre compte <strong>${typeLabel}</strong> a ete cree. Cliquez sur le bouton ci-dessous pour confirmer votre email :</p>`,
      `<p style=\"margin:24px 0;\"><a href=\"${verificationUrl}\" style=\"display:inline-block;background:#111827;color:#ffffff;text-decoration:none;padding:12px 20px;border-radius:8px;font-weight:700;\">Confirmer mon email</a></p>`,
      `<p>Ou copiez ce lien dans votre navigateur :<br><a href=\"${verificationUrl}\">${verificationUrl}</a></p>`,
      `<p>Ce lien expire dans <strong>${ttlHours} heure(s)</strong>.</p>`,
      "<p>Si vous n'etes pas a l'origine de cette demande, ignorez cet email.</p>",
      "</div>"
    ].join("")
  };
};

const buildVerificationError = (message, status = 400, code = null) => {
  const error = new Error(message);
  error.status = status;
  if (code) {
    error.code = code;
  }
  return error;
};

export const sendPartnerEmailVerification = async ({
  userId,
  email,
  type,
  verificationBaseUrl
}) => {
  const normalizedEmail = normalizeRegistrationEmail(email);
  const token = signPartnerEmailVerificationToken({
    userId,
    email: normalizedEmail,
    type
  });
  const verificationUrl = buildVerificationLink({
    verificationBaseUrl,
    token
  });

  const emailContent = buildVerificationEmailContent({
    verificationUrl,
    type
  });
  const deliveryInfo = await sendEmail({
    to: normalizedEmail,
    ...emailContent
  });

  return {
    email: normalizedEmail,
    type,
    expiresInSeconds: EMAIL_VERIFICATION_TTL_SECONDS,
    deliveryMode: deliveryInfo.deliveryMode,
    ...(deliveryInfo.deliveryMode === "dev-fallback"
      ? { verificationUrl }
      : {})
  };
};

export const confirmPartnerEmailVerification = async ({ token }) => {
  let payload;
  try {
    payload = verifyPartnerEmailVerificationToken(token);
  } catch (error) {
    throw buildVerificationError(
      "Email verification link is invalid or expired",
      400,
      "EMAIL_VERIFICATION_INVALID"
    );
  }

  if (payload?.purpose !== EMAIL_VERIFICATION_TOKEN_PURPOSE) {
    throw buildVerificationError(
      "Email verification link is invalid or expired",
      400,
      "EMAIL_VERIFICATION_INVALID"
    );
  }

  const user = await User.findByPk(String(payload.sub || ""));
  if (!user) {
    throw buildVerificationError(
      "User not found for this verification link",
      404,
      "EMAIL_VERIFICATION_USER_NOT_FOUND"
    );
  }

  if (!["driver", "restaurant"].includes(user.role)) {
    throw buildVerificationError(
      "This verification link is not valid for the current account",
      400,
      "EMAIL_VERIFICATION_ROLE_MISMATCH"
    );
  }

  if (user.role !== payload.role) {
    throw buildVerificationError(
      "This verification link is not valid for the current account",
      400,
      "EMAIL_VERIFICATION_ROLE_MISMATCH"
    );
  }

  if (normalizeRegistrationEmail(user.email) !== payload.email) {
    throw buildVerificationError(
      "This verification link no longer matches the current email address",
      400,
      "EMAIL_VERIFICATION_EMAIL_MISMATCH"
    );
  }

  if (user.email_verified_at) {
    return {
      user,
      alreadyVerified: true
    };
  }

  user.email_verified_at = new Date();
  await user.save();

  return {
    user,
    alreadyVerified: false
  };
};
