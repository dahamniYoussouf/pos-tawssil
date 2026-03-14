export const SUPPORTED_LOCALES = ['fr', 'en', 'ar'] as const;
export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number];

export const DEFAULT_LOCALE: SupportedLocale = 'fr';

export const LOCALE_OPTIONS: Array<{ value: SupportedLocale; label: string }> = [
  { value: 'fr', label: 'Francais' },
  { value: 'en', label: 'Anglais' },
  { value: 'ar', label: 'Arabe' }
];

export const normalizeLocale = (value?: string | null): SupportedLocale => {
  if (!value) return DEFAULT_LOCALE;
  const normalized = value.toLowerCase() as SupportedLocale;
  return SUPPORTED_LOCALES.includes(normalized) ? normalized : DEFAULT_LOCALE;
};

export const getLocaleLabel = (value?: string | null) => {
  const normalized = normalizeLocale(value);
  return LOCALE_OPTIONS.find((option) => option.value === normalized)?.label || 'Francais';
};
