'use client';

import React, { useState, useCallback, useEffect } from 'react';
import { FileText, Plus, Edit, Trash2, Save, X, Eye, CheckCircle, AlertCircle, Copy } from 'lucide-react';
import apiClient from '@/lib/api/auth';
import { getApiErrorMessage } from '@/lib/api/error';

type PrinterTemplate = {
  id: string;
  restaurant_id: string;
  printer_id?: string;
  name: string;
  type: 'general' | 'caisse' | 'cuisine' | 'bar';
  template_content: string;
  is_default: boolean;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
};

type TemplateForm = {
  name: string;
  type: 'general' | 'caisse' | 'cuisine' | 'bar';
  template_content: string;
  printer_id: string;
  is_default: boolean;
  is_active: boolean;
};

interface PrinterTemplateManagementProps {
  restaurantId: string;
  printers: Array<{ id: string; name: string; type: string }>;
  onUpdate?: () => void;
}

export default function PrinterTemplateManagement({ restaurantId, printers, onUpdate }: PrinterTemplateManagementProps) {
  const [templates, setTemplates] = useState<PrinterTemplate[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [editingTemplate, setEditingTemplate] = useState<PrinterTemplate | null>(null);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [previewContent, setPreviewContent] = useState('');
  const [previewPaperWidth, setPreviewPaperWidth] = useState<58 | 80>(80);
  const [previewData, setPreviewData] = useState<any>(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [variables, setVariables] = useState<Array<{ variable: string; description: string }>>([]);
  const [commands, setCommands] = useState<Array<{ command: string; description: string }>>([]);

  const [form, setForm] = useState<TemplateForm>({
    name: '',
    type: 'general',
    template_content: getDefaultTemplate(),
    printer_id: '',
    is_default: false,
    is_active: true,
  });

  const [showTemplatesModal, setShowTemplatesModal] = useState(false);

  const [formErrors, setFormErrors] = useState<Record<string, string>>({});

  // Charger les templates
  const loadTemplates = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await apiClient.get(`/restaurant/admin/printer-templates/${restaurantId}`);
      setTemplates(Array.isArray(res.data?.data) ? res.data.data : []);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Erreur lors du chargement des templates'));
    } finally {
      setLoading(false);
    }
  }, [restaurantId]);

  // Charger les variables disponibles
  const loadVariables = useCallback(async () => {
    try {
      const res = await apiClient.get('/restaurant/admin/printer-templates/variables');
      if (res.data?.success && res.data?.data) {
        setVariables(res.data.data.variables || []);
        setCommands(res.data.data.commands || []);
      }
    } catch (err) {
      console.error('Error loading variables:', err);
    }
  }, []);

  useEffect(() => {
    loadTemplates();
    loadVariables();
  }, [loadTemplates, loadVariables]);

  // Ouvrir le modal de creation
  const openCreateModal = useCallback(() => {
    setModalMode('create');
    setEditingTemplate(null);
    setForm({
      name: '',
      type: 'general',
      template_content: getDefaultTemplate(),
      printer_id: '',
      is_default: false,
      is_active: true,
    });
    setFormErrors({});
    setError('');
    setSuccess('');
    setModalOpen(true);
  }, []);

  // Ouvrir le modal d'edition
  const openEditModal = useCallback((template: PrinterTemplate) => {
    setModalMode('edit');
    setEditingTemplate(template);
    setForm({
      name: template.name,
      type: template.type,
      template_content: template.template_content,
      printer_id: template.printer_id || '',
      is_default: template.is_default,
      is_active: template.is_active,
    });
    setFormErrors({});
    setError('');
    setSuccess('');
    setModalOpen(true);
  }, []);

  // Fermer le modal
  const closeModal = useCallback(() => {
    setModalOpen(false);
    setEditingTemplate(null);
    setFormErrors({});
  }, []);

  // Sauvegarder le template
  const handleSave = useCallback(async () => {
    // Validation
    const errors: Record<string, string> = {};
    if (!form.name.trim()) errors.name = 'Le nom est requis';
    if (!form.template_content.trim()) errors.template_content = 'Le contenu du template est requis';
    
    if (Object.keys(errors).length > 0) {
      setFormErrors(errors);
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');
    
    try {
      if (modalMode === 'create') {
        await apiClient.post('/restaurant/admin/printer-templates', {
          restaurant_id: restaurantId,
          name: form.name.trim(),
          type: form.type,
          template_content: form.template_content.trim(),
          printer_id: form.printer_id || null,
          is_default: form.is_default,
          is_active: form.is_active,
        });
        setSuccess('Template cree avec succes');
      } else {
        await apiClient.put(`/restaurant/admin/printer-templates/${editingTemplate!.id}`, {
          name: form.name.trim(),
          type: form.type,
          template_content: form.template_content.trim(),
          printer_id: form.printer_id || null,
          is_default: form.is_default,
          is_active: form.is_active,
        });
        setSuccess('Template modifie avec succes');
      }
      
      loadTemplates();
      onUpdate?.();
      setTimeout(() => {
        setSuccess('');
        closeModal();
      }, 2000);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Erreur lors de la sauvegarde'));
    } finally {
      setLoading(false);
    }
  }, [form, modalMode, editingTemplate, restaurantId, loadTemplates, onUpdate, closeModal]);

  // Supprimer un template
  const handleDelete = useCallback(async (template: PrinterTemplate) => {
    if (!confirm(`Etes-vous sur de vouloir supprimer le template "${template.name}" ?`)) {
      return;
    }

    setLoading(true);
    setError('');
    try {
      await apiClient.delete(`/restaurant/admin/printer-templates/${template.id}`);
      setSuccess('Template supprime avec succes');
      loadTemplates();
      onUpdate?.();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Erreur lors de la suppression'));
    } finally {
      setLoading(false);
    }
  }, [loadTemplates, onUpdate]);

  // Previsualiser un template
  const handlePreview = useCallback(async (template: PrinterTemplate) => {
    setLoading(true);
    setError('');
    try {
      const res = await apiClient.post(`/restaurant/admin/printer-templates/${template.id}/preview`);
      if (res.data?.success && res.data?.data?.rendered) {
        setPreviewContent(res.data.data.rendered);
        setPreviewData(res.data.data);
        setPreviewPaperWidth(80); // Par defaut 80mm
        setPreviewOpen(true);
      }
    } catch (err) {
      setError(getApiErrorMessage(err, 'Erreur lors de la previsualisation'));
    } finally {
      setLoading(false);
    }
  }, []);

  // Inserer une variable dans le template
  const insertVariable = useCallback((variable: string) => {
    const textarea = document.getElementById('template_content') as HTMLTextAreaElement;
    if (textarea) {
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;
      const text = form.template_content;
      const newText = text.substring(0, start) + variable + text.substring(end);
      setForm({ ...form, template_content: newText });
      
      // Remettre le focus et la position du curseur
      setTimeout(() => {
        textarea.focus();
        textarea.setSelectionRange(start + variable.length, start + variable.length);
      }, 0);
    }
  }, [form]);

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
          <FileText className="h-5 w-5 text-slate-600 dark:text-slate-400" />
          <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
            Templates de Tickets
          </h2>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowTemplatesModal(true)}
            className="inline-flex items-center gap-2 rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100 transition-colors dark:border-indigo-800 dark:bg-indigo-900/20 dark:text-indigo-200 dark:hover:bg-indigo-900/30"
          >
            <FileText className="h-4 w-4" />
            Modeles prets a l'emploi
          </button>
          <button
            onClick={openCreateModal}
            className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 transition-colors"
          >
            <Plus className="h-4 w-4" />
            Nouveau Template
          </button>
        </div>
      </div>

      {/* Messages */}
      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
          <div className="flex items-center gap-2">
            <AlertCircle className="h-4 w-4" />
            {error}
          </div>
        </div>
      )}
      {success && (
        <div className="mb-4 flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-800 dark:border-green-800 dark:bg-green-900/20 dark:text-green-200">
          <CheckCircle className="h-4 w-4" />
          {success}
        </div>
      )}

      {/* Liste des templates */}
      {loading && templates.length === 0 ? (
        <div className="py-8 text-center text-sm text-gray-500 dark:text-slate-400">
          Chargement...
        </div>
      ) : templates.length === 0 ? (
        <div className="rounded-lg border border-dashed border-gray-300 bg-gray-50/50 py-8 text-center dark:bg-slate-900/50 dark:border-slate-700">
          <FileText className="mx-auto h-12 w-12 text-gray-400 dark:text-slate-600" />
          <p className="mt-2 text-sm text-gray-500 dark:text-slate-400">
            Aucun template configure
          </p>
          <p className="mt-1 text-xs text-gray-400 dark:text-slate-500">
            Creez un template pour personnaliser l'apparence des tickets
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {templates.map((template) => (
            <div
              key={template.id}
              className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-gray-200 bg-gray-50/50 p-4 dark:border-slate-700 dark:bg-slate-900/50"
            >
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-medium text-gray-900 dark:text-slate-100">
                    {template.name}
                  </span>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${getTypeColor(template.type)}`}>
                    {getTypeLabel(template.type)}
                  </span>
                  {template.is_default && (
                    <span className="rounded-full bg-yellow-100 px-2.5 py-0.5 text-xs font-medium text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-200">
                      Par defaut
                    </span>
                  )}
                  {!template.is_active && (
                    <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-900/30 dark:text-amber-200">
                      Inactif
                    </span>
                  )}
                </div>
                <div className="mt-1 text-sm text-gray-600 dark:text-slate-300">
                  {template.printer_id 
                    ? `Imprimante: ${printers.find(p => p.id === template.printer_id)?.name || template.printer_id}`
                    : 'Toutes les imprimantes de ce type'}
                </div>
                <div className="mt-1 text-xs text-gray-500 dark:text-slate-400 line-clamp-2">
                  {template.template_content.substring(0, 100)}...
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handlePreview(template)}
                  disabled={loading}
                  className="inline-flex items-center gap-1.5 rounded-lg border border-indigo-200 px-3 py-1.5 text-sm font-medium text-indigo-700 transition-colors hover:bg-indigo-50 disabled:opacity-50 dark:border-indigo-800 dark:text-indigo-200 dark:hover:bg-indigo-900/20"
                  title="Previsualiser"
                >
                  <Eye className="h-4 w-4" />
                  Apercu
                </button>
                <button
                  onClick={() => openEditModal(template)}
                  disabled={loading}
                  className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                  title="Modifier"
                >
                  <Edit className="h-4 w-4" />
                </button>
                <button
                  onClick={() => handleDelete(template)}
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

      {/* Modal de creation/edition */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-xl border border-gray-200 bg-white dark:bg-slate-900 dark:border-slate-700">
            <div className="sticky top-0 z-10 flex items-center justify-between border-b border-gray-200 bg-white px-6 py-4 dark:border-slate-700 dark:bg-slate-900">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                {modalMode === 'create' ? 'Nouveau Template' : 'Modifier le Template'}
              </h3>
              <button
                onClick={closeModal}
                className="text-gray-400 hover:text-gray-600 dark:text-slate-400 dark:hover:text-slate-200"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              {/* Nom */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                  Nom du template *
                </label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"
                  placeholder="Ex: Ticket Caisse Standard"
                />
                {formErrors.name && (
                  <p className="mt-1 text-xs text-red-600 dark:text-red-400">{formErrors.name}</p>
                )}
              </div>

              {/* Type et Imprimante */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Type de ticket *
                  </label>
                  <select
                    value={form.type}
                    onChange={(e) => setForm({ ...form, type: e.target.value as any })}
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"
                  >
                    <option value="general">General</option>
                    <option value="caisse">Caisse</option>
                    <option value="cuisine">Cuisine</option>
                    <option value="bar">Bar</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                    Imprimante specifique (optionnel)
                  </label>
                  <select
                    value={form.printer_id}
                    onChange={(e) => setForm({ ...form, printer_id: e.target.value })}
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"
                  >
                    <option value="">Toutes les imprimantes de ce type</option>
                    {printers
                      .filter(p => !form.type || p.type === form.type || form.type === 'general')
                      .map(printer => (
                        <option key={printer.id} value={printer.id}>
                          {printer.name}
                        </option>
                      ))}
                  </select>
                </div>
              </div>

              {/* Variables disponibles */}
              {variables.length > 0 && (
                <div className="rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-slate-700 dark:bg-slate-800">
                  <h4 className="text-sm font-semibold text-gray-900 dark:text-slate-100 mb-2">
                    Variables disponibles
                  </h4>
                  <div className="flex flex-wrap gap-2">
                    {variables.map((v) => (
                      <button
                        key={v.variable}
                        type="button"
                        onClick={() => insertVariable(v.variable)}
                        className="inline-flex items-center gap-1 rounded-md bg-white border border-gray-300 px-2 py-1 text-xs font-mono text-gray-700 hover:bg-gray-50 dark:bg-slate-700 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-600"
                        title={v.description}
                      >
                        <Copy className="h-3 w-3" />
                        {v.variable}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Commandes speciales */}
              {commands.length > 0 && (
                <div className="rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-slate-700 dark:bg-slate-800">
                  <h4 className="text-sm font-semibold text-gray-900 dark:text-slate-100 mb-2">
                    Commandes speciales
                  </h4>
                  <div className="flex flex-wrap gap-2">
                    {commands.map((c) => (
                      <button
                        key={c.command}
                        type="button"
                        onClick={() => insertVariable(c.command)}
                        className="inline-flex items-center gap-1 rounded-md bg-white border border-gray-300 px-2 py-1 text-xs font-mono text-gray-700 hover:bg-gray-50 dark:bg-slate-700 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-600"
                        title={c.description}
                      >
                        <Copy className="h-3 w-3" />
                        {c.command}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Contenu du template */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-slate-300 mb-1">
                  Contenu du template *
                </label>
                <textarea
                  id="template_content"
                  value={form.template_content}
                  onChange={(e) => setForm({ ...form, template_content: e.target.value })}
                  rows={15}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"
                  placeholder="Entrez le contenu du template avec les variables..."
                />
                {formErrors.template_content && (
                  <p className="mt-1 text-xs text-red-600 dark:text-red-400">{formErrors.template_content}</p>
                )}
                <p className="mt-1 text-xs text-gray-500 dark:text-slate-400">
                  Utilisez les variables ci-dessus pour personnaliser le contenu. Cliquez sur une variable pour l'inserer.
                </p>
              </div>

              {/* Options */}
              <div className="flex items-center gap-6">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={form.is_default}
                    onChange={(e) => setForm({ ...form, is_default: e.target.checked })}
                    className="rounded border-gray-300 text-emerald-600 focus:ring-emerald-500 dark:border-slate-600"
                  />
                  <span className="text-sm text-gray-700 dark:text-slate-300">
                    Template par defaut pour ce type
                  </span>
                </label>

                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={form.is_active}
                    onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
                    className="rounded border-gray-300 text-emerald-600 focus:ring-emerald-500 dark:border-slate-600"
                  />
                  <span className="text-sm text-gray-700 dark:text-slate-300">Actif</span>
                </label>
              </div>
            </div>

            {/* Footer */}
            <div className="sticky bottom-0 flex items-center justify-end gap-3 border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-slate-700 dark:bg-slate-800">
              <button
                onClick={closeModal}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
              >
                Annuler
              </button>
              <button
                onClick={handleSave}
                disabled={loading}
                className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-emerald-700 disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                    Enregistrement...
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4" />
                    Enregistrer
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de previsualisation amelioree */}
      {previewOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-xl border border-gray-200 bg-white dark:bg-slate-900 dark:border-slate-700">
            <div className="sticky top-0 z-10 flex items-center justify-between border-b border-gray-200 bg-white px-6 py-4 dark:border-slate-700 dark:bg-slate-900">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                Apercu du Template
              </h3>
              <div className="flex items-center gap-3">
                {/* Selecteur de largeur de papier */}
                <div className="flex items-center gap-2">
                  <label className="text-sm text-gray-700 dark:text-slate-300">Largeur:</label>
                  <select
                    value={previewPaperWidth}
                    onChange={(e) => setPreviewPaperWidth(Number(e.target.value) as 58 | 80)}
                    className="rounded-lg border border-gray-300 px-2 py-1 text-sm dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"
                  >
                    <option value={58}>58mm</option>
                    <option value={80}>80mm</option>
                  </select>
                </div>
                {/* Bouton d'export */}
                <button
                  onClick={() => {
                    const blob = new Blob([previewContent], { type: 'text/plain' });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = `template-preview-${Date.now()}.txt`;
                    a.click();
                    URL.revokeObjectURL(url);
                  }}
                  className="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800"
                >
                  <Copy className="h-4 w-4" />
                  Exporter
                </button>
                <button
                  onClick={() => setPreviewOpen(false)}
                  className="text-gray-400 hover:text-gray-600 dark:text-slate-400 dark:hover:text-slate-200"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
            </div>
            <div className="p-6">
              {/* Vue texte brute */}
              <div className="mb-4">
                <div className="mb-2 flex items-center justify-between">
                  <label className="text-sm font-medium text-gray-700 dark:text-slate-300">
                    Vue texte
                  </label>
                  <button
                    onClick={() => {
                      const textarea = document.getElementById('preview-text-view') as HTMLTextAreaElement;
                      if (textarea) {
                        textarea.select();
                        document.execCommand('copy');
                        alert('Contenu copie dans le presse-papiers');
                      }
                    }}
                    className="text-xs text-indigo-600 hover:text-indigo-700 dark:text-indigo-400"
                  >
                    Copier
                  </button>
                </div>
                <textarea
                  id="preview-text-view"
                  readOnly
                  value={previewContent || 'Aucun apercu disponible'}
                  className="w-full rounded-lg border border-gray-300 bg-gray-50 p-3 font-mono text-xs whitespace-pre-wrap dark:border-slate-600 dark:bg-slate-800 dark:text-slate-100"
                  rows={10}
                />
              </div>

              {/* Simulation visuelle du ticket */}
              <div className="rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-6 dark:border-slate-600 dark:bg-slate-800">
                <div className="mb-4 text-center text-sm font-medium text-gray-600 dark:text-slate-400">
                  Simulation d'impression ({previewPaperWidth}mm)
                </div>
                <div
                  className={`mx-auto bg-white shadow-lg ${
                    previewPaperWidth === 58 ? 'w-[58mm] max-w-[58mm]' : 'w-[80mm] max-w-[80mm]'
                  }`}
                  style={{
                    minHeight: '200px',
                    padding: '16px',
                    fontFamily: 'monospace',
                    fontSize: previewPaperWidth === 58 ? '10px' : '11px',
                    lineHeight: '1.4',
                    color: '#000',
                    boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
                  }}
                >
                  <TicketPreviewRenderer content={previewContent} paperWidth={previewPaperWidth} />
                </div>
                <div className="mt-4 text-center text-xs text-gray-500 dark:text-slate-400">
                  Cette simulation montre approximativement l'apparence du ticket imprime
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal des modeles prets a l'emploi */}
      {showTemplatesModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-xl border border-gray-200 bg-white dark:bg-slate-900 dark:border-slate-700">
            <div className="sticky top-0 z-10 flex items-center justify-between border-b border-gray-200 bg-white px-6 py-4 dark:border-slate-700 dark:bg-slate-900">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
                Modeles de Templates Prets a l'Emploi
              </h3>
              <button
                onClick={() => setShowTemplatesModal(false)}
                className="text-gray-400 hover:text-gray-600 dark:text-slate-400 dark:hover:text-slate-200"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-6">
              <p className="mb-4 text-sm text-gray-600 dark:text-slate-300">
                Selectionnez un modele pour creer rapidement un nouveau template. Vous pourrez ensuite le personnaliser selon vos besoins.
              </p>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                {getTemplateModels().map((model) => (
                  <div
                    key={model.id}
                    className="rounded-lg border border-gray-200 bg-gray-50 p-4 transition-shadow hover:shadow-md dark:border-slate-700 dark:bg-slate-800"
                  >
                    <div className="mb-2 flex items-center justify-between">
                      <div>
                        <h4 className="font-semibold text-gray-900 dark:text-slate-100">{model.name}</h4>
                        <span className={`mt-1 inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${getTypeColor(model.type)}`}>
                          {getTypeLabel(model.type)}
                        </span>
                      </div>
                    </div>
                    <p className="mb-3 text-sm text-gray-600 dark:text-slate-300">{model.description}</p>
                    <div className="mb-3 rounded bg-white p-2 font-mono text-xs text-gray-700 dark:bg-slate-900 dark:text-slate-200">
                      <div className="line-clamp-3">{model.template_content.substring(0, 150)}...</div>
                    </div>
                    <button
                      onClick={() => {
                        setForm({
                          name: model.name,
                          type: model.type,
                          template_content: model.template_content,
                          printer_id: '',
                          is_default: false,
                          is_active: true,
                        });
                        setModalMode('create');
                        setEditingTemplate(null);
                        setFormErrors({});
                        setError('');
                        setSuccess('');
                        setShowTemplatesModal(false);
                        setModalOpen(true);
                      }}
                      className="w-full rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-emerald-700"
                    >
                      Utiliser ce modele
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function getTemplateModels(): Array<{
  id: string;
  name: string;
  type: 'general' | 'caisse' | 'cuisine' | 'bar';
  description: string;
  template_content: string;
}> {
  return [
    {
      id: 'caisse-standard',
      name: 'Ticket Caisse Standard',
      type: 'caisse',
      description: 'Template classique pour les tickets de caisse avec tous les details de la commande',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[FEED]

[LEFT]
Commande #{{orderNumber}}
Date: {{date}} {{time}}
Type: {{orderType}}
Caissier: {{cashierName}} ({{cashierCode}})
[HR]

{{items}}

[HR]
Sous-total: {{subtotal}} DA
{{#if deliveryFee}}
Livraison: {{deliveryFee}} DA
{{/if}}
[BOLD_ON]
TOTAL: {{total}} DA
[BOLD_OFF]
Paiement: {{paymentMethod}}
[FEED]

[CENTER]
{{footer}}
[FEED]
[FEED]
[CUT]`,
    },
    {
      id: 'caisse-minimal',
      name: 'Ticket Caisse Minimal',
      type: 'caisse',
      description: 'Template minimaliste pour les tickets de caisse, ideal pour les petits etablissements',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[FEED]

Commande #{{orderNumber}}
{{date}} {{time}}
[HR]

{{items}}

[HR]
[BOLD_ON]
TOTAL: {{total}} DA
[BOLD_OFF]
[FEED]
[CUT]`,
    },
    {
      id: 'cuisine-standard',
      name: 'Bon de Cuisine Standard',
      type: 'cuisine',
      description: 'Template pour les bons de cuisine avec instructions speciales et additions',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[BOLD_ON]
BON DE CUISINE
[BOLD_OFF]
[FEED]

[LEFT]
Commande #{{orderNumber}}
Date: {{date}} {{time}}
[HR]

{{items}}

[HR]
[CENTER]
Merci !
[FEED]
[FEED]
[CUT]`,
    },
    {
      id: 'cuisine-detaille',
      name: 'Bon de Cuisine Detaille',
      type: 'cuisine',
      description: 'Template detaille pour la cuisine avec toutes les informations necessaires',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[BOLD_ON]
BON DE CUISINE
[BOLD_OFF]
[FEED]

[LEFT]
Commande #{{orderNumber}}
Date: {{date}} {{time}}
Type: {{orderType}}
[HR]

{{items}}

[HR]
[CENTER]
[BOLD_ON]
Bon appetit !
[BOLD_OFF]
[FEED]
[FEED]
[CUT]`,
    },
    {
      id: 'bar-standard',
      name: 'Bon de Bar Standard',
      type: 'bar',
      description: 'Template pour les bons de bar avec les boissons et leurs quantites',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[BOLD_ON]
BON DE BAR
[BOLD_OFF]
[FEED]

[LEFT]
Commande #{{orderNumber}}
Date: {{date}} {{time}}
[HR]

{{items}}

[HR]
[CENTER]
Sante !
[FEED]
[FEED]
[CUT]`,
    },
    {
      id: 'general-complet',
      name: 'Template General Complet',
      type: 'general',
      description: 'Template complet pour tous types d\'imprimantes avec toutes les informations',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[FEED]

[LEFT]
Commande #{{orderNumber}}
Date: {{date}} {{time}}
Type: {{orderType}}
{{#if deliveryAddress}}
Adresse: {{deliveryAddress}}
{{/if}}
Caissier: {{cashierName}} ({{cashierCode}})
[HR]

{{items}}

[HR]
Sous-total: {{subtotal}} DA
{{#if deliveryFee}}
Livraison: {{deliveryFee}} DA
{{/if}}
[BOLD_ON]
TOTAL: {{total}} DA
[BOLD_OFF]
Paiement: {{paymentMethod}}
[FEED]

[CENTER]
{{footer}}
[FEED]
[FEED]
[CUT]`,
    },
    {
      id: 'caisse-professionnel',
      name: 'Ticket Caisse Professionnel',
      type: 'caisse',
      description: 'Template professionnel avec toutes les informations legales et commerciales',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[FEED]

[LEFT]
TICKET DE CAISSE
[HR]
Commande #{{orderNumber}}
Date: {{date}} {{time}}
Type: {{orderType}}
Caissier: {{cashierName}} ({{cashierCode}})
[HR]

{{items}}

[HR]
Sous-total: {{subtotal}} DA
{{#if deliveryFee}}
Frais de livraison: {{deliveryFee}} DA
{{/if}}
[HR]
[BOLD_ON]
TOTAL TTC: {{total}} DA
[BOLD_OFF]
Mode de paiement: {{paymentMethod}}
[HR]

[CENTER]
{{footer}}
[FEED]
Merci de votre visite !
[FEED]
[FEED]
[CUT]`,
    },
    {
      id: 'cuisine-rapide',
      name: 'Bon de Cuisine Rapide',
      type: 'cuisine',
      description: 'Template rapide et efficace pour la cuisine, facile a lire',
      template_content: `[CENTER]
[BOLD_ON]
{{restaurantName}} - CUISINE
[BOLD_OFF]
[FEED]

#{{orderNumber}} - {{time}}
[HR]

{{items}}

[HR]
[CUT]`,
    },
  ];
}

// Composant pour rendre la previsualisation visuelle du ticket
function TicketPreviewRenderer({ content, paperWidth }: { content: string; paperWidth: 58 | 80 }) {
  if (!content) return <div className="text-gray-400">Aucun contenu</div>;

  const lines = content.split('\n');
  const renderedLines: React.ReactElement[] = [];
  let currentAlign: 'left' | 'center' | 'right' = 'left';
  let isBold = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Commandes speciales
    if (line === '[CENTER]') {
      currentAlign = 'center';
      continue;
    }
    if (line === '[LEFT]') {
      currentAlign = 'left';
      continue;
    }
    if (line === '[RIGHT]') {
      currentAlign = 'right';
      continue;
    }
    if (line === '[BOLD_ON]') {
      isBold = true;
      continue;
    }
    if (line === '[BOLD_OFF]') {
      isBold = false;
      continue;
    }
    if (line === '[HR]') {
      renderedLines.push(
        <div
          key={`hr-${i}`}
          className="my-1 border-t border-gray-400"
          style={{ borderColor: '#000' }}
        />
      );
      continue;
    }
    if (line === '[FEED]' || line === '') {
      renderedLines.push(<div key={`feed-${i}`} className="h-2" />);
      continue;
    }
    if (line === '[CUT]') {
      renderedLines.push(
        <div
          key={`cut-${i}`}
          className="my-2 flex items-center justify-center"
        >
          <div className="border-t-2 border-dashed border-gray-600" style={{ width: '80%' }} />
          <span className="mx-2 text-xs text-gray-500">COUPE</span>
          <div className="border-t-2 border-dashed border-gray-600" style={{ width: '80%' }} />
        </div>
      );
      continue;
    }

    // Ligne normale avec variables remplacees
    if (line) {
      const textAlign = currentAlign === 'left' ? 'left' : currentAlign === 'right' ? 'right' : 'center';
      renderedLines.push(
        <div
          key={`line-${i}`}
          style={{
            textAlign,
            fontWeight: isBold ? 'bold' : 'normal',
            fontSize: isBold ? (paperWidth === 58 ? '11px' : '12px') : undefined,
          }}
          className={isBold ? 'font-bold' : ''}
        >
          {line}
        </div>
      );
    }
  }

  return <div className="space-y-0.5">{renderedLines}</div>;
}

function getDefaultTemplate(): string {
  return `[CENTER]
[BOLD_ON]
{{restaurantName}}
[BOLD_OFF]
[FEED]

[LEFT]
Commande #{{orderNumber}}
Date: {{date}} {{time}}
Type: {{orderType}}
[HR]

{{items}}

[HR]
Sous-total: {{subtotal}} DA
{{#if deliveryFee}}
Livraison: {{deliveryFee}} DA
{{/if}}
[BOLD_ON]
TOTAL: {{total}} DA
[BOLD_OFF]
[FEED]

[CENTER]
{{footer}}
[FEED]
[FEED]
[CUT]`;
}
