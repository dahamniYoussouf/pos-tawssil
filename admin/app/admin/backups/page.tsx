'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  Archive,
  AlertCircle,
  CheckCircle2,
  RefreshCw,
  Plus,
  RotateCcw,
  Trash2,
  ShieldAlert,
  X,
  Database,
  Clock,
  Power
} from 'lucide-react';
import Loader from '@/components/Loader';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type BackupStatus = 'pending' | 'completed' | 'failed' | 'restoring' | 'restored';

interface BackupAdminInfo {
  id: string;
  name: string;
  email?: string;
}

interface BackupStats {
  orders: number;
  restaurants: number;
  clients: number;
  admins: number;
  drivers: number;
}

interface Backup {
  id: string;
  filename: string;
  file_size: number | null;
  checksum: string | null;
  status: BackupStatus;
  source: string;
  label: string | null;
  database_name: string;
  stats?: BackupStats | null;
  created_at: string;
  updated_at: string;
  error_message?: string | null;
  restored_at?: string | null;
  created_by?: BackupAdminInfo | null;
  restored_by?: BackupAdminInfo | null;
}

const formatBytes = (bytes: number | null) => {
  if (!bytes && bytes !== 0) return 'N/A';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  let size = bytes;
  let unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex += 1;
  }
  return `${size.toFixed(size >= 10 || unitIndex === 0 ? 0 : 1)} ${units[unitIndex]}`;
};

const formatDate = (value?: string | null) => {
  if (!value) return 'N/A';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'N/A';
  return date.toLocaleString('fr-FR');
};

const formatCount = (value?: number | null) => {
  if (typeof value !== 'number') return 'N/A';
  return value.toLocaleString('fr-FR');
};

const statusClasses: Record<BackupStatus, string> = {
  completed: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300',
  pending: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-300',
  failed: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300',
  restoring: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
  restored: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300'
};

export default function DatabaseBackupsPage() {
  const [backups, setBackups] = useState<Backup[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [label, setLabel] = useState('');
  const [retention, setRetention] = useState<number>(5);
  const [scheduleEnabled, setScheduleEnabled] = useState(true);
  const [scheduleTime, setScheduleTime] = useState('02:00');
  const [scheduleSaving, setScheduleSaving] = useState(false);
  const [showRestoreModal, setShowRestoreModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedBackup, setSelectedBackup] = useState<Backup | null>(null);
  const [confirmText, setConfirmText] = useState('');

  useEffect(() => {
    fetchBackups();
    fetchScheduleConfig();
  }, []);

  const latestBackup = useMemo(() => backups[0], [backups]);

  const fetchBackups = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        setError('Non authentifie');
        return;
      }

      const response = await fetch(`${API_URL}/admin/backups`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement des sauvegardes');
      }

      const data = await response.json();
      if (data.success) {
        setBackups(Array.isArray(data.data) ? data.data : []);
        setRetention(data.retention || 5);
      }
    } catch (err: any) {
      setError(err?.message || 'Erreur lors du chargement des sauvegardes');
    } finally {
      setLoading(false);
    }
  };

  const normalizeBoolean = (value: any, fallback: boolean) => {
    if (value === undefined || value === null) return fallback;
    if (typeof value === 'boolean') return value;
    if (typeof value === 'number') return value !== 0;
    if (typeof value === 'string') {
      const normalized = value.trim().toLowerCase();
      if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
      if (['false', '0', 'no', 'off'].includes(normalized)) return false;
    }
    return fallback;
  };

  const normalizeNumber = (value: any, fallback: number, min: number, max: number) => {
    if (value === undefined || value === null) return fallback;
    const parsed = Number.parseInt(String(value), 10);
    if (!Number.isFinite(parsed)) return fallback;
    if (parsed < min || parsed > max) return fallback;
    return parsed;
  };

  const padTime = (value: number) => String(value).padStart(2, '0');

  const fetchScheduleConfig = async () => {
    try {
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        setError('Non authentifie');
        return;
      }

      const response = await fetch(`${API_URL}/admin/config/all`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement de la planification');
      }

      const data = await response.json();
      if (!data.success) return;

      const configs = Array.isArray(data.all) ? data.all : [];
      const map = new Map(configs.map((config: any) => [config.key, config.value]));

      const enabled = normalizeBoolean(map.get('BACKUP_SCHEDULE_ENABLED'), true);
      const hour = normalizeNumber(map.get('BACKUP_SCHEDULE_HOUR'), 2, 0, 23);
      const minute = normalizeNumber(map.get('BACKUP_SCHEDULE_MINUTE'), 0, 0, 59);

      setScheduleEnabled(enabled);
      setScheduleTime(`${padTime(hour)}:${padTime(minute)}`);
    } catch (err: any) {
      setError(err?.message || 'Erreur lors du chargement de la planification');
    }
  };

  const updateConfigValue = async (key: string, value: number) => {
    const token = localStorage.getItem('access_token') || localStorage.getItem('token');
    if (!token) {
      throw new Error('Non authentifie');
    }

    const response = await fetch(`${API_URL}/admin/config/${key}`, {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ value })
    });

    if (!response.ok) {
      const payload = await response.json().catch(() => ({}));
      throw new Error(payload?.message || 'Erreur lors de la mise a jour');
    }
  };

  const handleSaveSchedule = async () => {
    try {
      setScheduleSaving(true);
      setError(null);
      setSuccess(null);

      const [hourRaw, minuteRaw] = scheduleTime.split(':');
      const hour = normalizeNumber(hourRaw, 2, 0, 23);
      const minute = normalizeNumber(minuteRaw, 0, 0, 59);

      await updateConfigValue('BACKUP_SCHEDULE_ENABLED', scheduleEnabled ? 1 : 0);
      await updateConfigValue('BACKUP_SCHEDULE_HOUR', hour);
      await updateConfigValue('BACKUP_SCHEDULE_MINUTE', minute);

      setSuccess('Planification des sauvegardes mise a jour');
      await fetchScheduleConfig();
    } catch (err: any) {
      setError(err?.message || 'Erreur lors de la mise a jour de la planification');
    } finally {
      setScheduleSaving(false);
    }
  };

  const handleCreateBackup = async () => {
    try {
      setActionLoading(true);
      setError(null);
      setSuccess(null);
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/admin/backups`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ label: label.trim() || null })
      });

      if (!response.ok) {
        const payload = await response.json().catch(() => ({}));
        throw new Error(payload?.message || 'Erreur lors de la creation de la sauvegarde');
      }

      setLabel('');
      setSuccess('Sauvegarde creee avec succes');
      await fetchBackups();
    } catch (err: any) {
      setError(err?.message || 'Erreur lors de la creation de la sauvegarde');
    } finally {
      setActionLoading(false);
    }
  };

  const openRestoreModal = (backup: Backup) => {
    setSelectedBackup(backup);
    setConfirmText('');
    setShowRestoreModal(true);
  };

  const openDeleteModal = (backup: Backup) => {
    setSelectedBackup(backup);
    setShowDeleteModal(true);
  };

  const handleRestoreBackup = async () => {
    if (!selectedBackup) return;
    try {
      setActionLoading(true);
      setError(null);
      setSuccess(null);
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/admin/backups/${selectedBackup.id}/restore`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          confirm: true,
          confirm_text: confirmText.trim()
        })
      });

      if (!response.ok) {
        const payload = await response.json().catch(() => ({}));
        throw new Error(payload?.message || 'Erreur lors de la restauration');
      }

      setSuccess('Restauration terminee avec succes');
      setShowRestoreModal(false);
      setSelectedBackup(null);
      await fetchBackups();
    } catch (err: any) {
      setError(err?.message || 'Erreur lors de la restauration');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeleteBackup = async () => {
    if (!selectedBackup) return;
    try {
      setActionLoading(true);
      setError(null);
      setSuccess(null);
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/admin/backups/${selectedBackup.id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const payload = await response.json().catch(() => ({}));
        throw new Error(payload?.message || 'Erreur lors de la suppression');
      }

      setSuccess('Sauvegarde supprimee');
      setShowDeleteModal(false);
      setSelectedBackup(null);
      await fetchBackups();
    } catch (err: any) {
      setError(err?.message || 'Erreur lors de la suppression');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return <Loader message="Chargement des sauvegardes..." />;
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900 p-4 sm:p-6 lg:p-8">
      <div className="max-w-none mx-auto space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-slate-100 mb-2">
            Sauvegardes de la base de donnees
          </h1>
          <p className="text-gray-600 dark:text-slate-400">
            Gerez vos sauvegardes et restaurez la base en toute securite. Le systeme conserve automatiquement les {retention} dernieres sauvegardes.
          </p>
        </div>

        {error && (
          <div className="bg-red-50 dark:bg-red-900/30 border-2 border-red-200 dark:border-red-700 rounded-lg p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-sm font-medium text-red-800 dark:text-red-200">{error}</p>
            </div>
            <button onClick={() => setError(null)} className="text-red-400 hover:text-red-600 dark:hover:text-red-300">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {success && (
          <div className="bg-green-50 dark:bg-green-900/30 border-2 border-green-200 dark:border-green-700 rounded-lg p-4 flex items-start gap-3">
            <CheckCircle2 className="w-5 h-5 text-green-600 dark:text-green-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-sm font-medium text-green-800 dark:text-green-200">{success}</p>
            </div>
            <button onClick={() => setSuccess(null)} className="text-green-400 hover:text-green-600 dark:hover:text-green-300">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 p-6 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/40 flex items-center justify-center">
                <Database className="w-5 h-5 text-green-600 dark:text-green-300" />
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-slate-400">Derniere sauvegarde</p>
                <p className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                  {latestBackup ? formatDate(latestBackup.created_at) : 'Aucune'}
                </p>
              </div>
            </div>

            <div className="text-sm text-gray-600 dark:text-slate-400">
              <p>Base : <span className="font-semibold text-gray-900 dark:text-slate-100">{latestBackup?.database_name || 'N/A'}</span></p>
              <p>Taille : <span className="font-semibold text-gray-900 dark:text-slate-100">{latestBackup ? formatBytes(latestBackup.file_size) : 'N/A'}</span></p>
              <p>Statut : <span className="font-semibold text-gray-900 dark:text-slate-100">{latestBackup?.status || 'N/A'}</span></p>
              {latestBackup?.stats && (
                <p>
                  Stats :{' '}
                  <span className="font-semibold text-gray-900 dark:text-slate-100">
                    {formatCount(latestBackup.stats.orders)} commandes, {formatCount(latestBackup.stats.restaurants)} restaurants,{' '}
                    {formatCount(latestBackup.stats.clients)} clients, {formatCount(latestBackup.stats.admins)} admins,{' '}
                    {formatCount(latestBackup.stats.drivers)} livreurs
                  </span>
                </p>
              )}
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 p-6 space-y-4 lg:col-span-2">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100 flex items-center gap-2">
              <Archive className="w-5 h-5" />
              Creer une sauvegarde
            </h2>
            <p className="text-sm text-gray-600 dark:text-slate-400">
              Lancez une sauvegarde manuelle avant une mise a jour ou une operation critique.
            </p>
            <div className="flex flex-col md:flex-row gap-3">
              <input
                type="text"
                value={label}
                onChange={(event) => setLabel(event.target.value)}
                placeholder="Label optionnel (ex: Avant mise a jour)"
                className="flex-1 px-4 py-2 border-2 border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-700 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none text-gray-900 dark:text-slate-100"
              />
              <button
                onClick={handleCreateBackup}
                disabled={actionLoading}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {actionLoading ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Sauvegarde...
                  </>
                ) : (
                  <>
                    <Plus className="w-4 h-4" />
                    Creer
                  </>
                )}
              </button>
              <button
                onClick={fetchBackups}
                disabled={actionLoading}
                className="px-4 py-2 bg-gray-200 dark:bg-slate-700 hover:bg-gray-300 dark:hover:bg-slate-600 text-gray-700 dark:text-slate-200 font-medium rounded-lg transition-colors flex items-center justify-center gap-2"
              >
                <RefreshCw className="w-4 h-4" />
                Actualiser
              </button>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 p-6 space-y-4">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="space-y-1">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100 flex items-center gap-2">
                <Clock className="w-5 h-5" />
                Planification des sauvegardes
              </h2>
              <p className="text-sm text-gray-600 dark:text-slate-400">
                Choisissez l'heure quotidienne et activez/desactivez la sauvegarde automatique.
              </p>
            </div>
            <button
              onClick={handleSaveSchedule}
              disabled={scheduleSaving}
              className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {scheduleSaving ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  Enregistrement...
                </>
              ) : (
                <>
                  <RefreshCw className="w-4 h-4" />
                  Enregistrer
                </>
              )}
            </button>
          </div>

          <div className="flex flex-col lg:flex-row gap-6">
            <div className="flex items-center justify-between gap-4 bg-gray-50 dark:bg-slate-900/40 border border-gray-200 dark:border-slate-700 rounded-lg px-4 py-3 flex-1">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${scheduleEnabled ? 'bg-green-100 dark:bg-green-900/40' : 'bg-gray-200 dark:bg-slate-700'}`}>
                  <Power className={`w-5 h-5 ${scheduleEnabled ? 'text-green-600 dark:text-green-300' : 'text-gray-500 dark:text-slate-300'}`} />
                </div>
                <div>
                  <p className="text-sm font-semibold text-gray-900 dark:text-slate-100">Sauvegarde automatique</p>
                  <p className="text-xs text-gray-500 dark:text-slate-400">
                    {scheduleEnabled ? 'Activee' : 'Desactivee'}
                  </p>
                </div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  className="sr-only peer"
                  checked={scheduleEnabled}
                  onChange={(event) => setScheduleEnabled(event.target.checked)}
                />
                <div className="w-12 h-6 bg-gray-300 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-purple-500 dark:peer-focus:ring-purple-400 rounded-full peer dark:bg-slate-600 peer-checked:bg-purple-600 transition-colors"></div>
                <div className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></div>
              </label>
            </div>

            <div className="flex items-center justify-between gap-4 bg-gray-50 dark:bg-slate-900/40 border border-gray-200 dark:border-slate-700 rounded-lg px-4 py-3 flex-1">
              <div>
                <p className="text-sm font-semibold text-gray-900 dark:text-slate-100">Heure quotidienne</p>
                <p className="text-xs text-gray-500 dark:text-slate-400">Choisissez l'heure (HH:MM)</p>
              </div>
              <input
                type="time"
                value={scheduleTime}
                onChange={(event) => setScheduleTime(event.target.value)}
                className="px-3 py-2 border-2 border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-700 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none text-gray-900 dark:text-slate-100"
              />
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200 dark:border-slate-700 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
              Historique des sauvegardes
            </h2>
            <span className="text-sm text-gray-500 dark:text-slate-400">
              {backups.length} sauvegarde(s)
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full text-sm text-left">
              <thead className="bg-gray-50 dark:bg-slate-900/40 text-gray-600 dark:text-slate-300">
                <tr>
                  <th className="px-6 py-3 font-medium">Nom / Label</th>
                  <th className="px-6 py-3 font-medium">Creee le</th>
                  <th className="px-6 py-3 font-medium">Taille</th>
                  <th className="px-6 py-3 font-medium">Statut</th>
                  <th className="px-6 py-3 font-medium">Stats</th>
                  <th className="px-6 py-3 font-medium">Creee par</th>
                  <th className="px-6 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {backups.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-6 py-6 text-center text-gray-500 dark:text-slate-400">
                      Aucune sauvegarde disponible.
                    </td>
                  </tr>
                )}
                {backups.map((backup) => (
                  <tr key={backup.id} className="border-t border-gray-100 dark:border-slate-700">
                    <td className="px-6 py-4">
                      <div className="space-y-1">
                        <p className="font-semibold text-gray-900 dark:text-slate-100">
                          {backup.label || backup.filename}
                        </p>
                        <p className="text-xs text-gray-500 dark:text-slate-400">{backup.filename}</p>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-700 dark:text-slate-200">
                      {formatDate(backup.created_at)}
                    </td>
                    <td className="px-6 py-4 text-gray-700 dark:text-slate-200">
                      {formatBytes(backup.file_size)}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex px-3 py-1 rounded-full text-xs font-semibold ${statusClasses[backup.status]}`}>
                        {backup.status}
                      </span>
                      {backup.status === 'failed' && backup.error_message && (
                        <p className="text-xs text-red-500 mt-1">{backup.error_message}</p>
                      )}
                    </td>
                    <td className="px-6 py-4 text-xs text-gray-600 dark:text-slate-300">
                      {backup.stats ? (
                        <div className="space-y-1">
                          <p>Commandes: <span className="font-semibold text-gray-900 dark:text-slate-100">{formatCount(backup.stats.orders)}</span></p>
                          <p>Restaurants: <span className="font-semibold text-gray-900 dark:text-slate-100">{formatCount(backup.stats.restaurants)}</span></p>
                          <p>Clients: <span className="font-semibold text-gray-900 dark:text-slate-100">{formatCount(backup.stats.clients)}</span></p>
                          <p>Admins: <span className="font-semibold text-gray-900 dark:text-slate-100">{formatCount(backup.stats.admins)}</span></p>
                          <p>Livreurs: <span className="font-semibold text-gray-900 dark:text-slate-100">{formatCount(backup.stats.drivers)}</span></p>
                        </div>
                      ) : (
                        <span className="text-gray-500 dark:text-slate-400">N/A</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-gray-700 dark:text-slate-200">
                      {backup.created_by?.name || 'Systeme'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-wrap gap-2">
                        <button
                          onClick={() => openRestoreModal(backup)}
                          disabled={actionLoading || backup.status === 'pending' || backup.status === 'restoring'}
                          className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-medium flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          <RotateCcw className="w-3 h-3" />
                          Restaurer
                        </button>
                        <button
                          onClick={() => openDeleteModal(backup)}
                          disabled={actionLoading}
                          className="px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg text-xs font-medium flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          <Trash2 className="w-3 h-3" />
                          Supprimer
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {showRestoreModal && selectedBackup && (
        <div className="fixed inset-0 bg-black/60 z-[3000] flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg max-w-lg w-full p-6 space-y-4">
            <div className="flex items-center gap-3">
              <ShieldAlert className="w-6 h-6 text-red-500" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                Confirmer la restauration
              </h3>
            </div>
            <p className="text-sm text-gray-600 dark:text-slate-300">
              Cette action va remplacer la base actuelle par la sauvegarde selectionnee. Le service peut etre indisponible pendant l'operation.
            </p>
            <div className="bg-gray-50 dark:bg-slate-700/40 rounded-lg p-3 text-sm text-gray-700 dark:text-slate-200 space-y-1">
              <p><span className="font-semibold">Sauvegarde :</span> {selectedBackup.label || selectedBackup.filename}</p>
              <p><span className="font-semibold">Creee le :</span> {formatDate(selectedBackup.created_at)}</p>
              <p><span className="font-semibold">Taille :</span> {formatBytes(selectedBackup.file_size)}</p>
              {selectedBackup.stats && (
                <p>
                  <span className="font-semibold">Stats :</span>{' '}
                  {formatCount(selectedBackup.stats.orders)} commandes, {formatCount(selectedBackup.stats.restaurants)} restaurants,{' '}
                  {formatCount(selectedBackup.stats.clients)} clients, {formatCount(selectedBackup.stats.admins)} admins,{' '}
                  {formatCount(selectedBackup.stats.drivers)} livreurs
                </p>
              )}
            </div>
            <div className="space-y-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-slate-300">
                Tapez <span className="font-semibold">RESTORE</span> pour confirmer
              </label>
              <input
                value={confirmText}
                onChange={(event) => setConfirmText(event.target.value)}
                className="w-full px-4 py-2 border-2 border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-700 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none text-gray-900 dark:text-slate-100"
              />
            </div>
            <div className="flex justify-end gap-3 pt-2">
              <button
                onClick={() => setShowRestoreModal(false)}
                className="px-4 py-2 bg-gray-200 dark:bg-slate-700 hover:bg-gray-300 dark:hover:bg-slate-600 text-gray-700 dark:text-slate-200 font-medium rounded-lg"
              >
                Annuler
              </button>
              <button
                onClick={handleRestoreBackup}
                disabled={actionLoading || confirmText.trim() !== 'RESTORE'}
                className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {actionLoading ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Restauration...
                  </>
                ) : (
                  <>
                    <RotateCcw className="w-4 h-4" />
                    Restaurer
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {showDeleteModal && selectedBackup && (
        <div className="fixed inset-0 bg-black/60 z-[3000] flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg max-w-lg w-full p-6 space-y-4">
            <div className="flex items-center gap-3">
              <AlertCircle className="w-6 h-6 text-red-500" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                Supprimer la sauvegarde
              </h3>
            </div>
            <p className="text-sm text-gray-600 dark:text-slate-300">
              Cette action supprimera definitivement le fichier de sauvegarde.
            </p>
            <div className="bg-gray-50 dark:bg-slate-700/40 rounded-lg p-3 text-sm text-gray-700 dark:text-slate-200 space-y-1">
              <p><span className="font-semibold">Sauvegarde :</span> {selectedBackup.label || selectedBackup.filename}</p>
              <p><span className="font-semibold">Creee le :</span> {formatDate(selectedBackup.created_at)}</p>
            </div>
            <div className="flex justify-end gap-3 pt-2">
              <button
                onClick={() => setShowDeleteModal(false)}
                className="px-4 py-2 bg-gray-200 dark:bg-slate-700 hover:bg-gray-300 dark:hover:bg-slate-600 text-gray-700 dark:text-slate-200 font-medium rounded-lg"
              >
                Annuler
              </button>
              <button
                onClick={handleDeleteBackup}
                disabled={actionLoading}
                className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {actionLoading ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Suppression...
                  </>
                ) : (
                  <>
                    <Trash2 className="w-4 h-4" />
                    Supprimer
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
