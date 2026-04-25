import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";

const PrinterTemplate = sequelize.define(
  "PrinterTemplate",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    restaurant_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: "restaurants", key: "id" },
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    },
    printer_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: { model: "restaurant_printers", key: "id" },
      onDelete: "SET NULL",
      onUpdate: "CASCADE",
      comment: "Si null, template par défaut pour le type",
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false,
      comment: "Nom du template (ex: Ticket Caisse Standard)",
    },
    type: {
      type: DataTypes.STRING(50),
      allowNull: false,
      defaultValue: "general",
      comment: "general | caisse | cuisine | bar",
    },
    template_content: {
      type: DataTypes.TEXT,
      allowNull: false,
      comment: "Contenu du template avec variables (ex: {{orderNumber}}, {{date}})",
    },
    is_default: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
      comment: "Template par défaut pour ce type",
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    preview_image_url: {
      type: DataTypes.STRING,
      allowNull: true,
      comment: "URL de l'image de prévisualisation (optionnel)",
    },
  },
  {
    tableName: "printer_templates",
    timestamps: true,
    underscored: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      {
        fields: ["restaurant_id", "type"],
      },
      {
        fields: ["printer_id"],
      },
      {
        fields: ["is_default"],
      },
    ],
  }
);

export default PrinterTemplate;
