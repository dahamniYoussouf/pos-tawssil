import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";

const OptionGroup = sequelize.define("OptionGroup", {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  menu_item_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  nom: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
  },
  is_required: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  ordre_affichage: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
}, {
  tableName: "option_groups",
  timestamps: true,
  underscored: true,
  createdAt: "created_at",
  updatedAt: "updated_at",
  indexes: [
    { fields: ["menu_item_id"] },
    { fields: ["menu_item_id", "is_required"] },
  ],
});

export default OptionGroup;
