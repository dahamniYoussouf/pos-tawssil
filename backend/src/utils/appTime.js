export const APP_TIMEZONE =
  process.env.APP_TIMEZONE ||
  process.env.TZ ||
  "Africa/Algiers";

export const APP_LOCALE = process.env.APP_LOCALE || "fr-FR";

const ISO_DATE_TIME_WITH_ZONE_RE =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?(?:Z|[+-]\d{2}:?\d{2})$/i;

const resolveDate = (value) => {
  if (value === undefined || value === null || value === "") return null;
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};

const getDateTimePartsInTimeZone = (date, timeZone = APP_TIMEZONE) => {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23"
  });

  const parts = formatter.formatToParts(date);
  const values = {};

  for (const part of parts) {
    if (part.type !== "literal") {
      values[part.type] = part.value;
    }
  }

  return values;
};

const formatOffset = (offsetMinutes) => {
  const sign = offsetMinutes >= 0 ? "+" : "-";
  const absoluteMinutes = Math.abs(offsetMinutes);
  const hours = String(Math.floor(absoluteMinutes / 60)).padStart(2, "0");
  const minutes = String(absoluteMinutes % 60).padStart(2, "0");
  return `${sign}${hours}:${minutes}`;
};

const formatWithTimeZone = (value, locale, options, fallbackFactory) => {
  const date = resolveDate(value);
  if (!date) {
    if (value !== undefined && value !== null && value !== "") {
      return String(value);
    }
    return fallbackFactory(new Date());
  }

  try {
    return new Intl.DateTimeFormat(locale, {
      timeZone: APP_TIMEZONE,
      ...options
    }).format(date);
  } catch (error) {
    return fallbackFactory(date);
  }
};

export const formatDateInAppTimeZone = (value, locale = APP_LOCALE) =>
  formatWithTimeZone(
    value,
    locale,
    {
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
    },
    (date) => date.toLocaleDateString(locale)
  );

export const formatTimeInAppTimeZone = (value, locale = APP_LOCALE) =>
  formatWithTimeZone(
    value,
    locale,
    {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false
    },
    (date) =>
      date.toLocaleTimeString(locale, {
        hour: "2-digit",
        minute: "2-digit",
        hour12: false
      })
  );

export const formatDateTimeInAppTimeZone = (value, locale = APP_LOCALE) =>
  formatWithTimeZone(
    value,
    locale,
    {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false
    },
    (date) => date.toLocaleString(locale)
  );

export const formatIsoInAppTimeZone = (value) => {
  const date = resolveDate(value);
  if (!date) {
    return value === undefined || value === null ? null : String(value);
  }

  try {
    const parts = getDateTimePartsInTimeZone(date);
    const year = parts.year;
    const month = parts.month;
    const day = parts.day;
    const hour = parts.hour;
    const minute = parts.minute;
    const second = parts.second;

    if (!year || !month || !day || !hour || !minute || !second) {
      throw new Error("Incomplete date parts");
    }

    const milliseconds = String(date.getMilliseconds()).padStart(3, "0");
    const zonedTimestamp = Date.UTC(
      Number.parseInt(year, 10),
      Number.parseInt(month, 10) - 1,
      Number.parseInt(day, 10),
      Number.parseInt(hour, 10),
      Number.parseInt(minute, 10),
      Number.parseInt(second, 10),
      date.getMilliseconds()
    );
    const offsetMinutes = Math.round((zonedTimestamp - date.getTime()) / 60000);

    return `${year}-${month}-${day}T${hour}:${minute}:${second}.${milliseconds}${formatOffset(offsetMinutes)}`;
  } catch (error) {
    return date.toISOString();
  }
};

const isPlainObject = (value) => {
  if (!value || typeof value !== "object") return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
};

const normalizeSerializableValue = (value) => {
  if (!value || typeof value !== "object") return value;
  if (value instanceof Date || Array.isArray(value) || Buffer.isBuffer(value)) return value;

  if (!isPlainObject(value) && typeof value.toJSON === "function") {
    try {
      const serializedValue = value.toJSON();
      if (serializedValue !== value) {
        return serializedValue;
      }
    } catch (error) {
      return value;
    }
  }

  return value;
};

export const serializeDatesInAppTimeZone = (value, seen = new WeakSet()) => {
  if (value instanceof Date) {
    return formatIsoInAppTimeZone(value);
  }

  if (typeof value === "string" && ISO_DATE_TIME_WITH_ZONE_RE.test(value)) {
    return formatIsoInAppTimeZone(value);
  }

  if (!value || typeof value !== "object") {
    return value;
  }

  const normalizedValue = normalizeSerializableValue(value);
  if (normalizedValue !== value) {
    return serializeDatesInAppTimeZone(normalizedValue, seen);
  }

  if (Array.isArray(normalizedValue)) {
    return normalizedValue.map((entry) => serializeDatesInAppTimeZone(entry, seen));
  }

  if (seen.has(normalizedValue)) {
    return normalizedValue;
  }
  seen.add(normalizedValue);

  const serializedObject = {};
  for (const [key, entry] of Object.entries(normalizedValue)) {
    serializedObject[key] = serializeDatesInAppTimeZone(entry, seen);
  }

  seen.delete(normalizedValue);
  return serializedObject;
};

export const getDateStampInAppTimeZone = (value = new Date()) => {
  const date = resolveDate(value);
  if (!date) return null;

  try {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: APP_TIMEZONE,
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
    }).formatToParts(date);

    const values = {};
    for (const part of parts) {
      if (part.type !== "literal") {
        values[part.type] = part.value;
      }
    }

    if (!values.year || !values.month || !values.day) {
      return null;
    }

    return `${values.year}${values.month}${values.day}`;
  } catch (error) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}${month}${day}`;
  }
};
