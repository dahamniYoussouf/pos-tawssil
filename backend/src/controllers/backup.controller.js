import * as backupService from "../services/databaseBackup.service.js";

export const listBackups = async (req, res, next) => {
  try {
    const backups = await backupService.listBackups();
    res.json({
      success: true,
      data: backups,
      retention: backupService.getRetentionCount()
    });
  } catch (error) {
    next(error);
  }
};

export const createBackup = async (req, res, next) => {
  try {
    const label = req.body?.label ? String(req.body.label).trim() : null;
    const adminId = req.user?.admin_id || null;
    const backup = await backupService.createBackup({ adminId, label, source: "manual" });

    res.status(201).json({
      success: true,
      message: "Backup created successfully",
      data: {
        id: backup.id,
        filename: backup.filename,
        status: backup.status,
        created_at: backup.created_at
      }
    });
  } catch (error) {
    next(error);
  }
};

export const restoreBackup = async (req, res, next) => {
  try {
    const confirm = req.body?.confirm === true;
    const confirmText = String(req.body?.confirm_text || "").trim();

    if (!confirm || confirmText !== "RESTORE") {
      return res.status(400).json({
        success: false,
        message: "Confirmation required",
        error: "Please confirm by setting confirm=true and confirm_text=RESTORE"
      });
    }

    const adminId = req.user?.admin_id || null;
    const skipPreBackup = req.body?.skip_pre_backup === true;
    const backup = await backupService.restoreBackup({
      backupId: req.params.id,
      adminId,
      skipPreBackup
    });

    res.json({
      success: true,
      message: "Backup restored successfully",
      data: {
        id: backup.id,
        status: backup.status,
        restored_at: backup.restored_at
      }
    });
  } catch (error) {
    next(error);
  }
};

export const deleteBackup = async (req, res, next) => {
  try {
    await backupService.deleteBackup(req.params.id);
    res.json({
      success: true,
      message: "Backup deleted successfully"
    });
  } catch (error) {
    next(error);
  }
};
