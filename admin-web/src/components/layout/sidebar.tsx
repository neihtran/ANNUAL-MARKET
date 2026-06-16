'use client';

import * as React from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  Users,
  Store,
  Tag,
  ShoppingCart,
  BarChart2,
  HelpCircle,
  LogOut,
  Menu,
  X,
} from 'lucide-react';
import Cookies from 'js-cookie';
import { apiClient } from '@/lib/api';

const sidebarLinks = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/users', label: 'User Management', icon: Users },
  { href: '/markets', label: 'Market Management', icon: Store },
  { href: '/categories', label: 'Category Management', icon: Tag },
  { href: '/orders', label: 'Order Management', icon: ShoppingCart },
  { href: '/statistics', label: 'Statistics', icon: BarChart2 },
];

export function Sidebar() {
  const pathname = usePathname();
  const [isMobileOpen, setIsMobileOpen] = React.useState(false);
  const router = useRouter();
  const [loggingOut, setLoggingOut] = React.useState(false);

  const handleLogout = async () => {
    if (loggingOut) return;
    setLoggingOut(true);
    try {
      await apiClient.post('/auth/logout');
    } catch (_) {
      // Ignore logout API errors — proceed to clear cookies regardless
    } finally {
      Cookies.remove('accessToken');
      Cookies.remove('refreshToken');
      Cookies.remove('userData');
      window.location.href = '/login';
    }
  };

  return (
    <>
      <button
        className="fixed left-4 top-4 z-50 rounded-md bg-[#6B52A3] p-2 text-white lg:hidden"
        onClick={() => setIsMobileOpen(!isMobileOpen)}
      >
        {isMobileOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
      </button>

      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-40 flex w-64 flex-col bg-[#F4F2F7] transition-transform dark:bg-gray-900 lg:translate-x-0',
          isMobileOpen ? 'translate-x-0' : '-translate-x-full'
        )}
      >
        <div className="flex h-20 flex-col justify-center px-8">
          <Link href="/dashboard" className="flex flex-col">
            <span className="text-xl font-bold text-[#4B3B70] dark:text-gray-100">Chợ Truyền Thống</span>
            <span className="text-xs font-medium text-gray-500">Admin Console</span>
          </Link>
        </div>

        <nav className="flex-1 overflow-y-auto py-4">
          <ul className="space-y-1.5 px-4">
            {sidebarLinks.map((link) => {
              const Icon = link.icon;
              const isActive = pathname === link.href || pathname.startsWith(link.href + '/');
              return (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    onClick={() => setIsMobileOpen(false)}
                    className={cn(
                      'flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-[#6B52A3] text-white shadow-sm'
                        : 'text-gray-600 hover:bg-[#EBE7F1] hover:text-gray-900 dark:text-gray-300 dark:hover:bg-gray-800'
                    )}
                  >
                    <Icon className={cn("h-5 w-5", isActive ? "text-white" : "text-gray-500")} />
                    {link.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>

        <div className="p-4 pb-8 space-y-1.5 px-4">
          <Link
            href="/help"
            className="flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-gray-600 hover:bg-[#EBE7F1] hover:text-gray-900 transition-colors"
          >
            <HelpCircle className="h-5 w-5 text-gray-500" />
            Help
          </Link>
          <button
            onClick={handleLogout}
            disabled={loggingOut}
            className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium text-gray-600 hover:bg-[#EBE7F1] hover:text-gray-900 transition-colors disabled:opacity-60"
          >
            <LogOut className="h-5 w-5 text-gray-500" />
            {loggingOut ? 'Logging out...' : 'Logout'}
          </button>
        </div>
      </aside>

      {isMobileOpen && (
        <div
          className="fixed inset-0 z-30 bg-black/50 dark:bg-black/70 lg:hidden"
          onClick={() => setIsMobileOpen(false)}
        />
      )}
    </>
  );
}
