'use client';

import { useMemo, useState } from 'react';
import { BellRing, Send, Users, Truck, UtensilsCrossed, AlertCircle, CheckCircle2, Shield } from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type Audience = 'client' | 'driver' | 'restaurant' | 'admin';

type NotificationType = 'info' | 'success' | 'warning' | 'urgent' | 'announcement' | 'error';

interface BroadcastResponse {
  recipients?: {
    clients?: number;
    drivers?: number;
    restaurants?: number;
    admins?: number;
  };
  recipients_count?: number;
  targets?: string[];
}

const AUDIENCES: Array<{
  key: Audience;
  label: string;
  description: string;
  icon: typeof Users;
}> = [
  {
    key: 'client',
    label: 'Clients',
    description: 'Utilisateurs qui passent des commandes',
    icon: Users
  },
  {
    key: 'driver',
    label: 'Livreurs',
    description: 'Livreurs actifs sur la plateforme',
    icon: Truck
  },
  {
    key: 'restaurant',
    label: 'Restaurants',
    description: 'Partenaires restaurants',
    icon: UtensilsCrossed
  },
  {
    key: 'admin',
    label: 'Admins',
    description: 'Tous les admins (y compris vous)',
    icon: Shield
  }
];

const TYPE_OPTIONS: Array<{ value: NotificationType; label: string }> = [
  { value: 'info', label: 'Info' },
  { value: 'success', label: 'Succes' },
  { value: 'warning', label: 'Avertissement' },
  { value: 'urgent', label: 'Urgent' },
  { value: 'announcement', label: 'Annonce' },
  { value: 'error', label: 'Erreur' }
];

const TYPE_STYLES: Record<NotificationType, string> = {
  info: 'border-blue-200 bg-blue-50 text-blue-700',
  success: 'border-emerald-200 bg-emerald-50 text-emerald-700',
  warning: 'border-amber-200 bg-amber-50 text-amber-700',
  urgent: 'border-red-200 bg-red-50 text-red-700',
  announcement: 'border-violet-200 bg-violet-50 text-violet-700',
  error: 'border-red-200 bg-red-50 text-red-700'
};

export default function BroadcastNotificationsPage() {
  const [selectedAudiences, setSelectedAudiences] = useState<Audience[]>(['client']);
  const [type, setType] = useState<NotificationType>('info');
  const [title, setTitle] = useState('Notification Tawsil');
  const [message, setMessage] = useState('');
  const [useI18n, setUseI18n] = useState(false);
  const [titleEn, setTitleEn] = useState('');
  const [messageEn, setMessageEn] = useState('');
  const [titleAr, setTitleAr] = useState('');
  const [messageAr, setMessageAr] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [lastResult, setLastResult] = useState<BroadcastResponse | null>(null);

  const totalRecipients = useMemo(() => {
    if (!lastResult?.recipients) return null;
    return (
      (lastResult.recipients.clients || 0) +
      (lastResult.recipients.drivers || 0) +
      (lastResult.recipients.restaurants || 0) +
      (lastResult.recipients.admins || 0)
    );
  }, [lastResult]);

  const toggleAudience = (audience: Audience) => {
    setSelectedAudiences((prev) => {
      if (prev.includes(audience)) {
        return prev.filter((item) => item !== audience);
      }
      return [...prev, audience];
    });
    setError('');
    setSuccess('');
  };

  const handleSend = async () => {
    setError('');
    setSuccess('');

    if (!message.trim()) {
      setError('Le message est obligatoire.');
      return;
    }
    if (selectedAudiences.length === 0) {
      setError('Choisissez au moins un public a notifier.');
      return;
    }

    const baseTitle = title.trim();
    const baseMessage = message.trim();
    const i18n = useI18n
      ? {
          fr: { title: baseTitle, message: baseMessage },
          en: {
            title: titleEn.trim() || baseTitle,
            message: messageEn.trim() || baseMessage
          },
          ar: {
            title: titleAr.trim() || baseTitle,
            message: messageAr.trim() || baseMessage
          }
        }
      : undefined;

    const confirmText = `Envoyer cette notification a : ${selectedAudiences.join(', ')} ?`;
    if (!window.confirm(confirmText)) {
      return;
    }

    setSending(true);

    try {
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie. Veuillez vous reconnecter.');
      }

      const response = await fetch(`${API_URL}/admin/notify/broadcast`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          targets: selectedAudiences,
          type,
          title: baseTitle,
          message: baseMessage,
          i18n
        })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data?.message || "Erreur lors de l'envoi de la notification");
      }

      setLastResult(data?.data || null);
      setSuccess('Notification envoyee avec succes.');
      setMessage('');
      setMessageEn('');
      setMessageAr('');
    } catch (err: any) {
      setError(err?.message || "Erreur lors de l'envoi");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-3">
            <BellRing className="w-6 h-6 text-green-600" />
            Notifications utilisateurs
          </h1>
          <p className="text-sm text-gray-600 dark:text-gray-300 mt-1">
            Diffusez une notification aux clients, livreurs, restaurants et admins en quelques secondes.
          </p>
        </div>
        <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
          <Send className="w-4 h-4" />
          Diffusion en temps reel via Firebase
        </div>
      </div>

      {error && (
        <div className="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          <AlertCircle className="w-5 h-5 mt-0.5" />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="flex items-start gap-3 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
          <CheckCircle2 className="w-5 h-5 mt-0.5" />
          <span>{success}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Choisir le public
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {AUDIENCES.map((audience) => {
                const Icon = audience.icon;
                const active = selectedAudiences.includes(audience.key);
                return (
                  <label
                    key={audience.key}
                    className={`cursor-pointer border rounded-lg p-4 transition-all flex flex-col gap-3 ${
                      active
                        ? 'border-green-500 bg-green-50 dark:bg-green-500/10'
                        : 'border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <input
                        type="checkbox"
                        className="h-4 w-4 rounded border-gray-300 text-green-600 focus:ring-green-500"
                        checked={active}
                        onChange={() => toggleAudience(audience.key)}
                      />
                      <Icon className="w-5 h-5 text-gray-600 dark:text-gray-300" />
                      <span className="font-medium text-gray-900 dark:text-white">{audience.label}</span>
                    </div>
                    <p className="text-xs text-gray-500 dark:text-gray-400">{audience.description}</p>
                  </label>
                );
              })}
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-6 shadow-sm space-y-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
              Contenu de la notification
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Type
                </label>
                <select
                  value={type}
                  onChange={(e) => setType(e.target.value as NotificationType)}
                  className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-green-500"
                >
                  {TYPE_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="md:col-span-2">
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  {useI18n ? 'Titre (FR)' : 'Titre'}
                </label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Ex: Mise a jour importante"
                  className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-green-500"
                />
              </div>
            </div>

            <div>
              <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                {useI18n ? 'Message (FR)' : 'Message'}
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Decrivez clairement la notification a envoyer..."
                rows={5}
                className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-green-500"
              />
              <div className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                {message.length} caracteres
              </div>
            </div>

            <div className="flex items-center justify-between rounded-lg border border-gray-200 dark:border-slate-700 bg-gray-50 dark:bg-slate-900 px-4 py-3">
              <div>
                <p className="text-sm font-medium text-gray-700 dark:text-gray-200">
                  Multi-langue (FR/EN/AR)
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  Activez pour envoyer un message adapte a chaque langue.
                </p>
              </div>
              <label className="inline-flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={useI18n}
                  onChange={(e) => setUseI18n(e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300 text-green-600 focus:ring-green-500"
                />
                <span className="text-xs text-gray-600 dark:text-gray-300">
                  Activer
                </span>
              </label>
            </div>

            {useI18n && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    Titre (EN)
                  </label>
                  <input
                    type="text"
                    value={titleEn}
                    onChange={(e) => setTitleEn(e.target.value)}
                    placeholder="Optional"
                    className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    Message (EN)
                  </label>
                  <textarea
                    value={messageEn}
                    onChange={(e) => setMessageEn(e.target.value)}
                    placeholder="Optional"
                    rows={3}
                    className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    Titre (AR)
                  </label>
                  <input
                    type="text"
                    value={titleAr}
                    onChange={(e) => setTitleAr(e.target.value)}
                    placeholder="Optional"
                    className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                    Message (AR)
                  </label>
                  <textarea
                    value={messageAr}
                    onChange={(e) => setMessageAr(e.target.value)}
                    placeholder="Optional"
                    rows={3}
                    className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
              </div>
            )}

            <div className="flex flex-wrap items-center gap-3">
              <button
                onClick={handleSend}
                disabled={sending || !message.trim() || selectedAudiences.length === 0}
                className={`inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold text-white transition ${
                  sending || !message.trim() || selectedAudiences.length === 0
                    ? 'bg-gray-300 dark:bg-slate-700 cursor-not-allowed'
                    : 'bg-green-600 hover:bg-green-700'
                }`}
              >
                <Send className="w-4 h-4" />
                {sending ? 'Envoi en cours...' : 'Envoyer la notification'}
              </button>
              <span className="text-xs text-gray-500 dark:text-gray-400">
                Les utilisateurs recoivent la notification en temps reel s'ils sont connectes.
              </span>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Apercu</h2>
            <div className={`border rounded-lg p-4 ${TYPE_STYLES[type]}`}>
              <div className="text-xs uppercase tracking-widest font-semibold mb-2">
                {TYPE_OPTIONS.find((option) => option.value === type)?.label}
              </div>
              <h3 className="text-base font-semibold mb-1">
                {title.trim() || 'Titre de la notification'}
              </h3>
              <p className="text-sm">
                {message.trim() || 'Le message apparaitra ici.'}
              </p>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Derniere diffusion
            </h2>
            {lastResult ? (
              <div className="space-y-3 text-sm text-gray-600 dark:text-gray-300">
                <div className="flex items-center justify-between">
                  <span>Destinataires</span>
                  <span className="font-semibold text-gray-900 dark:text-white">
                    {totalRecipients ?? lastResult.recipients_count ?? 0}
                  </span>
                </div>
                <div className="border-t border-gray-200 dark:border-slate-700 pt-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <span>Clients</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {lastResult.recipients?.clients ?? 0}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span>Livreurs</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {lastResult.recipients?.drivers ?? 0}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span>Restaurants</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {lastResult.recipients?.restaurants ?? 0}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span>Admins</span>
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {lastResult.recipients?.admins ?? 0}
                    </span>
                  </div>
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Aucune diffusion envoyee pour le moment.
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

