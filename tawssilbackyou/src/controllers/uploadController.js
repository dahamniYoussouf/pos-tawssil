// Controller layer for file uploads
// Handles HTTP requests/responses and delegates logic to the service.

import { buildLocalUploadResponse } from "../services/fileUpload.service.js";

/**
 * Handle file upload request
 */
export const uploadFile = async (req, res) => {
  try {
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: "No file provided" });
    }

    const result = buildLocalUploadResponse(file);
    const rawUrl = result.url;
    let publicUrl = rawUrl;

    if (typeof rawUrl === "string" && !rawUrl.startsWith("http://") && !rawUrl.startsWith("https://")) {
      const host = req.get("x-forwarded-host") || req.get("host");
      const protocol = req.protocol || "http";
      const normalizedPath = rawUrl.startsWith("/") ? rawUrl : `/${rawUrl}`;
      const publicPath = normalizedPath.startsWith("/uploads/")
        ? `/api${normalizedPath}`
        : normalizedPath;
      publicUrl = `${protocol}://${host}${publicPath}`;
    }

    res.status(200).json({
      success: true,
      url: publicUrl,
    });
  } catch (error) {
    console.error("File upload error:", error);
    res.status(500).json({
      success: false,
      error: "Upload failed",
    });
  }
};
