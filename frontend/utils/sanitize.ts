const COMBINING_MARKS_REGEX = /[\u0300-\u036f]/g;
const NBSP_REGEX = /[\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]/g;
const SYMBOLS_REGEX = /[\u2010-\u2015\u2022\u2026\u2030-\u203F\u2040-\u206F\u20AC\u2122]/g;
const LATIN1_SYMBOLS_REGEX = /[\u00A1-\u00BF]/g;
const CONTROL_CHARS_REGEX = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g;
const REPLACEMENT_CHAR_REGEX = /\uFFFD/g;

const needsLatin1Fix = (value: string) => /[\u00C0-\u00FF]/.test(value) && !/[^\x00-\xFF]/.test(value);

const fixMojibake = (value: string) => {
  if (!needsLatin1Fix(value)) return value;

  try {
    const maybeBuffer = (globalThis as {
      Buffer?: { from: (input: string, encoding: string) => { toString: (encoding: string) => string } };
    }).Buffer;

    if (maybeBuffer) {
      return maybeBuffer.from(value, 'latin1').toString('utf8');
    }
  } catch {
    // Ignore Buffer failures and fall back to decode/escape.
  }

  try {
    return decodeURIComponent(escape(value));
  } catch {
    return value;
  }
};

export const sanitizeVisibleText = (value: string) => {
  let sanitized = fixMojibake(value);

  sanitized = sanitized
    .replace(/\u00E2(?=[\u20AC\u2013-\u2015\u2018-\u201D\u2026])/g, '')
    .replace(/\u00C2(?=[\u00A0-\u00BF])/g, '');

  sanitized = sanitized.normalize('NFKD').replace(COMBINING_MARKS_REGEX, '');
  sanitized = sanitized.replace(NBSP_REGEX, ' ');
  sanitized = sanitized.replace(REPLACEMENT_CHAR_REGEX, '');
  sanitized = sanitized.replace(SYMBOLS_REGEX, '');
  sanitized = sanitized.replace(LATIN1_SYMBOLS_REGEX, '');
  sanitized = sanitized.replace(CONTROL_CHARS_REGEX, '');

  return sanitized;
};

export const sanitizeDeep = <T>(input: T, seen = new WeakMap<object, unknown>()): T => {
  if (typeof input === 'string') {
    return sanitizeVisibleText(input) as T;
  }

  if (Array.isArray(input)) {
    return input.map((item) => sanitizeDeep(item, seen)) as T;
  }

  if (!input || typeof input !== 'object') {
    return input;
  }

  const isBlob = typeof Blob !== 'undefined' && input instanceof Blob;
  const isFile = typeof File !== 'undefined' && input instanceof File;
  const isFormData = typeof FormData !== 'undefined' && input instanceof FormData;

  if (input instanceof Date || isBlob || isFile || isFormData) {
    return input;
  }

  if (seen.has(input as object)) {
    return seen.get(input as object) as T;
  }

  const output: Record<string, unknown> = {};
  seen.set(input as object, output);

  Object.entries(input as Record<string, unknown>).forEach(([key, value]) => {
    output[key] = sanitizeDeep(value, seen);
  });

  return output as T;
};
