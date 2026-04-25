'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { AlertCircle, ArrowLeft, FileText, RefreshCw } from 'lucide-react';
import Loader from '@/components/Loader';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type LocaleKey = 'fr' | 'ar' | 'en';

const LOCALE_OPTIONS: Array<{ key: LocaleKey; label: string }> = [
  { key: 'fr', label: 'Francais' },
  { key: 'ar', label: 'Arabe' },
  { key: 'en', label: 'English' }
];

interface PolicyResponse {
  success?: boolean;
  data?: {
    locale?: LocaleKey;
    html?: string;
    updated_at?: string | null;
  };
}

export default function PrivacyPolicyPage() {
  const [locale, setLocale] = useState<LocaleKey>('fr');
  const [html, setHtml] = useState('');
  const [updatedAt, setUpdatedAt] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isRtl = locale === 'ar';

  const title = useMemo(() => {
    if (locale === 'ar') return 'سياسة الخصوصية';
    if (locale === 'en') return 'Privacy Policy';
    return 'Politique de confidentialite';
  }, [locale]);

  const fetchPolicy = async (nextLocale: LocaleKey, silent = false) => {
    if (silent) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }
    setError(null);

    try {
      const response = await fetch(
        `${API_URL}/privacy-policy?format=json&locale=${nextLocale}`,
        {
          headers: {
            Accept: 'application/json'
          },
          cache: 'no-store'
        }
      );

      if (!response.ok) {
        throw new Error('Erreur lors du chargement de la politique de confidentialite');
      }

      const data = (await response.json()) as PolicyResponse;
      if (!data?.success) {
        throw new Error('Contenu de politique indisponible');
      }

      setHtml(data.data?.html || '<p>Aucun contenu.</p>');
      setUpdatedAt(data.data?.updated_at || null);
    } catch (err: any) {
      setError(err?.message || 'Impossible de charger la politique de confidentialite');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchPolicy(locale);
  }, [locale]);

  if (loading) {
    return <Loader message="Chargement de la politique..." />;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      <div className="mx-auto max-w-5xl px-4 py-8 sm:px-6 lg:px-8">
        <div className="mb-6 flex flex-col gap-4 rounded-3xl border border-gray-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-800">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div className="flex items-start gap-4">
              <div className="grid h-14 w-14 place-items-center rounded-2xl bg-green-600 text-white shadow-sm">
                <FileText className="h-7 w-7" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-gray-900 dark:text-slate-100">
                  {title}
                </h1>
                <p className="mt-2 text-sm text-gray-600 dark:text-slate-400">
                  Consultez la politique de confidentialite publiee sur la plateforme.
                </p>
                {updatedAt && (
                  <p className="mt-2 text-xs text-gray-500 dark:text-slate-500">
                    Derniere mise a jour: {new Date(updatedAt).toLocaleString()}
                  </p>
                )}
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <Link
                href="/login"
                className="inline-flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 transition hover:bg-gray-50 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
              >
                <ArrowLeft className="h-4 w-4" />
                Retour
              </Link>
              <button
                type="button"
                onClick={() => fetchPolicy(locale, true)}
                className="inline-flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-green-700 disabled:opacity-60"
                disabled={refreshing}
              >
                <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
                {refreshing ? 'Actualisation...' : 'Actualiser'}
              </button>
            </div>
          </div>

          <div className="flex flex-wrap gap-2">
            {LOCALE_OPTIONS.map((option) => (
              <button
                key={option.key}
                type="button"
                onClick={() => setLocale(option.key)}
                className={`rounded-full border px-4 py-2 text-sm font-semibold transition ${
                  locale === option.key
                    ? 'border-green-600 bg-green-600 text-white'
                    : 'border-gray-200 bg-white text-gray-600 hover:border-green-300 hover:text-green-700 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300 dark:hover:border-green-500 dark:hover:text-green-300'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>

        {error && (
          <div className="mb-6 flex items-start gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 text-red-800 dark:border-red-700 dark:bg-red-900/30 dark:text-red-200">
            <AlertCircle className="mt-0.5 h-5 w-5 flex-shrink-0" />
            <p className="text-sm">{error}</p>
          </div>
        )}

        <div className="rounded-3xl border border-gray-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-800">
          <article
            className="prose prose-gray max-w-none prose-headings:text-gray-900 prose-a:text-green-700 dark:prose-invert dark:prose-headings:text-slate-100"
            dir={isRtl ? 'rtl' : 'ltr'}
            dangerouslySetInnerHTML={{ __html: html || '<p>Aucun contenu.</p>' }}
          />
        </div>
      </div>
    </div>
  );
}
