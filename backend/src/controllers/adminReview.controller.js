import * as adminReviewService from "../services/orders/adminReview.service.js";

export const getReviewQueue = async (req, res, next) => {
  try {
    const adminId = req.user?.admin_id;
    const result = await adminReviewService.getReviewQueue(req.query, adminId || null);

    res.json({
      success: true,
      count: result.pagination.total_items,
      data: result.orders,
      pagination: result.pagination
    });
  } catch (error) {
    next(error);
  }
};

export const claimReviewOrder = async (req, res, next) => {
  try {
    const adminId = req.user?.admin_id;
    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin profile not found in token"
      });
    }

    const order = await adminReviewService.claimReviewOrder(req.params.id, adminId);
    res.json({
      success: true,
      message: "Order claimed for client review",
      data: order
    });
  } catch (error) {
    if (error?.status) {
      return res.status(error.status).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

export const releaseReviewOrder = async (req, res, next) => {
  try {
    const adminId = req.user?.admin_id;
    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin profile not found in token"
      });
    }

    const order = await adminReviewService.releaseReviewOrder(req.params.id, adminId);
    res.json({
      success: true,
      message: "Client review lock released",
      data: order
    });
  } catch (error) {
    if (error?.status) {
      return res.status(error.status).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

export const approveReviewOrder = async (req, res, next) => {
  try {
    const adminId = req.user?.admin_id;
    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin profile not found in token"
      });
    }

    const order = await adminReviewService.approveReviewOrder(req.params.id, adminId, req.body || {});
    res.json({
      success: true,
      message: "Order approved and forwarded to restaurant",
      data: order
    });
  } catch (error) {
    if (error?.status) {
      return res.status(error.status).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

export const rejectReviewOrder = async (req, res, next) => {
  try {
    const adminId = req.user?.admin_id;
    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin profile not found in token"
      });
    }

    const order = await adminReviewService.rejectReviewOrder(req.params.id, adminId, req.body || {});
    res.json({
      success: true,
      message: "Order rejected during admin review",
      data: order
    });
  } catch (error) {
    if (error?.status) {
      return res.status(error.status).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};
