import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";

const DatabaseBackup = sequelize.define('DatabaseBackup', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    allowNull: false,
    primaryKey: true,
    comment: "Primary key (UUID)"
  },
  filename: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: "Backup file name"
  },
  file_path: {
    type: DataTypes.TEXT,
    allowNull: false,
    comment: "Absolute path to the backup file"
  },
  file_size: {
    type: DataTypes.BIGINT,
    allowNull: true,
    comment: "Backup size in bytes"
  },
  checksum: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: "SHA256 checksum"
  },
  status: {
    type: DataTypes.ENUM('pending', 'completed', 'failed', 'restoring', 'restored'),
    allowNull: false,
    defaultValue: 'pending',
    comment: "Backup status"
  },
  source: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'manual',
    comment: "Backup source (manual/auto/pre-restore)"
  },
  label: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: "Optional label provided by the admin"
  },
  database_name: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: "Database name at backup time"
  },
  stats: {
    type: DataTypes.JSONB,
    allowNull: true,
    comment: "Snapshot counts (orders, restaurants, clients, admins, drivers)"
  },
  error_message: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: "Last error message if failed"
  },
  created_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'admins',
      key: 'id'
    },
    comment: "Admin who created the backup"
  },
  restored_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'admins',
      key: 'id'
    },
    comment: "Admin who restored the backup"
  },
  restored_at: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: "Restore timestamp"
  }
}, {
  tableName: 'database_backups',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      fields: ['created_at']
    },
    {
      fields: ['status']
    }
  ]
});

export default DatabaseBackup;
