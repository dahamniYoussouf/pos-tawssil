'use client';

import { ReactNode } from 'react';
import { AuthProvider } from '@/contexts/AuthContext';
import { ThemeProvider } from '@/contexts/ThemeContext';
import SanitizeFetch from '@/components/SanitizeFetch';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <ThemeProvider>
      <SanitizeFetch />
      <AuthProvider>
        {children}
      </AuthProvider>
    </ThemeProvider>
  );
}







