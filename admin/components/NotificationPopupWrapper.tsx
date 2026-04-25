'use client';

import NotificationPopup from './NotificationPopup';

type NotificationPopupType =
  | 'pending_order_timeout'
  | 'restaurant_preparation_timeout'
  | 'driver_arrival_timeout'
  | 'restaurant_unresponsive'
  | 'driver_unresponsive'
  | 'driver_excessive_cancellations'
  | 'order_admin_review_required';

interface NotificationPopupWrapperProps {
  onViewDetails?: (notificationId: string, type?: NotificationPopupType) => void;
}

export default function NotificationPopupWrapper({ onViewDetails }: NotificationPopupWrapperProps) {
  return <NotificationPopup onViewDetails={onViewDetails} />;
}

