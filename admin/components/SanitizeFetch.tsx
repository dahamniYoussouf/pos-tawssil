'use client';

import { sanitizeDeep } from '@/utils/sanitize';

const PATCH_FLAG = '__tawsilSanitizeJsonPatched__';

if (typeof window !== 'undefined') {
  const responseProto = Response.prototype as Response & { [key: string]: unknown };
  const isPatched = Boolean(responseProto[PATCH_FLAG]);

  if (!isPatched) {
    const originalJson = responseProto.json;

    responseProto[PATCH_FLAG] = true;
    responseProto.json = async function (...args: Parameters<Response['json']>) {
      const data = await originalJson.apply(this, args);
      return sanitizeDeep(data);
    };
  }
}

export default function SanitizeFetch() {
  return null;
}
