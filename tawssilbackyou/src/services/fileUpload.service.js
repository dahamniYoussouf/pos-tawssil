// Service layer for file uploads
// Builds public URLs for files stored on local disk.

/**
 * Build the public URL for a locally stored upload.
 * @param {Object} file - The file object from Multer middleware
 * @returns {Object} - Returns the public URL of the uploaded file
 */
export const buildLocalUploadResponse = (file) => {
  if (!file?.filename) {
    throw new Error("No file provided");
  }

  return { url: `/uploads/${file.filename}` };
};
