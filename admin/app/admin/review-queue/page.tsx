'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { io, Socket } from 'socket.io-client';
import {
  AlertCircle,
  ArrowRight,
  CheckCircle,
  Copy,
  ExternalLink,
  RefreshCw,
  Search,
  ShieldAlert,
  Phone,
  Store,
  Truck,
  User,
  XCircle,
  Clock,
  DollarSign,
  Lock,
  Unlock,
  MessageSquare,
  Send
} from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type ReviewStatus = 'all' | 'pending' | 'claimed' | 'approved' | 'rejected';

type ReviewReason = 'low_client_history' | 'high_value_order' | string;

interface ReviewOrder {
  id: string;
  order_number: string;
  status: string;
  order_type: 'delivery' | 'pickup';
  total_amount: number;
  subtotal?: number;
  delivery_fee?: number;
  requires_admin_review: boolean;
  admin_review_status: 'none' | 'pending' | 'claimed' | 'approved' | 'rejected';
  admin_review_metadata?: {
    reasons?: ReviewReason[];
    client_order_count?: number;
    threshold_count?: number;
    threshold_amount?: number;
    total_amount?: number;
    claimed_by_me?: boolean;
    client_lock_active?: boolean;
  };
  admin_review_claimed_by?: string | null;
  admin_review_claimed_at?: string | null;
  admin_reviewed_by?: string | null;
  admin_reviewed_at?: string | null;
  admin_review_notes?: string | null;
  restaurant_notified_at?: string | null;
  created_at: string;
  updated_at: string;
  client?: {
    id?: string;
    first_name?: string;
    last_name?: string;
    phone_number?: string;
    address?: string;
    review_contact_lock_admin_id?: string | null;
    review_contact_lock_order_id?: string | null;
    review_contact_locked_at?: string | null;
    review_contact_lock_until?: string | null;
  };
  restaurant?: {
    id?: string;
    name?: string;
    phone_number?: string;
    address?: string;
  };
  order_items?: Array<{
    id?: string;
    quantite?: number;
    prix_total?: number;
    menu_item?: {
      nom?: string;
      prix?: number;
    };
    additions?: Array<{
      id?: string;
      quantite?: number;
      prix_total?: number;
      addition?: {
        nom?: string;
        prix?: number;
      };
    }>;
  }>;
  review?: {
    claimed_by_me?: boolean;
    is_claimed?: boolean;
    is_pending?: boolean;
    is_approved?: boolean;
    is_rejected?: boolean;
    client_lock_active?: boolean;
  };
}

const formatDate = (value?: string | null) => {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString('fr-FR', {
    dateStyle: 'short',
    timeStyle: 'short'
  });
};

const formatCurrency = (value?: number | string | null) => {
  const amount = Number(value || 0);
  return new Intl.NumberFormat('fr-DZ', {
    style: 'currency',
    currency: 'DZD'
  }).format(Number.isFinite(amount) ? amount : 0);
};

const normalizePhone = (phone?: string | null) => {
  if (!phone) return '';
  return String(phone).replace(/[^\d+]/g, '');
};

export default function ReviewQueuePage() {
  const socketRef = useRef<Socket | null>(null);
  const [orders, setOrders] = useState<ReviewOrder[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<ReviewOrder | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<ReviewStatus>('pending');
  const [actionLoading, setActionLoading] = useState<string>('');
  const [preparationTime, setPreparationTime] = useState<number>(15);
  const [rejectReason, setRejectReason] = useState('');
  const [socketConnected, setSocketConnected] = useState(false);

  const fetchQueue = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const token = localStorage.getItem('access_token');
      if (!token) {
        setError('Non authentifie. Veuillez vous reconnecter.');
        return;
      }

      const params = new URLSearchParams();
      if (filterStatus !== 'all') {
        params.set('review_status', filterStatus);
      }

      const response = await fetch(`${API_URL}/admin/orders/review-queue?${params.toString()}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Impossible de charger la file de validation');
      }

      const data = await response.json();
      const nextOrders = Array.isArray(data?.data) ? data.data : [];
      setOrders(nextOrders);
      setSelectedOrder((current) => {
        if (!nextOrders.length) return null;
        if (!current) return nextOrders[0];
        const updated = nextOrders.find((order: ReviewOrder) => order.id === current.id);
        return updated || nextOrders[0];
      });
    } catch (err: any) {
      console.error('review queue fetch error:', err);
      setError(err?.message || 'Erreur lors du chargement');
    } finally {
      setLoading(false);
    }
  }, [filterStatus]);

  useEffect(() => {
    fetchQueue();
  }, [fetchQueue]);

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    if (!token) return;

    const socket = io(API_URL, {
      path: '/socket.io',
      auth: { token },
      transports: ['websocket', 'polling']
    });

    socket.on('connect', () => setSocketConnected(true));
    socket.on('disconnect', () => setSocketConnected(false));
    socket.on('admin_review_queue_updated', () => {
      fetchQueue();
    });

    socketRef.current = socket;

    return () => {
      socket.disconnect();
      socketRef.current = null;
    };
  }, [fetchQueue]);

  useEffect(() => {
    const timer = window.setInterval(() => {
      fetchQueue();
    }, 15_000);

    return () => window.clearInterval(timer);
  }, [fetchQueue]);

  const filteredOrders = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return orders;
    return orders.filter((order) => {
      const clientName = `${order.client?.first_name || ''} ${order.client?.last_name || ''}`.trim().toLowerCase();
      const restaurantName = (order.restaurant?.name || '').toLowerCase();
      const orderNumber = (order.order_number || '').toLowerCase();
      const phone = (order.client?.phone_number || '').toLowerCase();
      return (
        clientName.includes(term) ||
        restaurantName.includes(term) ||
        orderNumber.includes(term) ||
        phone.includes(term)
      );
    });
  }, [orders, search]);

  const stats = useMemo(() => {
    const reasons = {
      low: 0,
      high: 0
    };

    for (const order of orders) {
      const orderReasons = order.admin_review_metadata?.reasons || [];
      if (orderReasons.includes('low_client_history')) reasons.low++;
      if (orderReasons.includes('high_value_order')) reasons.high++;
    }

    return {
      total: orders.length,
      pending: orders.filter((order) => order.admin_review_status === 'pending').length,
      claimed: orders.filter((order) => order.admin_review_status === 'claimed').length,
      approved: orders.filter((order) => order.admin_review_status === 'approved').length,
      rejected: orders.filter((order) => order.admin_review_status === 'rejected').length,
      low: reasons.low,
      high: reasons.high
    };
  }, [orders]);

  const selectedReasons = selectedOrder?.admin_review_metadata?.reasons || [];
  const isClaimedByMe = !!selectedOrder?.review?.claimed_by_me;
  const isClaimed = selectedOrder?.admin_review_status === 'claimed';
  const clientPhone = normalizePhone(selectedOrder?.client?.phone_number);
  const whatsappLink = clientPhone ? `https://wa.me/${clientPhone.replace(/^\+/, '')}` : '';

  const patchSelectedOrder = (patch: Partial<ReviewOrder>) => {
    if (!selectedOrder) return;
    setSelectedOrder({ ...selectedOrder, ...patch });
    setOrders((prev) => prev.map((order) => (order.id === selectedOrder.id ? { ...order, ...patch } : order)));
  };

  const runOrderAction = async (
    orderId: string,
    endpoint: string,
    payload: Record<string, unknown> = {},
    successMessage = 'Action effectuée'
  ) => {
    try {
      setActionLoading(orderId);
      setError('');
      const token = localStorage.getItem('access_token');
      if (!token) throw new Error('Non authentifie');

      const response = await fetch(`${API_URL}/admin/orders/${orderId}/review/${endpoint}`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      const data = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new Error(data?.message || 'Echec de l\'action');
      }

      if (data?.data) {
        patchSelectedOrder(data.data);
      }

      await fetchQueue();
      setError('');
      return successMessage;
    } catch (err: any) {
      console.error('order review action error:', err);
      setError(err?.message || 'Action impossible');
      return null;
    } finally {
      setActionLoading('');
    }
  };

  const claimSelected = async () => {
    if (!selectedOrder) return;
    await runOrderAction(selectedOrder.id, 'claim', {}, 'Commande prise en charge');
  };

  const approveSelected = async () => {
    if (!selectedOrder) return;
    await runOrderAction(
      selectedOrder.id,
      'approve',
      { preparation_time: preparationTime },
      'Commande envoyée au restaurant'
    );
  };

  const rejectSelected = async () => {
    if (!selectedOrder) return;
    if (!rejectReason.trim()) {
      setError('La raison de refus est requise');
      return;
    }
    await runOrderAction(
      selectedOrder.id,
      'reject',
      { reason: rejectReason.trim() },
      'Commande refusée'
    );
    setRejectReason('');
  };

  const releaseSelected = async () => {
    if (!selectedOrder) return;
    await runOrderAction(selectedOrder.id, 'release', {}, 'Verrou libéré');
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <div className="border-b border-slate-200 bg-white">
        <div className="mx-auto max-w-none px-4 py-6 sm:px-6 lg:px-8">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <div className="flex items-center gap-3">
                <div className="rounded-2xl bg-amber-100 p-3 text-amber-700">
                  <ShieldAlert className="h-6 w-6" />
                </div>
                <div>
                  <h1 className="text-2xl font-bold">Validation client</h1>
                  <p className="mt-1 text-sm text-slate-500">
                    Commandes à contacter avant envoi au restaurant
                  </p>
                </div>
              </div>
              <div className="mt-3 flex flex-wrap gap-2 text-xs">
                <span className={`rounded-full px-3 py-1 ${socketConnected ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-600'}`}>
                  {socketConnected ? 'Temps réel actif' : 'Connexion temps réel en attente'}
                </span>
                <span className="rounded-full bg-amber-100 px-3 py-1 text-amber-700">
                  Verrou client 15 min
                </span>
              </div>
            </div>

            <button
              onClick={() => fetchQueue()}
              className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-emerald-700 disabled:opacity-50"
              disabled={loading}
            >
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
              Actualiser
            </button>
          </div>

          <div className="mt-6 grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
            {[
              { label: 'Total', value: stats.total, tone: 'bg-slate-50 text-slate-700' },
              { label: 'En attente', value: stats.pending, tone: 'bg-amber-50 text-amber-700' },
              { label: 'Pris en charge', value: stats.claimed, tone: 'bg-blue-50 text-blue-700' },
              { label: 'Validées', value: stats.approved, tone: 'bg-emerald-50 text-emerald-700' },
              { label: 'Refusées', value: stats.rejected, tone: 'bg-rose-50 text-rose-700' },
              { label: 'Signalées', value: stats.low + stats.high, tone: 'bg-violet-50 text-violet-700' }
            ].map((card) => (
              <div key={card.label} className={`rounded-2xl border border-slate-200 p-4 ${card.tone}`}>
                <div className="text-xs font-medium uppercase tracking-[0.25em] opacity-70">{card.label}</div>
                <div className="mt-2 text-2xl font-bold">{card.value}</div>
              </div>
            ))}
          </div>

          <div className="mt-6 grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
            <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
              <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div className="relative w-full md:max-w-md">
                  <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                  <input
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder="Rechercher commande, client, téléphone, restaurant..."
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-10 pr-4 text-sm outline-none transition focus:border-emerald-500 focus:bg-white"
                  />
                </div>

                <div className="flex flex-wrap gap-2">
                  {(['all', 'pending', 'claimed', 'approved', 'rejected'] as ReviewStatus[]).map((status) => (
                    <button
                      key={status}
                      onClick={() => setFilterStatus(status)}
                      className={`rounded-full px-3 py-2 text-xs font-semibold transition ${
                        filterStatus === status
                          ? 'bg-emerald-600 text-white'
                          : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                      }`}
                    >
                      {status === 'all'
                        ? 'Tout'
                        : status === 'pending'
                          ? 'En attente'
                          : status === 'claimed'
                            ? 'Pris'
                            : status === 'approved'
                              ? 'Validé'
                              : 'Refusé'}
                    </button>
                  ))}
                </div>
              </div>

              {error && (
                <div className="mt-4 flex items-start gap-3 rounded-2xl border border-rose-200 bg-rose-50 p-4 text-rose-700">
                  <AlertCircle className="mt-0.5 h-5 w-5 flex-shrink-0" />
                  <div className="text-sm">{error}</div>
                </div>
              )}

              <div className="mt-4 overflow-hidden rounded-2xl border border-slate-200">
                <div className="grid grid-cols-[1.3fr_0.8fr_0.8fr_0.9fr] gap-3 border-b border-slate-200 bg-slate-50 px-4 py-3 text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
                  <div>Commande</div>
                  <div>Client</div>
                  <div>Montant</div>
                  <div>État</div>
                </div>

                <div className="max-h-[70vh] overflow-y-auto bg-white">
                  {loading ? (
                    <div className="flex items-center justify-center py-16">
                      <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-emerald-600" />
                    </div>
                  ) : filteredOrders.length === 0 ? (
                    <div className="px-4 py-16 text-center text-sm text-slate-500">
                      Aucune commande à valider
                    </div>
                  ) : (
                    filteredOrders.map((order) => {
                      const reasons = order.admin_review_metadata?.reasons || [];
                      const isSelected = selectedOrder?.id === order.id;
                      return (
                        <button
                          key={order.id}
                          onClick={() => setSelectedOrder(order)}
                          className={`grid w-full grid-cols-[1.3fr_0.8fr_0.8fr_0.9fr] gap-3 border-b border-slate-100 px-4 py-4 text-left transition ${
                            isSelected ? 'bg-emerald-50' : 'hover:bg-slate-50'
                          }`}
                        >
                          <div>
                            <div className="font-semibold text-slate-900">{order.order_number}</div>
                            <div className="mt-1 flex flex-wrap gap-1.5 text-[11px]">
                              {reasons.includes('low_client_history') && (
                                <span className="rounded-full bg-amber-100 px-2 py-0.5 text-amber-700">Nouveau client</span>
                              )}
                              {reasons.includes('high_value_order') && (
                                <span className="rounded-full bg-violet-100 px-2 py-0.5 text-violet-700">Montant élevé</span>
                              )}
                              {order.review?.client_lock_active && (
                                <span className="rounded-full bg-slate-200 px-2 py-0.5 text-slate-700">Verrou actif</span>
                              )}
                            </div>
                          </div>
                          <div className="text-sm text-slate-600">
                            {`${order.client?.first_name || ''} ${order.client?.last_name || ''}`.trim() || 'Client'}
                          </div>
                          <div className="text-sm font-semibold text-slate-900">{formatCurrency(order.total_amount)}</div>
                          <div className="text-sm">
                            <span
                              className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${
                                order.admin_review_status === 'claimed'
                                  ? 'bg-blue-100 text-blue-700'
                                  : order.admin_review_status === 'approved'
                                    ? 'bg-emerald-100 text-emerald-700'
                                    : order.admin_review_status === 'rejected'
                                      ? 'bg-rose-100 text-rose-700'
                                      : 'bg-amber-100 text-amber-700'
                              }`}
                            >
                              {order.admin_review_status === 'claimed'
                                ? 'Pris en charge'
                                : order.admin_review_status === 'approved'
                                  ? 'Validé'
                                  : order.admin_review_status === 'rejected'
                                    ? 'Refusé'
                                    : 'En attente'}
                            </span>
                            <div className="mt-1 text-xs text-slate-500">{formatDate(order.created_at)}</div>
                          </div>
                        </button>
                      );
                    })
                  )}
                </div>
              </div>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              {!selectedOrder ? (
                <div className="flex h-full min-h-[420px] flex-col items-center justify-center text-center text-slate-500">
                  <ShieldAlert className="h-12 w-12 text-slate-300" />
                  <p className="mt-3 text-sm">Sélectionnez une commande pour voir les détails</p>
                </div>
              ) : (
                <div className="space-y-5">
                  <div>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-400">Commande</div>
                        <h2 className="mt-1 text-xl font-bold text-slate-900">{selectedOrder.order_number}</h2>
                        <p className="mt-1 text-sm text-slate-500">{formatDate(selectedOrder.created_at)}</p>
                      </div>
                      <div className="rounded-2xl bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-700">
                        {selectedOrder.admin_review_status === 'claimed'
                          ? 'Pris en charge'
                          : selectedOrder.admin_review_status === 'approved'
                            ? 'Validée'
                            : selectedOrder.admin_review_status === 'rejected'
                              ? 'Refusée'
                              : 'En attente'}
                      </div>
                    </div>

                    <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
                      <div className="grid gap-4 sm:grid-cols-2">
                        <div>
                          <div className="text-xs text-slate-500">Client</div>
                          <div className="mt-1 font-semibold text-slate-900">
                            {`${selectedOrder.client?.first_name || ''} ${selectedOrder.client?.last_name || ''}`.trim() || '-'}
                          </div>
                          <div className="mt-1 text-sm text-slate-600">{selectedOrder.client?.phone_number || '-'}</div>
                        </div>
                        <div>
                          <div className="text-xs text-slate-500">Restaurant</div>
                          <div className="mt-1 font-semibold text-slate-900">{selectedOrder.restaurant?.name || '-'}</div>
                          <div className="mt-1 text-sm text-slate-600">{selectedOrder.restaurant?.phone_number || '-'}</div>
                        </div>
                      </div>

                      <div className="mt-4 grid gap-3 sm:grid-cols-2">
                        <div className="rounded-xl bg-white p-3">
                          <div className="text-xs text-slate-500">Montant</div>
                          <div className="mt-1 text-lg font-bold text-slate-900">{formatCurrency(selectedOrder.total_amount)}</div>
                        </div>
                        <div className="rounded-xl bg-white p-3">
                          <div className="text-xs text-slate-500">Décision</div>
                          <div className="mt-1 text-sm font-semibold text-slate-900">
                            {selectedOrder.admin_review_status === 'claimed'
                              ? 'Contact en cours'
                              : selectedOrder.admin_review_status === 'approved'
                                ? 'Restaurant notifié'
                                : selectedOrder.admin_review_status === 'rejected'
                                  ? 'Client notifié du refus'
                                  : 'A contacter'}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                      <MessageSquare className="h-4 w-4" />
                      Raison du filtrage
                    </div>
                    <div className="mt-3 flex flex-wrap gap-2">
                      {selectedReasons.length === 0 ? (
                        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs text-slate-600">Non renseignée</span>
                      ) : (
                        selectedReasons.map((reason) => (
                          <span
                            key={reason}
                            className="rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-700"
                          >
                            {reason === 'low_client_history' ? 'Historique client faible' : reason === 'high_value_order' ? 'Montant élevé' : reason}
                          </span>
                        ))
                      )}
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                      <User className="h-4 w-4" />
                      Contact client
                    </div>
                    <div className="mt-3 rounded-2xl border border-dashed border-slate-200 p-4">
                      <div className="grid gap-3 sm:grid-cols-2">
                        <div>
                          <div className="text-xs text-slate-500">Téléphone</div>
                          <div className="mt-1 font-semibold text-slate-900">{selectedOrder.client?.phone_number || '-'}</div>
                        </div>
                        <div>
                          <div className="text-xs text-slate-500">Adresse</div>
                          <div className="mt-1 font-semibold text-slate-900">{selectedOrder.client?.address || '-'}</div>
                        </div>
                      </div>
                      <div className="mt-4 flex flex-wrap gap-2">
                        {clientPhone && (
                          <a
                            href={`tel:${clientPhone}`}
                            className="inline-flex items-center gap-2 rounded-xl bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-200"
                          >
                            <Phone className="h-4 w-4" />
                            Appeler
                          </a>
                        )}
                        {whatsappLink && (
                          <a
                            href={whatsappLink}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-3 py-2 text-sm font-semibold text-white hover:bg-emerald-700"
                          >
                            <Send className="h-4 w-4" />
                            WhatsApp
                          </a>
                        )}
                        <button
                          onClick={() => navigator.clipboard.writeText(selectedOrder.client?.phone_number || '')}
                          className="inline-flex items-center gap-2 rounded-xl bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-200"
                        >
                          <Copy className="h-4 w-4" />
                          Copier
                        </button>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                      <Store className="h-4 w-4" />
                      Articles
                    </div>
                    <div className="mt-3 space-y-2">
                      {(selectedOrder.order_items || []).map((item, index) => (
                        <div key={`${item.id || index}`} className="rounded-xl border border-slate-200 p-3">
                          <div className="flex items-start justify-between gap-3">
                            <div>
                              <div className="font-semibold text-slate-900">{item.menu_item?.nom || 'Article'}</div>
                              <div className="text-xs text-slate-500">Qté: {item.quantite || 1}</div>
                            </div>
                            <div className="font-semibold text-slate-900">{formatCurrency(item.prix_total)}</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {selectedOrder.review?.client_lock_active && (
                    <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                      <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                        <Lock className="h-4 w-4" />
                        Verrou client actif
                      </div>
                      <p className="mt-2 text-sm text-slate-600">
                        Ce client est réservé à un seul agent pendant le traitement de la commande.
                      </p>
                    </div>
                  )}

                  <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                    <div className="grid gap-3">
                      <label className="text-sm font-semibold text-slate-700">
                        Temps de préparation à envoyer au restaurant
                      </label>
                      <input
                        type="number"
                        min={5}
                        max={120}
                        value={preparationTime}
                        onChange={(e) => setPreparationTime(Number(e.target.value))}
                        className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm outline-none focus:border-emerald-500"
                      />
                      <label className="text-sm font-semibold text-slate-700">
                        Raison de refus
                      </label>
                      <textarea
                        value={rejectReason}
                        onChange={(e) => setRejectReason(e.target.value)}
                        rows={3}
                        placeholder="Expliquez pourquoi la commande est refusée"
                        className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm outline-none focus:border-rose-500"
                      />
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 border-t border-slate-200 pt-4">
                    {!isClaimed && selectedOrder.admin_review_status !== 'approved' && selectedOrder.admin_review_status !== 'rejected' && (
                      <button
                        onClick={claimSelected}
                        disabled={!!actionLoading}
                        className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-50"
                      >
                        <Unlock className="h-4 w-4" />
                        Prendre en charge
                      </button>
                    )}

                    {isClaimedByMe && (
                      <>
                        <button
                          onClick={approveSelected}
                          disabled={!!actionLoading}
                          className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
                        >
                          <ArrowRight className="h-4 w-4" />
                          Envoyer au restaurant
                        </button>
                        <button
                          onClick={releaseSelected}
                          disabled={!!actionLoading}
                          className="inline-flex items-center gap-2 rounded-xl bg-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-300 disabled:opacity-50"
                        >
                          <Lock className="h-4 w-4" />
                          Libérer
                        </button>
                        <button
                          onClick={rejectSelected}
                          disabled={!!actionLoading || !rejectReason.trim()}
                          className="inline-flex items-center gap-2 rounded-xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-rose-700 disabled:opacity-50"
                        >
                          <XCircle className="h-4 w-4" />
                          Refuser
                        </button>
                      </>
                    )}

                    {actionLoading === selectedOrder.id && (
                      <span className="inline-flex items-center gap-2 rounded-xl bg-slate-100 px-3 py-2 text-sm text-slate-600">
                        <Clock className="h-4 w-4 animate-spin" />
                        Traitement...
                      </span>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
