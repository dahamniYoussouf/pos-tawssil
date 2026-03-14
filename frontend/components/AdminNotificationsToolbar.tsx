'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Bell,
  Ban,
  CheckCircle,
  Clock,
  Eye,
  Store,
  Truck
} from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

type NotificationType =
  | 'pending_order_timeout'
  | 'restaurant_preparation_timeout'
  | 'driver_arrival_timeout'
  | 'restaurant_unresponsive'
  | 'driver_unresponsive'
  | 'driver_excessive_cancellations';

type Category = 'all' | 'orders' | 'restaurants' | 'drivers';

interface AdminNotification {
  id: string;
  order_id?: string;
  restaurant_id?: string;
  driver_id?: string;
  type: NotificationType;
  message: string;
  order_details?: {
    order_number?: string;
    total_amount?: number;
    client?: {
      name?: string;
      phone?: string;
    };
  };
  restaurant_info?: {
    name?: string;
    phone?: string;
  };
  order?: any;
  restaurant?: any;
  driver?: any;
  is_read: boolean;
  is_resolved: boolean;
  created_at: string;
}

const CATEGORY_CONFIG: Record<
  Category,
  { label: string; icon: typeof Bell; types: NotificationType[] }
> = {
  all: {
    label: 'Tout',
    icon: Bell,
    types: [
      'pending_order_timeout',
      'restaurant_preparation_timeout',
      'driver_arrival_timeout',
      'restaurant_unresponsive',
      'driver_unresponsive',
      'driver_excessive_cancellations'
    ]
  },
  orders: {
    label: 'Commandes',
    icon: Clock,
    types: ['pending_order_timeout']
  },
  restaurants: {
    label: 'Restaurants',
    icon: Store,
    types: ['restaurant_unresponsive', 'restaurant_preparation_timeout']
  },
  drivers: {
    label: 'Livreurs',
    icon: Truck,
    types: ['driver_unresponsive', 'driver_excessive_cancellations', 'driver_arrival_timeout']
  }
};

const formatTimeAgo = (dateString: string) => {
  const createdAt = new Date(dateString).getTime();
  if (!Number.isFinite(createdAt)) return '';

  const diffSeconds = Math.floor((Date.now() - createdAt) / 1000);
  if (diffSeconds < 60) return "A l'instant";
  const diffMinutes = Math.floor(diffSeconds / 60);
  if (diffMinutes < 60) return `Il y a ${diffMinutes} min`;
  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) return `Il y a ${diffHours} h`;
  const diffDays = Math.floor(diffHours / 24);
  return `Il y a ${diffDays} j`;
};

const getTypeIcon = (type: NotificationType) => {
  switch (type) {
    case 'pending_order_timeout':
      return Clock;
    case 'restaurant_unresponsive':
      return Store;
    case 'restaurant_preparation_timeout':
      return Store;
    case 'driver_excessive_cancellations':
      return Ban;
    case 'driver_unresponsive':
    case 'driver_arrival_timeout':
    default:
      return Truck;
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
    default:
      return 'Notification';
  }
};

const getOrderMeta = (notification: AdminNotification) => {
  const order = notification.order_details ?? notification.order;
  return {
    orderNumber: order?.order_number ?? order?.number ?? order?.code,
    totalAmount: order?.total_amount ?? order?.total,
    clientName: order?.client?.name ?? order?.customer?.name,
    clientPhone: order?.client?.phone ?? order?.customer?.phone
  };
};

const getRestaurantMeta = (notification: AdminNotification) => {
  const restaurant = notification.restaurant_info ?? notification.restaurant;
  return {
    name: restaurant?.name,
    phone: restaurant?.phone
  };
};

export default function AdminNotificationsToolbar() {
  const router = useRouter();
  const wrapperRef = useRef<HTMLDivElement | null>(null);
  const [openCategory, setOpenCategory] = useState<Category | null>(null);
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const [loading, setLoading] = useState(false);

  const unread = useMemo(
    () => notifications.filter((n) => !n.is_read),
    [notifications]
  );

  const counts = useMemo(() => {
    const result: Record<Category, number> = {
      all: 0,
      orders: 0,
      restaurants: 0,
      drivers: 0
    };

    for (const notification of unread) {
      result.all++;
      if (CATEGORY_CONFIG.orders.types.includes(notification.type)) result.orders++;
      else if (CATEGORY_CONFIG.restaurants.types.includes(notification.type)) result.restaurants++;
      else result.drivers++;
    }

    return result;
  }, [unread]);

  const visibleList = useMemo(() => {
    if (!openCategory) return [];
    const allowed = CATEGORY_CONFIG[openCategory].types;
    return unread
      .filter((n) => allowed.includes(n.type))
      .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
      .slice(0, 8);
  }, [openCategory, unread]);

  const fetchUnreadNotifications = async () => {
    const token = localStorage.getItem('access_token') || localStorage.getItem('token');
    if (!token) return;

    try {
      setLoading(true);
      const response = await fetch(`${API_URL}/admin/notifications?is_read=false`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) return;
      const data = await response.json().catch(() => null);
      const list = (data?.data || []) as AdminNotification[];
      setNotifications(list);
    } catch (error) {
      console.warn('Failed to fetch admin notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const markAsRead = async (notificationId: string) => {
    const token = localStorage.getItem('access_token') || localStorage.getItem('token');
    if (!token) return;

    try {
      const response = await fetch(`${API_URL}/admin/notifications/${notificationId}/read`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) return;
      setNotifications((prev) => prev.map((n) => (n.id === notificationId ? { ...n, is_read: true } : n)));
    } catch (error) {
      console.warn('Failed to mark admin notification as read:', error);
    }
  };

  const handleOpenDetails = (notificationId: string) => {
    router.push(`/admin/notifications?selected=${notificationId}`);
    setOpenCategory(null);
  };

  useEffect(() => {
    fetchUnreadNotifications();
    const interval = window.setInterval(fetchUnreadNotifications, 20_000);
    return () => window.clearInterval(interval);
  }, []);

  useEffect(() => {
    const handlePointerDown = (event: MouseEvent) => {
      if (!wrapperRef.current) return;
      if (!openCategory) return;
      if (wrapperRef.current.contains(event.target as Node)) return;
      setOpenCategory(null);
    };

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setOpenCategory(null);
      }
    };

    document.addEventListener('mousedown', handlePointerDown);
    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('mousedown', handlePointerDown);
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [openCategory]);

  const buttons: Category[] = ['orders', 'restaurants', 'drivers'];

  return (
    <div ref={wrapperRef} className="relative flex items-center gap-2">
      {buttons.map((category) => {
        const Icon = CATEGORY_CONFIG[category].icon;
        const isOpen = openCategory === category;
        const count = counts[category];

        return (
          <button
            key={`notif-${category}`}
            type="button"
            onClick={() => setOpenCategory((prev) => (prev === category ? null : category))}
            className={`relative p-2 rounded-lg transition-colors ${
              isOpen
                ? 'bg-gray-100 dark:bg-slate-700 text-gray-900 dark:text-slate-100'
                : 'text-gray-600 dark:text-slate-300 hover:text-gray-900 dark:hover:text-slate-100 hover:bg-gray-100 dark:hover:bg-slate-700'
            }`}
            title={`Notifications ${CATEGORY_CONFIG[category].label}`}
            aria-label={`Notifications ${CATEGORY_CONFIG[category].label}`}
          >
            <Icon className="w-5 h-5" />
            {count > 0 && (
              <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-red-600 text-white text-[11px] font-bold flex items-center justify-center shadow">
                {count > 99 ? '99+' : count}
              </span>
            )}
          </button>
        );
      })}

      {openCategory && (
        <div className="absolute right-0 top-[calc(100%+8px)] w-[360px] max-w-[85vw] bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl shadow-xl overflow-hidden z-50">
          <div className="px-4 py-3 border-b border-gray-200 dark:border-slate-700 flex items-center justify-between">
            <div className="flex items-center gap-2">
              {(() => {
                const Icon = CATEGORY_CONFIG[openCategory].icon;
                return <Icon className="w-4 h-4 text-gray-700 dark:text-slate-200" />;
              })()}
              <div className="text-sm font-semibold text-gray-900 dark:text-slate-100">
                {CATEGORY_CONFIG[openCategory].label}
              </div>
              {counts[openCategory] > 0 && (
                <span className="text-xs font-semibold text-gray-500 dark:text-slate-400">
                  ({counts[openCategory]})
                </span>
              )}
            </div>

            <button
              type="button"
              onClick={() => {
                router.push('/admin/notifications');
                setOpenCategory(null);
              }}
              className="text-xs font-semibold text-green-700 dark:text-green-400 hover:underline"
            >
              Voir tout
            </button>
          </div>

          <div className="max-h-[360px] overflow-y-auto">
            {loading && (
              <div className="px-4 py-3 text-sm text-gray-500 dark:text-slate-400">
                Chargement...
              </div>
            )}

            {!loading && visibleList.length === 0 && (
              <div className="px-4 py-6 text-sm text-gray-500 dark:text-slate-400">
                Aucune notification non lue.
              </div>
            )}

            {!loading &&
              visibleList.map((notification) => (
                <div
                  key={notification.id}
                  className="px-4 py-3 border-b border-gray-100 dark:border-slate-700/60 hover:bg-gray-50 dark:hover:bg-slate-700/40 transition-colors cursor-pointer"
                  role="button"
                  tabIndex={0}
                  onClick={() => handleOpenDetails(notification.id)}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      handleOpenDetails(notification.id);
                    }
                  }}
                >
                  <div className="flex items-start gap-3">
                    <div className="mt-0.5">
                      {(() => {
                        const Icon = getTypeIcon(notification.type);
                        return <Icon className="w-4 h-4 text-gray-400" />;
                      })()}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="text-[11px] uppercase tracking-wide text-gray-400">
                        {getNotificationTitle(notification.type)}
                      </div>
                      <div className="text-sm text-gray-900 dark:text-slate-100 leading-snug">
                        {notification.message}
                      </div>
                      {(() => {
                        const orderMeta = getOrderMeta(notification);
                        const restaurantMeta = getRestaurantMeta(notification);
                        const hasMeta =
                          orderMeta.orderNumber ||
                          orderMeta.clientName ||
                          restaurantMeta.name ||
                          orderMeta.totalAmount;
                        if (!hasMeta) return null;
                        return (
                          <div className="mt-2 flex flex-wrap gap-2 text-xs text-gray-500 dark:text-slate-400">
                            {orderMeta.orderNumber && (
                              <span className="px-2 py-0.5 rounded-md bg-gray-100 dark:bg-slate-700/60">
                                Cmd: {orderMeta.orderNumber}
                              </span>
                            )}
                            {orderMeta.totalAmount !== undefined && orderMeta.totalAmount !== null && (
                              <span className="px-2 py-0.5 rounded-md bg-gray-100 dark:bg-slate-700/60">
                                {orderMeta.totalAmount} DA
                              </span>
                            )}
                            {restaurantMeta.name && (
                              <span className="px-2 py-0.5 rounded-md bg-gray-100 dark:bg-slate-700/60">
                                Resto: {restaurantMeta.name}
                              </span>
                            )}
                            {orderMeta.clientName && (
                              <span className="px-2 py-0.5 rounded-md bg-gray-100 dark:bg-slate-700/60">
                                Client: {orderMeta.clientName}
                              </span>
                            )}
                          </div>
                        );
                      })()}
                      <div className="mt-1 text-xs text-gray-500 dark:text-slate-400">
                        {formatTimeAgo(notification.created_at)}
                      </div>

                      <div className="mt-2 flex items-center gap-2">
                        <button
                          type="button"
                          onClick={(event) => {
                            event.stopPropagation();
                            markAsRead(notification.id);
                          }}
                          className="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-slate-200 text-xs font-semibold hover:bg-gray-200 dark:hover:bg-slate-600 transition-colors"
                          title="Marquer comme lu"
                        >
                          <CheckCircle className="w-4 h-4" />
                          Lu
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            handleOpenDetails(notification.id);
                          }}
                          className="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-300 text-xs font-semibold hover:bg-green-100 dark:hover:bg-green-900/30 transition-colors"
                          title="Voir dans la page notifications"
                        >
                          <Eye className="w-4 h-4" />
                          Details
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
          </div>
        </div>
      )}
    </div>
  );
}
