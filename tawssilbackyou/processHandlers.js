const FIREBASE_NETWORK_BACKOFF_MS = Number.parseInt(
  process.env.FIREBASE_NETWORK_BACKOFF_MS || "300000",
  10
);

let firebaseBackoffTimer = null;

const getErrorMessage = (value) => {
  if (!value) return "";
  if (value instanceof Error) return value.message || String(value);
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value);
  } catch (_error) {
    return String(value);
  }
};

const isFirebaseNetworkError = (error) => {
  const message = getErrorMessage(error);
  const errorInfoCode = error?.errorInfo?.code || "";
  const errorCode = error?.code || "";

  if (errorInfoCode === "app/network-error" || errorCode === "app/network-error") {
    return true;
  }

  // Typical DNS/network failures seen when Firebase FCM is unreachable.
  if (message.includes("fcm.googleapis.com")) return true;
  if (message.includes("messaging.googleapis.com")) return true;
  if (message.includes("getaddrinfo") && message.includes("EAI_AGAIN")) return true;
  if (message.includes("ENOTFOUND") && message.includes("googleapis.com")) return true;

  return false;
};

const disableFirebaseTemporarily = (error) => {
  if (process.env.NOTIFICATION_FIREBASE_ENABLED === "false") return;

  process.env.NOTIFICATION_FIREBASE_ENABLED = "false";
  console.error(
    `[FCM] Disabling Firebase notifications for ${FIREBASE_NETWORK_BACKOFF_MS}ms due to network error: ${getErrorMessage(error)}`
  );

  if (firebaseBackoffTimer) {
    clearTimeout(firebaseBackoffTimer);
  }

  firebaseBackoffTimer = setTimeout(() => {
    // Only block when explicitly set to "false". Any other value means enabled.
    process.env.NOTIFICATION_FIREBASE_ENABLED = "true";
    console.error("[FCM] Re-enabled Firebase notifications after backoff window");
    firebaseBackoffTimer = null;
  }, FIREBASE_NETWORK_BACKOFF_MS);

  firebaseBackoffTimer?.unref?.();
};

// Handle unhandled promise rejections
process.on("unhandledRejection", (reason, promise) => {
  if (isFirebaseNetworkError(reason)) {
    disableFirebaseTemporarily(reason);
    console.error("⚠️ Firebase network unhandled rejection:", reason);
    return;
  }

  console.error("🚨 Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});

// Handle uncaught exceptions
process.on("uncaughtException", (error) => {
  if (isFirebaseNetworkError(error)) {
    disableFirebaseTemporarily(error);
    console.error("⚠️ Firebase network uncaught exception (ignored to keep API running):", error);
    return;
  }

  console.error("💥 Uncaught Exception:", error);
  process.exit(1);
});
