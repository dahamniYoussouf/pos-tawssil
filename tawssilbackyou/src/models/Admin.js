import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";
import { normalizePhoneNumber } from "../utils/phoneNormalizer.js";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES } from "../utils/locale.js";

const Admin = sequelize.define('Admin', {
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
    unique: true,
    references: {
      model: 'users',
      key: 'id'
    },
    onDelete: 'CASCADE',
    comment: "Reference to user account"
  },
  first_name: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: "Admin's first name"
  },
  last_name: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: "Admin's last name"
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: "Admin's phone number"
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      isEmail: true
    },
    comment: "Admin's email"
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
    comment: "Admin preferred locale (ar/fr/en)"
  },
  role_level: {
    type: DataTypes.ENUM('super_admin', 'admin', 'moderator'),
    defaultValue: 'admin',
    allowNull: false,
    comment: "Admin access level"
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    allowNull: false,
    comment: "Admin account active status"
  }
}, {
  tableName: 'admins',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  hooks: {
    beforeCreate: async (admin) => {
      if (admin.phone) {
        admin.phone = normalizePhoneNumber(admin.phone);
      }
    },
    beforeUpdate: async (admin) => {
      if (admin.changed('phone') && admin.phone) {
        admin.phone = normalizePhoneNumber(admin.phone);
      }
    }
  }
});

// Instance methods
Admin.prototype.getFullName = function() {
  return `${this.first_name} ${this.last_name}`;
};

export default Admin;
