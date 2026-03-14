import Announcement from "../models/Announcement.js";
import Restaurant from "../models/Restaurant.js";
import { Op } from "sequelize";
import { buildClientVisibleRestaurantWhere } from "../utils/restaurantVisibility.js";

const announcementInclude = [
  {
    model: Restaurant,
    as: "restaurant",
    attributes: ["id", "name", "address", "phone_number"]
  }
];

// Create a new announcement
export const createAnnouncement = async (data) => {
  return Announcement.create(data);
};

// Get all announcements
export const getAllAnnouncements = async () => {
  return Announcement.findAll({
    include: announcementInclude,
    order: [["created_at", "DESC"]],
  });
};

// Get active announcements
export const getActiveAnnouncements = async () => {
  const now = new Date();

  const announcements = await Announcement.findAll({
    where: {
      is_active: true,
      [Op.and]: [
        {
          [Op.or]: [
            { start_date: null },
            { start_date: { [Op.lte]: now } }
          ]
        },
        {
          [Op.or]: [
            { end_date: null },
            { end_date: { [Op.gte]: now } }
          ]
        }
      ]
    },
    include: [
      {
        model: Restaurant,
        as: "restaurant",
        attributes: ["id", "name", "address", "phone_number"],
        required: false,
        where: buildClientVisibleRestaurantWhere()
      }
    ],
    order: [["created_at", "DESC"]],
  });

  return announcements.filter((announcement) =>
    !announcement.restaurant_id || Boolean(announcement.restaurant)
  );
};

// Update announcement
export const updateAnnouncement = async (id, data) => {
  const announcement = await Announcement.findOne({ where: { id } });
  if (!announcement) return null;

  await announcement.update(data);
  return announcement;
};

// Delete announcement
export const deleteAnnouncement = async (id) => {
  return Announcement.destroy({ where: { id } });
};
