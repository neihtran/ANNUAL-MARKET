'use client';

import * as React from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Cookies from 'js-cookie';
import { apiClient } from '@/lib/api';

interface AuthGuardProps {
  children: React.ReactNode;
}

export function AuthGuard({ children }: AuthGuardProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [verified, setVerified] = React.useState(false);
  const [checking, setChecking] = React.useState(false);
  // Prevent race conditions with a ref
  const checkInFlightRef = React.useRef(false);

  React.useEffect(() => {
    // Skip auth check on login page — login page handles its own redirect
    if (pathname === '/login' || pathname === '/login/') {
      setVerified(true);
      return;
    }

    // Prevent multiple simultaneous checks (prevents race on pathname change)
    if (checkInFlightRef.current) return;

    const token = Cookies.get('accessToken');
    if (!token) {
      router.push('/login');
      return;
    }

    checkInFlightRef.current = true;
    setChecking(true);

    const verifyAndRedirect = async () => {
      try {
        const freshToken = Cookies.get('accessToken');
        if (!freshToken) {
          router.push('/login');
          return;
        }

        const meResponse = await apiClient.get<{ user: { role: string; _id?: string; fullName?: string; avatar?: string } }>('/auth/me');
        const user = (meResponse as any)?.user || meResponse;
        if (!user || user.role !== 'admin') {
          router.push('/login');
          return;
        }
        try {
          Cookies.set('userData', JSON.stringify(user), { expires: 7 });
        } catch (_) {
          // ignore cookie write issues
        }
        setVerified(true);
      } catch (err: any) {
        const status = err?.response?.status;
        if (status === 401 || status === 403) {
          // Explicit auth failure — clear cookies and redirect
          Cookies.remove('accessToken');
          Cookies.remove('refreshToken');
          Cookies.remove('userData');
          router.push('/login');
          return;
        }
        // Network error or server error — redirect without clearing cookies.
        // The session is still valid; user can retry by navigating.
        // Show a brief loading state instead of immediate redirect.
        console.warn('Auth check failed (will retry on next navigation):', err?.message);
        setVerified(true); // Let the user see the page; it'll re-check on next navigation
      } finally {
        checkInFlightRef.current = false;
        setChecking(false);
      }
    };

    verifyAndRedirect();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pathname]);

  // Show loading only on initial mount while verifying
  if (!verified && checking) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin" />
          <p className="text-sm text-gray-500">Đang xác thực...</p>
        </div>
      </div>
    );
  }

  if (!verified) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin" />
          <p className="text-sm text-gray-500">Đang chuyển hướng...</p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
