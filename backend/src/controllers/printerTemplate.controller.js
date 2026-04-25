import PrinterTemplate from "../models/PrinterTemplate.js";
import Restaurant from "../models/Restaurant.js";
import RestaurantPrinter from "../models/RestaurantPrinter.js";
import { renderTemplate, templateToEscPos, getAvailableVariables, getAvailableCommands } from "../services/templateRendererService.js";

/**
 * GET /restaurant/admin/printer-templates/:restaurantId
 * Liste les templates d'un restaurant
 */
export const listByRestaurant = async (req, res, next) => {
  try {
    const { restaurantId } = req.params;
    const templates = await PrinterTemplate.findAll({
      where: { restaurant_id: restaurantId },
      include: [
        { model: RestaurantPrinter, as: "printer", attributes: ["id", "name"], required: false },
      ],
      order: [["type", "ASC"], ["is_default", "DESC"], ["created_at", "ASC"]],
    });
    res.json({ success: true, data: templates });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /restaurant/admin/printer-templates/:restaurantId/:type
 * Récupère le template par défaut pour un type donné
 */
export const getDefaultByType = async (req, res, next) => {
  try {
    const { restaurantId, type } = req.params;
    
    // Chercher d'abord un template par défaut pour ce type
    let template = await PrinterTemplate.findOne({
      where: {
        restaurant_id: restaurantId,
        type: type,
        is_default: true,
        is_active: true,
      },
    });
    
    // Sinon, chercher n'importe quel template actif pour ce type
    if (!template) {
      template = await PrinterTemplate.findOne({
        where: {
          restaurant_id: restaurantId,
          type: type,
          is_active: true,
        },
        order: [["created_at", "ASC"]],
      });
    }
    
    // Sinon, template général par défaut
    if (!template) {
      template = await PrinterTemplate.findOne({
        where: {
          restaurant_id: restaurantId,
          type: "general",
          is_active: true,
        },
        order: [["created_at", "ASC"]],
      });
    }
    
    if (!template) {
      return res.status(404).json({
        success: false,
        message: "Aucun template trouvé",
      });
    }
    
    res.json({ success: true, data: template });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /restaurant/admin/printer-templates/:id
 * Récupère un template par ID
 */
export const getById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const template = await PrinterTemplate.findByPk(id, {
      include: [
        { model: RestaurantPrinter, as: "printer", attributes: ["id", "name"], required: false },
      ],
    });
    
    if (!template) {
      return res.status(404).json({
        success: false,
        message: "Template introuvable",
      });
    }
    
    res.json({ success: true, data: template });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /restaurant/admin/printer-templates
 * Crée un nouveau template
 * Body: { restaurant_id, printer_id?, name, type, template_content, is_default?, is_active? }
 */
export const create = async (req, res, next) => {
  try {
    const {
      restaurant_id,
      printer_id,
      name,
      type,
      template_content,
      is_default = false,
      is_active = true,
    } = req.body;
    
    if (!restaurant_id || !name || !type || !template_content) {
      return res.status(400).json({
        success: false,
        message: "restaurant_id, name, type et template_content sont requis",
      });
    }
    
    // Vérifier que le restaurant existe
    const restaurant = await Restaurant.findByPk(restaurant_id, { attributes: ["id"] });
    if (!restaurant) {
      return res.status(404).json({ success: false, message: "Restaurant introuvable" });
    }
    
    // Vérifier que l'imprimante existe si fournie
    if (printer_id) {
      const printer = await RestaurantPrinter.findByPk(printer_id, { attributes: ["id"] });
      if (!printer) {
        return res.status(404).json({ success: false, message: "Imprimante introuvable" });
      }
    }
    
    // Si ce template est marqué comme défaut, désactiver les autres par défaut du même type
    if (is_default) {
      await PrinterTemplate.update(
        { is_default: false },
        {
          where: {
            restaurant_id,
            type,
            is_default: true,
          },
        }
      );
    }
    
    const template = await PrinterTemplate.create({
      restaurant_id,
      printer_id: printer_id || null,
      name: String(name).trim(),
      type: ["general", "caisse", "cuisine", "bar"].includes(String(type || "").toLowerCase())
        ? String(type).toLowerCase()
        : "general",
      template_content: String(template_content).trim(),
      is_default: !!is_default,
      is_active: is_active !== false,
    });
    
    res.status(201).json({ success: true, data: template });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /restaurant/admin/printer-templates/:id
 * Met à jour un template
 */
export const update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const template = await PrinterTemplate.findByPk(id);
    
    if (!template) {
      return res.status(404).json({ success: false, message: "Template introuvable" });
    }
    
    const {
      name,
      type,
      template_content,
      printer_id,
      is_default,
      is_active,
    } = req.body;
    
    if (name !== undefined) template.name = String(name).trim();
    if (type !== undefined) {
      template.type = ["general", "caisse", "cuisine", "bar"].includes(String(type || "").toLowerCase())
        ? String(type).toLowerCase()
        : template.type;
    }
    if (template_content !== undefined) template.template_content = String(template_content).trim();
    if (printer_id !== undefined) {
      if (printer_id) {
        const printer = await RestaurantPrinter.findByPk(printer_id, { attributes: ["id"] });
        if (!printer) {
          return res.status(404).json({ success: false, message: "Imprimante introuvable" });
        }
        template.printer_id = printer_id;
      } else {
        template.printer_id = null;
      }
    }
    if (is_default !== undefined) {
      // Si on définit comme défaut, désactiver les autres
      if (is_default) {
        await PrinterTemplate.update(
          { is_default: false },
          {
            where: {
              restaurant_id: template.restaurant_id,
              type: template.type,
              is_default: true,
              id: { [require("sequelize").Op.ne]: id },
            },
          }
        );
      }
      template.is_default = !!is_default;
    }
    if (is_active !== undefined) template.is_active = !!is_active;
    
    await template.save();
    res.json({ success: true, data: template });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /restaurant/admin/printer-templates/:id
 * Supprime un template
 */
export const remove = async (req, res, next) => {
  try {
    const { id } = req.params;
    const template = await PrinterTemplate.findByPk(id);
    
    if (!template) {
      return res.status(404).json({ success: false, message: "Template introuvable" });
    }
    
    await template.destroy();
    res.json({ success: true, message: "Template supprimé" });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /restaurant/admin/printer-templates/:id/preview
 * Prévisualise un template avec des données de test
 * Body: { order_data? } (optionnel, utilise des données de test sinon)
 */
export const preview = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { order_data } = req.body;
    
    const template = await PrinterTemplate.findByPk(id);
    if (!template) {
      return res.status(404).json({ success: false, message: "Template introuvable" });
    }
    
    // Données de test si non fournies
    const testOrder = order_data || {
      order_number: "TEST-001",
      created_at: new Date(),
      order_type: "pickup",
      order_items: [
        {
          menu_item_name: "Pizza Margherita",
          quantite: 2,
          prix_unitaire: 15.00,
          prix_total: 30.00,
          additions: [
            {
              nom: "Fromage supplémentaire",
              quantite: 1,
              prix_total: 2.50,
            },
          ],
          instructions_speciales: "Sans olives",
        },
        {
          menu_item_name: "Coca Cola",
          quantite: 1,
          prix_unitaire: 3.50,
          prix_total: 3.50,
          additions: [],
        },
        {
          menu_item_name: "Salade César",
          quantite: 1,
          prix_unitaire: 12.00,
          prix_total: 12.00,
          additions: [],
        },
      ],
      subtotal: 48.00,
      delivery_fee: 0,
      total_amount: 48.00,
      payment_method: "cash",
      delivery_address: null,
    };
    
    // Rendre le template
    const rendered = renderTemplate(template.template_content, testOrder, {
      restaurantName: "Restaurant Test",
      cashierName: "Caissier Test",
      cashierCode: "CSH-001",
    });
    
    res.json({
      success: true,
      data: {
        rendered,
        variables: getAvailableVariables(),
        commands: getAvailableCommands(),
      },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /restaurant/admin/printer-templates/variables
 * Liste les variables disponibles
 */
export const getVariables = async (req, res, next) => {
  try {
    res.json({
      success: true,
      data: {
        variables: getAvailableVariables(),
        commands: getAvailableCommands(),
      },
    });
  } catch (err) {
    next(err);
  }
};
