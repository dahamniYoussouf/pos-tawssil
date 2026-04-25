type ApiValidationIssue = {
  field?: unknown;
  path?: unknown;
  param?: unknown;
  message?: unknown;
  msg?: unknown;
};

type ApiErrorPayload = {
  message?: unknown;
  error?: unknown;
  errors?: unknown;
  response?: {
    data?: unknown;
  };
  data?: unknown;
};

const GENERIC_MESSAGES = new Set([
  'bad request',
  'validation error',
  'erreur de validation'
]);

const asNonEmptyString = (value: unknown) => {
  if (typeof value !== 'string') {
    return '';
  }

  return value.trim();
};

const isObject = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null;

const getErrorPayload = (value: unknown): ApiErrorPayload | null => {
  if (!isObject(value)) {
    return null;
  }

  const candidate = value as ApiErrorPayload;

  if (isObject(candidate.response?.data)) {
    return getErrorPayload(candidate.response.data) ?? (candidate.response.data as ApiErrorPayload);
  }

  if (
    isObject(candidate.data) &&
    ('message' in candidate.data || 'error' in candidate.data || 'errors' in candidate.data)
  ) {
    return candidate.data as ApiErrorPayload;
  }

  return candidate;
};

const isGenericMessage = (message: string) => {
  const normalized = message.trim().toLowerCase();
  return GENERIC_MESSAGES.has(normalized);
};

export const getApiValidationErrors = (value: unknown): Record<string, string> => {
  const payload = getErrorPayload(value);
  const rawErrors = Array.isArray(payload?.errors) ? payload.errors : [];
  const mappedErrors: Record<string, string> = {};

  rawErrors.forEach((issue) => {
    if (!isObject(issue)) {
      return;
    }

    const apiIssue = issue as ApiValidationIssue;
    const field =
      asNonEmptyString(apiIssue.field) ||
      asNonEmptyString(apiIssue.path) ||
      asNonEmptyString(apiIssue.param);
    const message = asNonEmptyString(apiIssue.message) || asNonEmptyString(apiIssue.msg);

    if (!field || !message || mappedErrors[field]) {
      return;
    }

    mappedErrors[field] = message;
  });

  return mappedErrors;
};

export const getApiErrorMessage = (value: unknown, fallback: string) => {
  const payload = getErrorPayload(value);
  const validationMessages = Object.values(getApiValidationErrors(value));

  const candidates = [
    asNonEmptyString(payload?.message),
    asNonEmptyString(payload?.error),
    value instanceof Error ? asNonEmptyString(value.message) : '',
    asNonEmptyString(value)
  ].filter(Boolean);

  if (validationMessages.length > 0) {
    const explicitMessage = candidates.find((candidate) => !isGenericMessage(candidate));
    return explicitMessage || validationMessages[0];
  }

  return candidates[0] || fallback;
};
