'use client';

import { AlertCircle, X } from 'lucide-react';

type ModalErrorNoticeProps = {
  message?: string | null;
  onClose?: () => void;
};

export default function ModalErrorNotice({ message, onClose }: ModalErrorNoticeProps) {
  if (!message) {
    return null;
  }

  return (
    <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 shadow-sm">
      <div className="flex items-start gap-3">
        <AlertCircle className="mt-0.5 h-5 w-5 flex-shrink-0 text-red-600" />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-medium text-red-800">Erreur</p>
          <p className="mt-1 text-sm text-red-700">{message}</p>
        </div>
        {onClose ? (
          <button
            type="button"
            onClick={onClose}
            className="rounded-md p-1 text-red-500 transition-colors hover:bg-red-100 hover:text-red-700"
            aria-label="Fermer le message d'erreur"
          >
            <X className="h-4 w-4" />
          </button>
        ) : null}
      </div>
    </div>
  );
}
