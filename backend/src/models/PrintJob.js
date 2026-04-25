import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";

const PrintJob = sequelize.define(
  "PrintJob",
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
      allowNull: false,
      references: { model: "restaurant_printers", key: "id" },
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    },
    order_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: { model: "orders", key: "id" },
      onDelete: "CASCADE",
      onUpdate: "CASCADE",
    },
    status: {
      type: DataTypes.ENUM("pending", "processing", "completed", "failed"),
      allowNull: false,
      defaultValue: "pending",
    },
    error_message: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    processed_by: {
      type: DataTypes.STRING(255),
      allowNull: true,
      comment: "ID of POS device that processed this job",
    },
    processed_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    retry_count: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    max_retries: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 3,
    },
  },
  {
    tableName: "print_jobs",
    timestamps: true,
    underscored: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      {
        fields: ["restaurant_id", "status"],
        name: "idx_print_jobs_restaurant_status",
      },
      {
        fields: ["status", "created_at"],
        name: "idx_print_jobs_status_created",
      },
      {
        fields: ["order_id"],
        name: "idx_print_jobs_order",
      },
    ],
  }
);

export default PrintJob;
