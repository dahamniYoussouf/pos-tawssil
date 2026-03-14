'use client';

import { useEffect, useMemo, useState } from 'react';
import { AlertCircle, CheckCircle2, FileText, RefreshCw, Save } from 'lucide-react';
import Loader from '@/components/Loader';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type LocaleKey = 'fr' | 'ar' | 'en';

interface PolicyContent {
  fr: string;
  ar: string;
  en: string;
}

const EMPTY_CONTENT: PolicyContent = { fr: '', ar: '', en: '' };

const LOCALE_TABS: Array<{ key: LocaleKey; label: string }> = [
  { key: 'fr', label: 'Francais' },
  { key: 'ar', label: 'Arabe' },
  { key: 'en', label: 'English' }
];

export default function PrivacyPolicyManagementPage() {
  const [content, setContent] = useState<PolicyContent>(EMPTY_CONTENT);
  const [activeLocale, setActiveLocale] = useState<LocaleKey>('fr');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [updatedAt, setUpdatedAt] = useState<string | null>(null);

  const activeHtml = content[activeLocale] ?? '';
  const isRtl = activeLocale === 'ar';

  const activeLabel = useMemo(() => {
    return LOCALE_TABS.find((tab) => tab.key === activeLocale)?.label ?? 'Francais';
  }, [activeLocale]);

  const fetchPolicy = async () => {
    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/admin/privacy-policy`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement de la politique');
      }

      const data = await response.json();
      if (data?.success) {
        setContent(data.data?.content || EMPTY_CONTENT);
        setUpdatedAt(data.data?.updated_at || null);
      }
    } catch (err: any) {
      setError(err.message || 'Erreur lors du chargement');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPolicy();
  }, []);

  const handleChange = (value: string) => {
    setContent((prev) => ({
      ...prev,
      [activeLocale]: value
    }));
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    setSuccess(null);

    try {
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/admin/privacy-policy`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ content })
      });

      if (!response.ok) {
        throw new Error('Erreur lors de la publication');
      }

      const data = await response.json();
      if (data?.success) {
        setUpdatedAt(data.data?.updated_at || null);
        setSuccess('Politique publiee avec succes');
      } else {
        throw new Error('Erreur lors de la publication');
      }
    } catch (err: any) {
      setError(err.message || 'Erreur lors de la publication');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <Loader message="Chargement de la politique..." />;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900 p-4 sm:p-6 lg:p-8">
      <div className="max-w-none mx-auto">
        <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-slate-100 flex items-center gap-3">
              <span className="grid h-12 w-12 place-items-center rounded-2xl bg-emerald-500 text-white">
                <FileText className="h-6 w-6" />
              </span>
              Politique de confidentialite
            </h1>
            <p className="text-gray-600 dark:text-slate-400">
              Editez le contenu HTML et publiez la page web de politique.
            </p>
            {updatedAt && (
              <p className="text-xs text-gray-500 dark:text-slate-500 mt-1">
                Derniere mise a jour: {new Date(updatedAt).toLocaleString()}
              </p>
            )}
          </div>
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={fetchPolicy}
              className="inline-flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 shadow-sm transition hover:bg-gray-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
            >
              <RefreshCw className="h-4 w-4" />
              Recharger
            </button>
            <button
              type="button"
              onClick={handleSave}
              disabled={saving}
              className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
            >
              <Save className="h-4 w-4" />
              {saving ? 'Publication...' : 'Publier'}
            </button>
          </div>
        </div>

        {error && (
          <div className="mb-6 bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-700 rounded-lg p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-red-800 dark:text-red-200">{error}</p>
          </div>
        )}

        {success && (
          <div className="mb-6 bg-emerald-50 dark:bg-emerald-900/30 border border-emerald-200 dark:border-emerald-700 rounded-lg p-4 flex items-start gap-3">
            <CheckCircle2 className="w-5 h-5 text-emerald-600 dark:text-emerald-400 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-emerald-800 dark:text-emerald-200">{success}</p>
          </div>
        )}

        <div className="flex flex-wrap gap-2 mb-5">
          {LOCALE_TABS.map((tab) => (
            <button
              key={tab.key}
              type="button"
              onClick={() => setActiveLocale(tab.key)}
              className={`px-4 py-2 text-sm font-semibold rounded-full border transition ${
                activeLocale === tab.key
                  ? 'bg-emerald-600 border-emerald-600 text-white'
                  : 'bg-white border-gray-200 text-gray-600 hover:border-emerald-300 dark:bg-slate-800 dark:border-slate-700 dark:text-slate-300'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <div className="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                Editeur HTML ({activeLabel})
              </h2>
            </div>
            <textarea
              value={activeHtml}
              onChange={(event) => handleChange(event.target.value)}
              className="h-[520px] w-full rounded-xl border border-gray-200 bg-gray-50 p-4 text-sm font-mono text-gray-800 outline-none transition focus:border-emerald-400 focus:ring-1 focus:ring-emerald-400 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"
              placeholder="<h1>Politique de confidentialite</h1>"
              dir={isRtl ? 'rtl' : 'ltr'}
            />
          </div>

          <div className="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                Apercu de la page ({activeLabel})
              </h2>
            </div>
            <div
              className="h-[520px] overflow-auto rounded-xl border border-gray-200 bg-gray-50 p-4 text-sm text-gray-800 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"
              dir={isRtl ? 'rtl' : 'ltr'}
              dangerouslySetInnerHTML={{ __html: activeHtml || '<p>Aucun contenu.</p>' }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}