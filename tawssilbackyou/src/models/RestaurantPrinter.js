import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";

const RestaurantPrinter = sequelize.define(
  "RestaurantPrinter",
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
    name: {
      type: DataTypes.STRING(255),
      allowNull: false,
      comment: "Nom affiché: Caisse 1, Cuisine, Bar...",
    },
    type: {
      type: DataTypes.STRING(50),
      allowNull: false,
      defaultValue: "general",
      comment: "general | caisse | cuisine",
    },
    ip: {
      type: DataTypes.STRING(45),
      allowNull: false,
      comment: "Adresse IP de l'imprimante réseau (LAN)",
    },
    port: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 9100,
      comment: "Port RAW (souvent 9100) pour ESC/POS",
    },
    is_enabled: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    paper_width_mm: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 80,
      comment: "58 ou 80 mm",
    },
  },
  {
    tableName: "restaurant_printers",
    timestamps: true,
    underscored: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
  }
);

export default RestaurantPrinter;
