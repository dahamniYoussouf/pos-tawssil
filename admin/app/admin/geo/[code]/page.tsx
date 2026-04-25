'use client';

import { useEffect, useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  Plus,
  RefreshCw,
  AlertCircle,
  Eye,
  Edit,
  Trash2,
  ArrowLeft,
  Search,
  X
} from 'lucide-react';
import ModalErrorNotice from '@/components/admin/ModalErrorNotice';
import { getApiErrorMessage } from '@/lib/api/error';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

interface Wilaya {
  code: string;
  name: string;
  name_ar?: string | null;
}

interface Commune {
  id: string;
  name: string;
  name_ar?: string | null;
  wilaya_code: string;
  wilaya_name?: string | null;
  code?: string | null;
  lat?: number | null;
  lng?: number | null;
}

type ModalType = '' | 'view' | 'edit' | 'delete' | 'create';

const emptyCommuneForm = {
  name: '',
  name_ar: '',
  code: '',
  lat: '',
  lng: ''
};

export default function WilayaCommunesPage() {
  const router = useRouter();
  const params = useParams();
  const wilayaCodeParam = params?.code;
  const wilayaCode = Array.isArray(wilayaCodeParam) ? wilayaCodeParam[0] : wilayaCodeParam;

  const [wilaya, setWilaya] = useState<Wilaya | null>(null);
  const [communes, setCommunes] = useState<Commune[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState<ModalType>('');
  const [selectedCommune, setSelectedCommune] = useState<Commune | null>(null);
  const [saving, setSaving] = useState(false);
  const [modalError, setModalError] = useState('');
  const [form, setForm] = useState(emptyCommuneForm);

  const fetchWilayaInfo = async (token: string) => {
    const response = await fetch(`${API_URL}/admin/geo/wilayas`, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error('Erreur lors du chargement des wilayas');
    }

    const payload = await response.json();
    const list = Array.isArray(payload?.data) ? payload.data : [];
    const found = list.find((item: Wilaya) => item.code === wilayaCode);
    setWilaya(found || null);
  };

  const fetchCommunes = async (token: string) => {
    if (!wilayaCode) return;
    const response = await fetch(
      `${API_URL}/admin/geo/communes?wilaya_code=${encodeURIComponent(String(wilayaCode))}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (!response.ok) {
      throw new Error('Erreur lors du chargement des communes');
    }

    const payload = await response.json();
    const list = Array.isArray(payload?.data) ? payload.data : [];
    setCommunes(list);
  };

  const loadPageData = async () => {
    if (!wilayaCode) {
      setError('Code wilaya invalide');
      return;
    }

    try {
      setLoading(true);
      setError('');
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        setError('Non authentifie');
        setLoading(false);
        return;
      }

      await Promise.all([fetchWilayaInfo(token), fetchCommunes(token)]);
    } catch (err: any) {
      setError(err?.message || 'Erreur lors du chargement');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPageData();
  }, [wilayaCode]);

  const filteredCommunes = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    if (!term) return communes;
    return communes.filter((commune) => {
      const nameAr = commune.name_ar || '';
      const code = commune.code || '';
      return (
        commune.name.toLowerCase().includes(term) ||
        nameAr.toLowerCase().includes(term) ||
        code.toLowerCase().includes(term)
      );
    });
  }, [communes, searchTerm]);

  const openModal = (type: ModalType, commune?: Commune) => {
    setModalError('');
    setModalType(type);
    setShowModal(true);
    if (type === 'create') {
      setForm(emptyCommuneForm);
      setSelectedCommune(null);
    } else if (commune) {
      setSelectedCommune(commune);
      setForm({
        name: commune.name || '',
        name_ar: commune.name_ar || '',
        code: commune.code || '',
        lat: commune.lat !== null && commune.lat !== undefined ? String(commune.lat) : '',
        lng: commune.lng !== null && commune.lng !== undefined ? String(commune.lng) : ''
      });
    }
  };

  const closeModal = () => {
    setShowModal(false);
    setModalType('');
    setSelectedCommune(null);
    setModalError('');
  };

  const parseCoordinates = () => {
    const latValue = Number.parseFloat(form.lat);
    const lngValue = Number.parseFloat(form.lng);
    if (!Number.isFinite(latValue) || !Number.isFinite(lngValue)) {
      throw new Error('Latitude et longitude sont obligatoires');
    }
    return { lat: latValue, lng: lngValue };
  };

  const handleCreate = async () => {
    try {
      setSaving(true);
      setModalError('');
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const coords = parseCoordinates();
      const payload = {
        name: form.name.trim(),
        name_ar: form.name_ar.trim() || null,
        code: form.code.trim() || null,
        wilaya_code: String(wilayaCode),
        lat: coords.lat,
        lng: coords.lng
      };

      if (!payload.name) {
        throw new Error('Le nom est obligatoire');
      }

      const response = await fetch(`${API_URL}/admin/geo/communes`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(getApiErrorMessage(data, 'Erreur lors de la creation'));
      }

      await fetchCommunes(token);
      closeModal();
    } catch (err: any) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la creation'));
    } finally {
      setSaving(false);
    }
  };

  const handleUpdate = async () => {
    if (!selectedCommune) return;
    try {
      setSaving(true);
      setModalError('');
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const coords = parseCoordinates();
      const payload = {
        name: form.name.trim(),
        name_ar: form.name_ar.trim() || null,
        code: form.code.trim() || null,
        lat: coords.lat,
        lng: coords.lng
      };

      if (!payload.name) {
        throw new Error('Le nom est obligatoire');
      }

      const response = await fetch(`${API_URL}/admin/geo/communes/${selectedCommune.id}`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(getApiErrorMessage(data, 'Erreur lors de la mise a jour'));
      }

      await fetchCommunes(token);
      closeModal();
    } catch (err: any) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la mise a jour'));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedCommune) return;
    try {
      setSaving(true);
      setModalError('');
      const token = localStorage.getItem('access_token') || localStorage.getItem('token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/admin/geo/communes/${selectedCommune.id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data?.message || 'Erreur lors de la suppression');
      }

      await fetchCommunes(token);
      closeModal();
    } catch (err: any) {
      setModalError(err?.message || 'Erreur lors de la suppression');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900 p-4 sm:p-6 lg:p-8">
      <div className="max-w-none mx-auto space-y-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <div className="flex items-center gap-3 text-sm text-gray-500 dark:text-slate-400">
              <button
                onClick={() => router.push('/admin/geo')}
                className="inline-flex items-center gap-2 text-gray-600 dark:text-slate-300 hover:text-gray-900 dark:hover:text-white"
              >
                <ArrowLeft className="w-4 h-4" />
                Retour aux wilayas
              </button>
            </div>
            <h1 className="mt-2 text-3xl font-bold text-gray-900 dark:text-slate-100">
              Communes {wilaya ? `- ${wilaya.name}` : ''}
            </h1>
            <p className="text-sm text-gray-600 dark:text-slate-400">
              Wilaya {wilayaCode} {wilaya?.name_ar ? `• ${wilaya.name_ar}` : ''}
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => openModal('create')}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-green-600 hover:bg-green-700 text-white text-sm font-medium"
            >
              <Plus className="w-4 h-4" />
              Ajouter une commune
            </button>
            <button
              onClick={loadPageData}
              disabled={loading}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 text-gray-700 dark:text-slate-200 text-sm font-medium hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-60"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              Actualiser
            </button>
          </div>
        </div>

        {error && (
          <div className="flex items-start gap-3 rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/30 px-4 py-3 text-sm text-red-700 dark:text-red-200">
            <AlertCircle className="w-5 h-5 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        <div className="flex flex-col md:flex-row md:items-center gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Rechercher par nom ou code..."
              className="w-full pl-9 pr-4 py-2 rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-sm text-gray-700 dark:text-slate-200 focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none"
            />
          </div>
          <div className="text-sm text-gray-500 dark:text-slate-400">
            {filteredCommunes.length} resultat{filteredCommunes.length !== 1 ? 's' : ''}
          </div>
        </div>

        <div className="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-gray-200 dark:border-slate-700 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm text-left">
              <thead className="bg-gray-50 dark:bg-slate-900/40 text-gray-600 dark:text-slate-300">
                <tr>
                  <th className="px-6 py-3 font-medium">Nom (FR)</th>
                  <th className="px-6 py-3 font-medium">Nom (AR)</th>
                  <th className="px-6 py-3 font-medium">Code</th>
                  <th className="px-6 py-3 font-medium">Latitude</th>
                  <th className="px-6 py-3 font-medium">Longitude</th>
                  <th className="px-6 py-3 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr>
                    <td colSpan={6} className="px-6 py-6 text-center text-gray-500 dark:text-slate-400">
                      Chargement...
                    </td>
                  </tr>
                )}
                {!loading && filteredCommunes.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-6 py-6 text-center text-gray-500 dark:text-slate-400">
                      Aucune commune trouvee.
                    </td>
                  </tr>
                )}
                {!loading &&
                  filteredCommunes.map((commune) => (
                    <tr
                      key={commune.id}
                      className="border-t border-gray-100 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700/40 transition-colors"
                    >
                      <td className="px-6 py-4 font-semibold text-gray-900 dark:text-slate-100">
                        {commune.name}
                      </td>
                      <td className="px-6 py-4 text-gray-600 dark:text-slate-300">
                        {commune.name_ar || '-'}
                      </td>
                      <td className="px-6 py-4 text-gray-700 dark:text-slate-200">
                        {commune.code || '-'}
                      </td>
                      <td className="px-6 py-4 text-gray-700 dark:text-slate-200">
                        {commune.lat ?? '-'}
                      </td>
                      <td className="px-6 py-4 text-gray-700 dark:text-slate-200">
                        {commune.lng ?? '-'}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => openModal('view', commune)}
                            className="text-gray-600 hover:text-gray-900 p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
                            title="Voir les details"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => openModal('edit', commune)}
                            className="text-blue-600 hover:text-blue-900 p-1.5 rounded-lg hover:bg-blue-50 transition-colors"
                            title="Modifier"
                          >
                            <Edit className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => openModal('delete', commune)}
                            className="text-red-600 hover:text-red-900 p-1.5 rounded-lg hover:bg-red-50 transition-colors"
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4" />
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

      {showModal && (
        <div className="fixed inset-0 bg-black/60 z-[3000] flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl shadow-lg max-w-lg w-full p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                {modalType === 'create' && 'Ajouter une commune'}
                {modalType === 'view' && 'Details de la commune'}
                {modalType === 'edit' && 'Modifier la commune'}
                {modalType === 'delete' && 'Supprimer la commune'}
              </h3>
              <button onClick={closeModal} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <ModalErrorNotice message={modalError} onClose={() => setModalError('')} />

            {modalType === 'view' && selectedCommune && (
              <div className="space-y-3 text-sm text-gray-700 dark:text-slate-200">
                <div>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Nom (FR)</p>
                  <p className="font-semibold">{selectedCommune.name}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Nom (AR)</p>
                  <p className="font-semibold">{selectedCommune.name_ar || '-'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Code</p>
                  <p className="font-semibold">{selectedCommune.code || '-'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Latitude</p>
                  <p className="font-semibold">{selectedCommune.lat ?? '-'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Longitude</p>
                  <p className="font-semibold">{selectedCommune.lng ?? '-'}</p>
                </div>
              </div>
            )}

            {(modalType === 'create' || modalType === 'edit') && (
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-slate-200">
                    Nom (FR)
                  </label>
                  <input
                    value={form.name}
                    onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
                    className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200 focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none"
                    placeholder="Nom de la commune"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-slate-200">
                    Nom (AR)
                  </label>
                  <input
                    value={form.name_ar}
                    onChange={(event) => setForm((prev) => ({ ...prev, name_ar: event.target.value }))}
                    className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200 focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none"
                    placeholder="Nom en arabe (optionnel)"
                  />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-200">
                      Code
                    </label>
                    <input
                      value={form.code}
                      onChange={(event) => setForm((prev) => ({ ...prev, code: event.target.value }))}
                      className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200 focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none"
                      placeholder="Code officiel"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-200">
                      Latitude
                    </label>
                    <input
                      value={form.lat}
                      onChange={(event) => setForm((prev) => ({ ...prev, lat: event.target.value }))}
                      className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200 focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none"
                      placeholder="Ex: 36.7525"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-200">
                      Longitude
                    </label>
                    <input
                      value={form.lng}
                      onChange={(event) => setForm((prev) => ({ ...prev, lng: event.target.value }))}
                      className="mt-2 w-full rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-gray-700 dark:text-slate-200 focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none"
                      placeholder="Ex: 3.04197"
                    />
                  </div>
                </div>
              </div>
            )}

            {modalType === 'delete' && selectedCommune && (
              <div className="space-y-2 text-sm text-gray-700 dark:text-slate-200">
                <p>
                  Supprimer la commune <span className="font-semibold">{selectedCommune.name}</span> ?
                </p>
                <p className="text-xs text-gray-500 dark:text-slate-400">
                  Les restaurants associes seront detaches de cette commune.
                </p>
              </div>
            )}

            <div className="flex justify-end gap-3 pt-2">
              <button
                onClick={closeModal}
                disabled={saving}
                className="px-4 py-2 rounded-lg bg-gray-200 dark:bg-slate-700 text-gray-700 dark:text-slate-200 text-sm font-medium hover:bg-gray-300 dark:hover:bg-slate-600 disabled:opacity-60"
              >
                {modalType === 'view' ? 'Fermer' : 'Annuler'}
              </button>
              {modalType === 'create' && (
                <button
                  onClick={handleCreate}
                  disabled={saving}
                  className="px-4 py-2 rounded-lg bg-green-600 hover:bg-green-700 text-white text-sm font-medium disabled:opacity-60"
                >
                  {saving ? 'Creation...' : 'Creer'}
                </button>
              )}
              {modalType === 'edit' && (
                <button
                  onClick={handleUpdate}
                  disabled={saving}
                  className="px-4 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-white text-sm font-medium disabled:opacity-60"
                >
                  {saving ? 'Enregistrement...' : 'Enregistrer'}
                </button>
              )}
              {modalType === 'delete' && (
                <button
                  onClick={handleDelete}
                  disabled={saving}
                  className="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-sm font-medium disabled:opacity-60"
                >
                  {saving ? 'Suppression...' : 'Supprimer'}
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
