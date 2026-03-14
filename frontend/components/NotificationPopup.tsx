'use client';

import { useState, useEffect, useRef } from 'react';
import { 
  Bell, 
  X, 
  CheckCircle, 
  Clock, 
  Store, 
  Truck, 
  Ban,
  Eye
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import { initializeApp, getApps } from 'firebase/app';
import { deleteToken, getMessaging, getToken, isSupported, onMessage } from 'firebase/messaging';
import { useAuth } from '@/contexts/AuthContext';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
const FIREBASE_CONFIG = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};
const FIREBASE_VAPID_KEY = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY || '';
const PROFILE_LOCALE_STORAGE_KEY = 'profile_locale';

interface NotificationData {
  id: string;
  type:
    | 'pending_order_timeout'
    | 'restaurant_preparation_timeout'
    | 'driver_arrival_timeout'
    | 'restaurant_unresponsive'
    | 'driver_unresponsive'
    | 'driver_excessive_cancellations';
  message: string;
  order?: any;
  restaurant?: any;
  driver?: any;
  created_at: string;
}

interface NotificationPopupProps {
  onViewDetails?: (notificationId: string) => void;
}

export default function NotificationPopup({ onViewDetails }: NotificationPopupProps) {
  const [notifications, setNotifications] = useState<NotificationData[]>([]);
  const [actionLoading, setActionLoading] = useState<Record<string, boolean>>({});
  const fcmInitialized = useRef(false);
  const fcmTokenRef = useRef<string | null>(null);
  const { token: authToken } = useAuth();
  const router = useRouter();
  const hasFirebaseConfig = Object.values(FIREBASE_CONFIG).every(Boolean);

  const logFcmDiag = (stage: string, extra?: Record<string, unknown>) => {
    if (typeof window === 'undefined') return;
    console.info('[FCM]', stage, {
      origin: window.location?.origin,
      secureContext: window.isSecureContext,
      permission: 'Notification' in window ? Notification.permission : 'missing',
      hasServiceWorker: !!navigator.serviceWorker,
      hasConfig: hasFirebaseConfig,
      hasVapid: !!FIREBASE_VAPID_KEY,
      ...extra
    });
  };

  const normalizeError = (error: any) => ({
    name: error?.name,
    message: error?.message,
    code: error?.code,
    stack: error?.stack
  });

  const pushNotification = (data: NotificationData) => {
    setNotifications((prev) => {
      if (prev.some((item) => item.id === data.id)) return prev;
      return [...prev, data];
    });
  };

  const removeNotification = (id: string) => {
    setNotifications((prev) => prev.filter((item) => item.id !== id));
    setActionLoading((prev) => {
      if (!prev[id]) return prev;
      const next = { ...prev };
      delete next[id];
      return next;
    });
  };

  useEffect(() => {
    if (!authToken) return;
    const cachedToken = fcmTokenRef.current || localStorage.getItem('fcm_token');
    if (!cachedToken) return;
    registerDeviceToken(cachedToken, authToken);
  }, [authToken]);

  useEffect(() => {
    const initFcm = async () => {
      if (typeof window === 'undefined') return;
      if (fcmInitialized.current) return;

      const hostname = window.location?.hostname || '';
      const isLocalhost =
        hostname === 'localhost' ||
        hostname === '127.0.0.1' ||
        hostname === '[::1]';
      if (!window.isSecureContext && !isLocalhost) {
        logFcmDiag('insecure-context');
        return;
      }

      if (!hasFirebaseConfig || !FIREBASE_VAPID_KEY) {
        console.warn('Firebase config or VAPID key missing, skipping FCM');
        logFcmDiag('missing-config');
        return;
      }

      if (!('Notification' in window) || !navigator.serviceWorker) return;

      const supported = await isSupported().catch(() => false);
      if (!supported) {
        logFcmDiag('unsupported');
        return;
      }

      try {
        const app = getApps().length ? getApps()[0] : initializeApp(FIREBASE_CONFIG);
        const messaging = getMessaging(app);

        const permission =
          Notification.permission === 'granted'
            ? 'granted'
            : await Notification.requestPermission();
        if (permission !== 'granted') {
          logFcmDiag('permission-not-granted', { permission });
          return;
        }

        const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js', {
          scope: '/'
        });
        await registration.update();

        const readyRegistration = await navigator.serviceWorker.ready.catch(() => null);
        const activeRegistration = readyRegistration || registration;

        if (!activeRegistration?.active) {
          console.warn('Service worker not active yet. Reload the page to finish setup.');
          logFcmDiag('sw-not-active');
          return;
        }

        let token = '';
        try {
          token = await getToken(messaging, {
            vapidKey: FIREBASE_VAPID_KEY,
            serviceWorkerRegistration: activeRegistration
          });
        } catch (tokenError) {
          const normalized = normalizeError(tokenError);
          console.warn('FCM getToken failed:', normalized);
          logFcmDiag('get-token-failed', { error: normalized });

          const shouldRetry =
            normalized?.code === 20 ||
            typeof normalized?.message === 'string' &&
              normalized.message.toLowerCase().includes('push service error');

          if (shouldRetry) {
            try {
              const existingSub = await activeRegistration.pushManager?.getSubscription();
              if (existingSub) {
                await existingSub.unsubscribe();
              }
              try {
                await deleteToken(messaging);
              } catch (_err) {
                // ignore deleteToken failures, we'll retry getToken anyway
              }

              token = await getToken(messaging, {
                vapidKey: FIREBASE_VAPID_KEY,
                serviceWorkerRegistration: activeRegistration
              });
            } catch (retryError) {
              console.warn('FCM getToken retry failed:', normalizeError(retryError));
              logFcmDiag('get-token-retry-failed', { error: normalizeError(retryError) });
              return;
            }
          } else {
            return;
          }
        }

        if (token) {
          fcmTokenRef.current = token;
          localStorage.setItem('fcm_token', token);
          console.info('[FCM] token stored', token.slice(-12));
          const currentAuthToken = authToken || localStorage.getItem('access_token') || localStorage.getItem('token');
          await registerDeviceToken(token, currentAuthToken);
        }

        onMessage(messaging, (payload) => {
          const normalized = normalizePayload(payload);
          pushNotification(normalized);
          try {
            playNotificationSound();
          } catch (e) {
            console.log('Could not play sound:', e);
          }
          if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
            try {
              new Notification('Nouvelle Notification Admin', {
                body: normalized.message,
                icon: '/delivery-notification.svg',
                requireInteraction: true
              });
            } catch (e) {
              console.log('Could not show browser notification:', e);
            }
          }
        });

        fcmInitialized.current = true;
        logFcmDiag('ready');
        console.log('FCM ready for admin dashboard');
      } catch (error) {
        console.warn('FCM init failed:', normalizeError(error));
        logFcmDiag('init-failed');
      }
    };

    // Only run on client side
    if (typeof window !== 'undefined') {
      initFcm();

      // Request browser notification permission
      if ('Notification' in window && Notification.permission === 'default') {
        Notification.requestPermission().catch(err => {
          console.log('Notification permission error:', err);
        });
      }
    }

    return () => {};
  }, []);

  const playNotificationSound = () => {
    if (typeof window === 'undefined') return;
    
    try {
      // Create a simple notification sound
      const AudioContext = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContext) return;
      
      const audioContext = new AudioContext();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      oscillator.frequency.value = 800;
      oscillator.type = 'sine';
      
      gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.3);
    } catch (error) {
      console.log('Could not play notification sound:', error);
    }
  };

  const handleClose = (id: string) => {
    removeNotification(id);
  };

  const handleMarkAsRead = async (id: string) => {
    if (!id) return;

    try {
      setActionLoading((prev) => ({ ...prev, [id]: true }));
      const token = localStorage.getItem('access_token');
      if (!token) throw new Error('Non authentifie');

      const response = await fetch(`${API_URL}/admin/notifications/${id}/read`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        removeNotification(id);
      }
    } catch (error) {
      console.error('Error marking as read:', error);
    } finally {
      setActionLoading((prev) => ({ ...prev, [id]: false }));
    }
  };

  const handleViewDetails = (id: string) => {
    if (!id) return;
    if (onViewDetails) {
      onViewDetails(id);
    } else {
      router.push(`/admin/notifications?selected=${id}`);
    }
    removeNotification(id);
  };

  const getNotificationIcon = (type: string) => {
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
      default:
        return <Bell className="w-5 h-5" />;
    }
  };

  const getNotificationColor = (type: string) => {
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
      default:
        return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  const getNotificationTitle = (type: string) => {
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

  if (notifications.length === 0) return null;

  return (
    <>
      {/* Snackbars */}
      <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-3 items-end">
        {notifications.map((notification) => (
          <div
            key={notification.id}
            role="button"
            tabIndex={0}
            onClick={() => handleViewDetails(notification.id)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                handleViewDetails(notification.id);
              }
            }}
            className="w-full max-w-md bg-white rounded-lg shadow-2xl border border-gray-200 animate-slide-up cursor-pointer"
          >
            <div className="p-4">
              {/* Header */}
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className={`flex-shrink-0 w-10 h-10 rounded-lg flex items-center justify-center border ${getNotificationColor(notification.type)}`}>
                    {getNotificationIcon(notification.type)}
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-gray-900">
                      {getNotificationTitle(notification.type)}
                    </h3>
                    <p className="text-xs text-gray-500 mt-0.5">
                      {new Date(notification.created_at).toLocaleTimeString('fr-FR', {
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </p>
                  </div>
                </div>
                <button
                  onClick={(event) => {
                    event.stopPropagation();
                    handleClose(notification.id);
                  }}
                  className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100 transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Message */}
              <div className="mb-4">
                <p className="text-sm text-gray-700 whitespace-pre-line">
                  {notification.message}
                </p>
              </div>

              {/* Order details if available */}
              {notification.order && (
                <div className="mb-4 p-3 bg-gray-50 rounded-lg border border-gray-200">
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    {notification.order.order_number && (
                      <div>
                        <p className="text-gray-500">Commande</p>
                        <p className="font-semibold text-gray-900">
                          {notification.order.order_number}
                        </p>
                      </div>
                    )}
                    {notification.order.total_amount && (
                      <div>
                        <p className="text-gray-500">Montant</p>
                        <p className="font-semibold text-gray-900">
                          {notification.order.total_amount} DA
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="flex gap-2">
                <button
                  onClick={(event) => {
                    event.stopPropagation();
                    handleViewDetails(notification.id);
                  }}
                  className="flex-1 px-3 py-2 text-sm font-medium bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors flex items-center justify-center gap-2"
                >
                  <Eye className="w-4 h-4" />
                  Voir details
                </button>
                <button
                  onClick={(event) => {
                    event.stopPropagation();
                    handleMarkAsRead(notification.id);
                  }}
                  disabled={!!actionLoading[notification.id]}
                  className="px-3 py-2 text-sm font-medium bg-green-50 text-green-700 rounded-lg hover:bg-green-100 transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  <CheckCircle className="w-4 h-4" />
                  {actionLoading[notification.id] ? '...' : 'Marquer lu'}
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <style jsx>{`
        @keyframes slide-up {
          from {
            transform: translateY(100%);
            opacity: 0;
          }
          to {
            transform: translateY(0);
            opacity: 1;
          }
        }
        .animate-slide-up {
          animation: slide-up 0.3s ease-out;
        }
      `}</style>
    </>
  );
}

const parseMaybeJson = (value: any) => {
  if (typeof value !== 'string') return value;
  try {
    return JSON.parse(value);
  } catch (_err) {
    return value;
  }
};

const normalizePayload = (payload: any): NotificationData => {
  const data = payload?.data ? { ...payload.data } : {};
  const notification = payload?.notification || {};

  const order = parseMaybeJson(data.order || data.order_details || data.order_info);
  const restaurant = parseMaybeJson(data.restaurant || data.restaurant_info);
  const driver = parseMaybeJson(data.driver || data.driver_info);

  return {
    id: data.id || data.notification_id || `fcm-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    type: (data.type as NotificationData['type']) || 'driver_unresponsive',
    message: data.message || data.body || notification.body || 'Nouvelle notification',
    order,
    restaurant,
    driver,
    created_at: data.created_at || new Date().toISOString()
  };
};

const registerDeviceToken = async (token: string, explicitAccessToken?: string | null) => {
  const accessToken =
    explicitAccessToken ||
    localStorage.getItem('access_token') ||
    localStorage.getItem('token');
  if (!accessToken) return;

  try {
    const locale = await resolveLocaleForRegistration(accessToken);
    const response = await fetch(`${API_URL}/notifications/token`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        token,
        platform: 'web',
        locale: locale || undefined
      })
    });
    if (!response.ok) {
      const text = await response.text().catch(() => '');
      console.warn('Failed to register FCM token:', response.status, text);
    }
  } catch (error) {
    console.warn('Failed to register FCM token:', error);
  }
};

const resolveLocaleForRegistration = async (accessToken?: string | null) => {
  if (typeof window === 'undefined') return null;

  const stored =
    localStorage.getItem(PROFILE_LOCALE_STORAGE_KEY) ||
    localStorage.getItem('locale');
  if (stored) return stored;

  if (!accessToken) return null;

  try {
    const response = await fetch(`${API_URL}/admin/profile/me`, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    });
    if (!response.ok) return null;

    const data = await response.json().catch(() => null);
    const locale = data?.data?.locale || data?.data?.profile?.locale || null;
    if (locale) {
      localStorage.setItem(PROFILE_LOCALE_STORAGE_KEY, locale);
    }
    return locale;
  } catch (error) {
    console.warn('Failed to resolve locale for FCM registration:', error);
    return null;
  }
};


