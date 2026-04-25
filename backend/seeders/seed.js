// seeders/seed.js
import { sequelize } from "../src/config/database.js";
import User from "../src/models/User.js";
import Client from "../src/models/Client.js";
import Driver from "../src/models/Driver.js";
import Restaurant from "../src/models/Restaurant.js";
import Commune from "../src/models/Commune.js";
import Wilaya from "../src/models/Wilaya.js";
import Admin from "../src/models/Admin.js";
import AdminNotification from "../src/models/AdminNotification.js";
import SystemConfig from "../src/models/SystemConfig.js"; 
import Announcement from "../src/models/Announcement.js";
import HomeCategory from "../src/models/HomeCategory.js";
import ThematicSelection from "../src/models/ThematicSelection.js";
import RecommendedDish from "../src/models/RecommendedDish.js";
import Promotion from "../src/models/Promotion.js";
import PromotionMenuItem from "../src/models/PromotionMenuItem.js";
import DailyDeal from "../src/models/DailyDeal.js";
import FoodCategory from "../src/models/FoodCategory.js";
import MenuItem from "../src/models/MenuItem.js";
import OptionGroup from "../src/models/OptionGroup.js";
import Addition from "../src/models/Addition.js";
import Order from "../src/models/Order.js";
import OrderItem from "../src/models/OrderItem.js";
import OrderItemAddition from "../src/models/OrderItemAddition.js";
import FavoriteRestaurant from "../src/models/FavoriteRestaurant.js";
import FavoriteMeal from "../src/models/FavoriteMeal.js";
import * as associations from "../src/models/index.js";
import Cashier from "../src/models/Cashier.js";
import { seedHomepageModules } from "./homepageSeeder.js";

import bcrypt from "bcryptjs";
import { randomUUID } from "crypto";
import { readFile } from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

// ===============================
//   Données de base
// ===============================
const firstNames = [
  "Ahmed", "Mohamed", "Fatima", "Karim", "Samira", "Youcef", "Amina", "Rachid", 
  "Nawal", "Omar", "Leila", "Sofiane", "Bilal", "Hichem", "Amine", "Farid",
  "Walid", "Kamel", "Sarah", "Riad", "Yasmine", "Hamza", "Imane", "Mehdi",
  "Salima", "Tarek", "Nadia", "Djamel", "Karima", "Malik"
];

const cashierNames = [
  { first: "Nassim", last: "Boudiaf" },
  { first: "Meriem", last: "Cherif" },
  { first: "Karim", last: "Lahlou" },
  { first: "Rania", last: "Zerrouki" },
  { first: "Youcef", last: "Sadek" },
  { first: "Amina", last: "Khelifi" },
  { first: "Sofiane", last: "Touati" },
  { first: "Leila", last: "Bouzid" }
];

const lastNames = [
  "Benali", "Mansouri", "Bouteflika", "Medjdoub", "Hamidi", "Sadek", "Zerrouki",
  "Touati", "Bouzid", "Khelifi", "Kaddour", "Bellahcene", "Cherif", "Lahlou",
  "Djebar", "Mohand", "Saidi", "Bensalah", "Boudiaf", "Mahrez", "Benaissa",
  "Rahmani", "Taleb", "Bencheikh", "Ouali", "Sahli", "Boualem", "Ferhat"
];

const adminNames = [
  { first: "Kamel", last: "Bensalah", role: "super_admin" },
  { first: "Sarah", last: "Boudiaf", role: "admin" },
  { first: "Riad", last: "Mahrez", role: "moderator" }
];

const restaurantModels = [
  {
    name: "Pizza Palace",
    description: "Authentic Italian pizza with Algerian twist",
    categories: ["pizza", "burger"],
    image: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800"
  },
  {
    name: "Tacos Express",
    description: "Best tacos in Alger with spicy sauce",
    categories: ["tacos"],
    image: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=800"
  },
  {
    name: "Burger King's",
    description: "Premium burgers and fries",
    categories: ["burger"],
    image: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800"
  },
  {
    name: "Sandwich Corner",
    description: "Fresh sandwiches made daily",
    categories: ["sandwish"],
    image: "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=800"
  },
  {
    name: "La Pizzeria",
    description: "Wood-fired pizzas and pasta",
    categories: ["pizza"],
    image: "https://images.unsplash.com/photo-1513104890138-7c749659a513?w=800"
  }
];

const menuItemsByCategory = {
  pizza: [
    { name: "Pizza Margherita", description: "Classic tomato, mozzarella, and basil", price: 850, image: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=500" },
    { name: "Pizza Pepperoni", description: "Spicy pepperoni with extra cheese", price: 950, image: "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=500" },
    { name: "Pizza Quattro Formaggi", description: "Four cheese pizza", price: 1050, image: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500" }
  ],
  burger: [
    { name: "Classic Burger", description: "Beef patty with lettuce, tomato", price: 650, image: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500" },
    { name: "Cheeseburger", description: "Double cheese, special sauce", price: 750, image: "https://images.unsplash.com/photo-1572802419224-296b0aeee0d9?w=500" },
    { name: "Chicken Burger", description: "Crispy chicken with mayo", price: 700, image: "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=500" }
  ],
  tacos: [
    { name: "Tacos Poulet", description: "Chicken, fries, cheese sauce", price: 550, image: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=500" },
    { name: "Tacos Viande", description: "Beef, fries, spicy sauce", price: 600, image: "https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?w=500" }
  ],
  sandwish: [
    { name: "Sandwich Poulet", description: "Grilled chicken sandwich", price: 400, image: "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500" },
    { name: "Sandwich Thon", description: "Tuna with vegetables", price: 350, image: "https://images.unsplash.com/photo-1509722747041-616f39b57569?w=500" }
  ],
  promo: [
    { name: "2tacos+pizza", description: "Combo tacos and pizza", price: 1200, image: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=500" },
    { name: "burger+fries+cola", description: "Burger combo with fries and soda", price: 950, image: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500" },
    { name: "family combo", description: "Pizza, burgers, and drinks", price: 1800, image: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500" }
  ]
};

const restaurant1ExtraCategories = ["salads", "desserts", "drinks"];

const restaurant1ExtraMenuItemsByCategory = {
  pizza: [
    { name: "Pizza BBQ Chicken", description: "BBQ sauce, chicken, onions", price: 1100, image: "https://images.unsplash.com/photo-1594007654729-407eedc4be65?w=500" },
    { name: "Pizza Vegetariana", description: "Seasonal veggies with olives", price: 900, image: "https://images.unsplash.com/photo-1601924582975-7d5f1b8d0a0b?w=500" }
  ],
  burger: [
    { name: "Double Beef Burger", description: "Two patties, cheddar, pickles", price: 950, image: "https://images.unsplash.com/photo-1550547660-d9450f859349?w=500" },
    { name: "Spicy Burger", description: "Chili sauce, jalapenos, onions", price: 880, image: "https://images.unsplash.com/photo-1550547660-0d4d7c0a36f3?w=500" }
  ],
  salads: [
    { name: "Caesar Salad", description: "Romaine, chicken, parmesan, croutons", price: 450, image: "https://images.unsplash.com/photo-1551248429-40975aa4de74?w=500" },
    { name: "Greek Salad", description: "Tomato, cucumber, feta, olives", price: 420, image: "https://images.unsplash.com/photo-1543353071-873f17a7a088?w=500" },
    { name: "Tuna Salad", description: "Tuna, lettuce, corn, egg", price: 480, image: "https://images.unsplash.com/photo-1562967916-eb82221dfb36?w=500" }
  ],
  desserts: [
    { name: "Chocolate Brownie", description: "Warm brownie with chocolate", price: 320, image: "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500" },
    { name: "Cheesecake", description: "Creamy cheesecake slice", price: 360, image: "https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=500" },
    { name: "Fruit Salad", description: "Seasonal fruit mix", price: 300, image: "https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=500" }
  ],
  drinks: [
    { name: "Cola Can", description: "330ml can", price: 150, image: "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=500", optionKey: "drinks_soft" },
    { name: "Orange Juice", description: "Fresh orange juice", price: 200, image: "https://images.unsplash.com/photo-1551024601-bec78aea704b?w=500", optionKey: "drinks_juice" },
    { name: "Water Bottle", description: "500ml still water", price: 120, image: "https://images.unsplash.com/photo-1523362628745-0c100150b504?w=500", optionKey: "drinks_water" }
  ]
};

const additionTemplates = [
  { nom: "Extra Cheese", description: "Mozzarella boost", prix: 80 },
  { nom: "Extra Sauce", description: "House special sauce", prix: 50 },
  { nom: "Olives", description: "Black olives topping", prix: 60 },
  { nom: "Fries", description: "Side of crispy fries", prix: 120 },
  { nom: "Spicy Mix", description: "Jalapeños & spicy oil", prix: 70 }
];

const sizeOptionTemplates = [
  { nom: "M", description: "Medium", prix: 0 },
  { nom: "L", description: "Large", prix: 100 },
  { nom: "XL", description: "Extra large", prix: 200 }
];

// Volume/format options for drinks (different barème per product type)
const volumeWaterTemplates = [
  { nom: "33cl", description: "33 cl", prix: 0 },
  { nom: "50cl", description: "50 cl", prix: 25 },
  { nom: "1L", description: "1 litre", prix: 60 },
  { nom: "1.5L", description: "1,5 litre", prix: 90 }
];
const volumeSoftTemplates = [
  { nom: "33cl", description: "Canette 33cl", prix: 0 },
  { nom: "50cl", description: "50 cl", prix: 40 }
];
const volumeJuiceTemplates = [
  { nom: "25cl", description: "25 cl", prix: 0 },
  { nom: "33cl", description: "33 cl", prix: 25 },
  { nom: "50cl", description: "50 cl", prix: 50 }
];
const portionSaladTemplates = [
  { nom: "Normal", description: "Portion standard", prix: 0 },
  { nom: "Large", description: "Grande portion", prix: 80 }
];

const breadOptionTemplates = [
  { nom: "Normal", description: "Pain normal", prix: 0 },
  { nom: "Syrien", description: "Pain syrien", prix: 0 }
];

const sauceOptionTemplates = [
  { nom: "Algerienne", description: "Sauce algerienne", prix: 0 },
  { nom: "Harissa", description: "Sauce harissa", prix: 0 },
  { nom: "Fromage", description: "Sauce fromage", prix: 0 }
];

const cookingOptionTemplates = [
  { nom: "Saignant", description: "Cuisson saignant", prix: 0 },
  { nom: "A point", description: "Cuisson a point", prix: 0 },
  { nom: "Bien cuit", description: "Cuisson bien cuit", prix: 0 }
];

const drinkOptionTemplates = [
  { nom: "Coca", description: "Coca 33cl", prix: 0 },
  { nom: "Fanta", description: "Fanta 33cl", prix: 0 },
  { nom: "Sprite", description: "Sprite 33cl", prix: 0 }
];

const pickRandomSubset = (items, min, max) => {
  if (!Array.isArray(items) || items.length === 0) return [];
  const safeMin = Math.max(0, Number.isFinite(min) ? min : 0);
  const safeMax = Math.max(safeMin, Number.isFinite(max) ? max : safeMin);
  const countMax = Math.min(items.length, safeMax);
  const countMin = Math.min(items.length, safeMin);
  const count = countMin + Math.floor(Math.random() * (countMax - countMin + 1));
  return [...items].sort(() => 0.5 - Math.random()).slice(0, count);
};

const loadSeedJson = async (relativePath) => {
  const seedDir = path.dirname(fileURLToPath(import.meta.url));
  const normalizedPath = String(relativePath || "").replace(/^[./\\]+/, "");
  const candidates = [
    new URL(relativePath, import.meta.url),
    path.resolve(seedDir, normalizedPath),
    path.resolve(process.cwd(), normalizedPath),
    path.resolve(process.cwd(), "seeders", normalizedPath),
    path.resolve(process.cwd(), "tawssilbackyou", "seeders", normalizedPath)
  ];

  for (const candidate of candidates) {
    try {
      const raw = await readFile(candidate, "utf-8");
      const data = JSON.parse(raw);
      return Array.isArray(data) ? data : [];
    } catch (error) {
      // Try next candidate.
    }
  }

  console.warn(`⚠️ Seed file not found: ${relativePath}`);
  return [];
};

const normalizeWilayaCode = (value) => {
  const raw = String(value ?? "").trim();
  if (!raw) return "";
  if (/^\\d+$/.test(raw)) {
    const numeric = Number.parseInt(raw, 10);
    if (Number.isFinite(numeric)) {
      return String(numeric).padStart(2, "0");
    }
  }
  return raw;
};

const buildWilayaMap = (wilayas = []) =>
  new Map(
    wilayas
      .map((wilaya) => {
        const code = normalizeWilayaCode(wilaya.code);
        if (!code) return null;
        return [code, wilaya];
      })
      .filter(Boolean)
  );

const seedWilayas = async () => {
  let wilayaData = await loadSeedJson("./data/wilayas.json");
  if (!wilayaData.length) {
    const communeData = await loadSeedJson("./data/communes.json");
    if (communeData.length) {
      const derived = new Map();
      communeData.forEach((commune) => {
        const code = normalizeWilayaCode(commune.wilaya_code);
        const name = String(commune.wilaya_name || "").trim();
        if (!code || !name) return;
        if (!derived.has(code)) {
          derived.set(code, { code, name, name_ar: null });
        }
      });
      wilayaData = Array.from(derived.values());
    }
  }
  if (!wilayaData.length) {
    console.warn("⚠️ No wilaya data found. Skipping wilaya seeding.");
    return [];
  }

  const payload = wilayaData
    .map((wilaya) => ({
      code: normalizeWilayaCode(wilaya.code),
      name: String(wilaya.name || "").trim(),
      name_ar: wilaya.name_ar || null
    }))
    .filter((wilaya) => wilaya.code && wilaya.name);

  if (!payload.length) {
    console.warn("⚠️ Wilaya data invalid. Skipping wilaya seeding.");
    return [];
  }

    await Wilaya.bulkCreate(payload, {
    validate: true,
    updateOnDuplicate: ["name", "name_ar"]
  });
  const created = await Wilaya.findAll({ attributes: ["code", "name", "name_ar"] });
  console.log(`✅ ${created.length} wilayas created`);
  return created.map((row) => row.toJSON());
};

const seedCommunes = async (wilayas = []) => {
  const communeData = await loadSeedJson("./data/communes.json");
  if (!communeData.length) {
    console.warn("⚠️ No commune data found. Skipping commune seeding.");
    return [];
  }

  let wilayaSource = wilayas;
  if (!wilayaSource.length) {
    const dbWilayas = await Wilaya.findAll({ attributes: ["code", "name"] });
    wilayaSource = dbWilayas.map((row) => row.toJSON());
  }  let wilayaMap = buildWilayaMap(wilayaSource);

  if (!wilayaMap.size && communeData.length) {
    const derived = new Map();
    communeData.forEach((commune) => {
      const code = normalizeWilayaCode(commune.wilaya_code);
      const name = String(commune.wilaya_name || "").trim();
      if (!code || !name) return;
      if (!derived.has(code)) {
        derived.set(code, { code, name, name_ar: null });
      }
    });

    const derivedPayload = Array.from(derived.values());
    if (derivedPayload.length) {
      await Wilaya.bulkCreate(derivedPayload, {
        validate: true,
        updateOnDuplicate: ["name", "name_ar"]
      });
      const dbWilayas = await Wilaya.findAll({ attributes: ["code", "name"] });
      wilayaMap = buildWilayaMap(dbWilayas.map((row) => row.toJSON()));
    }
  }

  if (!wilayaMap.size) {
    console.warn("⚠️ No wilayas available. Skipping commune seeding.");
    return [];
  }

  const missingWilayas = new Set();

  const payload = communeData
    .map((commune) => {
      const wilayaCode = normalizeWilayaCode(commune.wilaya_code);
      const wilaya = wilayaMap.get(wilayaCode);
      const lat = Number(commune.lat);
      const lng = Number(commune.lng);
      const wilayaName = commune.wilaya_name || wilaya?.name || null;

      if (!wilaya) {
        if (wilayaCode) {
          missingWilayas.add(wilayaCode);
        }
        return null;
      }

      if (!wilayaCode || !commune.name || !Number.isFinite(lat) || !Number.isFinite(lng) || !wilayaName) {
        return null;
      }

      return {
        name: String(commune.name).trim(),
        name_ar: commune.name_ar || null,
        wilaya_code: wilayaCode,
        wilaya_name: wilayaName,
        code: commune.code || null,
        location: {
          type: "Point",
          coordinates: [lng, lat]
        }
      };
    })
    .filter(Boolean);

  if (!payload.length) {
    console.warn("⚠️ Commune data invalid. Skipping commune seeding.");
    return [];
  }

  const created = await Commune.bulkCreate(payload, { validate: true });
  console.log(`✅ ${created.length} communes created`);
  return created.map((row) => row.toJSON());
};

const baseGroups = {
  taille: {
    nom: "Taille",
    description: "Choisissez une taille",
    options: sizeOptionTemplates
  },
  pain: {
    nom: "Type de pain",
    description: "Choisissez un type de pain",
    options: breadOptionTemplates
  },
  sauces: {
    nom: "Sauces",
    description: "Choisissez vos sauces",
    options: sauceOptionTemplates
  },
  cuisson: {
    nom: "Cuisson",
    description: "Choisissez la cuisson",
    options: cookingOptionTemplates
  },
  boisson: {
    nom: "Boisson",
    description: "Choisissez une boisson",
    options: drinkOptionTemplates
  },
  extras: {
    nom: "Extras",
    description: "Supplements",
    options: additionTemplates,
    minOptions: 1,
    maxOptions: 3,
    priceJitter: 10
  },
  volume_water: {
    nom: "Format",
    description: "Choisissez le format",
    options: volumeWaterTemplates
  },
  volume_soft: {
    nom: "Format",
    description: "Choisissez le format",
    options: volumeSoftTemplates
  },
  volume_juice: {
    nom: "Format",
    description: "Choisissez le format",
    options: volumeJuiceTemplates
  },
  portion_salad: {
    nom: "Portion",
    description: "Choisissez la portion",
    options: portionSaladTemplates
  }
};

const optionGroupTemplatesByCategory = {
  pizza: {
    required: [
      { ...baseGroups.taille, ordre_affichage: 1 }
    ],
    optional: [
      { ...baseGroups.extras, ordre_affichage: 2 }
    ]
  },
  tacos: {
    required: [
      { ...baseGroups.taille, ordre_affichage: 1 },
      { ...baseGroups.pain, ordre_affichage: 2 }
    ],
    optional: [
      { ...baseGroups.sauces, ordre_affichage: 3 },
      { ...baseGroups.extras, ordre_affichage: 4 }
    ]
  },
  burger: {
    required: [
      { ...baseGroups.cuisson, ordre_affichage: 1 }
    ],
    optional: [
      { ...baseGroups.extras, ordre_affichage: 2 }
    ]
  },
  sandwish: {
    required: [
      { ...baseGroups.pain, ordre_affichage: 1 }
    ],
    optional: [
      { ...baseGroups.sauces, ordre_affichage: 2 },
      { ...baseGroups.extras, ordre_affichage: 3 }
    ]
  },
  salads: {
    required: [
      { ...baseGroups.portion_salad, ordre_affichage: 1 }
    ],
    optional: [
      { ...baseGroups.extras, ordre_affichage: 2 }
    ]
  },
  desserts: {
    required: [],
    optional: []
  },
  drinks: {
    required: [],
    optional: []
  },
  promo: {
    required: [
      { ...baseGroups.boisson, ordre_affichage: 1 }
    ],
    optional: [
      { ...baseGroups.extras, ordre_affichage: 2 }
    ]
  },
  default: {
    required: [
      { ...baseGroups.taille, ordre_affichage: 1 }
    ],
    optional: [
      { ...baseGroups.extras, ordre_affichage: 2 }
    ]
  }
};

// Per-item option overrides (e.g. Water: volume 33cl/50cl/1L/1.5L; Cola: 33cl/50cl; Juice: 25cl/33cl/50cl)
const optionGroupTemplatesByItemKey = {
  drinks_water: {
    required: [
      { ...baseGroups.volume_water, ordre_affichage: 1 }
    ],
    optional: []
  },
  drinks_soft: {
    required: [
      { ...baseGroups.volume_soft, ordre_affichage: 1 }
    ],
    optional: []
  },
  drinks_juice: {
    required: [
      { ...baseGroups.volume_juice, ordre_affichage: 1 }
    ],
    optional: []
  }
};

// Different icon per category for the POS sidebar
const categoryIconUrls = {
  pizza: "https://images.unsplash.com/photo-1513104890138-7c749659a513?w=200",
  burger: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200",
  tacos: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=200",
  sandwish: "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=200",
  salads: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200",
  desserts: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=200",
  drinks: "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200",
  promo: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=200"
};

const streets = [
  "Rue des Frères Bouadou", "Avenue de l'ALN", "Rue Mohamed Belouizdad",
  "Boulevard du 1er Novembre", "Rue Larbi Ben M'hidi", "Avenue Didouche Mourad",
  "Rue Hassiba Ben Bouali", "Rue Abane Ramdane", "Avenue Souidani Boudjemaa",
  "Rue Amirouche", "Boulevard Zighoud Youcef", "Rue Colonel Lotfi"
];

const vehicleTypes = ['motorcycle', 'bicycle', 'scooter'];
const orderStatuses = ['pending', 'accepted', 'preparing', 'assigned', 'delivering', 'delivered', 'declined'];
const paymentMethods = ['baridi_mob', 'cash_on_delivery', 'bank_transfer'];

// Génère coordonnées aléatoires autour de Sidi Abdellah
const BASE_COORDS = { lat: 36.747385, lng: 6.27404 };
const DEFAULT_LOCATION_OFFSET = 0.02;

const getRandomLocation = (base = BASE_COORDS, offset = DEFAULT_LOCATION_OFFSET) => {
  const baseLat = Number(base?.lat ?? BASE_COORDS.lat);
  const baseLng = Number(base?.lng ?? BASE_COORDS.lng);
  const safeOffset = Number.isFinite(offset) ? offset : DEFAULT_LOCATION_OFFSET;
  return {
    type: 'Point',
    coordinates: [
      baseLng + (Math.random() - 0.5) * safeOffset,
      baseLat + (Math.random() - 0.5) * safeOffset
    ]
  };
};

const getLocationCoords = (location) => {
  const coords = location?.coordinates;
  if (!Array.isArray(coords) || coords.length < 2) return null;
  const lng = Number(coords[0]);
  const lat = Number(coords[1]);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return { lat, lng };
};

const getCommuneCoords = (commune) => {
  const coords = getLocationCoords(commune?.location);
  if (coords) return coords;
  const lat = Number(commune?.lat);
  const lng = Number(commune?.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return { lat, lng };
};

const distanceSq = (a, b) => {
  const dLat = (a?.lat ?? 0) - (b?.lat ?? 0);
  const dLng = (a?.lng ?? 0) - (b?.lng ?? 0);
  return dLat * dLat + dLng * dLng;
};

const buildNearbyCommunes = (communes = [], center = BASE_COORDS, limit = 120) => {
  const withCoords = communes
    .map((commune) => {
      const coords = getCommuneCoords(commune);
      if (!coords) return null;
      return { ...commune, ...coords, _distance: distanceSq(coords, center) };
    })
    .filter(Boolean);

  if (!withCoords.length) return [];

  return withCoords
    .sort((a, b) => a._distance - b._distance)
    .slice(0, Math.max(1, limit));
};

const attachCommuneCoords = (communes = []) =>
  communes
    .map((commune) => {
      const coords = getCommuneCoords(commune);
      if (!coords) return null;
      return { ...commune, ...coords };
    })
    .filter(Boolean);

// Génère un nom aléatoire
const getRandomName = () => ({
  first: firstNames[Math.floor(Math.random() * firstNames.length)],
  last: lastNames[Math.floor(Math.random() * lastNames.length)]
});

// Génère une adresse aléatoire
const getRandomAddress = (city = "Jijel") => {
  const street = streets[Math.floor(Math.random() * streets.length)];
  const number = Math.floor(Math.random() * 200) + 1;
  return `${number} ${street}, ${city}`;
};

// ✅ FONCTION CORRIGÉE - Génère un numéro de téléphone UNIQUE
const getUniquePhone = (prefix, index) => {
  // Prendre les 6 derniers chiffres de (1000000 + index)
  const baseNumber = 1000000 + index;
  const lastSixDigits = String(baseNumber).slice(-6);
  return `+213${prefix}${lastSixDigits}`;
};

// ===============================
//   Fonction principale
// ===============================
const seedDatabase = async () => {
  try {
    console.log("🌱 Starting massive database seeding...");

    const getEnvInt = (key, fallback) => {
      const parsed = Number.parseInt(process.env[key] ?? "", 10);
      return Number.isFinite(parsed) ? parsed : fallback;
    };

    const seedConfig = {
      clients: Math.max(1, getEnvInt("SEED_CLIENTS", 1000)),
      drivers: Math.max(1, getEnvInt("SEED_DRIVERS", 1000)),
      restaurants: Math.max(1, getEnvInt("SEED_RESTAURANTS", 1000)),
      orders: Math.max(1, getEnvInt("SEED_ORDERS", 10)),
      favoritesClients: Math.max(0, getEnvInt("SEED_FAVORITES_CLIENTS", 10)),
      cashiersPerRestaurant: Math.max(0, getEnvInt("SEED_CASHIERS_PER_RESTAURANT", 2)),
      cashiersRestaurantLimit: Math.max(0, getEnvInt("SEED_CASHIERS_RESTAURANT_LIMIT", 100))
    };

    console.log(
      `📊 Seed counts: clients=${seedConfig.clients}, drivers=${seedConfig.drivers}, restaurants=${seedConfig.restaurants}, orders=${seedConfig.orders}`
    );

    await sequelize.sync({ force: true, cascade: true });

    console.log("🗑️  Clearing existing data...");
    await sequelize.truncate({ cascade: true, restartIdentity: true });

    // ✅ Hash password once
    const hashedPassword = await bcrypt.hash("password123", 10);

    // ----------------------------
    // 1️⃣ Admins
    // ----------------------------
    console.log("👨‍💼 Creating admins...");
    const admins = [];
    for (let i = 0; i < adminNames.length; i++) {
      const adminData = adminNames[i];
      const user = await User.create({
        email: `admin${i + 1}@example.com`,
        password: "password123",
        role: "admin",
        is_active: true
      });

      admins.push(await Admin.create({
        user_id: user.id,
        first_name: adminData.first,
        last_name: adminData.last,
        email: `admin${i + 1}@example.com`,
        phone: getUniquePhone("777", i), // ✅ CORRIGÉ
        role_level: adminData.role,
        is_active: true
      }));
    }
    console.log(`✅ ${admins.length} admins created`);

    // ----------------------------
    // 🆕 SYSTEM CONFIGURATIONS (COMPLETE)
    // ----------------------------
    console.log("⚙️  Initializing system configurations...");
    
    await SystemConfig.create({
      config_key: 'max_orders_per_driver',
      config_value: 5,
      description: 'Maximum number of orders a driver can handle simultaneously',
      updated_by: admins[0].id
    });
    
    await SystemConfig.create({
      config_key: 'client_restaurant_search_radius',
      config_value: 2000,
      description: 'Default search radius (in meters) for clients to find nearby restaurants',
      updated_by: admins[0].id
    });

    await SystemConfig.create({
      config_key: 'default_preparation_time',
      config_value: 15,
      description: 'Default preparation time (in minutes) used when not provided by a restaurant',
      updated_by: admins[0].id
    });

    await SystemConfig.create({
      config_key: 'pending_order_timeout',
      config_value: 3,
      description: 'Delay (in minutes) before notifying admins about a pending order without response',
      updated_by: admins[0].id
    });

    await SystemConfig.create({
      config_key: 'restaurant_preparation_timeout',
      config_value: 20,
      description: 'Delay (in minutes) before notifying admins about long restaurant preparation',
      updated_by: admins[0].id
    });

    await SystemConfig.create({
      config_key: 'driver_arrival_timeout',
      config_value: 15,
      description: 'Delay (in minutes) before notifying admins about late driver arrival',
      updated_by: admins[0].id
    });

    await SystemConfig.create({
      config_key: 'default_delivery_fee',
      config_value: 200,
      description: 'Default delivery fee (in DA) applied when not provided for delivery orders',
      updated_by: admins[0].id
    });

    // ----------------------------
    // 🗺️ Wilayas & Communes
    // ----------------------------
    console.log("🗺️ Seeding wilayas and communes...");
    const seededWilayas = await seedWilayas();
    const seededCommunes = await seedCommunes(seededWilayas);
    const targetWilayaCode = normalizeWilayaCode(process.env.SEED_WILAYA_CODE || "18");
    const targetWilaya = seededWilayas.find(
      (wilaya) => String(wilaya.code) === targetWilayaCode
    );
    const targetWilayaName = targetWilaya?.name || "Jijel";
    const targetCommunes = seededCommunes.filter(
      (commune) => String(commune.wilaya_code) === targetWilayaCode
    );
    const targetCommunesWithCoords = attachCommuneCoords(targetCommunes);
    const nearbyCommunes = targetCommunesWithCoords.length
      ? targetCommunesWithCoords
      : buildNearbyCommunes(seededCommunes, BASE_COORDS, 120);
    const seedCenter = (() => {
      if (!nearbyCommunes.length) return BASE_COORDS;
      const total = nearbyCommunes.reduce(
        (acc, commune) => ({
          lat: acc.lat + (commune.lat || 0),
          lng: acc.lng + (commune.lng || 0)
        }),
        { lat: 0, lng: 0 }
      );
      return { lat: total.lat / nearbyCommunes.length, lng: total.lng / nearbyCommunes.length };
    })();

    await SystemConfig.create({
      config_key: 'max_driver_cancellations',
      config_value: 3,
      description: 'Maximum cancellations allowed before notifying admins about a driver',
      updated_by: admins[0].id
    });

    console.log("✅ 9 system configurations initialized");

    // ----------------------------
    // 2️⃣ Clients
    // ----------------------------
    console.log(`👥 Creating ${seedConfig.clients} clients...`);
    const clientUsers = [];
    for (let i = 0; i < seedConfig.clients; i++) {
      clientUsers.push({
        email: `client${i + 1}@example.com`,
        password: hashedPassword,
        role: "client",
        is_active: true,
        last_login: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000)
      });
      
      if ((i + 1) % 200 === 0) console.log(`➡️  ${i + 1} client users created...`);
    }
    const clientUsersCreated = await User.bulkCreate(clientUsers, { returning: true });
    
    const clients = [];
    for (let i = 0; i < seedConfig.clients; i++) {
      const name = getRandomName();
      const communeChoice = nearbyCommunes.length
        ? nearbyCommunes[Math.floor(Math.random() * nearbyCommunes.length)]
        : null;
      const location = communeChoice
        ? getRandomLocation({ lat: communeChoice.lat, lng: communeChoice.lng }, 0.02)
        : getRandomLocation(seedCenter);
      
      clients.push({
        user_id: clientUsersCreated[i].id,
        first_name: name.first,
        last_name: name.last,
        email: `client${i + 1}@example.com`,
        phone_number: getUniquePhone("555", i), // ✅ CORRIGÉ
        address: getRandomAddress(communeChoice?.name || targetWilayaName),
        location: location,
        rating: parseFloat((3.0 + Math.random() * 2.0).toFixed(1)),
        loyalty_points: Math.floor(Math.random() * 1000),
        is_active: Math.random() > 0.05,
        status: Math.random() > 0.9 ? "suspended" : "active"
      });
      
      if ((i + 1) % 200 === 0) console.log(`➡️  ${i + 1} clients created...`);
    }
    
    const createdClients = await Client.bulkCreate(clients, { returning: true });
    console.log(`✅ ${createdClients.length} clients created`);

    // ----------------------------
    // 3️⃣ Drivers
    // ----------------------------
    console.log(`🚗 Creating ${seedConfig.drivers} drivers...`);
    const driverUsers = [];
    for (let i = 0; i < seedConfig.drivers; i++) {
      driverUsers.push({
        email: `driver${i + 1}@example.com`,
        password: hashedPassword,
        role: "driver",
        is_active: true,
        last_login: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000)
      });
      
      if ((i + 1) % 200 === 0) console.log(`➡️  ${i + 1} driver users created...`);
    }
    const driverUsersCreated = await User.bulkCreate(driverUsers, { returning: true });
    
    const drivers = [];
    const statuses = ['available', 'busy', 'offline'];
    
    for (let i = 0; i < seedConfig.drivers; i++) {
      const name = getRandomName();
      const communeChoice = nearbyCommunes.length
        ? nearbyCommunes[Math.floor(Math.random() * nearbyCommunes.length)]
        : null;
      const location = communeChoice
        ? getRandomLocation({ lat: communeChoice.lat, lng: communeChoice.lng }, 0.02)
        : getRandomLocation(seedCenter);
      const status = statuses[Math.floor(Math.random() * statuses.length)];
      
      drivers.push({
        user_id: driverUsersCreated[i].id,
        driver_code: `DRV-${String(i + 1).padStart(4, '0')}`,
        first_name: name.first,
        last_name: name.last,
        profile_image_url: `https://i.pravatar.cc/150?img=${i + 1}`,
        phone: getUniquePhone("666", i), // ✅ CORRIGÉ
        email: `driver${i + 1}@example.com`,
        vehicle_type: vehicleTypes[Math.floor(Math.random() * vehicleTypes.length)],
        vehicle_plate: `${Math.floor(Math.random() * 48) + 1}-${10000 + i}-${Math.floor(Math.random() * 99) + 1}`,
        license_number: `LIC${100000 + i}`,
        status: status,
        current_location: location,
        rating: parseFloat((3.5 + Math.random() * 1.5).toFixed(1)),
        total_deliveries: Math.floor(Math.random() * 1000) + 10,
        is_verified: Math.random() > 0.05,
        is_active: Math.random() > 0.05,
        last_active_at: new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000),
        max_orders_capacity: 5,
        active_orders: [],
        cancellation_count: Math.floor(Math.random() * 5),
        notes: i % 10 === 0 ? `Excellent driver, very punctual` : null
      });
      
      if ((i + 1) % 200 === 0) console.log(`➡️  ${i + 1} drivers created...`);
    }
    
    const createdDrivers = await Driver.bulkCreate(drivers, { returning: true });
    console.log(`✅ ${createdDrivers.length} drivers created (capacity: 5 orders each)`);

    // ----------------------------
    // 4️⃣ Restaurants
    // ----------------------------
    console.log(`🍽️  Creating ${seedConfig.restaurants} restaurants...`);
    const restaurantUsers = [];
    for (let i = 0; i < seedConfig.restaurants; i++) {
      restaurantUsers.push({
        email: `restaurant${i + 1}@example.com`,
        password: hashedPassword,
        role: "restaurant",
        is_active: true
      });
      
      if ((i + 1) % 200 === 0) console.log(`➡️  ${i + 1} restaurant users created...`);
    }

    const restaurantUsersCreated = await User.bulkCreate(restaurantUsers, { returning: true });

    const restaurantList = [];
    for (let i = 0; i < seedConfig.restaurants; i++) {
      const model = restaurantModels[i % restaurantModels.length];
      const communeChoice = nearbyCommunes.length
        ? nearbyCommunes[Math.floor(Math.random() * nearbyCommunes.length)]
        : null;
      const location = communeChoice
        ? getRandomLocation({ lat: communeChoice.lat, lng: communeChoice.lng }, 0.01)
        : getRandomLocation(seedCenter);
      
      restaurantList.push({
        user_id: restaurantUsersCreated[i].id,
        name: `${model.name} ${i + 1}`,
        description: model.description,
        address: getRandomAddress(communeChoice?.name || targetWilayaName),
        phone_number: getUniquePhone("770", i), // ✅ CORRIGÉ
        email: `restaurant${i + 1}@example.com`,
        location: location,
        commune_id: communeChoice?.id || null,
        rating: parseFloat((3.0 + Math.random() * 2.0).toFixed(1)),
        image_url: model.image,
        is_active: Math.random() > 0.1,
        is_premium: Math.random() > 0.7,
        status: Math.random() > 0.9 ? "suspended" : "approved",
        opening_hours: {
          mon: { open: 1000, close: 2200 },
          tue: { open: 1000, close: 2200 },
          wed: { open: 1000, close: 2200 },
          thu: { open: 1000, close: 2200 },
          fri: { open: 1000, close: 2300 },
          sat: { open: 1000, close: 2300 },
          sun: { open: 1100, close: 2200 }
        }
      });
      
      if ((i + 1) % 200 === 0) console.log(`➡️  ${i + 1} restaurants created...`);
    }

    const restaurants = await Restaurant.bulkCreate(restaurantList, { returning: true });
    const categoryAssignments = restaurants.map((restaurant, index) => ({
      restaurantId: restaurant.id,
      categories: restaurantModels[index % restaurantModels.length].categories
    }));
    console.log(`✅ ${restaurants.length} restaurants created`);




    // ----------------------------
    // 4.5️⃣ Cashiers
    // ----------------------------
    const cashierRestaurantCount = Math.min(restaurants.length, seedConfig.cashiersRestaurantLimit);
    const cashierCount = cashierRestaurantCount * seedConfig.cashiersPerRestaurant;

    console.log(
      `💰 Creating ${cashierCount} cashiers (${seedConfig.cashiersPerRestaurant} per restaurant for first ${cashierRestaurantCount} restaurants)...`
    );

    let createdCashiers = [];
    if (cashierCount > 0) {
      const cashierUsers = [];

      for (let i = 0; i < cashierCount; i++) {
        cashierUsers.push({
          email: `cashier${i + 1}@example.com`,
          password: hashedPassword,
          role: "cashier",
          is_active: true,
          last_login: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000)
        });

        if ((i + 1) % 50 === 0) console.log(`➡️  ${i + 1} cashier users created...`);
      }

      const cashierUsersCreated = await User.bulkCreate(cashierUsers, { returning: true });

      const cashiers = [];
      const cashierStatuses = ['active', 'on_break', 'offline'];

      for (let i = 0; i < cashierCount; i++) {
        const restaurantIndex = Math.floor(i / seedConfig.cashiersPerRestaurant);
        const restaurant = restaurants[restaurantIndex];
        const name = cashierNames[i % cashierNames.length];

        const cashierStatus = cashierStatuses[Math.floor(Math.random() * cashierStatuses.length)];
        const isOnShift = cashierStatus === 'active' || cashierStatus === 'on_break';

        cashiers.push({
          user_id: cashierUsersCreated[i].id,
          restaurant_id: restaurant.id,
          cashier_code: `CSH-${String(i + 1).padStart(4, '0')}`,
          first_name: name.first,
          last_name: name.last,
          phone: getUniquePhone("771", i), // ✅ Numéros uniques pour cashiers
          email: `cashier${i + 1}@example.com`,
          profile_image_url: `https://i.pravatar.cc/150?img=${i + 50}`,
          is_active: Math.random() > 0.05,
          status: cashierStatus,
          shift_start: isOnShift ? new Date(Date.now() - Math.random() * 8 * 60 * 60 * 1000) : null,
          shift_end: cashierStatus === 'offline' && Math.random() > 0.5 
            ? new Date(Date.now() - Math.random() * 2 * 60 * 60 * 1000) 
            : null,
          total_orders_processed: Math.floor(Math.random() * 500) + 50,
          total_sales_amount: parseFloat((50000 + Math.random() * 200000).toFixed(2)),
          last_active_at: new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000),
          notes: i % 15 === 0 ? `Excellent cashier, very efficient` : null,
          permissions: {
            can_create_orders: true,
            can_cancel_orders: i % 5 === 0, // 20% peuvent annuler
            can_apply_discounts: i % 4 === 0, // 25% peuvent faire des réductions
            can_process_refunds: i % 10 === 0, // 10% peuvent faire des remboursements
            can_view_reports: i % 3 === 0 // 33% peuvent voir les rapports
          }
        });

        if ((i + 1) % 50 === 0) console.log(`➡️  ${i + 1} cashiers created...`);
      }

      createdCashiers = await Cashier.bulkCreate(cashiers, { returning: true });
    }

    console.log(
      `✅ ${createdCashiers.length} cashiers created (${seedConfig.cashiersPerRestaurant} per restaurant for first ${cashierRestaurantCount} restaurants)`
    );





    // ----------------------------
    // 5️⃣ Catégories & Menus (pour tous les restaurants)
    // ----------------------------
    console.log("🍕 Creating food categories and menu items for all restaurants...");
    const allMenuItems = [];
    const allAdditions = [];
    const menuItemOptionalAdditionsMap = new Map();
    const menuItemRequiredGroupsMap = new Map();
    const restaurantMenuMap = new Map();

    for (let i = 0; i < restaurants.length; i++) {
      const restaurant = restaurants[i];
      const model = restaurantModels[i % restaurantModels.length];
      const parentCategories = Array.isArray(model.categories) ? model.categories : [];
      const isRestaurant1 = i === 0;
      const promoPool = menuItemsByCategory.promo || [];
      const forcePromoCategory = model.name === "Pizza Palace" && i === 0;
      const wantsPromoCategory =
        promoPool.length > 0 && (forcePromoCategory || Math.random() < 0.6);
      const promoItems = wantsPromoCategory
        ? (forcePromoCategory
          ? [...promoPool]
          : [...promoPool]
            .sort(() => 0.5 - Math.random())
            .slice(0, Math.max(1, Math.floor(Math.random() * promoPool.length))))
        : [];
      const baseCategoryTypes = isRestaurant1
        ? [...parentCategories, ...restaurant1ExtraCategories]
        : [...parentCategories];
      const categoryTypes = baseCategoryTypes.filter(
        (value, index, self) => self.indexOf(value) === index
      );
      if (wantsPromoCategory && !categoryTypes.includes("promo")) {
        categoryTypes.push("promo");
      }
      let categoryOrder = 1;

      for (const categoryType of categoryTypes) {
        const baseItems = categoryType === "promo"
          ? promoItems
          : (menuItemsByCategory[categoryType] || []);
        const extraItems = isRestaurant1 && categoryType !== "promo"
          ? (restaurant1ExtraMenuItemsByCategory[categoryType] || [])
          : [];
        const categoryItems = [...baseItems, ...extraItems];
        if (categoryItems.length === 0) {
          continue;
        }

        const category = await FoodCategory.create({
          restaurant_id: restaurant.id,
          nom: categoryType.charAt(0).toUpperCase() + categoryType.slice(1),
          description: `${restaurant.name}'s ${categoryType} selection`,
          icone_url: categoryIconUrls[categoryType] || "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=200",
          ordre_affichage: categoryOrder
        });
        categoryOrder += 1;

        for (const item of categoryItems) {
          const menuItem = await MenuItem.create({
            restaurant_id: restaurant.id,
            category_id: category.id,
            nom: item.name,
            description: item.description,
            prix: item.price + (Math.random() * 200 - 100),
            photo_url: item.image,
            is_available: Math.random() > 0.1,
            temps_preparation: 10 + Math.floor(Math.random() * 30)
          });
          allMenuItems.push(menuItem);
          const restaurantMenu = restaurantMenuMap.get(restaurant.id) || [];
          restaurantMenu.push(menuItem);
          restaurantMenuMap.set(restaurant.id, restaurantMenu);

          const groupTemplates = (item.optionKey && optionGroupTemplatesByItemKey[item.optionKey])
            ? optionGroupTemplatesByItemKey[item.optionKey]
            : (optionGroupTemplatesByCategory[categoryType] || optionGroupTemplatesByCategory.default);
          const requiredGroups = [];
          const optionalAdditions = [];

          const createGroupAdditions = async (groupTemplate, isRequired) => {
            const group = await OptionGroup.create({
              menu_item_id: menuItem.id,
              nom: groupTemplate.nom,
              description: groupTemplate.description,
              is_required: isRequired,
              ordre_affichage: groupTemplate.ordre_affichage ?? 0
            });

            const optionsPool = Array.isArray(groupTemplate.options) ? groupTemplate.options : [];
            const useSubset = Number.isFinite(groupTemplate.maxOptions);
            const selectedOptions = useSubset
              ? pickRandomSubset(optionsPool, groupTemplate.minOptions ?? 1, groupTemplate.maxOptions)
              : optionsPool;

            if (selectedOptions.length === 0) {
              return;
            }

            const priceJitter = Number.isFinite(groupTemplate.priceJitter) ? groupTemplate.priceJitter : 0;
            const createdAdditions = await Addition.bulkCreate(
              selectedOptions.map(option => {
                const jitter = priceJitter > 0
                  ? Math.floor(Math.random() * (priceJitter * 2 + 1)) - priceJitter
                  : 0;
                const basePrice = Number.isFinite(option.prix) ? option.prix : 0;
                return {
                  id: randomUUID(),
                  menu_item_id: menuItem.id,
                  option_group_id: group.id,
                  nom: option.nom,
                  description: option.description,
                  prix: Math.max(0, basePrice + jitter),
                  is_available: isRequired ? true : Math.random() > 0.05
                };
              }),
              { returning: true }
            );

            allAdditions.push(...createdAdditions);

            if (isRequired) {
              requiredGroups.push({ additions: createdAdditions });
            } else {
              optionalAdditions.push(...createdAdditions);
            }
          };

          for (const requiredGroup of groupTemplates.required || []) {
            await createGroupAdditions(requiredGroup, true);
          }

          for (const optionalGroup of groupTemplates.optional || []) {
            await createGroupAdditions(optionalGroup, false);
          }

          menuItemOptionalAdditionsMap.set(menuItem.id, optionalAdditions);
          menuItemRequiredGroupsMap.set(menuItem.id, requiredGroups);
        }
      }
      
      if ((i + 1) % 20 === 0) console.log(`➡️  ${i + 1} restaurants with menus created...`);
    }
    console.log(`✅ ${allMenuItems.length} menu items created`);
    console.log(`✅ ${allAdditions.length} additions created`);

    await seedHomepageModules({
      restaurants,
      restaurantMenuMap,
      categoryAssignments
    });

    // ----------------------------
    // 6️⃣ Orders
    // ----------------------------
    // ----------------------------
    // ✅ MODIFIER LA SECTION 6️⃣ Orders pour lier certaines commandes aux caissiers
    // ----------------------------
    console.log(`📦 Creating ${seedConfig.orders} orders...`);
    const orders = [];
    const guaranteedDeliveredRecent = Math.min(seedConfig.orders, 6);
    
    for (let i = 0; i < seedConfig.orders; i++) {
      const client = createdClients[i % createdClients.length];
      const restaurant = restaurants[i % restaurants.length];
      const forcePipelineDelivered = i < guaranteedDeliveredRecent;
      const driver = forcePipelineDelivered
        ? createdDrivers[i % createdDrivers.length]
        : (i % 3 === 0 ? createdDrivers[i % createdDrivers.length] : null);
      const status = forcePipelineDelivered
        ? 'delivered'
        : orderStatuses[Math.floor(Math.random() * orderStatuses.length)];
      
      // ✅ 30% des commandes sont créées via POS (pickup) par un caissier
      const isFromPOS = forcePipelineDelivered ? false : Math.random() < 0.3;
      const orderType = forcePipelineDelivered
        ? 'delivery'
        : (isFromPOS ? 'pickup' : (Math.random() > 0.2 ? 'delivery' : 'pickup'));
      
      // ✅ Si c'est une commande POS, assigner un caissier du restaurant
      let cashierId = null;
      if (isFromPOS) {
        const restaurantCashiers = createdCashiers.filter(c => c.restaurant_id === restaurant.id);
        if (restaurantCashiers.length > 0) {
          cashierId = restaurantCashiers[Math.floor(Math.random() * restaurantCashiers.length)].id;
        }
      }
      
      const subtotal = 800 + Math.floor(Math.random() * 2000);
      const deliveryFee = orderType === 'delivery' ? 150 + Math.floor(Math.random() * 150) : 0;
      const totalAmount = subtotal + deliveryFee;
      
      const createdAt = forcePipelineDelivered
        ? new Date(Date.now() - Math.random() * 6 * 24 * 60 * 60 * 1000)
        : new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000);
      let acceptedAt = null;
      let preparingStartedAt = null;
      let assignedAt = null;
      let deliveringStartedAt = null;
      let deliveredAt = null;
      
      if (['accepted', 'preparing', 'assigned', 'delivering', 'delivered'].includes(status)) {
        acceptedAt = new Date(createdAt.getTime() + 5 * 60 * 1000);
      }
      if (['preparing', 'assigned', 'delivering', 'delivered'].includes(status)) {
        preparingStartedAt = new Date(acceptedAt.getTime() + 1 * 60 * 1000);
      }
      if (['assigned', 'delivering', 'delivered'].includes(status)) {
        assignedAt = new Date(preparingStartedAt.getTime() + 15 * 60 * 1000);
      }
      if (['delivering', 'delivered'].includes(status)) {
        deliveringStartedAt = new Date(assignedAt.getTime() + 10 * 60 * 1000);
      }
      if (status === 'delivered') {
        deliveredAt = new Date(deliveringStartedAt.getTime() + 20 * 60 * 1000);
      }
      
      const order = {
        client_id: isFromPOS ? null : client.id, // ✅ POS orders peuvent ne pas avoir de client
        restaurant_id: restaurant.id,
        livreur_id: driver ? driver.id : null,
        created_by_cashier_id: cashierId, // ✅ NOUVEAU: Lier au caissier si POS
        order_type: orderType,
        order_number: `${orderType === 'pickup' ? 'PKP' : 'DEL'}-${createdAt.toISOString().slice(0, 10).replace(/-/g, '')}-${String(i + 1).padStart(4, '0')}`,
        status: status,
        delivery_address: orderType === 'delivery' && !isFromPOS ? client.address : null,
        delivery_location: orderType === 'delivery' && !isFromPOS ? client.location : null,
        delivery_distance: orderType === 'delivery' ? parseFloat((Math.random() * 10 + 1).toFixed(2)) : null,
        subtotal: subtotal,
        delivery_fee: deliveryFee,
        total_amount: totalAmount,
        payment_method: paymentMethods[Math.floor(Math.random() * paymentMethods.length)],
        delivery_instructions: !isFromPOS && i % 5 === 0 ? "Please call when you arrive" : null,
        preparation_time: 15 + Math.floor(Math.random() * 20),
        estimated_delivery_time: new Date(createdAt.getTime() + (30 + Math.random() * 30) * 60 * 1000),
        rating: status === 'delivered' && Math.random() > 0.3 ? parseFloat((3 + Math.random() * 2).toFixed(1)) : null,
        restaurant_review_comment: status === 'delivered' && Math.random() > 0.7 ? "Great food and fast delivery!" : null,
        driver_review_comment: status === 'delivered' && Math.random() > 0.6 ? "Driver arrived on time and courteous" : null,
        decline_reason: status === 'declined' ? "Restaurant is too busy" : null,
        created_at: createdAt,
        updated_at: deliveredAt || deliveringStartedAt || assignedAt || preparingStartedAt || acceptedAt || createdAt,
        accepted_at: acceptedAt,
        preparing_started_at: preparingStartedAt,
        assigned_at: assignedAt,
        delivering_started_at: deliveringStartedAt,
        delivered_at: deliveredAt
      };
      
      orders.push(order);
      
      if ((i + 1) % 200 === 0) console.log(`➡️  ${i + 1} orders prepared...`);
    }
    
    const createdOrders = await Order.bulkCreate(orders, { returning: true });
    console.log(`✅ ${createdOrders.length} orders created (${orders.filter(o => o.created_by_cashier_id).length} from POS)`);

    // ----------------------------
    // 7️⃣ Order Items
    // ----------------------------
    console.log("🍕 Creating order items...");
    const orderSubtotalMap = new Map();
    const orderItemAdditionPlans = [];
    const orderItems = [];
    
    for (let i = 0; i < createdOrders.length; i++) {
      const order = createdOrders[i];
      const restaurant = restaurants.find(r => r.id === order.restaurant_id);
      
      const restaurantCategories = await FoodCategory.findAll({
        where: { restaurant_id: restaurant.id }
      });
      
      if (restaurantCategories.length > 0) {
        const restaurantMenuItems = await MenuItem.findAll({
          where: { category_id: restaurantCategories.map(c => c.id) }
        });
        
        if (restaurantMenuItems.length > 0) {
          const itemCount = Math.floor(Math.random() * 3) + 1;
          
          for (let j = 0; j < itemCount; j++) {
            const menuItem = restaurantMenuItems[Math.floor(Math.random() * restaurantMenuItems.length)];
            const quantity = Math.floor(Math.random() * 3) + 1;
            const unitPrice = parseFloat(menuItem.prix);
            const totalPrice = unitPrice * quantity;
            
            const requiredGroups = menuItemRequiredGroupsMap.get(menuItem.id) || [];
            const optionalAdditions = menuItemOptionalAdditionsMap.get(menuItem.id) || [];
            const selectedAdditions = [];
            let additionsTotal = 0;

            for (const group of requiredGroups) {
              if (!group.additions || group.additions.length === 0) {
                continue;
              }
              const pick = group.additions[Math.floor(Math.random() * group.additions.length)];
              const pickPrice = parseFloat(pick.prix);
              additionsTotal += pickPrice * quantity;
              selectedAdditions.push({
                addition_id: pick.id,
                prix: pickPrice,
                quantity: 1
              });
            }

            if (optionalAdditions.length && Math.random() > 0.4) {
              const extrasCount = Math.min(optionalAdditions.length, Math.floor(Math.random() * 2) + 1);
              const picked = [...optionalAdditions].sort(() => 0.5 - Math.random()).slice(0, extrasCount);
              for (const add of picked) {
                const addQty = 1;
                additionsTotal += parseFloat(add.prix) * quantity * addQty;
                selectedAdditions.push({
                  addition_id: add.id,
                  prix: parseFloat(add.prix),
                  quantity: addQty
                });
              }
            }

            orderItems.push({
              order_id: order.id,
              menu_item_id: menuItem.id,
              quantite: quantity,
              prix_unitaire: unitPrice,
              prix_total: totalPrice,
              instructions_speciales: j === 0 && Math.random() > 0.7 ? "Extra sauce please" : null
            });

            orderItemAdditionPlans.push({
              order_id: order.id,
              menu_item_id: menuItem.id,
              quantity,
              additions: selectedAdditions
            });

            const combinedTotal = totalPrice + additionsTotal;
            const currentSubtotal = orderSubtotalMap.get(order.id) || 0;
            orderSubtotalMap.set(order.id, currentSubtotal + combinedTotal);
          }
        }
      }
      
      if ((i + 1) % 200 === 0) console.log(`➡️  Order items for ${i + 1} orders created...`);
    }
    
    const createdOrderItemsRows = await OrderItem.bulkCreate(orderItems, { returning: true });

    const additionRows = [];
    createdOrderItemsRows.forEach((orderItem, idx) => {
      const plan = orderItemAdditionPlans[idx] || { additions: [], quantity: 1 };
      (plan.additions || []).forEach(add => {
        additionRows.push({
          order_item_id: orderItem.id,
          addition_id: add.addition_id,
          quantite: plan.quantity * (add.quantity || 1),
          prix_unitaire: add.prix,
          prix_total: parseFloat(add.prix) * plan.quantity * (add.quantity || 1)
        });
      });
    });

    if (additionRows.length) {
      await OrderItemAddition.bulkCreate(additionRows);
      console.log(`✅ ${additionRows.length} order item additions created`);
    }

    for (const order of createdOrders) {
      const subtotal = orderSubtotalMap.get(order.id) ?? parseFloat(order.subtotal || 0);
      const total = subtotal + parseFloat(order.delivery_fee || 0);
      order.subtotal = subtotal;
      order.total_amount = total;
      await order.save();
    }

    console.log(`✅ ${orderItems.length} order items created`);

    // ----------------------------
    // 8️⃣ Favorites (Sample)
    // ----------------------------
    console.log("⭐ Creating favorite restaurants and meals...");
    
    const favoriteRestaurants = [];
    const favoriteMeals = [];
    
    const favoritesClientSample = Math.min(createdClients.length, seedConfig.favoritesClients);
    for (let i = 0; i < favoritesClientSample; i++) {
      const client = createdClients[i];
      const favCount = Math.floor(Math.random() * 5) + 1;
      
      for (let j = 0; j < favCount; j++) {
        const restaurant = restaurants[Math.floor(Math.random() * restaurants.length)];
        
        favoriteRestaurants.push({
          client_id: client.id,
          restaurant_id: restaurant.id,
          notes: j === 0 ? "Best pizza in town!" : null,
          tags: j % 2 === 0 ? ["favorite", "quick"] : []
        });
      }
    }
    
    if (favoriteRestaurants.length) {
      await FavoriteRestaurant.bulkCreate(favoriteRestaurants, { ignoreDuplicates: true });
    }
    console.log(`✅ ${favoriteRestaurants.length} favorite restaurants created`);
    
    for (let i = 0; i < favoritesClientSample; i++) {
      const client = createdClients[i];
      const favCount = Math.floor(Math.random() * 10) + 1;
      
      for (let j = 0; j < favCount; j++) {
        if (allMenuItems.length > 0) {
          const menuItem = allMenuItems[Math.floor(Math.random() * allMenuItems.length)];
          
          favoriteMeals.push({
            client_id: client.id,
            meal_id: menuItem.id,
            customizations: j % 3 === 0 ? "Extra cheese, no onions" : null,
            notes: j % 2 === 0 ? "My favorite!" : null
          });
        }
      }
    }
    
    if (favoriteMeals.length) {
      await FavoriteMeal.bulkCreate(favoriteMeals, { ignoreDuplicates: true });
    }
    console.log(`✅ ${favoriteMeals.length} favorite meals created`);

    // ----------------------------
    // 9️⃣ Admin Notifications
    // ----------------------------
    console.log("🔔 Creating admin notifications...");
    const notifications = [];

    const pendingOrders = createdOrders.filter(o => o.status === 'pending').slice(0, 10);
    
    for (const order of pendingOrders) {
      const restaurant = restaurants.find(r => r.id === order.restaurant_id);
      const client = order.client_id ? createdClients.find(c => c.id === order.client_id) : null;

      notifications.push({
        order_id: order.id,
        restaurant_id: order.restaurant_id,
        type: 'pending_order_timeout',
        message: `⚠️ Commande #${order.order_number} sans réponse depuis 3 minutes.\n` +
                 `Restaurant: ${restaurant?.name ?? 'N/A'}\n` +
                 `Montant: ${order.total_amount} DA`,
        order_details: {
          order_number: order.order_number,
          order_type: order.order_type,
          total_amount: parseFloat(order.total_amount),
          delivery_address: order.delivery_address,
          created_at: order.created_at,
          client: client ? {
            name: `${client.first_name} ${client.last_name}`,
            phone: client.phone_number,
            address: client.address
          } : null
        },
        restaurant_info: restaurant ? {
          id: restaurant.id,
          name: restaurant.name,
          address: restaurant.address,
          phone: restaurant.phone_number
        } : null,
        is_read: Math.random() > 0.5,
        is_resolved: false
      });
    }
    
    // ƒo. Add more notification types for admin UI testing (even when there are no pending orders).
    const pickOne = (list) => (Array.isArray(list) && list.length ? list[Math.floor(Math.random() * list.length)] : null);
    const findRestaurant = (order) => restaurants.find((r) => r.id === order.restaurant_id);
    const findClient = (order) => (order.client_id ? createdClients.find((c) => c.id === order.client_id) : null);
    const buildOrderDetails = (order) => {
      const client = findClient(order);
      return {
        order_number: order.order_number,
        order_type: order.order_type,
        total_amount: parseFloat(order.total_amount),
        delivery_address: order.delivery_address,
        created_at: order.created_at,
        client: client
          ? {
              name: `${client.first_name} ${client.last_name}`,
              phone: client.phone_number,
              address: client.address
            }
          : null
      };
    };
    const buildRestaurantInfo = (restaurant) =>
      restaurant
        ? {
            id: restaurant.id,
            name: restaurant.name,
            address: restaurant.address,
            phone: restaurant.phone_number
          }
        : null;

    // Ensure at least a few notifications exist even with 0 pending orders.
    if (notifications.length === 0 && createdOrders.length) {
      const fallbackOrders = createdOrders.slice(0, Math.min(createdOrders.length, 6));
      for (const order of fallbackOrders) {
        const restaurant = findRestaurant(order);
        notifications.push({
          order_id: order.id,
          restaurant_id: order.restaurant_id,
          type: 'pending_order_timeout',
          message:
            `ALERTE: Commande #${order.order_number} en attente de validation.\n` +
            `Restaurant: ${restaurant?.name ?? 'N/A'}\n` +
            `Montant: ${order.total_amount} DA`,
          order_details: buildOrderDetails(order),
          restaurant_info: buildRestaurantInfo(restaurant),
          is_read: Math.random() > 0.6,
          is_resolved: false
        });
      }
    }

    // Restaurant unresponsive notifications
    const restaurantTargets = createdOrders
      .filter((order) => ['pending', 'accepted', 'preparing'].includes(order.status))
      .slice(0, 4);

    for (const order of restaurantTargets) {
      const restaurant = findRestaurant(order);
      const shouldResolve = Math.random() > 0.7;
      notifications.push({
        order_id: order.id,
        restaurant_id: order.restaurant_id,
        type: 'restaurant_unresponsive',
        message:
          `ALERTE: Restaurant sans reponse pour la commande #${order.order_number}.\n` +
          `Restaurant: ${restaurant?.name ?? 'N/A'}\n` +
          `Action: contacter le restaurant.`,
        order_details: buildOrderDetails(order),
        restaurant_info: buildRestaurantInfo(restaurant),
        is_read: shouldResolve || Math.random() > 0.4,
        is_resolved: shouldResolve,
        resolved_by: shouldResolve ? pickOne(admins)?.id ?? null : null,
        resolved_at: shouldResolve ? new Date(Date.now() - Math.random() * 12 * 60 * 60 * 1000) : null,
        admin_action: shouldResolve ? 'contacted_restaurant' : null,
        admin_notes: shouldResolve ? 'Restaurant contactAc, prise en charge confirmAce.' : null
      });
    }

    // Restaurant preparation timeout notifications
    const preparationTargets = createdOrders
      .filter((order) => ['accepted', 'preparing'].includes(order.status))
      .slice(0, 4);

    for (const order of preparationTargets) {
      const restaurant = findRestaurant(order);
      notifications.push({
        order_id: order.id,
        restaurant_id: order.restaurant_id,
        type: 'restaurant_preparation_timeout',
        message:
          `ALERTE: Preparation trop longue pour la commande #${order.order_number}.\n` +
          `Restaurant: ${restaurant?.name ?? 'N/A'}\n` +
          `Action: verifier le statut avec le restaurant.`,
        order_details: buildOrderDetails(order),
        restaurant_info: buildRestaurantInfo(restaurant),
        is_read: Math.random() > 0.4,
        is_resolved: false
      });
    }

    // Driver unresponsive notifications
    const driverOrderTargets = createdOrders
      .filter((order) => order.livreur_id && ['assigned', 'delivering'].includes(order.status))
      .slice(0, 4);

    for (const order of driverOrderTargets) {
      const restaurant = findRestaurant(order);
      notifications.push({
        order_id: order.id,
        restaurant_id: order.restaurant_id,
        driver_id: order.livreur_id,
        type: 'driver_unresponsive',
        message:
          `ALERTE: Livreur injoignable pour la commande #${order.order_number}.\n` +
          `Action: vAcrifier la position et contacter le livreur.`,
        order_details: buildOrderDetails(order),
        restaurant_info: buildRestaurantInfo(restaurant),
        is_read: Math.random() > 0.5,
        is_resolved: false
      });
    }

    // Driver arrival timeout notifications
    const driverArrivalTargets = createdOrders
      .filter((order) => order.livreur_id && order.status === 'assigned')
      .slice(0, 4);

    for (const order of driverArrivalTargets) {
      const restaurant = findRestaurant(order);
      notifications.push({
        order_id: order.id,
        restaurant_id: order.restaurant_id,
        driver_id: order.livreur_id,
        type: 'driver_arrival_timeout',
        message:
          `ALERTE: Livreur en retard pour la commande #${order.order_number}.\n` +
          `Action: contacter le livreur.`,
        order_details: buildOrderDetails(order),
        restaurant_info: buildRestaurantInfo(restaurant),
        is_read: Math.random() > 0.5,
        is_resolved: false
      });
    }

    // Driver excessive cancellations notifications (no order required)
    const driversSample = createdDrivers.slice(0, Math.min(createdDrivers.length, 3));
    for (const driver of driversSample) {
      const shouldResolve = Math.random() > 0.5;
      notifications.push({
        driver_id: driver.id,
        type: 'driver_excessive_cancellations',
        message: `ALERTE: Livreur ${driver.first_name ?? ''} ${driver.last_name ?? ''} a depasse le seuil d'annulations.`,
        is_read: shouldResolve || Math.random() > 0.7,
        is_resolved: shouldResolve,
        resolved_by: shouldResolve ? pickOne(admins)?.id ?? null : null,
        resolved_at: shouldResolve ? new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000) : null,
        admin_action: shouldResolve ? 'none' : null,
        admin_notes: shouldResolve ? 'Avertissement envoye au livreur.' : null
      });
    }

    await AdminNotification.bulkCreate(notifications);
    console.log(`✅ ${notifications.length} admin notifications created`);

    // ----------------------------
    // 📊 Résumé final
    // ----------------------------
    console.log("\n" + "=".repeat(60));
    console.log("📊 DATABASE SEEDING COMPLETE");
    console.log("=".repeat(60));
    console.log(`✅ ${admins.length} admins`);
    console.log(`✅ ${createdClients.length} clients`);
    console.log(`✅ ${createdDrivers.length} drivers (capacity: 5 orders each)`);
    console.log(`✅ ${restaurants.length} restaurants`);
    console.log(
      `✅ ${createdCashiers.length} cashiers (${seedConfig.cashiersPerRestaurant} per restaurant for first ${cashierRestaurantCount})`
    );
    console.log(`✅ ${allMenuItems.length} menu items`);
    console.log(`✅ ${createdOrders.length} orders (${orders.filter(o => o.created_by_cashier_id).length} from POS)`); // ✅ MODIFIÉ
    console.log(`✅ ${orderItems.length} order items`);
    console.log(`✅ ${favoriteRestaurants.length} favorite restaurants`);
    console.log(`✅ ${favoriteMeals.length} favorite meals`);
    console.log(`✅ ${notifications.length} admin notifications`);
    console.log(`✅ 8 system configurations`);
    
    console.log("\n⚙️  SYSTEM CONFIGURATIONS:");
    console.log("─".repeat(60));
    console.log("✓ max_orders_per_driver: 5");
    console.log("✓ client_restaurant_search_radius: 2000m");
    console.log("✓ default_preparation_time: 15 min");
    console.log("✓ pending_order_timeout: 3 min");
    console.log("✓ restaurant_preparation_timeout: 20 min");
    console.log("✓ driver_arrival_timeout: 15 min");
    console.log("✓ default_delivery_fee: 200 DA");
    console.log("✓ max_driver_cancellations: 3");
    console.log("─".repeat(60));
    
    console.log("\n🔑 LOGIN CREDENTIALS:");
    console.log("─".repeat(60));
    console.log("ADMINS:");
    console.log("  • admin1@example.com (Super Admin) / password123");
    console.log("  • admin2@example.com (Admin) / password123");
    console.log("  • admin3@example.com (Moderator) / password123");
    console.log("\nCLIENTS:");
    console.log(`  • client1@example.com → client${createdClients.length}@example.com / password123`);
    console.log("\nDRIVERS:");
    console.log(`  • driver1@example.com → driver${createdDrivers.length}@example.com / password123`);
    console.log("\nRESTAURANTS:");
    console.log(`  • restaurant1@example.com → restaurant${restaurants.length}@example.com / password123`);
    console.log("\n💰 CASHIERS:");
    if (createdCashiers.length) {
      console.log(`  • cashier1@example.com → cashier${createdCashiers.length}@example.com / password123`);
      console.log(`  • ${seedConfig.cashiersPerRestaurant} cashiers per restaurant (first ${cashierRestaurantCount} restaurants)`);
    } else {
      console.log("  • (no cashiers seeded)");
    }
    console.log("  • Various permission levels for testing");
    console.log("─".repeat(60));
    
    console.log("\n📊 CASHIER STATISTICS:");
    console.log("─".repeat(60));
    const activeCashiers = createdCashiers.filter(c => c.status === 'active').length;
    const onBreakCashiers = createdCashiers.filter(c => c.status === 'on_break').length;
    const offlineCashiers = createdCashiers.filter(c => c.status === 'offline').length;
    const posOrders = orders.filter(o => o.created_by_cashier_id).length;
    
    console.log(`✓ Active cashiers: ${activeCashiers}`);
    console.log(`✓ On break: ${onBreakCashiers}`);
    console.log(`✓ Offline: ${offlineCashiers}`);
    console.log(`✓ POS orders created: ${posOrders} (~30% of total)`);
    console.log("─".repeat(60));
    
    console.log("\n✅ System ready for testing!");
    console.log("🚀 Multi-delivery features enabled");
    console.log("💰 POS system with cashiers ready"); // ✅ NOUVEAU
    console.log("📱 Ready for production load testing");
    console.log("🔧 Admins can modify all configs via API endpoints");

  } catch (err) {
    console.error("❌ Seeding failed:", err);
    console.error(err.stack);
  } finally {
    await sequelize.close();
    console.log("\n👋 Database connection closed");
  }
};

seedDatabase();

















