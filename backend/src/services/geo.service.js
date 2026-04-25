import Wilaya from "../models/Wilaya.js";
import Commune from "../models/Commune.js";

const normalizeWilayaCode = (value) => String(value || "").trim();
const normalizeText = (value) => String(value || "").trim();

const normalizeOptionalText = (value) => {
  const trimmed = normalizeText(value);
  return trimmed.length ? trimmed : null;
};

const serializeCommune = (commune) => {
  const coordinates = commune?.getCoordinates?.() || null;
  return {
    id: commune.id,
    name: commune.name,
    name_ar: commune.name_ar,
    wilaya_code: commune.wilaya_code,
    wilaya_name: commune.wilaya_name,
    code: commune.code,
    lat: coordinates?.latitude ?? null,
    lng: coordinates?.longitude ?? null
  };
};

const parseCoordinate = (value, label) => {
  const parsed = Number.parseFloat(String(value));
  if (!Number.isFinite(parsed)) {
    const error = new Error(`${label} is required`);
    error.status = 400;
    throw error;
  }
  return parsed;
};

const requireWilaya = async (code) => {
  const normalizedCode = normalizeWilayaCode(code);
  if (!normalizedCode) {
    const error = new Error("wilaya_code is required");
    error.status = 400;
    throw error;
  }
  const wilaya = await Wilaya.findByPk(normalizedCode);
  if (!wilaya) {
    const error = new Error("Wilaya not found");
    error.status = 404;
    throw error;
  }
  return wilaya;
};

export const listWilayas = async () => {
  const rows = await Wilaya.findAll({
    order: [["code", "ASC"]],
    attributes: ["code", "name", "name_ar"]
  });
  return rows.map((row) => row.toJSON());
};

export const listCommunes = async ({ wilaya_code } = {}) => {
  const normalizedCode = normalizeWilayaCode(wilaya_code);
  const where = normalizedCode ? { wilaya_code: normalizedCode } : undefined;
  const rows = await Commune.findAll({
    where,
    order: [["name", "ASC"]],
    attributes: ["id", "name", "name_ar", "wilaya_code", "wilaya_name", "code", "location"]
  });
  return rows.map((row) => serializeCommune(row));
};

export const getCommuneById = async (id) => {
  const commune = await Commune.findByPk(id, {
    attributes: ["id", "name", "name_ar", "wilaya_code", "wilaya_name", "code", "location"]
  });
  if (!commune) {
    const error = new Error("Commune not found");
    error.status = 404;
    throw error;
  }
  return serializeCommune(commune);
};

export const createWilaya = async ({ code, name, name_ar }) => {
  const normalizedCode = normalizeWilayaCode(code);
  const normalizedName = normalizeText(name);

  if (!normalizedCode || !normalizedName) {
    const error = new Error("code and name are required");
    error.status = 400;
    throw error;
  }

  const existing = await Wilaya.findByPk(normalizedCode);
  if (existing) {
    const error = new Error("Wilaya code already exists");
    error.status = 409;
    throw error;
  }

  const wilaya = await Wilaya.create({
    code: normalizedCode,
    name: normalizedName,
    name_ar: normalizeOptionalText(name_ar)
  });

  return wilaya.toJSON();
};

export const updateWilaya = async (code, payload = {}) => {
  const normalizedCode = normalizeWilayaCode(code);
  const wilaya = await Wilaya.findByPk(normalizedCode);
  if (!wilaya) return null;

  const updates = {};
  if (payload.name !== undefined) {
    const normalizedName = normalizeText(payload.name);
    if (!normalizedName) {
      const error = new Error("name is required");
      error.status = 400;
      throw error;
    }
    updates.name = normalizedName;
  }

  if (payload.name_ar !== undefined) {
    updates.name_ar = normalizeOptionalText(payload.name_ar);
  }

  if (Object.keys(updates).length === 0) {
    return wilaya.toJSON();
  }

  await wilaya.update(updates);

  if (updates.name) {
    await Commune.update(
      { wilaya_name: updates.name },
      { where: { wilaya_code: normalizedCode } }
    );
  }

  return wilaya.toJSON();
};

export const deleteWilaya = async (code) => {
  const normalizedCode = normalizeWilayaCode(code);
  const wilaya = await Wilaya.findByPk(normalizedCode);
  if (!wilaya) return false;

  const communesCount = await Commune.count({ where: { wilaya_code: normalizedCode } });
  if (communesCount > 0) {
    const error = new Error("Cannot delete a wilaya with communes");
    error.status = 400;
    throw error;
  }

  await wilaya.destroy();
  return true;
};

export const createCommune = async ({ name, name_ar, wilaya_code, code, lat, lng }) => {
  const wilaya = await requireWilaya(wilaya_code);
  const normalizedName = normalizeText(name);

  if (!normalizedName) {
    const error = new Error("name is required");
    error.status = 400;
    throw error;
  }

  const latitude = parseCoordinate(lat, "lat");
  const longitude = parseCoordinate(lng, "lng");

  const commune = Commune.build({
    name: normalizedName,
    name_ar: normalizeOptionalText(name_ar),
    wilaya_code: wilaya.code,
    wilaya_name: wilaya.name,
    code: normalizeOptionalText(code)
  });

  commune.setCoordinates(longitude, latitude);
  await commune.save();

  return serializeCommune(commune);
};

export const updateCommune = async (id, payload = {}) => {
  const commune = await Commune.findByPk(id);
  if (!commune) return null;

  const updates = {};
  if (payload.name !== undefined) {
    const normalizedName = normalizeText(payload.name);
    if (!normalizedName) {
      const error = new Error("name is required");
      error.status = 400;
      throw error;
    }
    updates.name = normalizedName;
  }

  if (payload.name_ar !== undefined) {
    updates.name_ar = normalizeOptionalText(payload.name_ar);
  }

  if (payload.code !== undefined) {
    updates.code = normalizeOptionalText(payload.code);
  }

  if (payload.wilaya_code !== undefined) {
    const normalizedWilayaCode = normalizeWilayaCode(payload.wilaya_code);
    if (!normalizedWilayaCode) {
      const error = new Error("wilaya_code is required");
      error.status = 400;
      throw error;
    }
    const wilaya = await requireWilaya(normalizedWilayaCode);
    updates.wilaya_code = wilaya.code;
    updates.wilaya_name = wilaya.name;
  }

  const hasLatitude = payload.lat !== undefined;
  const hasLongitude = payload.lng !== undefined;
  if (hasLatitude || hasLongitude) {
    if (!hasLatitude || !hasLongitude) {
      const error = new Error("lat and lng are required together");
      error.status = 400;
      throw error;
    }
    const latitude = parseCoordinate(payload.lat, "lat");
    const longitude = parseCoordinate(payload.lng, "lng");
    commune.setCoordinates(longitude, latitude);
  }

  if (Object.keys(updates).length > 0) {
    Object.assign(commune, updates);
  }

  if (Object.keys(updates).length > 0 || hasLatitude || hasLongitude) {
    await commune.save();
  }

  return serializeCommune(commune);
};

export const deleteCommune = async (id) => {
  const commune = await Commune.findByPk(id);
  if (!commune) return false;
  await commune.destroy();
  return true;
};
