import { Op } from "sequelize";
import PrintJob from "../models/PrintJob.js";
import RestaurantPrinter from "../models/RestaurantPrinter.js";
import Order from "../models/Order.js";
import { emit } from "../config/socket.js";
import { getOrderByIdService } from "../services/orders/queries.service.js";

/**
 * GET /cashier/print-jobs/pending
 * Récupère les jobs d'impression en attente pour le restaurant du cashier
 */
export const getPendingPrintJobs = async (req, res, next) => {
  try {
    const restaurantId = req.user.restaurant_id;
    
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        message: "Restaurant ID non trouvé"
      });
    }

    const jobs = await PrintJob.findAll({
      where: {
        restaurant_id: restaurantId,
        status: "pending"
      },
      include: [
        {
          model: RestaurantPrinter,
          as: "printer",
          attributes: ["id", "name", "type", "ip", "port", "paper_width_mm", "is_enabled"]
        },
        {
          model: Order,
          as: "order",
          attributes: ["id", "order_number", "total_amount", "order_type"]
        }
      ],
      order: [["created_at", "ASC"]],
      limit: 50 // Limiter pour éviter de surcharger
    });

    res.json({
      success: true,
      data: jobs,
      count: jobs.length
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /cashier/print-jobs/:id/complete
 * Marque un job d'impression comme complété
 * Body: { success: boolean, error_message?: string }
 */
export const completePrintJob = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { success, error_message } = req.body;
    const deviceId = req.user.cashier_id || req.user.id || "unknown";

    const job = await PrintJob.findByPk(id);
    if (!job) {
      return res.status(404).json({
        success: false,
        message: "Job d'impression introuvable"
      });
    }

    // Vérifier que le job appartient au restaurant du cashier
    if (job.restaurant_id !== req.user.restaurant_id) {
      return res.status(403).json({
        success: false,
        message: "Non autorisé"
      });
    }

    if (success) {
      job.status = "completed";
      job.processed_by = deviceId;
      job.processed_at = new Date();
      job.error_message = null;
    } else {
      job.retry_count += 1;
      if (job.retry_count >= job.max_retries) {
        job.status = "failed";
        job.error_message = error_message || "Échec après plusieurs tentatives";
      } else {
        // Réessayer plus tard
        job.status = "pending";
        job.error_message = error_message;
      }
    }

    await job.save();

    res.json({
      success: true,
      message: success ? "Job marqué comme complété" : "Job marqué comme échoué",
      data: job
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /cashier/print-jobs/:id/claim
 * Marque un job comme en cours de traitement (pour éviter les doublons)
 */
export const claimPrintJob = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deviceId = req.user.cashier_id || req.user.id || "unknown";

    const job = await PrintJob.findByPk(id);
    if (!job) {
      return res.status(404).json({
        success: false,
        message: "Job d'impression introuvable"
      });
    }

    // Vérifier que le job appartient au restaurant du cashier
    if (job.restaurant_id !== req.user.restaurant_id) {
      return res.status(403).json({
        success: false,
        message: "Non autorisé"
      });
    }

    // Vérifier que le job est toujours en attente
    if (job.status !== "pending") {
      return res.status(400).json({
        success: false,
        message: `Le job est déjà ${job.status}`
      });
    }

    // Marquer comme en cours de traitement
    job.status = "processing";
    job.processed_by = deviceId;
    await job.save();

    // Récupérer les données complètes de la commande
    const orderData = await getOrderByIdService(job.order_id);

    res.json({
      success: true,
      message: "Job réclamé avec succès",
      data: {
        job: job.toJSON(),
        order: orderData,
        printer: await RestaurantPrinter.findByPk(job.printer_id, {
          attributes: ["id", "name", "type", "ip", "port", "paper_width_mm", "is_enabled"]
        })
      }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /restaurant/admin/print-jobs/queue
 * Crée un job d'impression (appelé par le backend quand l'impression directe échoue)
 * Body: { printer_id, order_id }
 */
export const queuePrintJob = async (req, res, next) => {
  try {
    const { printer_id, order_id } = req.body;
    const restaurantId = req.user.restaurant_id || req.body.restaurant_id;

    if (!printer_id || !order_id || !restaurantId) {
      return res.status(400).json({
        success: false,
        message: "printer_id, order_id et restaurant_id sont requis"
      });
    }

    // Vérifier que l'imprimante existe
    const printer = await RestaurantPrinter.findByPk(printer_id);
    if (!printer) {
      return res.status(404).json({
        success: false,
        message: "Imprimante introuvable"
      });
    }

    // Vérifier que la commande existe
    const order = await Order.findByPk(order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Commande introuvable"
      });
    }

    // Créer le job
    const existing = await PrintJob.findOne({
      where: {
        restaurant_id: restaurantId,
        printer_id: printer_id,
        order_id: order_id,
        status: { [Op.in]: ["pending", "processing"] }
      }
    });

    const job = existing || await PrintJob.create({
      restaurant_id: restaurantId,
      printer_id: printer_id,
      order_id: order_id,
      status: "pending"
    });

    // Notify POS cashiers via Socket.IO
    if (!existing) {
      emit(`restaurant:${restaurantId}`, "print_job:queued", {
        job_id: job.id,
        restaurant_id: restaurantId,
        printer_id: printer_id,
        order_id: order_id
      });
    }

    res.status(201).json({
      success: true,
      message: "Job d'impression créé",
      data: job
    });
  } catch (err) {
    next(err);
  }
};
