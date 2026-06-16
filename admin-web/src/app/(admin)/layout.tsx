'use client';

import * as React from 'react';
import { Sidebar } from '@/components/layout/sidebar';
import { Header } from '@/components/layout/header';
import { AuthGuard } from '@/components/layout/auth-guard';
import { SocketProvider } from '@/contexts/socket-context';

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <SocketProvider>
        <div className="min-h-screen bg-[#FAFAFA] dark:bg-gray-950 flex font-sans">
          <Sidebar />
          <div className="flex-1 flex flex-col lg:pl-64">
            <Header />
            <main className="flex-1 p-8">{children}</main>
          </div>
        </div>
      </SocketProvider>
    </AuthGuard>
  );
}
