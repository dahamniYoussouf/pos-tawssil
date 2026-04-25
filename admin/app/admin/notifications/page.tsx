'use client';

import { useState, useEffect, useMemo } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  Bell,
  BellOff,
  Search,
  CheckCircle,
  XCircle,
  AlertCircle,
  Clock,
  Truck,
  Store,
  ThumbsUp,
  ThumbsDown,
  Ban,
  ArrowLeft,
  ArrowRight,
  RefreshCw,
  Eye,
  Archive,
  ShieldAlert
} from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// ==== TYPES ====

type NotificationType = 
  | 'pending_order_timeout' 
  | 'restaurant_preparation_timeout'
  | 'driver_arrival_timeout'
  | 'restaurant_unresponsive' 
  | 'driver_unresponsive' 
  | 'driver_excessive_cancellations'
  | 'order_admin_review_required';

type AdminAction = 'force_accept' | 'cancel_order' | 'contacted_restaurant' | 'none';

interface AdminNotification {
  id: string;
  order_id?: string;
  restaurant_id?: string;
  driver_id?: string;
  type: NotificationType;
  message: string;
  order_details?: any;
  restaurant_info?: any;
  order?: any;
  restaurant?: any;
  is_read: boolean;
  is_resolved: boolean;
  resolved_by?: string;
  resolved_at?: string;
  admin_action?: AdminAction;
  admin_notes?: string;
  created_at: string;
  updated_at: string;
}

type ModalType = '' | 'resolve' | 'force-accept' | 'force-cancel';

export default function AdminNotifications() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const selectedFromQuery = searchParams?.get('selected');
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [filterType, setFilterType] = useState<'all' | NotificationType>('all');
  const [filterStatus, setFilterStatus] = useState<'all' | 'unread' | 'read' | 'resolved' | 'unresolved'>('all');
  const [selectedNotification, setSelectedNotification] = useState<AdminNotification | null>(null);
  const [showModal, setShowModal] = useState<boolean>(false);
  const [modalType, setModalType] = useState<ModalType>('');
  const [actionLoading, setActionLoading] = useState<boolean>(false);
  const [isMobile, setIsMobile] = useState<boolean>(false);
  const [mobileView, setMobileView] = useState<'list' | 'details'>('list');
  
  // Resolve form state
  const [resolveAction, setResolveAction] = useState<AdminAction>('none');
  const [resolveNotes, setResolveNotes] = useState<string>('');
  const [forceAcceptTime, setForceAcceptTime] = useState<number>(15);
  const [forceCancelReason, setForceCancelReason] = useState<string>('');

  // Statistics
  const [stats, setStats] = useState({
    total: 0,
    unread: 0,
    unresolved: 0,
    pending_timeout: 0,
    order_review: 0,
    driver_cancellations: 0
  });

  // Fetch notifications
  useEffect(() => {
    fetchNotifications();
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const mediaQuery = window.matchMedia('(max-width: 1023px)');
    const update = () => setIsMobile(mediaQuery.matches);
    update();
    if (mediaQuery.addEventListener) {
      mediaQuery.addEventListener('change', update);
      return () => mediaQuery.removeEventListener('change', update);
    }
    mediaQuery.addListener(update);
    return () => mediaQuery.removeListener(update);
  }, []);

  // Calculate stats when notifications change
  useEffect(() => {
    calculateStats();
  }, [notifications]);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) {
        setError('Non authentifie. Veuillez vous reconnecter.');
        setLoading(false);
        return;
      }

      const response = await fetch(`${API_URL}/admin/notifications`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement des notifications');
      }

      const data = await response.json();

      if (data.success && data.data) {
        setNotifications(data.data as AdminNotification[]);
      } else {
        throw new Error('Format de donnees invalide');
      }
    } catch (err: any) {
      console.error('Erreur fetch notifications:', err);
      setError(err?.message || 'Impossible de charger les notifications');
    } finally {
      setLoading(false);
    }
  };

  const calculateStats = () => {
    const total = notifications.length;
    const unread = notifications.filter(n => !n.is_read).length;
    const unresolved = notifications.filter(n => !n.is_resolved).length;
    const pending_timeout = notifications.filter(n =>
      ['pending_order_timeout', 'restaurant_preparation_timeout'].includes(n.type) && !n.is_resolved
    ).length;
    const order_review = notifications.filter(n =>
      n.type === 'order_admin_review_required' && !n.is_resolved
    ).length;
    const driver_cancellations = notifications.filter(n =>
      ['driver_excessive_cancellations', 'driver_arrival_timeout'].includes(n.type) && !n.is_resolved
    ).length;

    setStats({
      total,
      unread,
      unresolved,
      pending_timeout,
      order_review,
      driver_cancellations
    });
  };

  // Filter notifications
  const filteredNotifications = notifications.filter((notification) => {
    const search = searchTerm.toLowerCase();

    const matchesSearch =
      notification.message?.toLowerCase().includes(search) ||
      notification.order_details?.order_number?.toLowerCase().includes(search);

    const matchesType =
      filterType === 'all' || notification.type === filterType;

    const matchesStatus =
      filterStatus === 'all' ||
      (filterStatus === 'read' && notification.is_read) ||
      (filterStatus === 'unread' && !notification.is_read) ||
      (filterStatus === 'resolved' && notification.is_resolved) ||
      (filterStatus === 'unresolved' && !notification.is_resolved);

    return matchesSearch && matchesType && matchesStatus;
  });

  const sortedNotifications = useMemo(() => {
    return [...filteredNotifications].sort(
      (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );
  }, [filteredNotifications]);

  useEffect(() => {
    if (!selectedFromQuery) return;
    const match = notifications.find((notification) => notification.id === selectedFromQuery);
    if (match) {
      setSelectedNotification(match);
      if (isMobile) setMobileView('details');
    }
  }, [selectedFromQuery, notifications, isMobile]);

  useEffect(() => {
    if (selectedNotification) return;
    if (isMobile) return;
    if (sortedNotifications.length > 0) {
      setSelectedNotification(sortedNotifications[0]);
    }
  }, [sortedNotifications, selectedNotification, isMobile]);

  useEffect(() => {
    if (!selectedNotification) return;
    const updated = notifications.find((notification) => notification.id === selectedNotification.id);
    if (updated) {
      setSelectedNotification(updated);
    }
  }, [notifications, selectedNotification]);

  useEffect(() => {
    if (!selectedNotification) return;
    const element = document.getElementById(`notif-${selectedNotification.id}`);
    if (element) {
      element.scrollIntoView({ block: 'center' });
    }
  }, [selectedNotification?.id]);

  // Mark as read
  const handleMarkAsRead = async (notificationId: string) => {
    try {
      const token = localStorage.getItem('access_token');
      if (!token) throw new Error('Non authentifie');

      const response = await fetch(`${API_URL}/admin/notifications/${notificationId}/read`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors de la mise a jour');
      }

      await fetchNotifications();
    } catch (err: any) {
      console.error('Erreur mark as read:', err);
      setError(err?.message || 'Impossible de marquer comme lu');
    }
  };

  // Resolve notification
  const handleResolve = async () => {
    if (!selectedNotification) return;

    try {
      setActionLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) throw new Error('Non authentifie');

      const response = await fetch(`${API_URL}/admin/notifications/${selectedNotification.id}/resolve`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          action: resolveAction,
          notes: resolveNotes
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Erreur lors de la resolution');
      }

      await fetchNotifications();
      handleCloseModal();
    } catch (err: any) {
      console.error('Erreur resolve:', err);
      setError(err?.message || 'Impossible de resoudre');
    } finally {
      setActionLoading(false);
    }
  };

  // Force accept order
  const handleForceAccept = async () => {
    if (!selectedNotification?.order_id) return;

    try {
      setActionLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) throw new Error('Non authentifie');

      const response = await fetch(`${API_URL}/admin/orders/${selectedNotification.order_id}/force-accept`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          preparation_time: forceAcceptTime
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Erreur lors de l\'acceptation forcee');
      }

      // Auto-resolve notification
      await fetch(`${API_URL}/admin/notifications/${selectedNotification.id}/resolve`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          action: 'force_accept',
          notes: `Commande acceptee de force - Temps de preparation: ${forceAcceptTime} min`
        })
      });

      await fetchNotifications();
      handleCloseModal();
    } catch (err: any) {
      console.error('Erreur force accept:', err);
      setError(err?.message || 'Impossible d\'accepter la commande');
    } finally {
      setActionLoading(false);
    }
  };

  // Force cancel order
  const handleForceCancel = async () => {
    if (!selectedNotification?.order_id || !forceCancelReason.trim()) {
      setError('La raison d\'annulation est requise');
      return;
    }

    try {
      setActionLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) throw new Error('Non authentifie');

      const response = await fetch(`${API_URL}/admin/orders/${selectedNotification.order_id}/force-cancel`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          reason: forceCancelReason
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Erreur lors de l\'annulation');
      }

      // Auto-resolve notification
      await fetch(`${API_URL}/admin/notifications/${selectedNotification.id}/resolve`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          action: 'cancel_order',
          notes: `Commande annulee: ${forceCancelReason}`
        })
      });

      await fetchNotifications();
      handleCloseModal();
    } catch (err: any) {
      console.error('Erreur force cancel:', err);
      setError(err?.message || 'Impossible d\'annuler la commande');
    } finally {
      setActionLoading(false);
    }
  };

  const handleAction = (notification: AdminNotification, type: ModalType) => {
    setSelectedNotification(notification);
    setModalType(type);
    setShowModal(true);
    setResolveAction('none');
    setResolveNotes('');
    setForceAcceptTime(15);
    setForceCancelReason('');
    setError('');
  };

  const handleSelectNotification = (notification: AdminNotification) => {
    setSelectedNotification(notification);
    if (isMobile) setMobileView('details');
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setModalType('');
    setResolveAction('none');
    setResolveNotes('');
    setForceAcceptTime(15);
    setForceCancelReason('');
    setError('');
    setActionLoading(false);
  };

  const showList = !isMobile || mobileView === 'list';
  const showDetails = !isMobile || mobileView === 'details';

  const formatDate = (dateString: string) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'A l\'instant';
    if (diffMins < 60) return `Il y a ${diffMins} min`;
    if (diffHours < 24) return `Il y a ${diffHours}h`;
    if (diffDays < 7) return `Il y a ${diffDays}j`;
    
    return date.toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  };

  const getNotificationIcon = (type: NotificationType) => {
    switch (type) {
      case 'pending_order_timeout':
        return <Clock className="w-5 h-5" />;
      case 'restaurant_preparation_timeout':
        return <Store className="w-5 h-5" />;
      case 'driver_arrival_timeout':
        return <Truck className="w-5 h-5" />;
      case 'restaurant_unresponsive':
        return <Store className="w-5 h-5" />;
        case 'driver_unresponsive':
          return <Truck className="w-5 h-5" />;
        case 'driver_excessive_cancellations':
          return <Ban className="w-5 h-5" />;
        case 'order_admin_review_required':
          return <ShieldAlert className="w-5 h-5" />;
        default:
          return <Bell className="w-5 h-5" />;
      }
  };

  const getNotificationColor = (type: NotificationType) => {
    switch (type) {
      case 'pending_order_timeout':
        return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'restaurant_preparation_timeout':
        return 'bg-orange-100 text-orange-800 border-orange-300';
      case 'driver_arrival_timeout':
        return 'bg-blue-100 text-blue-800 border-blue-300';
      case 'restaurant_unresponsive':
        return 'bg-orange-100 text-orange-800 border-orange-300';
        case 'driver_unresponsive':
          return 'bg-blue-100 text-blue-800 border-blue-300';
        case 'driver_excessive_cancellations':
          return 'bg-red-100 text-red-800 border-red-300';
        case 'order_admin_review_required':
          return 'bg-amber-100 text-amber-800 border-amber-300';
        default:
          return 'bg-gray-100 text-gray-800 border-gray-300';
      }
  };

  const getNotificationTitle = (type: NotificationType) => {
    switch (type) {
      case 'pending_order_timeout':
        return 'Commande en attente';
      case 'restaurant_preparation_timeout':
        return 'Preparation restaurant en retard';
      case 'driver_arrival_timeout':
        return 'Arrivee livreur en retard';
      case 'restaurant_unresponsive':
        return 'Restaurant ne repond pas';
        case 'driver_unresponsive':
          return 'Livreur ne repond pas';
        case 'driver_excessive_cancellations':
          return 'Livreur - Annulations excessives';
        case 'order_admin_review_required':
          return 'Commande a valider';
        default:
          return 'Notification';
      }
  };

  const getCompactSummary = (notification: AdminNotification) => {
    const order = notification.order_details ?? notification.order ?? {};
    const orderNumber = order?.order_number ?? order?.number ?? order?.code;
    const totalAmount = order?.total_amount ?? order?.total;
    const clientName = order?.client?.name ?? order?.customer?.name;
    const restaurantName = notification.restaurant_info?.name ?? notification.restaurant?.name;

    const parts: string[] = [];
    if (orderNumber) parts.push(`Cmd: ${orderNumber}`);
    if (totalAmount !== undefined && totalAmount !== null) parts.push(`${totalAmount} DA`);
    if (clientName) parts.push(`Client: ${clientName}`);
    if (restaurantName) parts.push(`Resto: ${restaurantName}`);

    if (parts.length === 0) {
      const firstLine = String(notification.message || '').split('\n')[0].trim();
      if (firstLine) parts.push(firstLine);
    }

    return parts.join(' * ');
  };

  const getOrderItemsForNotification = (notification: AdminNotification | null) => {
    if (!notification) return [];
    const candidates = [
      notification.order_details?.items,
      notification.order_details?.order_items,
      notification.order?.order_items,
      notification.order?.items
    ].filter((items) => Array.isArray(items) && items.length > 0);

    if (candidates.length === 0) return [];

    const withAdditions = candidates.find((items) =>
      items.some((item: any) =>
        Array.isArray(item?.additions) ||
        Array.isArray(item?.options) ||
        Array.isArray(item?.order_item_additions)
      )
    );

    return withAdditions || candidates[0];
  };

  const getItemAdditions = (item: any) => {
    const candidates = [item?.additions, item?.options, item?.order_item_additions];
    for (const additions of candidates) {
      if (Array.isArray(additions) && additions.length > 0) {
        return additions;
      }
    }
    return [];
  };

  const normalizeOrderItem = (item: any) => {
    return {
      name: item?.name ?? item?.menu_item?.nom ?? item?.menu_item_name ?? 'Article',
      quantity: item?.quantity ?? item?.quantite ?? item?.qty ?? null,
      price: item?.price ?? item?.prix ?? item?.prix_unitaire ?? item?.unit_price ?? null,
      total: item?.total ?? item?.prix_total ?? item?.line_total ?? null,
      additions: getItemAdditions(item)
    };
  };

  const normalizeAddition = (addition: any) => {
    return {
      name: addition?.name ?? addition?.nom ?? addition?.addition?.nom ?? 'Addition',
      quantity: addition?.quantity ?? addition?.quantite ?? addition?.qty ?? 1,
      price: addition?.price ?? addition?.prix ?? addition?.prix_unitaire ?? addition?.addition?.prix ?? null,
      total: addition?.total ?? addition?.prix_total ?? null
    };
  };

  const orderItems = getOrderItemsForNotification(selectedNotification);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div className="max-w-none mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-3">
                Notifications Admin
              </h1>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {filteredNotifications.length} notification
                {filteredNotifications.length > 1 ? 's' : ''} trouvee
                {filteredNotifications.length > 1 ? 's' : ''}
              </p>
            </div>
            <button
              onClick={fetchNotifications}
              disabled={loading}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors flex items-center gap-2"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              {loading ? 'Chargement...' : 'Actualiser'}
            </button>
          </div>

          {/* Statistics Cards */}
          <div className="mt-6 grid grid-cols-2 md:grid-cols-5 gap-4">
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-blue-600 font-medium">Total</p>
                  <p className="text-2xl font-bold text-blue-900">{stats.total}</p>
                </div>
                <Bell className="w-8 h-8 text-blue-400" />
              </div>
            </div>

            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-red-600 font-medium">Non lues</p>
                  <p className="text-2xl font-bold text-red-900">{stats.unread}</p>
                </div>
                <BellOff className="w-8 h-8 text-red-400" />
              </div>
            </div>

            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-yellow-600 font-medium">Non resolues</p>
                  <p className="text-2xl font-bold text-yellow-900">{stats.unresolved}</p>
                </div>
                <AlertCircle className="w-8 h-8 text-yellow-400" />
              </div>
            </div>

            <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-orange-600 font-medium">Commandes</p>
                  <p className="text-2xl font-bold text-orange-900">{stats.pending_timeout}</p>
                </div>
                <Clock className="w-8 h-8 text-orange-400" />
              </div>
            </div>

            <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-purple-600 font-medium">Livreurs</p>
                  <p className="text-2xl font-bold text-purple-900">{stats.driver_cancellations}</p>
                </div>
                <Truck className="w-8 h-8 text-purple-400" />
              </div>
            </div>
          </div>

          {/* Error message */}
          {error && !showModal && (
            <div className="mt-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-sm font-medium text-red-800">Erreur</p>
                <p className="text-sm text-red-700 mt-1">{error}</p>
              </div>
            </div>
          )}

          {/* Search and Filters */}
          <div className="mt-6 flex flex-col sm:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Rechercher par message ou numero de commande..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none"
              />
            </div>
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value as typeof filterType)}
              className="px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none bg-white"
            >
              <option value="all">Tous les types</option>
              <option value="pending_order_timeout">Commandes en attente</option>
              <option value="restaurant_preparation_timeout">Preparation restaurant en retard</option>
              <option value="driver_arrival_timeout">Arrivee livreur en retard</option>
              <option value="restaurant_unresponsive">Restaurant ne repond pas</option>
              <option value="driver_unresponsive">Livreur ne repond pas</option>
              <option value="driver_excessive_cancellations">Annulations livreurs</option>
              <option value="order_admin_review_required">Commande a valider</option>
            </select>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value as typeof filterStatus)}
              className="px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none bg-white"
            >
              <option value="all">Tous les statuts</option>
              <option value="unread">Non lues</option>
              <option value="read">Lues</option>
              <option value="unresolved">Non resolues</option>
              <option value="resolved">Resolues</option>
            </select>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-none mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
          </div>
        ) : filteredNotifications.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            <BellOff className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Aucune notification
            </h3>
            <p className="text-sm text-gray-500">
              {searchTerm || filterType !== 'all' || filterStatus !== 'all'
                ? 'Aucune notification ne correspond a vos criteres'
                : 'Tout est calme pour le moment'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,360px)_minmax(0,1fr)] gap-4">
            <div
              className={`bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden ${
                showList ? 'block' : 'hidden'
              } lg:block`}
            >
              <div className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
                <div className="text-sm font-semibold text-gray-900">Toutes les notifications</div>
                <span className="text-xs text-gray-500">{sortedNotifications.length}</span>
              </div>
              <div className="max-h-none overflow-visible lg:max-h-[calc(100vh-260px)] lg:overflow-y-auto">
                {sortedNotifications.map((notification) => {
                  const isSelected = selectedNotification?.id === notification.id;
                  return (
                    <div
                      key={notification.id}
                      id={`notif-${notification.id}`}
                      onClick={() => handleSelectNotification(notification)}
                      className={`cursor-pointer px-4 py-3 border-b border-gray-100 transition-colors ${
                        isSelected ? 'bg-green-50 border-l-4 border-green-500' : 'hover:bg-gray-50'
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div
                          className={`flex-shrink-0 w-9 h-9 rounded-lg flex items-center justify-center border ${getNotificationColor(
                            notification.type
                          )}`}
                        >
                          {getNotificationIcon(notification.type)}
                        </div>

                        <div className="min-w-0 flex-1">
                          <div className="flex items-start justify-between gap-3">
                            <div>
                              <p className="text-xs uppercase tracking-wide text-gray-400">
                                {getNotificationTitle(notification.type)}
                              </p>
                              <p className="text-sm text-gray-700 line-clamp-2">
                                {getCompactSummary(notification)}
                              </p>
                            </div>
                            <div className="flex flex-col items-end gap-1">
                              <span className="text-[11px] text-gray-400 whitespace-nowrap">
                                {formatDate(notification.created_at)}
                              </span>
                              <div className="flex flex-wrap gap-1 justify-end">
                                {!notification.is_read && (
                                  <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-red-100 text-red-700">
                                    Nouveau
                                  </span>
                                )}
                                {notification.is_resolved && (
                                  <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-green-100 text-green-700 flex items-center gap-1">
                                    <CheckCircle className="w-3 h-3" />
                                    Resolu
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>

                          <div className="mt-2 flex items-center gap-2">
                            <button
                              onClick={(event) => {
                                event.stopPropagation();
                                handleSelectNotification(notification);
                              }}
                              className="px-3 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded-full hover:bg-gray-200 transition-colors flex items-center gap-1"
                            >
                              <Eye className="w-3.5 h-3.5" />
                              Details
                            </button>
                            {!notification.is_read && (
                              <span className="text-[11px] text-gray-400">Non lue</span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div
              className={`bg-white rounded-xl border border-gray-200 shadow-sm p-4 sm:p-6 max-h-none overflow-visible lg:max-h-[calc(100vh-260px)] lg:overflow-y-auto ${
                showDetails ? 'block' : 'hidden'
              } lg:block`}
            >
              {!selectedNotification ? (
                <div className="h-full flex flex-col items-center justify-center text-gray-500 text-sm gap-2">
                  <Eye className="w-6 h-6 text-gray-300" />
                  <p>Selectionnez une notification pour voir les details.</p>
                </div>
              ) : (
                <div className="space-y-6">
                  {isMobile && (
                    <button
                      onClick={() => setMobileView('list')}
                      className="inline-flex items-center gap-2 text-sm font-medium text-gray-600 hover:text-gray-900"
                    >
                      <ArrowLeft className="w-4 h-4" />
                      Retour a la liste
                    </button>
                  )}
                  <div className="flex flex-wrap items-start justify-between gap-4">
                    <div>
                      <span
                        className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getNotificationColor(
                          selectedNotification.type
                        )}`}
                      >
                        {getNotificationIcon(selectedNotification.type)}
                        <span className="ml-2">{getNotificationTitle(selectedNotification.type)}</span>
                      </span>
                      <div className="mt-2 text-xs text-gray-500">
                        Creee: {formatDate(selectedNotification.created_at)} | Mise a jour:{' '}
                        {formatDate(selectedNotification.updated_at)}
                      </div>
                      <div className="mt-2 flex flex-wrap gap-2">
                        {!selectedNotification.is_read && (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-red-100 text-red-700">
                            Nouveau
                          </span>
                        )}
                        {selectedNotification.is_resolved && (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-green-100 text-green-700 flex items-center gap-1">
                            <CheckCircle className="w-3 h-3" />
                            Resolu
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-2">
                      {!selectedNotification.is_read && (
                        <button
                          onClick={() => handleMarkAsRead(selectedNotification.id)}
                          className="px-3 py-2 text-xs font-semibold bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors flex items-center gap-2"
                        >
                          <CheckCircle className="w-4 h-4" />
                          Marquer comme lu
                        </button>
                      )}

                      {!selectedNotification.is_resolved && (
                        <button
                          onClick={() => handleAction(selectedNotification, 'resolve')}
                          className="px-3 py-2 text-xs font-semibold bg-purple-50 text-purple-700 rounded-lg hover:bg-purple-100 transition-colors flex items-center gap-2"
                        >
                          <Archive className="w-4 h-4" />
                          Resoudre
                        </button>
                      )}

                      {selectedNotification.type === 'order_admin_review_required' && (
                        <button
                          onClick={() => router.push('/admin/review-queue')}
                          className="px-3 py-2 text-xs font-semibold bg-amber-50 text-amber-700 rounded-lg hover:bg-amber-100 transition-colors flex items-center gap-2"
                        >
                          <ArrowRight className="w-4 h-4" />
                          Ouvrir validation client
                        </button>
                      )}

                      {!selectedNotification.is_resolved && selectedNotification.order_id && selectedNotification.type !== 'order_admin_review_required' && (
                        <>
                          <button
                            onClick={() => handleAction(selectedNotification, 'force-accept')}
                            className="px-3 py-2 text-xs font-semibold bg-green-50 text-green-700 rounded-lg hover:bg-green-100 transition-colors flex items-center gap-2"
                          >
                            <ThumbsUp className="w-4 h-4" />
                            Accepter
                          </button>
                          <button
                            onClick={() => handleAction(selectedNotification, 'force-cancel')}
                            className="px-3 py-2 text-xs font-semibold bg-red-50 text-red-700 rounded-lg hover:bg-red-100 transition-colors flex items-center gap-2"
                          >
                            <ThumbsDown className="w-4 h-4" />
                            Annuler
                          </button>
                        </>
                      )}
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Message</label>
                    <p className="text-sm text-gray-900 whitespace-pre-line p-3 bg-gray-50 rounded-lg">
                      {selectedNotification.message}
                    </p>
                  </div>

                  {selectedNotification.order_details && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Details de la commande
                      </label>
                      <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 p-4">
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
                          {selectedNotification.order_details?.order_number && (
                            <div>
                              <p className="text-xs text-gray-500">Commande</p>
                              <p className="font-semibold text-gray-900">
                                {selectedNotification.order_details.order_number}
                              </p>
                            </div>
                          )}
                          {selectedNotification.order_details?.order_type && (
                            <div>
                              <p className="text-xs text-gray-500">Type</p>
                              <p className="font-semibold text-gray-900">
                                {selectedNotification.order_details.order_type}
                              </p>
                            </div>
                          )}
                          {(selectedNotification.order_details?.total_amount ?? null) !== null && (
                            <div>
                              <p className="text-xs text-gray-500">Montant</p>
                              <p className="font-semibold text-gray-900">
                                {selectedNotification.order_details.total_amount} DA
                              </p>
                            </div>
                          )}
                          {selectedNotification.order_details?.created_at && (
                            <div>
                              <p className="text-xs text-gray-500">Creee</p>
                              <p className="font-semibold text-gray-900">
                                {formatDate(selectedNotification.order_details.created_at)}
                              </p>
                            </div>
                          )}
                          {selectedNotification.order_details?.delivery_address && (
                            <div className="sm:col-span-2">
                              <p className="text-xs text-gray-500">Adresse de livraison</p>
                              <p className="font-semibold text-gray-900 break-words">
                                {selectedNotification.order_details.delivery_address}
                              </p>
                            </div>
                          )}
                          {selectedNotification.order_details?.client?.name && (
                            <div>
                              <p className="text-xs text-gray-500">Client</p>
                              <p className="font-semibold text-gray-900">
                                {selectedNotification.order_details.client.name}
                              </p>
                            </div>
                          )}
                          {selectedNotification.order_details?.client?.phone && (
                            <div>
                              <p className="text-xs text-gray-500">Telephone</p>
                              <p className="font-semibold text-gray-900">
                                {selectedNotification.order_details.client.phone}
                              </p>
                            </div>
                          )}
                          {selectedNotification.order_details?.client?.address && (
                            <div className="sm:col-span-2">
                              <p className="text-xs text-gray-500">Adresse client</p>
                              <p className="font-semibold text-gray-900 break-words">
                                {selectedNotification.order_details.client.address}
                              </p>
                            </div>
                          )}
                        </div>

                        {orderItems.length > 0 && (
                          <div className="mt-4 border-t border-gray-200 pt-4">
                            <p className="text-xs font-medium text-gray-500 mb-3">Contenu de la commande</p>
                            <div className="space-y-2">
                              {orderItems.map((item: any, index: number) => {
                                const normalized = normalizeOrderItem(item);
                                const additions = Array.isArray(normalized.additions)
                                  ? normalized.additions.map(normalizeAddition)
                                  : [];
                                return (
                                  <div
                                    key={`${normalized.name || 'item'}-${index}`}
                                    className="flex items-start justify-between gap-3"
                                  >
                                    <div className="min-w-0">
                                      <p className="text-sm font-medium text-gray-900 break-words">
                                        {normalized.name}
                                      </p>
                                      {(normalized.quantity || normalized.price) && (
                                        <p className="text-xs text-gray-500">
                                          {normalized.quantity ? `Qte: ${normalized.quantity}` : null}
                                          {normalized.quantity && normalized.price ? ' * ' : null}
                                          {normalized.price ? `Prix: ${normalized.price} DA` : null}
                                        </p>
                                      )}
                                      {additions.length > 0 && (
                                        <div className="mt-1 space-y-1">
                                          {additions.map((add, addIndex) => (
                                            <div
                                              key={`${add.name || 'add'}-${addIndex}`}
                                              className="text-xs text-gray-500"
                                            >
                                              + {add.name}
                                              {add.quantity && add.quantity !== 1 ? ` x${add.quantity}` : ''}
                                              {add.total !== null && add.total !== undefined
                                                ? ` (${add.total} DA)`
                                                : add.price !== null && add.price !== undefined
                                                ? ` (${add.price} DA)`
                                                : ''}
                                            </div>
                                          ))}
                                        </div>
                                      )}
                                    </div>
                                    {normalized.total !== undefined && normalized.total !== null && (
                                      <p className="text-sm font-semibold text-gray-900 whitespace-nowrap">
                                        {normalized.total} DA
                                      </p>
                                    )}
                                  </div>
                                );
                              })}
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  {selectedNotification.restaurant_info && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Informations Restaurant
                      </label>
                      <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 p-4">
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
                          {selectedNotification.restaurant_info?.name && (
                            <div>
                              <p className="text-xs text-gray-500">Restaurant</p>
                              <p className="font-semibold text-gray-900">
                                {selectedNotification.restaurant_info.name}
                              </p>
                            </div>
                          )}
                          {selectedNotification.restaurant_info?.phone && (
                            <div>
                              <p className="text-xs text-gray-500">Telephone</p>
                              <p className="font-semibold text-gray-900">
                                {selectedNotification.restaurant_info.phone}
                              </p>
                            </div>
                          )}
                          {selectedNotification.restaurant_info?.email && (
                            <div>
                              <p className="text-xs text-gray-500">Email</p>
                              <p className="font-semibold text-gray-900 break-words">
                                {selectedNotification.restaurant_info.email}
                              </p>
                            </div>
                          )}
                          {selectedNotification.restaurant_info?.address && (
                            <div className="sm:col-span-2">
                              <p className="text-xs text-gray-500">Adresse</p>
                              <p className="font-semibold text-gray-900 break-words">
                                {selectedNotification.restaurant_info.address}
                              </p>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  )}

                  {selectedNotification.is_resolved && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Resolution
                      </label>
                      <div className="p-3 bg-green-50 rounded-lg border border-green-200">
                        <p className="text-sm text-green-800">
                          <strong>Action:</strong> {selectedNotification.admin_action || 'Aucune'}
                        </p>
                        {selectedNotification.admin_notes && (
                          <p className="text-sm text-green-800 mt-2">
                            <strong>Notes:</strong> {selectedNotification.admin_notes}
                          </p>
                        )}
                        {selectedNotification.resolved_at && (
                          <p className="text-xs text-green-700 mt-2">
                            Resolu le {formatDate(selectedNotification.resolved_at)}
                          </p>
                        )}
                      </div>
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Informations techniques
                    </label>
                    <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 p-4">
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
                        <div>
                          <p className="text-xs text-gray-500">ID Notification</p>
                          <p className="font-semibold text-gray-900 break-words">
                            {selectedNotification.id}
                          </p>
                        </div>
                        {selectedNotification.order_id && (
                          <div>
                            <p className="text-xs text-gray-500">ID Commande</p>
                            <p className="font-semibold text-gray-900 break-words">
                              {selectedNotification.order_id}
                            </p>
                          </div>
                        )}
                        {selectedNotification.restaurant_id && (
                          <div>
                            <p className="text-xs text-gray-500">ID Restaurant</p>
                            <p className="font-semibold text-gray-900 break-words">
                              {selectedNotification.restaurant_id}
                            </p>
                          </div>
                        )}
                        {selectedNotification.driver_id && (
                          <div>
                            <p className="text-xs text-gray-500">ID Livreur</p>
                            <p className="font-semibold text-gray-900 break-words">
                              {selectedNotification.driver_id}
                            </p>
                          </div>
                        )}
                        <div>
                          <p className="text-xs text-gray-500">Creee</p>
                          <p className="font-semibold text-gray-900">
                            {formatDate(selectedNotification.created_at)}
                          </p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500">Mise a jour</p>
                          <p className="font-semibold text-gray-900">
                            {formatDate(selectedNotification.updated_at)}
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
      {/* Modal */}
      {showModal && selectedNotification && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between sticky top-0 bg-white z-10">
              <h2 className="text-xl font-bold text-gray-900">
                
                {modalType === 'resolve' && 'Resoudre la Notification'}
                {modalType === 'force-accept' && 'Accepter la Commande de Force'}
                {modalType === 'force-cancel' && 'Annuler la Commande'}
              </h2>
              <button
                onClick={handleCloseModal}
                className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100"
              >
                oe*
              </button>
            </div>

            {/* Content */}
            <div className="px-6 py-4">
              {error && (
                <div className="mb-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-red-800">Erreur</p>
                    <p className="text-sm text-red-700 mt-1">{error}</p>
                  </div>
                </div>
              )}

              {modalType === 'resolve' && (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Action effectuee
                    </label>
                    <select
                      value={resolveAction}
                      onChange={(e) => setResolveAction(e.target.value as AdminAction)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    >
                      <option value="none">Aucune action specifique</option>
                      <option value="force_accept">Commande acceptee de force</option>
                      <option value="cancel_order">Commande annulee</option>
                      <option value="contacted_restaurant">Restaurant contacte</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Notes (optionnel)
                    </label>
                    <textarea
                      value={resolveNotes}
                      onChange={(e) => setResolveNotes(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                      rows={4}
                      placeholder="Ajoutez des notes sur la resolution de cette notification..."
                    />
                  </div>
                </div>
              )}

              {modalType === 'force-accept' && (
                <div className="space-y-4">
                  <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <p className="text-sm text-yellow-800">
                      s i Vous allez accepter cette commande de force au nom du restaurant.
                      Le restaurant sera notifie de cette action.
                    </p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Temps de preparation (minutes)
                    </label>
                    <input
                      type="number"
                      value={forceAcceptTime}
                      onChange={(e) => setForceAcceptTime(Number(e.target.value))}
                      min="5"
                      max="120"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    />
                  </div>

                  {selectedNotification.order_details && (
                    <div className="p-3 bg-gray-50 rounded-lg">
                      <p className="text-sm text-gray-700">
                        <strong>Commande:</strong> {selectedNotification.order_details.order_number}
                      </p>
                      <p className="text-sm text-gray-700">
                        <strong>Montant:</strong> {selectedNotification.order_details.total_amount} DA
                      </p>
                    </div>
                  )}
                </div>
              )}

              {modalType === 'force-cancel' && (
                <div className="space-y-4">
                  <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                    <p className="text-sm text-red-800">
                      s i Vous allez annuler cette commande. Cette action est irreversible.
                      Le client et le restaurant seront notifies.
                    </p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Raison de l&apos;annulation <span className="text-red-500">*</span>
                    </label>
                    <textarea
                      value={forceCancelReason}
                      onChange={(e) => setForceCancelReason(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                      rows={4}
                      placeholder="Expliquez la raison de l&apos;annulation..."
                      required
                    />
                  </div>

                  {selectedNotification.order_details && (
                    <div className="p-3 bg-gray-50 rounded-lg">
                      <p className="text-sm text-gray-700">
                        <strong>Commande:</strong> {selectedNotification.order_details.order_number}
                      </p>
                      <p className="text-sm text-gray-700">
                        <strong>Montant:</strong> {selectedNotification.order_details.total_amount} DA
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-3">
              <button
                onClick={handleCloseModal}
                disabled={actionLoading}
                className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors disabled:opacity-50"
              >
                Annuler
              </button>
              {modalType === 'resolve' && (
                <button
                  onClick={handleResolve}
                  disabled={actionLoading}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 flex items-center gap-2"
                >
                  {actionLoading ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      Resolution...
                    </>
                  ) : (
                    <>
                      <CheckCircle className="w-4 h-4" />
                      Resoudre
                    </>
                  )}
                </button>
              )}
              {modalType === 'force-accept' && (
                <button
                  onClick={handleForceAccept}
                  disabled={actionLoading}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 flex items-center gap-2"
                >
                  {actionLoading ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      Acceptation...
                    </>
                  ) : (
                    <>
                      <ThumbsUp className="w-4 h-4" />
                      Accepter de Force
                    </>
                  )}
                </button>
              )}
              {modalType === 'force-cancel' && (
                <button
                  onClick={handleForceCancel}
                  disabled={actionLoading || !forceCancelReason.trim()}
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center gap-2"
                >
                  {actionLoading ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      Annulation...
                    </>
                  ) : (
                    <>
                      <XCircle className="w-4 h-4" />
                      Annuler la Commande
                    </>
                  )}
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}


