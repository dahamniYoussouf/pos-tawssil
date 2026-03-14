'use client';

import NotificationPopup from './NotificationPopup';

interface NotificationPopupWrapperProps {
  onViewDetails?: (notificationId: string) => void;
}

export default function NotificationPopupWrapper({ onViewDetails }: NotificationPopupWrapperProps) {
  return <NotificationPopup onViewDetails={onViewDetails} />;
}

