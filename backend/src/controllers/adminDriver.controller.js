import Driver from "../models/Driver.js";

/**
 * POST /admin/drivers/:id/restore
 * Restore a suspended driver (reactivate + set a non-suspended status).
 */
export const restoreDriver = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;

    const driver = await Driver.findByPk(id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: "Driver not found"
      });
    }

    const restoredAt = new Date().toISOString();
    const restoreNote = `[${restoredAt}] RESTORED: ${notes || "Restored by admin"}`;
    const mergedNotes = [driver.notes, restoreNote].filter(Boolean).join("\n");

    const hasActiveOrders =
      Array.isArray(driver.active_orders) && driver.active_orders.length > 0;

    await driver.update({
      status: hasActiveOrders ? "busy" : "offline",
      is_active: true,
      notes: mergedNotes
    });

    res.json({
      success: true,
      message: "Driver restored successfully",
      data: {
        driver_id: driver.id,
        driver_code: driver.driver_code,
        status: driver.status,
        is_active: driver.is_active
      }
    });
  } catch (err) {
    next(err);
  }
};

