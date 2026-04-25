export const RESTAURANT_OPENING_HOURS_TIMEZONE =
  process.env.OPENING_HOURS_TIMEZONE ||
  process.env.APP_TIMEZONE ||
  "Africa/Algiers";

const DAY_KEYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];

const DAY_ALIASES = {
  sun: new Set(["sun", "sunday", "dim", "dimanche"]),
  mon: new Set(["mon", "monday", "lun", "lundi"]),
  tue: new Set(["tue", "tues", "tuesday", "mar", "mardi"]),
  wed: new Set(["wed", "wednesday", "mer", "mercredi"]),
  thu: new Set(["thu", "thur", "thurs", "thursday", "jeu", "jeudi"]),
  fri: new Set(["fri", "friday", "ven", "vendredi"]),
  sat: new Set(["sat", "saturday", "sam", "samedi"])
};

export const parseOpeningHours = (value) => {
  if (!value) return null;

  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : null;
    } catch (error) {
      return null;
    }
  }

  return typeof value === "object" && !Array.isArray(value) ? value : null;
};

const normalizeDayKey = (value) => {
  if (value === null || value === undefined) return null;

  const normalized = String(value).trim().toLowerCase().replace(/[^a-z]/g, "");
  if (!normalized) return null;

  for (const [dayKey, aliases] of Object.entries(DAY_ALIASES)) {
    if (aliases.has(normalized)) return dayKey;
  }

  return null;
};

const normalizeTimeValue = (value) => {
  if (value === null || value === undefined || value === "") return null;

  const normalized = Number.parseInt(String(value), 10);
  if (!Number.isFinite(normalized)) return null;
  if (normalized === 2400) return 2400;
  if (normalized < 0 || normalized > 2359) return null;

  const hours = Math.floor(normalized / 100);
  const minutes = normalized % 100;

  if (hours > 23 || minutes > 59) return null;

  return normalized;
};

export const normalizeOpeningHours = (value) => {
  const parsedOpeningHours = parseOpeningHours(value);
  if (!parsedOpeningHours) return null;

  const normalizedOpeningHours = {};

  for (const [rawDayKey, schedule] of Object.entries(parsedOpeningHours)) {
    const dayKey = normalizeDayKey(rawDayKey);
    if (!dayKey || !schedule || typeof schedule !== "object") continue;

    const open = normalizeTimeValue(schedule.open);
    const close = normalizeTimeValue(schedule.close);

    if (open === null || close === null) continue;

    normalizedOpeningHours[dayKey] = { open, close };
  }

  return Object.keys(normalizedOpeningHours).length > 0 ? normalizedOpeningHours : null;
};

const getScheduleForDay = (openingHours, dayKey) => {
  if (!openingHours || !dayKey) return null;

  const directMatch = openingHours[dayKey];
  if (directMatch && typeof directMatch === "object") return directMatch;

  for (const [rawKey, schedule] of Object.entries(openingHours)) {
    if (normalizeDayKey(rawKey) === dayKey && schedule && typeof schedule === "object") {
      return schedule;
    }
  }

  return null;
};

const getCurrentContext = (now, timeZone) => {
  try {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone,
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false
    }).formatToParts(now);

    const values = {};
    for (const part of parts) {
      if (part.type !== "literal") {
        values[part.type] = part.value;
      }
    }

    const dayKey = normalizeDayKey(values.weekday);
    const hours = Number.parseInt(values.hour, 10);
    const minutes = Number.parseInt(values.minute, 10);

    if (!dayKey || !Number.isFinite(hours) || !Number.isFinite(minutes)) {
      return null;
    }

    return {
      dayKey,
      currentTime: hours * 100 + minutes
    };
  } catch (error) {
    const fallbackDay = normalizeDayKey(now.toLocaleDateString("en-US", { weekday: "short" }));
    if (!fallbackDay) return null;

    return {
      dayKey: fallbackDay,
      currentTime: now.getHours() * 100 + now.getMinutes()
    };
  }
};

const isWithinTodaySchedule = (schedule, currentTime) => {
  const open = normalizeTimeValue(schedule?.open);
  const close = normalizeTimeValue(schedule?.close);

  if (open === null || close === null) return false;

  if (open <= close) {
    return currentTime >= open && currentTime <= close;
  }

  return currentTime >= open;
};

const isWithinPreviousOvernightSchedule = (schedule, currentTime) => {
  const open = normalizeTimeValue(schedule?.open);
  const close = normalizeTimeValue(schedule?.close);

  if (open === null || close === null || open <= close) return false;

  return currentTime <= close;
};

export const isRestaurantOpenNow = ({
  openingHours,
  availabilityStatus = "open",
  now = new Date(),
  timeZone = RESTAURANT_OPENING_HOURS_TIMEZONE
} = {}) => {
  const normalizedStatus = String(availabilityStatus || "open").trim().toLowerCase();
  if (normalizedStatus !== "open") return false;

  const parsedOpeningHours = normalizeOpeningHours(openingHours);
  if (!parsedOpeningHours) return false;

  const context = getCurrentContext(now, timeZone);
  if (!context) return false;

  const { dayKey, currentTime } = context;
  const todaySchedule = getScheduleForDay(parsedOpeningHours, dayKey);
  if (isWithinTodaySchedule(todaySchedule, currentTime)) return true;

  const dayIndex = DAY_KEYS.indexOf(dayKey);
  if (dayIndex === -1) return false;

  const previousDayKey = DAY_KEYS[(dayIndex + DAY_KEYS.length - 1) % DAY_KEYS.length];
  const previousDaySchedule = getScheduleForDay(parsedOpeningHours, previousDayKey);

  return isWithinPreviousOvernightSchedule(previousDaySchedule, currentTime);
};
