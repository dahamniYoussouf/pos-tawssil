'use client';

import { useEffect, useMemo, useState } from 'react';
import { Search, Mail, RefreshCcw, ChevronLeft, ChevronRight, AlertCircle } from 'lucide-react';
import apiClient from '@/lib/api/auth';
import { getLocaleLabel } from '@/lib/locale';

type NewsletterStatus = 'subscribed' | 'unsubscribed';

interface NewsletterSubscriber {
  id: string;
  email: string;
  name?: string | null;
  locale?: string | null;
  source?: string | null;
  status: NewsletterStatus;
  created_at: string;
  updated_at?: string | null;
  unsubscribed_at?: string | null;
}

export default function NewsletterSubscribersPage() {
  const [subscribers, setSubscribers] = useState<NewsletterSubscriber[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | NewsletterStatus>('subscribed');
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);
  const [totalCount, setTotalCount] = useState(0);

  const totalPages = Math.max(1, Math.ceil(totalCount / limit));

  const fetchSubscribers = async () => {
    try {
      setLoading(true);
      setError('');

      const params: Record<string, string | number> = {
        page,
        limit
      };

      if (statusFilter !== 'all') {
        params.status = statusFilter;
      }

      if (searchTerm.trim()) {
        params.q = searchTerm.trim();
      }

      const response = await apiClient.get('/newsletter/subscribers', { params });
      const payload = response.data;

      if (payload?.success) {
        setSubscribers(payload.data || []);
        setTotalCount(payload.count || 0);
      } else {
        throw new Error(payload?.message || 'Impossible de charger les inscrits.');
      }
    } catch (err: any) {
      console.error('Newsletter fetch error:', err);
      setError(err?.message || 'Erreur lors du chargement des inscrits.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSubscribers();
  }, [page, limit, statusFilter, searchTerm]);

  useEffect(() => {
    setPage(1);
  }, [statusFilter, searchTerm]);

  const showingFrom = totalCount === 0 ? 0 : (page - 1) * limit + 1;
  const showingTo = Math.min(page * limit, totalCount);

  const emptyMessage = useMemo(() => {
    if (statusFilter === 'unsubscribed') {
      return "Aucun utilisateur désinscrit pour l’instant.";
    }
    if (statusFilter === 'subscribed') {
      return "Aucun inscrit trouvé. Lancez une campagne pour collecter des emails.";
    }
    return "Aucun inscrit trouvé.";
  }, [statusFilter]);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900 p-4 sm:p-6 lg:p-8">
      <div className="max-w-none mx-auto space-y-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-slate-100 mb-2">Newsletter</h1>
            <p className="text-gray-600 dark:text-slate-400">
              Gérez les clients inscrits à la newsletter.
            </p>
          </div>
          <button
            onClick={fetchSubscribers}
            disabled={loading}
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-gray-200 px-4 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-300 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-slate-700 dark:text-slate-200 dark:hover:bg-slate-600"
          >
            <RefreshCcw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            {loading ? 'Chargement...' : 'Actualiser'}
          </button>
        </div>

        {error && !loading && (
          <div className="bg-red-50 dark:bg-red-900/30 border-2 border-red-200 dark:border-red-700 rounded-lg p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-sm font-medium text-red-800 dark:text-red-200">{error}</p>
            </div>
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-3">
          <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 p-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/40 flex items-center justify-center">
                <Mail className="w-5 h-5 text-green-600 dark:text-green-300" />
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-slate-400">Total affiché</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-slate-100">{totalCount}</p>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 p-6">
            <p className="text-sm text-gray-500 dark:text-slate-400">Statut</p>
            <div className="mt-3 flex flex-wrap gap-2">
              {['subscribed', 'unsubscribed', 'all'].map((status) => (
                <button
                  key={status}
                  onClick={() => setStatusFilter(status as 'all' | NewsletterStatus)}
                  className={`rounded-full px-4 py-2 text-xs font-semibold transition ${
                    statusFilter === status
                      ? 'bg-green-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-slate-700 dark:text-slate-200 dark:hover:bg-slate-600'
                  }`}
                >
                  {status === 'subscribed' && 'Abonnés'}
                  {status === 'unsubscribed' && 'Désinscrits'}
                  {status === 'all' && 'Tous'}
                </button>
              ))}
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 p-6">
            <p className="text-sm text-gray-500 dark:text-slate-400">Recherche</p>
            <div className="mt-3 flex items-center gap-2 rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2">
              <Search className="h-4 w-4 text-gray-400" />
              <input
                value={searchTerm}
                onChange={(event) => setSearchTerm(event.target.value)}
                placeholder="Email ou nom"
                className="w-full bg-transparent text-sm text-gray-800 dark:text-slate-100 outline-none placeholder:text-gray-400"
              />
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700">
          <div className="flex flex-col gap-3 border-b border-gray-200 dark:border-slate-700 px-4 py-3 md:flex-row md:items-center md:justify-between">
            <p className="text-sm text-gray-500 dark:text-slate-400">
              Affichage {showingFrom}-{showingTo} sur {totalCount}
            </p>
            <select
              value={limit}
              onChange={(event) => setLimit(Number(event.target.value))}
              className="rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200"
            >
              {[20, 50, 100, 200].map((size) => (
                <option key={size} value={size}>
                  {size} / page
                </option>
              ))}
            </select>
          </div>

          {loading ? (
            <div className="p-6 text-center text-sm text-gray-500 dark:text-slate-400">Chargement...</div>
          ) : subscribers.length === 0 ? (
            <div className="p-6 text-center text-sm text-gray-500 dark:text-slate-400">{emptyMessage}</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full text-left text-sm">
                <thead className="bg-gray-50 text-xs uppercase text-gray-500 dark:bg-slate-900/40 dark:text-slate-400">
                  <tr>
                    <th className="px-4 py-3">Email</th>
                    <th className="px-4 py-3">Nom</th>
                    <th className="px-4 py-3">Locale</th>
                    <th className="px-4 py-3">Source</th>
                    <th className="px-4 py-3">Statut</th>
                    <th className="px-4 py-3">Inscription</th>
                    <th className="px-4 py-3">Désinscription</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-slate-700">
                  {subscribers.map((subscriber) => (
                    <tr key={subscriber.id} className="hover:bg-gray-50 dark:hover:bg-slate-700/40">
                      <td className="px-4 py-3 font-medium text-gray-800 dark:text-slate-100">
                        {subscriber.email}
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-slate-300">{subscriber.name || '—'}</td>
                      <td className="px-4 py-3 text-gray-600 dark:text-slate-300">
                        {getLocaleLabel(subscriber.locale)}
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-slate-300">
                        {subscriber.source || 'landing'}
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`rounded-full px-3 py-1 text-xs font-semibold ${
                            subscriber.status === 'subscribed'
                              ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-300'
                              : 'bg-gray-200 text-gray-600 dark:bg-slate-600/40 dark:text-slate-200'
                          }`}
                        >
                          {subscriber.status === 'subscribed' ? 'Abonné' : 'Désinscrit'}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-slate-300">
                        {subscriber.created_at ? new Date(subscriber.created_at).toLocaleDateString() : '—'}
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-slate-300">
                        {subscriber.unsubscribed_at ? new Date(subscriber.unsubscribed_at).toLocaleDateString() : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <div className="flex flex-col items-center justify-between gap-3 border-t border-gray-200 dark:border-slate-700 px-4 py-4 md:flex-row">
            <p className="text-sm text-gray-500 dark:text-slate-400">
              Page {page} sur {totalPages}
            </p>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage((prev) => Math.max(prev - 1, 1))}
                disabled={page <= 1}
                className="inline-flex items-center gap-2 rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200 disabled:cursor-not-allowed disabled:opacity-50"
              >
                <ChevronLeft className="h-4 w-4" />
                Précédent
              </button>
              <button
                onClick={() => setPage((prev) => Math.min(prev + 1, totalPages))}
                disabled={page >= totalPages}
                className="inline-flex items-center gap-2 rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Suivant
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
