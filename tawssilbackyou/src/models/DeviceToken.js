import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES } from "../utils/locale.js";

const DeviceToken = sequelize.define(
  "DeviceToken",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      allowNull: false,
      primaryKey: true,
      comment: "Primary key (UUID)"
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "users",
        key: "id"
      },
      onDelete: "CASCADE",
      comment: "Reference to user account"
    },
    role: {
      type: DataTypes.STRING(20),
      allowNull: false,
      comment: "User role at registration time"
    },
    profile_id: {
      type: DataTypes.UUID,
      allowNull: true,
      comment: "Role profile id (client/driver/restaurant/admin/cashier)"
    },
    token: {
      type: DataTypes.TEXT,
      allowNull: false,
      unique: true,
      comment: "FCM device token"
    },
    platform: {
      type: DataTypes.STRING(20),
      allowNull: true,
      comment: "Device platform (ios/android/web)"
    },
    device_id: {
      type: DataTypes.STRING(120),
      allowNull: true,
      comment: "Optional device identifier"
    },
    locale: {
      type: DataTypes.STRING(5),
      allowNull: false,
      defaultValue: DEFAULT_LOCALE,
      validate: {
        isIn: {
          args: [SUPPORTED_LOCALES],
          msg: "Locale must be one of: ar, fr, en"
        }
      },
      comment: "Preferred locale for this device token (ar/fr/en)"
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      comment: "Whether token is active"
    },
    last_seen_at: {
      type: DataTypes.DATE,
      allowNull: true,
      comment: "Last time this token was seen"
    }
  },
  {
    tableName: "device_tokens",
    timestamps: true,
    underscored: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      { unique: true, fields: ["token"] },
      { fields: ["user_id"] },
      { fields: ["role"] },
      { fields: ["profile_id"] },
      { fields: ["locale"] },
      { fields: ["is_active"] }
    ]
  }
);

export default DeviceToken;
