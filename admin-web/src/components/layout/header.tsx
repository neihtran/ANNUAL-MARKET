'use client';

import * as React from 'react';
import { Settings, Search } from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Input } from '@/components/ui/input';
import { useRouter } from 'next/navigation';
import Cookies from 'js-cookie';
import { NotificationsPopover } from '@/components/notifications-popover';
import { User } from '@/types';

export function Header() {
  const [query, setQuery] = React.useState('');
  const [user, setUser] = React.useState<{ fullName?: string; avatar?: string } | null>(null);
  const router = useRouter();

  React.useEffect(() => {
    try {
      const userData = Cookies.get('userData');
      if (userData) {
        const parsed = JSON.parse(userData) as User;
        setUser(parsed);
      }
    } catch { }
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim()) return;
    router.push(`/orders?search=${encodeURIComponent(query.trim())}`);
  };

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-transparent bg-[#FAFAFA] px-8 dark:bg-gray-900">
      <form onSubmit={handleSearch} className="flex w-full max-w-md items-center gap-2 rounded-full bg-gray-100 px-3 py-1.5 dark:bg-gray-800">
        <Search className="h-4 w-4 text-gray-500" />
        <Input
          type="search"
          placeholder="Tìm kiếm đơn hàng..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="h-8 border-none bg-transparent shadow-none focus-visible:ring-0 px-1 placeholder:text-gray-400"
        />
      </form>

      <div className="flex items-center gap-4">
        <NotificationsPopover />
        <button
          className="rounded-full p-2 text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
          onClick={() => router.push('/settings')}
          title="Cài đặt"
        >
          <Settings className="h-5 w-5" />
        </button>

        <div className="h-6 w-px bg-gray-300 dark:bg-gray-700 mx-2" />

        <div className="flex items-center gap-3">
          <div className="flex flex-col items-end">
            <span className="text-sm font-medium text-gray-900 dark:text-gray-100">
              {user?.fullName || 'Admin User'}
            </span>
            <span className="text-xs text-gray-500">ADMIN</span>
          </div>
          <Avatar className="h-9 w-9 border border-gray-200">
            <AvatarImage src={user?.avatar || '/avatars/01.png'} />
            <AvatarFallback className="bg-primary text-white">
              {user?.fullName ? user.fullName[0].toUpperCase() : 'AD'}
            </AvatarFallback>
          </Avatar>
        </div>
      </div>
    </header>
  );
}
