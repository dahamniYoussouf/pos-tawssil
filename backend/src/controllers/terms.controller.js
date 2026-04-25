import SystemConfig from '../models/SystemConfig.js';
import { DEFAULT_LOCALE, normalizeLocale } from '../utils/locale.js';

const TERMS_CONFIG_KEY = 'terms_of_use';

const DEFAULT_TERMS = {
  fr: "<h1>Conditions d'utilisation</h1><p>Veuillez remplacer ce contenu par vos propres conditions.</p>",
  ar: "<h1>Conditions d'utilisation (AR)</h1><p>Ajoutez votre contenu en arabe ici.</p>",
  en: "<h1>Terms of Use</h1><p>Please replace this content with your own terms.</p>"
};

const normalizeTermsContent = (value) => {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return {
      fr: typeof value.fr === 'string' ? value.fr : '',
      ar: typeof value.ar === 'string' ? value.ar : '',
      en: typeof value.en === 'string' ? value.en : ''
    };
  }

  if (typeof value === 'string') {
    return { fr: value, ar: '', en: '' };
  }

  return { ...DEFAULT_TERMS };
};

const pickLocalizedHtml = (content, locale) => {
  const normalized = normalizeTermsContent(content);
  return normalized[locale] || normalized[DEFAULT_LOCALE] || '';
};

const buildTermsPage = (html, locale) => {
  const dir = locale === 'ar' ? 'rtl' : 'ltr';
  const title = locale === 'en' ? 'Terms of Use' : "Conditions d'utilisation";
  const safeHtml = html || '';

  return `<!doctype html>
<html lang="${locale}" dir="${dir}">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
    <style>
      :root { color-scheme: light; }
      body {
        margin: 0;
        padding: 40px 20px;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        line-height: 1.6;
        color: #0f172a;
        background: #f8fafc;
      }
      main {
        max-width: 900px;
        margin: 0 auto;
        background: #fff;
        padding: 32px;
        border-radius: 16px;
        box-shadow: 0 10px 30px rgba(15, 23, 42, 0.08);
      }
      h1, h2, h3 { color: #0f172a; }
      a { color: #0ea5e9; }
    </style>
  </head>
  <body>
    <main>
      ${safeHtml || '<p>Aucun contenu.</p>'}
    </main>
  </body>
</html>`;
};

export const getTerms = async (req, res, next) => {
  try {
    const locale = normalizeLocale(req.query.locale, DEFAULT_LOCALE);
    const config = await SystemConfig.findOne({ where: { config_key: TERMS_CONFIG_KEY } });
    const html = pickLocalizedHtml(config?.config_value, locale);
    const acceptHeader = String(req.headers.accept || '');
    const wantsJson =
      req.query.format === 'json' ||
      req.query.json === 'true' ||
      acceptHeader.includes('application/json');

    if (wantsJson) {
      return res.json({
        success: true,
        data: {
          locale,
          html,
          updated_at: config?.updated_at || null
        }
      });
    }

    const page = buildTermsPage(html, locale);
    res.status(200).set('Content-Type', 'text/html; charset=utf-8');
    return res.send(page);
  } catch (err) {
    next(err);
  }
};

export const getTermsAdmin = async (req, res, next) => {
  try {
    const config = await SystemConfig.findOne({ where: { config_key: TERMS_CONFIG_KEY } });
    const content = normalizeTermsContent(config?.config_value);

    res.json({
      success: true,
      data: {
        content,
        updated_at: config?.updated_at || null,
        updated_by: config?.updated_by || null
      }
    });
  } catch (err) {
    next(err);
  }
};

export const updateTermsAdmin = async (req, res, next) => {
  try {
    const adminId = req.user?.admin_id;
    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: 'Admin profile not found in token'
      });
    }

    const { content, locale, html } = req.body;
    let nextContent = null;

    if (content && typeof content === 'object' && !Array.isArray(content)) {
      nextContent = normalizeTermsContent(content);
    } else if (locale !== undefined && html !== undefined) {
      const normalizedLocale = normalizeLocale(locale, DEFAULT_LOCALE);
      const existing = await SystemConfig.findOne({ where: { config_key: TERMS_CONFIG_KEY } });
      const merged = normalizeTermsContent(existing?.config_value);
      merged[normalizedLocale] = String(html);
      nextContent = merged;
    }

    if (!nextContent) {
      return res.status(400).json({
        success: false,
        message: 'content or (locale + html) is required'
      });
    }

    const config = await SystemConfig.set(
      TERMS_CONFIG_KEY,
      nextContent,
      adminId,
      "Conditions d'utilisation (HTML)"
    );

    res.json({
      success: true,
      message: 'Terms updated successfully',
      data: {
        content: config.config_value,
        updated_at: config.updated_at
      }
    });
  } catch (err) {
    next(err);
  }
};
