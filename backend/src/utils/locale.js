export const SUPPORTED_LOCALES = ["ar", "fr", "en"];
export const DEFAULT_LOCALE = "fr";

export const normalizeLocale = (value, fallback = DEFAULT_LOCALE) => {
  if (value === null || value === undefined) return fallback;
  let locale = String(value).trim().toLowerCase();
  if (!locale) return fallback;
  if (locale.includes("-")) {
    locale = locale.split("-")[0];
  }
  return SUPPORTED_LOCALES.includes(locale) ? locale : fallback;
};

export const isSupportedLocale = (value) => {
  if (value === null || value === undefined) return false;
  let locale = String(value).trim().toLowerCase();
  if (!locale) return false;
  if (locale.includes("-")) {
    locale = locale.split("-")[0];
  }
  return SUPPORTED_LOCALES.includes(locale);
};
