export function errorHandler(err, req, res, next) {
  const status = err?.status || err?.statusCode || 500;
  const message = err?.message || "Internal Server Error";

  // body-parser invalid JSON payload (Content-Type: application/json)
  if (status === 400 && err?.type === "entity.parse.failed") {
    const preview =
      typeof err?.body === "string" ? err.body.slice(0, 200) : undefined;

    console.warn(`[400 INVALID_JSON] ${req.method} ${req.originalUrl}`, {
      ip: req.ip,
      user_agent: req.get("user-agent"),
      content_type: req.get("content-type"),
      ...(preview ? { body_preview: preview } : {})
    });

    return res.status(400).json({
      success: false,
      message: "Invalid JSON body",
      code: "INVALID_JSON",
      error: "Invalid JSON body",
      ...(process.env.NODE_ENV !== "production" &&
        preview && { body_preview: preview })
    });
  }

  if (status >= 500) {
    console.error("Unhandled error:", err);
  } else {
    console.warn(`[${status}] ${req.method} ${req.originalUrl} - ${message}`);
  }

  // En production, masquer les détails des erreurs 500
  if (status === 500 && process.env.NODE_ENV === "production") {
    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: "Internal Server Error"
    });
  }

  res.status(status).json({
    success: false,
    message,
    error: message,
    ...(process.env.NODE_ENV !== "production" && { stack: err?.stack })
  });
}

export function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    message: "Route not found",
    error: "Route not found"
  });
}
