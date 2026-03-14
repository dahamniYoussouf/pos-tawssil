import { literal } from "sequelize";
import Commune from "../models/Commune.js";
import cacheService from "./cache.service.js";

const DEFAULT_RADIUS_METERS = 5000;
const DEFAULT_LIMIT = 15;
const DEFAULT_CACHE_TTL_SECONDS = 21600; // 6 hours

const normalizeCoord = (value, precision = 3) =>
  Number.parseFloat(value).toFixed(precision);

const getLocationCoords = (location) => {
  if (!location) return null;
  const coords = location.coordinates;
  if (Array.isArray(coords) && coords.length === 2) {
    return { lng: coords[0], lat: coords[1] };
  }
  const lat = location.lat ?? location.latitude;
  const lng = location.lng ?? location.longitude;
  if (Number.isFinite(lat) && Number.isFinite(lng)) {
    return { lat, lng };
  }
  return null;
};

export const getNearbyCommunes = async ({
  lat,
  lng,
  radius = DEFAULT_RADIUS_METERS,
  limit = DEFAULT_LIMIT
}) => {
  const latitude = Number(lat);
  const longitude = Number(lng);
  const radiusMeters = Number.parseInt(radius, 10) || DEFAULT_RADIUS_METERS;
  const limitRows = Number.parseInt(limit, 10) || DEFAULT_LIMIT;

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    const error = new Error("Invalid coordinates");
    error.status = 400;
    throw error;
  }

  const cacheTTL = Math.max(
    60,
    Number.parseInt(process.env.COMMUNES_CACHE_TTL || DEFAULT_CACHE_TTL_SECONDS, 10)
  );
  const cacheKey = `communes:db:${radiusMeters}:${limitRows}:${normalizeCoord(latitude)}:${normalizeCoord(longitude)}`;
  const cached = await cacheService.get(cacheKey);
  if (cached) {
    return cached;
  }

  const point = `ST_GeogFromText('POINT(${longitude} ${latitude})')`;
  const communes = await Commune.findAll({
    attributes: [
      "id",
      "name",
      "name_ar",
      "wilaya_code",
      "wilaya_name",
      "location",
      [literal(`ST_Distance("Commune"."location", ${point})`), "distance_m"]
    ],
    where: literal(`ST_DWithin("Commune"."location", ${point}, ${radiusMeters})`),
    order: [literal(`distance_m ASC`)],
    limit: limitRows
  });

  const data = communes
    .map((commune) => {
      const coords = getLocationCoords(commune.location);
      if (!coords) return null;
      return {
        id: commune.id,
        name: commune.name,
        name_ar: commune.name_ar || null,
        wilaya_code: commune.wilaya_code,
        wilaya_name: commune.wilaya_name,
        lat: coords.lat,
        lng: coords.lng
      };
    })
    .filter(Boolean);

  const result = {
    center: { lat: latitude, lng: longitude },
    radius_m: radiusMeters,
    count: data.length,
    data
  };

  await cacheService.set(cacheKey, result, cacheTTL);
  return result;
};
