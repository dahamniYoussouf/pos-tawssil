import { DataTypes } from "sequelize";
import { sequelize } from "../config/database.js";
import { normalizePhoneNumber } from "../utils/phoneNormalizer.js";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES } from "../utils/locale.js";

const isTestEnv = process.env.NODE_ENV === "test";

const restaurantIndexes = [
  {
    fields: ['status']
  },
  {
    fields: ['is_active']
  },
  {
    fields: ['is_premium']
  },
  {
    fields: ['commune_id']
  }
];

if (!isTestEnv) {
  restaurantIndexes.push(
    {
      fields: ['location'],
      using: 'gist',
      name: 'restaurants_location_gix'
    }
  );
}

const Restaurant = sequelize.define('Restaurant', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    allowNull: false,
    primaryKey: true,
    comment: "Primary key (UUID)",
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
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true
  },
    phone_number: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Restaurant contact phone number'
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isEmail: true
    },
    comment: 'Restaurant contact email'
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
    comment: "Restaurant preferred locale (ar/fr/en)"
  },
  location: isTestEnv
    ? {
        type: DataTypes.JSON,
        allowNull: true,
      }
    : {
        type: DataTypes.GEOGRAPHY('POINT', 4326),
        allowNull: false,
        validate: {
          notNull: {
            msg: 'La localisation est requise'
          }
        }
      },
  rating: {
    type: DataTypes.DECIMAL(2, 1),
    allowNull: true,
    defaultValue: 0.0,
    validate: {
      min: 0.0,
      max: 5.0
    },
    comment: 'Note sur 5 étoiles'
  },
  image_url: {
    type: DataTypes.STRING,
    allowNull: true,
    validate: {
      isUrl: true
    },
    comment: 'URL de l\'image principale du restaurant'
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    allowNull: false,
    comment: 'Restaurant actif ou non'
  },
  is_premium: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    allowNull: false,
    comment: 'Restaurant premium ou non'
  },
  status: {
    type: DataTypes.ENUM("pending", "approved", "suspended", "archived"),
    defaultValue: "pending"
  },
  availability_status: {
    type: DataTypes.ENUM("open", "closed", "vacation", "saturated", "other"),
    allowNull: false,
    defaultValue: "open",
    comment: "Operational availability status for clients"
  },
  availability_note: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: "Optional note explaining availability status"
  },
  opening_hours: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: "Opening hours per day, e.g.: { Mon: {open: 9:00 a.m., close: 6:00 p.m.}, Tue: {...} }"
  }, 
  commune_id: {
    type: DataTypes.UUID,
    allowNull: true,
    comment: "Reference to commune"
  }
}, {
  tableName: 'restaurants',
  timestamps: true,
  underscored: true, 
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  hooks: {
    beforeCreate: async (restaurant) => {
      if (restaurant.phone_number) {
        restaurant.phone_number = normalizePhoneNumber(restaurant.phone_number);
      }
    },
    beforeUpdate: async (restaurant) => {
      if (restaurant.changed('phone_number') && restaurant.phone_number) {
        restaurant.phone_number = normalizePhoneNumber(restaurant.phone_number);
      }
    }
  },
  indexes: restaurantIndexes
});

// Helper methods
Restaurant.prototype.setCoordinates = function(longitude, latitude) {
  this.location = {
    type: 'Point',
    coordinates: [longitude, latitude]
  };
};

Restaurant.prototype.getCoordinates = function() {
  if (this.location && this.location.coordinates) {
    return {
      longitude: this.location.coordinates[0],
      latitude: this.location.coordinates[1]
    };
  }
  return null;
};


Restaurant.prototype.isOpen = function () {
  if (!this.opening_hours) return false;

  const availabilityStatus = (this.availability_status || "open").toLowerCase();
  if (availabilityStatus !== "open") return false;

  const now = new Date();
  const day = now.toLocaleDateString("en-US", { weekday: "short" }).toLowerCase();
  const currentTime = now.getHours() * 100 + now.getMinutes();

  const todayHours = this.opening_hours[day];
  if (!todayHours) return false;

  return currentTime >= todayHours.open && currentTime <= todayHours.close;
};

export default Restaurant;
