'use client';

import React, { useState, useCallback, useEffect } from 'react';
import { Printer, Plus, Edit, Trash2, Save, X, CheckCircle, AlertCircle } from 'lucide-react';
import apiClient from '@/lib/api/auth';
import { getApiErrorMessage } from '@/lib/api/error';

type RestaurantPrinter = {
  id: string;
  restaurant_id: string;
  name: string;
  type: 'general' | 'caisse' | 'cuisine' | 'bar';
  ip: string;
  port: number;
  is_enabled: boolean;
  paper_width_mm: 58 | 80;
  created_at?: string;
  updated_at?: string;
};

type PrinterForm = {
  name: string;
  type: 'general' | 'caisse' | 'cuisine' | 'bar';
  connectionType: 'network' | 'local' | 'windows';
  ip: string;
  port: string;
  localPort: string;
  windowsPrinterName: string;
  is_enabled: boolean;
  paper_width_mm: string;
};

interface TicketPrinterManagementProps {
  restaurantId: string;
  onUpdate?: () => void;
}

function isLocalPrinterIp(ip: string) {
  return /^LPT\d+$/i.test(ip || '') || /^COM\d+$/i.test(ip || '') || /^USB\d+$/i.test(ip || '');
}

function isWindowsPrinterIp(ip: string) {
  return /^WIN:/i.test(ip || '');
}

function getWindowsPrinterDisplayName(ip: string) {
  if (!/^WIN:/i.test(ip || '')) return ip || '';
  return (ip || '').replace(/^WIN:/i, '').trim() || ip || '';
}

export default function TicketPrinterManagement({ restaurantId, onUpdate }: TicketPrinterManagementProps) {
  const [printers, setPrinters] = useState<RestaurantPrinter[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [editingPrinter, setEditingPrinter] = useState<RestaurantPrinter | null>(null);
  const [testingId, setTestingId] = useState<string | null>(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [errorDetails, setErrorDetails] = useState<{
    title: string;
    message: string;
    solutions: string[];
  } | null>(null);

  const [form, setForm] = useState<PrinterForm>({
    name: '',
    type: 'general',
    connectionType: 'network',
    ip: '',
    port: '9100',
    localPort: 'LPT1',
    windowsPrinterName: '',
    is_enabled: true,
    paper_width_mm: '80',
  });

  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [isScanning, setIsScanning] = useState(false);
  const [detectedPrinters, setDetectedPrinters] = useState<any[]>([]);
  const [showDetectedPrinters, setShowDetectedPrinters] = useState(false);

  // Charger les imprimantes
  const loadPrinters = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await apiClient.get(`/restaurant/admin/printers/${restaurantId}`);
      setPrinters(Array.isArray(res.data?.data) ? res.data.data : []);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Erreur lors du chargement des imprimantes'));
    } finally {
      setLoading(false);
    }
  }, [restaurantId]);

  useEffect(() => {
    loadPrinters();
  }, [loadPrinters]);

  // Ouvrir le modal de creation
  const openCreateModal = useCallback(() => {
    setModalMode('create');
    setEditingPrinter(null);
    setForm({
      name: '',
      type: 'general',
      connectionType: 'network',
      ip: '',
      port: '9100',
      localPort: 'LPT1',
      windowsPrinterName: '',
      is_enabled: true,
      paper_width_mm: '80',
    });
    setFormErrors({});
    setError('');
    setSuccess('');
    setModalOpen(true);
  }, []);

  // Ouvrir le modal d'edition
  const openEditModal = useCallback((printer: RestaurantPrinter) => {
    setModalMode('edit');
    setEditingPrinter(printer);
    const isLocal = isLocalPrinterIp(printer.ip);
    const isWindows = isWindowsPrinterIp(printer.ip);
    setForm({
      name: printer.name,
      type: printer.type === 'bar' ? 'general' : printer.type,
      connectionType: isWindows ? 'windows' : isLocal ? 'local' : 'network',
      ip: isLocal || isWindows ? '' : printer.ip,
      port: printer.port.toString(),
      localPort: isLocal ? printer.ip : 'LPT1',
      windowsPrinterName: isWindows ? getWindowsPrinterDisplayName(printer.ip) : '',
      is_enabled: printer.is_enabled,
      paper_width_mm: printer.paper_width_mm.toString(),
    });
    setFormErrors({});
    setError('');
    setSuccess('');
    setModalOpen(true);
  }, []);

  // Fermer le modal
  const closeModal = useCallback(() => {
    setModalOpen(false);
    setEditingPrinter(null);
    setError('');
    setSuccess('');
    setErrorDetails(null);
  }, []);

  // Valider et soumettre le formulaire
  const handleSubmit = useCallback(async () => {
    const errors: Record<string, string> = {};
    
    if (!form.name.trim()) {
      errors.name = 'Le nom est requis';
    }

    const isLocal = form.connectionType === 'local';
    const isWindows = form.connectionType === 'windows';

    if (isLocal) {
      if (!form.localPort.trim()) {
        errors.localPort = 'Le port local est requis';
      }
    } else if (isWindows) {
      if (!form.windowsPrinterName.trim()) {
        errors.windowsPrinterName = 'Le nom de l\'imprimante Windows est requis';
      }
    } else {
      if (!form.ip.trim()) {
        errors.ip = 'L\'adresse IP est requise';
      }
      const port = parseInt(form.port, 10);
      if (isNaN(port) || port < 1 || port > 65535) {
        errors.port = 'Le port doit etre entre 1 et 65535';
      }
    }

    const paperWidth = parseInt(form.paper_width_mm, 10);
    if (paperWidth !== 58 && paperWidth !== 80) {
      errors.paper_width_mm = 'La largeur doit etre 58 ou 80 mm';
    }

    setFormErrors(errors);
    if (Object.keys(errors).length > 0) {
      return;
    }

    const ip = isWindows 
      ? `WIN:${form.windowsPrinterName.trim()}` 
      : isLocal 
      ? form.localPort.trim() 
      : form.ip.trim();
    
    const port = isLocal || isWindows ? 9100 : parseInt(form.port, 10);

    setLoading(true);
    setError('');
    setSuccess('');
    setErrorDetails(null);

    try {
      if (modalMode === 'create') {
        await apiClient.post('/restaurant/admin/printers', {
          restaurant_id: restaurantId,
          name: form.name.trim(),
          type: form.type,
          ip,
          port,
          is_enabled: form.is_enabled,
          paper_width_mm: paperWidth,
        });
        setSuccess('Imprimante creee avec succes');
      } else if (editingPrinter) {
        await apiClient.put(`/restaurant/admin/printers/${editingPrinter.id}`, {
          name: form.name.trim(),
          type: form.type,
          ip,
          port,
          is_enabled: form.is_enabled,
          paper_width_mm: paperWidth,
        });
        setSuccess('Imprimante mise a jour avec succes');
      }

      setTimeout(() => {
        closeModal();
        loadPrinters();
        onUpdate?.();
      }, 1000);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Erreur lors de l\'enregistrement'));
    } finally {
      setLoading(false);
    }
  }, [form, modalMode, editingPrinter, restaurantId, closeModal, loadPrinters, onUpdate]);

  // Supprimer une imprimante
  const handleDelete = useCallback(async (printer: RestaurantPrinter) => {
    if (!window.confirm(`Etes-vous sur de vouloir supprimer l'imprimante "${printer.name}" ?`)) {
      return;
    }

    setLoading(true);
    setError('');
    setErrorDetails(null);
    try {
      await apiClient.delete(`/restaurant/admin/printers/${printer.id}`);
      setSuccess('Imprimante supprimee avec succes');
      loadPrinters();
      onUpdate?.();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Erreur lors de la suppression'));
    } finally {
      setLoading(false);
    }
  }, [loadPrinters, onUpdate]);

  // Scanner le reseau pour detecter les imprimantes
  const handleScan = useCallback(async () => {
    setIsScanning(true);
    setError('');
    setSuccess('');
    setDetectedPrinters([]);
    setShowDetectedPrinters(false);
    
    try {
      const res = await apiClient.post('/restaurant/admin/printers/scan', {
        scanNetwork: true,
        scanWindows: true,
        scanLocal: true,
      });
      
      if (res.data?.success && res.data?.data?.printers) {
        setDetectedPrinters(res.data.data.printers);
        setShowDetectedPrinters(true);
        setSuccess(`${res.data.data.totalFound} imprimante(s) detectee(s)`);
        setTimeout(() => setSuccess(''), 5000);
      } else {
        setError('Aucune imprimante detectee');
      }
    } catch (err: any) {
      setError(getApiErrorMessage(err, 'Erreur lors du scan'));
    } finally {
      setIsScanning(false);
    }
  }, []);

  // Utiliser une imprimante detectee
  const useDetectedPrinter = useCallback((detectedPrinter: any) => {
    const suggestedConfig = detectedPrinter.suggestedConfig;
    if (!suggestedConfig) return;
    
    setModalMode('create');
    setEditingPrinter(null);
    
    const ip = suggestedConfig.ip || '';
    let connectionType = 'network';
    if (ip.startsWith('WIN:')) {
      connectionType = 'windows';
    } else if (isLocalPrinterIp(ip) || ip.startsWith('LPT') || ip.startsWith('COM')) {
      connectionType = 'local';
    }
    
    setForm({
      name: suggestedConfig.name || '',
      type: suggestedConfig.type || 'general',
      connectionType: connectionType as 'network' | 'local' | 'windows',
      ip: connectionType === 'network' ? ip : '',
      port: (suggestedConfig.port || 9100).toString(),
      localPort: connectionType === 'local' ? ip : 'LPT1',
      windowsPrinterName: connectionType === 'windows' ? ip.replace(/^WIN:/i, '') : '',
      is_enabled: suggestedConfig.is_enabled !== false,
      paper_width_mm: (suggestedConfig.paper_width_mm || 80).toString(),
    });
    setFormErrors({});
    setError('');
    setSuccess('');
    setShowDetectedPrinters(false);
    setModalOpen(true);
  }, []);

  // Tester une imprimante
  const handleTest = useCallback(async (printer: RestaurantPrinter) => {
    setTestingId(printer.id);
    setError('');
    setErrorDetails(null);
    try {
      await apiClient.post(`/restaurant/admin/printers/${printer.id}/test`);
      setSuccess(`Ticket de test envoye avec succes a ${printer.name}`);
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: any) {
      // Extraire les details d'erreur si disponibles
      const errorData = err?.response?.data?.error;
      if (errorData && errorData.solutions) {
        // Afficher un message detaille avec solutions
        const errorMessage = [
          errorData.detailedMessage || err?.response?.data?.message || 'Echec du test d\'impression',
          '',
          'Solutions:',
          ...errorData.solutions,
        ].join('\n');
        setError(errorMessage);
        setErrorDetails({
          title: errorData.detailedMessage || err?.response?.data?.message || 'Erreur d\'impression',
          message: errorData.detailedMessage || err?.response?.data?.message || 'Une erreur s\'est produite',
          solutions: errorData.solutions || [],
        });
      } else {
        const msg = getApiErrorMessage(err, 'Echec du test d\'impression');
        setError(msg);
      }
    } finally {
      setTestingId(null);
    }
  }, []);

  const getTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      general: 'General',
      caisse: 'Caisse',
      cuisine: 'Cuisine',
      bar: 'Bar',
    };
    return labels[type] || type;
  };

  const getTypeColor = (type: string) => {
    const colors: Record<string, string> = {
      general: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200',
      caisse: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-200',
      cuisine: 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-200',
      bar: 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-200',
    };
    return colors[type] || colors.general;
  };

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6 dark:bg-slate-900 dark:border-slate-700">
      {/* Header */}
      <div className="mb-4 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Printer className="h-5 w-5 text-slate-600 dark:text-slate-400" />
          <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
            Gestion des Tickets
          </h2>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleScan}
            disabled={isScanning}
            className="inline-flex items-center gap-2 rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-700 transition-colors hover:bg-indigo-100 disabled:opacity-50 dark:border-indigo-800 dark:bg-indigo-900/20 dark:text-indigo-200 dark:hover:bg-indigo-900/30"
          >
            {isScanning ? (
              <>
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-600 border-t-transparent"></div>
                Scan en cours...
              </>
            ) : (
              <>
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                Scanner
              </>
            )}
          </button>
          <button
            onClick={openCreateModal}
            className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 transition-colors"
          >
            <Plus className="h-4 w-4" />
            Nouvelle imprimante
          </button>
        </div>
      </div>

      {/* Description */}
      <div className="mb-4 space-y-2">
        <p className="text-sm text-gray-600 dark:text-slate-400">
          Configurez les imprimantes pour l'impression automatique des tickets de commande.
          Les tickets sont imprimes automatiquement a chaque nouvelle commande.
        </p>
        <div className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-800 dark:border-blue-800 dark:bg-blue-900/20 dark:text-blue-200">
          <div className="font-semibold mb-1"> Important - Types de connexion :</div>
          <ul className="list-disc list-inside space-y-1 ml-2">
            <li><strong>Reseau (IP)</strong> : Le backend et l'imprimante peuvent etre sur des machines differentes, mais doivent etre sur le meme reseau</li>
            <li><strong>Locale (LPT/COM)</strong> : Le backend DOIT etre sur le meme PC que l'imprimante</li>
            <li><strong>Windows</strong> : Le backend DOIT etre sur le meme PC que l'imprimante</li>
          </ul>
        </div>
      </div>

      {/* Messages */}
      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 dark:border-red-800 dark:bg-red-900/20">
          <div className="flex items-start gap-2">
            <AlertCircle className="h-4 w-4 mt-0.5 text-red-800 dark:text-red-200 flex-shrink-0" />
            <div className="flex-1 text-sm text-red-800 dark:text-red-200">
              <div className="font-semibold mb-2">{error.split('\n')[0]}</div>
              {error.includes('Solutions:') && (
                <div className="mt-2 space-y-1">
                  {error.split('\n').slice(error.split('\n').indexOf('Solutions:') + 1).map((line, idx) => (
                    line.trim() && (
                      <div key={idx} className="text-xs">
                        {line}
                      </div>
                    )
                  ))}
                </div>
              )}
            </div>
            <div className="flex gap-2">
              {errorDetails && (
                <button
                  onClick={() => {
                    const details = [
                      errorDetails.title,
                      '',
                      errorDetails.message,
                      '',
                      'Solutions:',
                      ...errorDetails.solutions,
                    ].join('\n');
                    alert(details);
                  }}
                  className="text-xs text-red-700 hover:text-red-900 dark:text-red-300 dark:hover:text-red-100 underline"
                >
                  Details
                </button>
              )}
              <button
                onClick={() => {
                  setError('');
                  setErrorDetails(null);
                }}
                className="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-200"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}
      {success && (
        <div className="mb-4 flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-800 dark:border-green-800 dark:bg-green-900/20 dark:text-green-200">
          <CheckCircle className="h-4 w-4" />
          {success}
        </div>
      )}

      {/* Imprimantes detectees */}
      {showDetectedPrinters && detectedPrinters.length > 0 && (
        <div className="mb-4 rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-800 dark:bg-green-900/20">
          <div className="mb-3 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-600 dark:text-green-400" />
              <h3 className="text-sm font-semibold text-green-900 dark:text-green-200">
                Imprimantes Detectees ({detectedPrinters.length})
              </h3>
            </div>
            <button
              onClick={() => setShowDetectedPrinters(false)}
              className="text-green-600 hover:text-green-800 dark:text-green-400 dark:hover:text-green-200"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="space-y-2">
            {detectedPrinters.map((printer: any, index: number) => {
              const confidence = printer.confidence || 'medium';
              const type = printer.type || 'unknown';
              const ip = printer.ip || '';
              const name = printer.name || ip;
              const responseTime = printer.responseTime;
              
              return (
                <div
                  key={index}
                  className="flex items-center justify-between rounded-lg border border-green-200 bg-white p-3 dark:border-green-800 dark:bg-slate-800"
                >
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-medium text-gray-900 dark:text-slate-100">
                        {name}
                      </span>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                        type === 'network' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200' :
                        type === 'windows' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-200' :
                        'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'
                      }`}>
                        {type}
                      </span>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                        confidence === 'high' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-200' :
                        confidence === 'medium' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-200' :
                        'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'
                      }`}>
                        {confidence === 'high' ? 'Haute' : confidence === 'medium' ? 'Moyenne' : 'Faible'}
                      </span>
                    </div>
                    <div className="mt-1 text-xs text-gray-600 dark:text-slate-300">
                      {ip}
                      {responseTime && ` * ${responseTime}ms`}
                    </div>
                  </div>
                  <button
                    onClick={() => useDetectedPrinter(printer)}
                    className="ml-3 inline-flex items-center gap-1.5 rounded-lg bg-green-600 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-green-700"
                  >
                    <Plus className="h-3 w-3" />
                    Utiliser
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Liste des imprimantes */}
      {loading && printers.length === 0 ? (
        <div className="py-8 text-center text-sm text-gray-500 dark:text-slate-400">
          Chargement...
        </div>
      ) : printers.length === 0 ? (
        <div className="rounded-lg border border-dashed border-gray-300 bg-gray-50/50 py-8 text-center dark:bg-slate-900/50 dark:border-slate-700">
          <Printer className="mx-auto h-12 w-12 text-gray-400 dark:text-slate-600" />
          <p className="mt-2 text-sm text-gray-500 dark:text-slate-400">
            Aucune imprimante configuree
          </p>
          <p className="mt-1 text-xs text-gray-400 dark:text-slate-500">
            Cliquez sur "Nouvelle imprimante" pour ajouter une imprimante
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {printers.map((printer) => (
            <div
              key={printer.id}
              className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-gray-200 bg-gray-50/50 p-4 dark:border-slate-700 dark:bg-slate-900/50"
            >
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-medium text-gray-900 dark:text-slate-100">
                    {printer.name}
                  </span>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${getTypeColor(printer.type)}`}>
                    {getTypeLabel(printer.type)}
                  </span>
                  {!printer.is_enabled && (
                    <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-900/30 dark:text-amber-200">
                      Desactivee
                    </span>
                  )}
                </div>
                <div className="mt-1 text-sm text-gray-600 dark:text-slate-300">
                  {isWindowsPrinterIp(printer.ip) ? (
                    <>
                      <span className="font-medium">Windows:</span> {getWindowsPrinterDisplayName(printer.ip)}
                      <span className="ml-2 text-xs text-amber-600 dark:text-amber-400">(Backend sur meme PC requis)</span>
                    </>
                  ) : isLocalPrinterIp(printer.ip) ? (
                    <>
                      <span className="font-medium">{printer.ip}</span> (locale)
                      <span className="ml-2 text-xs text-amber-600 dark:text-amber-400">(Backend sur meme PC requis)</span>
                    </>
                  ) : (
                    <>
                      <span className="font-medium">{printer.ip}:{printer.port}</span> (reseau)
                      <span className="ml-2 text-xs text-blue-600 dark:text-blue-400">(Meme reseau requis)</span>
                    </>
                  )}
                  {' * '}
                  {printer.paper_width_mm} mm
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleTest(printer)}
                  disabled={loading || testingId === printer.id}
                  className="inline-flex items-center gap-1.5 rounded-lg border border-indigo-200 px-3 py-1.5 text-sm font-medium text-indigo-700 transition-colors hover:bg-indigo-50 disabled:opacity-50 dark:border-indigo-800 dark:text-indigo-200 dark:hover:bg-indigo-900/20"
                  title="Envoyer un ticket de test et verifier la connexion"
                >
                  <Printer className="h-4 w-4" />
                  {testingId === printer.id ? 'Test en cours...' : 'Test'}
                </button>
                <button
                  onClick={() => openEditModal(printer)}
                  disabled={loading}
                  className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                  title="Modifier"
                >
                  <Edit className="h-4 w-4" />
                </button>
                <button
                  onClick={() => handleDelete(printer)}
                  disabled={loading}
                  className="rounded-lg border border-red-200 px-3 py-1.5 text-sm font-medium text-red-700 transition-colors hover:bg-red-50 disabled:opacity-50 dark:border-red-800 dark:text-red-200 dark:hover:bg-red-900/20"
                  title="Supprimer"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-xl bg-white shadow-xl dark:bg-slate-900">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4 dark:border-slate-800">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                {modalMode === 'create' ? 'Nouvelle imprimante' : 'Modifier l\'imprimante'}
              </h3>
              <button
                onClick={closeModal}
                className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-slate-800 dark:hover:text-slate-300"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Body */}
            <div className="max-h-[calc(100vh-200px)] overflow-y-auto p-6 space-y-4">
              {error && (
                <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 dark:border-red-800 dark:bg-red-900/20">
                  <div className="flex items-start gap-2">
                    <AlertCircle className="h-4 w-4 mt-0.5 text-red-800 dark:text-red-200 flex-shrink-0" />
                    <div className="flex-1 text-sm text-red-800 dark:text-red-200">
                      <div className="font-semibold mb-2">{error.split('\n')[0]}</div>
                      {error.includes('Solutions:') && (
                        <div className="mt-2 space-y-1 max-h-40 overflow-y-auto">
                          {error.split('\n').slice(error.split('\n').indexOf('Solutions:') + 1).map((line, idx) => (
                            line.trim() && (
                              <div key={idx} className="text-xs">
                                {line}
                              </div>
                            )
                          ))}
                        </div>
                      )}
                    </div>
                    {errorDetails && (
                      <button
                        onClick={() => {
                          const details = [
                            errorDetails.title,
                            '',
                            errorDetails.message,
                            '',
                            'Solutions:',
                            ...errorDetails.solutions,
                          ].join('\n');
                          alert(details);
                        }}
                        className="text-xs text-red-700 hover:text-red-900 dark:text-red-300 dark:hover:text-red-100 underline whitespace-nowrap"
                      >
                        Voir tout
                      </button>
                    )}
                  </div>
                </div>
              )}

              {/* Nom */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                  Nom de l'imprimante *
                </label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Ex: Caisse 1, Cuisine, Bar"
                />
                {formErrors.name && (
                  <p className="mt-1 text-xs text-red-500">{formErrors.name}</p>
                )}
              </div>

              {/* Type */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                  Type de ticket *
                </label>
                <select
                  value={form.type}
                  onChange={(e) => setForm((prev) => ({ ...prev, type: e.target.value as PrinterForm['type'] }))}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="general">General</option>
                  <option value="caisse">Caisse</option>
                  <option value="cuisine">Cuisine</option>
                  <option value="bar">Bar</option>
                </select>
              </div>

              {/* Type de connexion */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                  Type de connexion *
                </label>
                <select
                  value={form.connectionType}
                  onChange={(e) => setForm((prev) => ({ ...prev, connectionType: e.target.value as PrinterForm['connectionType'] }))}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="network">Reseau (IP + port 9100)</option>
                  <option value="local">Locale (LPT/COM)</option>
                  <option value="windows">Imprimante Windows</option>
                </select>
                <div className="mt-1 space-y-1">
                  <p className="text-xs text-gray-500 dark:text-slate-400">
                    {form.connectionType === 'local' 
                      ? 'Port LPT ou COM sur le PC du serveur (Windows uniquement). Le backend DOIT etre sur le meme PC que l\'imprimante.'
                      : form.connectionType === 'windows'
                      ? 'Nom exact de l\'imprimante comme dans Parametres > Imprimantes. Le backend DOIT etre sur le meme PC que l\'imprimante.'
                      : 'Imprimante reseau Ethernet/Wi-Fi avec une adresse IP. Le backend et l\'imprimante doivent etre sur le meme reseau.'}
                  </p>
                  {form.connectionType === 'network' && (
                    <p className="text-xs text-amber-600 dark:text-amber-400">
                       Si le backend est en cloud, il ne peut pas atteindre une IP locale (192.168.x.x). Utilisez une imprimante reseau accessible depuis Internet ou un tunnel VPN.
                    </p>
                  )}
                </div>
              </div>

              {/* Champs conditionnels selon le type de connexion */}
              {form.connectionType === 'local' ? (
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                    Port local *
                  </label>
                  <select
                    value={form.localPort}
                    onChange={(e) => setForm((prev) => ({ ...prev, localPort: e.target.value }))}
                    className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  >
                    <option value="LPT1">LPT1</option>
                    <option value="LPT2">LPT2</option>
                    <option value="LPT3">LPT3</option>
                    <option value="COM1">COM1</option>
                    <option value="COM2">COM2</option>
                    <option value="COM3">COM3</option>
                    <option value="COM4">COM4</option>
                    <option value="USB001">USB001</option>
                    <option value="USB002">USB002</option>
                  </select>
                  {formErrors.localPort && (
                    <p className="mt-1 text-xs text-red-500">{formErrors.localPort}</p>
                  )}
                </div>
              ) : form.connectionType === 'windows' ? (
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                    Nom de l'imprimante Windows *
                  </label>
                  <input
                    type="text"
                    value={form.windowsPrinterName}
                    onChange={(e) => setForm((prev) => ({ ...prev, windowsPrinterName: e.target.value }))}
                    className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    placeholder="Ex: xprinter 2, XP-80C"
                  />
                  {formErrors.windowsPrinterName && (
                    <p className="mt-1 text-xs text-red-500">{formErrors.windowsPrinterName}</p>
                  )}
                </div>
              ) : (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                      Adresse IP *
                    </label>
                    <input
                      type="text"
                      value={form.ip}
                      onChange={(e) => setForm((prev) => ({ ...prev, ip: e.target.value }))}
                      className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                      placeholder="192.168.1.100"
                    />
                    {formErrors.ip && (
                      <p className="mt-1 text-xs text-red-500">{formErrors.ip}</p>
                    )}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                      Port (RAW, souvent 9100) *
                    </label>
                    <input
                      type="number"
                      value={form.port}
                      onChange={(e) => setForm((prev) => ({ ...prev, port: e.target.value }))}
                      className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                      placeholder="9100"
                      min="1"
                      max="65535"
                    />
                    {formErrors.port && (
                      <p className="mt-1 text-xs text-red-500">{formErrors.port}</p>
                    )}
                  </div>
                </>
              )}

              {/* Largeur du papier */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-200 mb-1">
                  Largeur du papier *
                </label>
                <select
                  value={form.paper_width_mm}
                  onChange={(e) => setForm((prev) => ({ ...prev, paper_width_mm: e.target.value }))}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="58">58 mm</option>
                  <option value="80">80 mm</option>
                </select>
                {formErrors.paper_width_mm && (
                  <p className="mt-1 text-xs text-red-500">{formErrors.paper_width_mm}</p>
                )}
              </div>

              {/* Active */}
              <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-200">
                <input
                  type="checkbox"
                  checked={form.is_enabled}
                  onChange={(e) => setForm((prev) => ({ ...prev, is_enabled: e.target.checked }))}
                  className="h-4 w-4 rounded border-gray-300 text-emerald-600 focus:ring-2 focus:ring-emerald-500"
                />
                Imprimante activee (impression automatique a chaque commande)
              </label>
            </div>

            {/* Footer */}
            <div className="flex justify-end gap-3 border-t border-gray-100 px-6 py-4 dark:border-slate-800">
              <button
                onClick={closeModal}
                className="rounded-lg border border-gray-200 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                disabled={loading}
              >
                Annuler
              </button>
              <button
                onClick={handleSubmit}
                disabled={loading}
                className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-emerald-700 disabled:opacity-50"
              >
                <Save className="h-4 w-4" />
                {loading ? 'Enregistrement...' : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
