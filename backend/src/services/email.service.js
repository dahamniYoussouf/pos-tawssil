import nodemailer from "nodemailer";
import { Resend } from "resend";

let transporterPromise = null;
const GMAIL_TOKEN_URL = "https://oauth2.googleapis.com/token";
const GMAIL_SEND_URL = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send";

const parseBoolean = (value, fallback = false) => {
  if (value === undefined || value === null) return fallback;
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;

  const normalized = String(value).trim().toLowerCase();
  if (["true", "1", "yes", "on"].includes(normalized)) return true;
  if (["false", "0", "no", "off"].includes(normalized)) return false;

  return fallback;
};

const parseInteger = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const hasText = (value) => typeof value === "string" && value.trim().length > 0;

const getMailFrom = () =>
  process.env.RESEND_FROM?.trim()
  || process.env.MAIL_FROM?.trim()
  || process.env.SMTP_FROM?.trim()
  || process.env.GOOGLE_OAUTH_EMAIL?.trim()
  || process.env.SMTP_USER?.trim()
  || null;

const buildResendTransportConfig = () => {
  const apiKey = process.env.RESEND_API_KEY?.trim();
  if (!apiKey) return null;

  return {
    mode: "resend-api",
    from: getMailFrom(),
    resend: new Resend(apiKey)
  };
};

const buildSmtpTransportConfig = () => {
  const host = process.env.SMTP_HOST?.trim();
  if (!host) return null;

  const port = parseInteger(process.env.SMTP_PORT, 587);
  const secure = parseBoolean(process.env.SMTP_SECURE, port === 465);
  const requireTls = parseBoolean(process.env.SMTP_REQUIRE_TLS, false);
  const user = process.env.SMTP_USER?.trim();
  const pass = process.env.SMTP_PASS;

  const auth = hasText(user)
    ? {
        user,
        ...(pass ? { pass } : {})
      }
    : undefined;

  return {
    mode: "smtp",
    from: getMailFrom(),
    transporterOptions: {
      host,
      port,
      secure,
      ...(auth ? { auth } : {}),
      ...(requireTls ? { requireTLS: true } : {})
    }
  };
};

const buildGmailOauthTransportConfig = () => {
  const clientId = process.env.GOOGLE_CLIENT_ID?.trim();
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET?.trim();
  const refreshToken = process.env.GOOGLE_REFRESH_TOKEN?.trim();
  const user = process.env.GOOGLE_OAUTH_EMAIL?.trim() || process.env.SMTP_USER?.trim();

  if (!clientId || !clientSecret || !refreshToken || !user) {
    return null;
  }

  return {
    mode: "gmail-api",
    from: getMailFrom() || user,
    gmailConfig: {
      user,
      clientId,
      clientSecret,
      refreshToken
    }
  };
};

const buildTransportConfig = () =>
  buildResendTransportConfig()
  || buildSmtpTransportConfig()
  || buildGmailOauthTransportConfig();

const getTransportContext = async () => {
  if (!transporterPromise) {
    transporterPromise = (async () => {
      const config = buildTransportConfig();
      if (!config) return null;

      return {
        ...config,
        ...(config.transporterOptions
          ? { transporter: nodemailer.createTransport(config.transporterOptions) }
          : {})
      };
    })();
  }

  return transporterPromise;
};

export const canUseDevEmailFallback = () =>
  process.env.NODE_ENV === "test"
    || parseBoolean(process.env.EMAIL_DEV_FALLBACK, false);

export const resetEmailTransportForTests = () => {
  transporterPromise = null;
};

export const sendEmail = async ({ to, subject, text, html }) => {
  const context = await getTransportContext();

  if (!context) {
    if (canUseDevEmailFallback()) {
      return {
        deliveryMode: "dev-fallback",
        accepted: [to],
        rejected: [],
        response: "Email transport is not configured"
      };
    }

    const error = new Error("Email transport is not configured");
    error.status = 500;
    error.code = "EMAIL_TRANSPORT_NOT_CONFIGURED";
    throw error;
  }

  if (!context.from) {
    const error = new Error("MAIL_FROM is required to send email");
    error.status = 500;
    error.code = "MAIL_FROM_MISSING";
    throw error;
  }

  if (context.mode === "resend-api") {
    const { data, error } = await context.resend.emails.send({
      from: context.from,
      to: [to],
      subject,
      text,
      ...(html ? { html } : {})
    });

    if (error) {
      const resendError = new Error(error.message || "Failed to send Resend email");
      resendError.status = 502;
      resendError.code = "RESEND_SEND_FAILED";
      throw resendError;
    }

    return {
      deliveryMode: context.mode,
      accepted: [to],
      rejected: [],
      response: data?.id || "resend-api-ok"
    };
  }

  if (context.mode === "gmail-api") {
    const tokenResponse = await fetch(GMAIL_TOKEN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: new URLSearchParams({
        client_id: context.gmailConfig.clientId,
        client_secret: context.gmailConfig.clientSecret,
        refresh_token: context.gmailConfig.refreshToken,
        grant_type: "refresh_token"
      })
    });

    const tokenPayload = await tokenResponse.json().catch(() => null);
    if (!tokenResponse.ok || !tokenPayload?.access_token) {
      const error = new Error(tokenPayload?.error_description || tokenPayload?.error || "Failed to obtain Gmail access token");
      error.status = 502;
      throw error;
    }

    const boundary = `tawsil-${Date.now().toString(16)}`;
    const messageLines = [
      `From: ${context.from}`,
      `To: ${to}`,
      `Subject: ${subject}`,
      "MIME-Version: 1.0"
    ];

    if (html) {
      messageLines.push(`Content-Type: multipart/alternative; boundary="${boundary}"`, "");
      messageLines.push(`--${boundary}`);
      messageLines.push('Content-Type: text/plain; charset="UTF-8"', "");
      messageLines.push(text || "");
      messageLines.push(`--${boundary}`);
      messageLines.push('Content-Type: text/html; charset="UTF-8"', "");
      messageLines.push(html);
      messageLines.push(`--${boundary}--`);
    } else {
      messageLines.push('Content-Type: text/plain; charset="UTF-8"', "", text || "");
    }

    const rawMessage = Buffer.from(messageLines.join("\r\n"))
      .toString("base64")
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/g, "");

    const sendResponse = await fetch(GMAIL_SEND_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${tokenPayload.access_token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ raw: rawMessage })
    });

    const sendPayload = await sendResponse.json().catch(() => null);
    if (!sendResponse.ok) {
      const error = new Error(sendPayload?.error?.message || "Failed to send Gmail message");
      error.status = 502;
      throw error;
    }

    return {
      deliveryMode: context.mode,
      accepted: [to],
      rejected: [],
      response: sendPayload?.id || "gmail-api-ok"
    };
  }

  const info = await context.transporter.sendMail({
    from: context.from,
    to,
    subject,
    text,
    ...(html ? { html } : {})
  });

  return {
    ...info,
    deliveryMode: context.mode
  };
};
