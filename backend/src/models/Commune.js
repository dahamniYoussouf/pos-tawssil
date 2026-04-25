import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";

const isTestEnv = process.env.NODE_ENV === "test";

const communeIndexes = [
  {
    fields: ["wilaya_code"]
  },
  {
    fields: ["name"]
  }
];

if (!isTestEnv) {
  communeIndexes.push({
    fields: ["location"],
    using: "gist",
    name: "communes_location_gix"
  });
}

const Commune = sequelize.define("Commune", {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    allowNull: false,
    primaryKey: true,
    comment: "Primary key (UUID)"
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: "Commune name (FR)"
  },
  name_ar: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: "Commune name (AR)"
  },
  wilaya_code: {
    type: DataTypes.STRING(10),
    allowNull: false,
    comment: "Wilaya code"
  },
  wilaya_name: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: "Wilaya name"
  },
  code: {
    type: DataTypes.STRING(20),
    allowNull: true,
    comment: "Optional official commune code"
  },
  location: isTestEnv
    ? {
        type: DataTypes.JSON,
        allowNull: true
      }
    : {
        type: DataTypes.GEOGRAPHY("POINT", 4326),
        allowNull: false,
        comment: "Commune centroid"
      }
}, {
  tableName: "communes",
  timestamps: true,
  underscored: true,
  createdAt: "created_at",
  updatedAt: "updated_at",
  indexes: communeIndexes
});

Commune.prototype.setCoordinates = function(longitude, latitude) {
  this.location = {
    type: "Point",
    coordinates: [longitude, latitude]
  };
};

Commune.prototype.getCoordinates = function() {
  if (this.location && this.location.coordinates) {
    return {
      longitude: this.location.coordinates[0],
      latitude: this.location.coordinates[1]
    };
  }
  return null;
};

export default Commune;
