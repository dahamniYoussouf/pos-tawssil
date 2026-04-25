import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES } from "../utils/locale.js";

const NewsletterSubscriber = sequelize.define(
  "NewsletterSubscriber",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      allowNull: false,
      primaryKey: true
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
      validate: {
        isEmail: {
          msg: "Invalid email address"
        }
      }
    },
    name: {
      type: DataTypes.STRING(120),
      allowNull: true
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
      }
    },
    source: {
      type: DataTypes.STRING(50),
      allowNull: true,
      defaultValue: "landing"
    },
    status: {
      type: DataTypes.ENUM("subscribed", "unsubscribed"),
      allowNull: false,
      defaultValue: "subscribed"
    },
    unsubscribed_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    ip_address: {
      type: DataTypes.STRING(64),
      allowNull: true
    },
    user_agent: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    metadata: {
      type: DataTypes.JSONB,
      allowNull: true
    }
  },
  {
    tableName: "newsletter_subscribers",
    timestamps: true,
    underscored: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      { unique: true, fields: ["email"] },
      { fields: ["status"] },
      { fields: ["locale"] },
      { fields: ["source"] }
    ]
  }
);

export default NewsletterSubscriber;
