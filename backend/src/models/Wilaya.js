import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";

const Wilaya = sequelize.define(
  "Wilaya",
  {
    code: {
      type: DataTypes.STRING(10),
      allowNull: false,
      primaryKey: true,
      comment: "Wilaya code"
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      comment: "Wilaya name (FR)"
    },
    name_ar: {
      type: DataTypes.STRING,
      allowNull: true,
      comment: "Wilaya name (AR)"
    }
  },
  {
    tableName: "wilayas",
    timestamps: true,
    underscored: true,
    createdAt: "created_at",
    updatedAt: "updated_at"
  }
);

export default Wilaya;
