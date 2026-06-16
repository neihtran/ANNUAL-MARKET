'use client';

import * as React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Bell, RefreshCw, Check, Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { notificationApi } from '@/lib/api-service';
import { Notification } from '@/types';
import { toast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';
import { useSocket, SocketNotification } from '@/contexts/socket-context';

function timeAgo(dateStr: string): string {
  const now = Date.now();
  const date = new Date(dateStr).getTime();
  const diff = Math.floor((now - date) / 1000);
  if (diff < 60) return `${diff} giây trước`;
  if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`;
  return `${Math.floor(diff / 86400)} ngày trước`;
}

export function NotificationsPopover() {
  const router = useRouter();
  const [notifications, setNotifications] = React.useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = React.useState(0);
  const [loading, setLoading] = React.useState(false);
  const [markingAll, setMarkingAll] = React.useState(false);
  const pollIntervalRef = React.useRef<NodeJS.Timeout | null>(null);
  const [isReady, setIsReady] = React.useState(false);
  const { isConnected, onNotification } = useSocket();

  // Subscribe to real-time socket notifications
  React.useEffect(() => {
    const unsubscribe = onNotification((socketNotif: SocketNotification) => {
      const newNotif: Notification = {
        _id: socketNotif._id || `socket-${Date.now()}`,
        userId: (socketNotif.userId as string) || '',
        title: socketNotif.title,
        body: socketNotif.body,
        type: socketNotif.type,
        referenceId: socketNotif.referenceId,
        data: socketNotif.data,
        isRead: false,
        createdAt: socketNotif.createdAt || new Date().toISOString(),
      };

      // Prepend new notification to the top of the list
      setNotifications(prev => [newNotif, ...prev]);
      setUnreadCount(prev => prev + 1);

      // Show a toast for the new notification
      toast({
        title: socketNotif.title || 'Thông báo mới',
        description: socketNotif.body,
        variant: 'default',
      });
    });

    return unsubscribe;
  }, [onNotification]);

  const fetchNotifications = React.useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const data = await notificationApi.getAll({ limit: 20 });
      const payload = (data as { notifications?: Notification[]; unreadCount?: number });
      if (payload?.notifications) {
        setNotifications(payload.notifications || []);
        setUnreadCount(payload.unreadCount || 0);
      } else if (Array.isArray(payload)) {
        setNotifications(payload as Notification[]);
        setUnreadCount(0);
      }
      setIsReady(true);
    } catch {
      // Silently fail — bell should not break the UI
    } finally {
      if (!silent) setLoading(false);
    }
  }, []);

  // Initial fetch
  React.useEffect(() => {
    fetchNotifications(false);
  }, [fetchNotifications]);

  // Poll as fallback every 15 seconds (increased from 10s since we have real-time now)
  React.useEffect(() => {
    if (!isReady) return;

    pollIntervalRef.current = setInterval(() => {
      fetchNotifications(true).catch(() => {/* ignore */});
    }, 15000);

    return () => {
      if (pollIntervalRef.current) {
        clearInterval(pollIntervalRef.current);
        pollIntervalRef.current = null;
      }
    };
  }, [isReady, fetchNotifications]);

  const handleMarkAsRead = async (id: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      await notificationApi.markAsRead(id);
      setNotifications(prev =>
        prev.map(n => n._id === id ? { ...n, isRead: true } : n)
      );
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch {
      toast({ title: 'Lỗi', description: 'Không thể đánh dấu đã đọc', variant: 'destructive' });
    }
  };

  const handleMarkAllRead = async () => {
    try {
      setMarkingAll(true);
      await notificationApi.markAllAsRead();
      setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
      setUnreadCount(0);
    } catch {
      toast({ title: 'Lỗi', description: 'Không thể đánh dấu tất cả đã đọc', variant: 'destructive' });
    } finally {
      setMarkingAll(false);
    }
  };

  const handleNotificationClick = async (notification: Notification) => {
    if (!notification.isRead) {
      try {
        await notificationApi.markAsRead(notification._id);
        setNotifications(prev =>
          prev.map(n => n._id === notification._id ? { ...n, isRead: true } : n)
        );
        setUnreadCount(prev => Math.max(0, prev - 1));
      } catch {
        // continue even if mark as read fails
      }
    }
    const type = notification.type;
    const hasUserData = !!notification.data?.userId || !!notification.referenceId;
    if (
      type === 'user_register' ||
      type === 'account_approved' ||
      type === 'account_rejected' ||
      type === 'account_banned' ||
      type === 'account_unbanned' ||
      type === 'account_approval' ||
      type === 'user_approval' ||
      (notification.title && notification.title.includes('Đăng ký'))
    ) {
      router.push('/users');
    } else if (
      type === 'order_new' ||
      type === 'order_status' ||
      type === 'order' ||
      type === 'order_approved' ||
      type === 'review'
    ) {
      router.push('/orders');
    }
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] rounded-full bg-red-500 text-[10px] font-bold text-white flex items-center justify-center px-1 animate-pulse">
              {unreadCount > 99 ? '99+' : unreadCount}
            </span>
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-96 max-h-[480px] flex flex-col">
        <div className="flex items-center justify-between px-4 py-3 border-b">
          <div className="flex items-center gap-2">
            <span className="font-semibold text-sm">Thông báo</span>
            {unreadCount > 0 && (
              <span className="px-2 py-0.5 bg-red-100 text-red-600 text-xs font-medium rounded-full">
                {unreadCount} mới
              </span>
            )}
          </div>
          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7"
              onClick={() => fetchNotifications(false)}
              disabled={loading}
              title="Làm mới"
            >
              <RefreshCw className={cn('h-3.5 w-3.5', loading && 'animate-spin')} />
            </Button>
            {unreadCount > 0 && (
              <Button
                variant="ghost"
                size="sm"
                className="h-auto py-1 px-2 text-xs text-[#4B3B70] hover:text-[#4B3B70]"
                onClick={handleMarkAllRead}
                disabled={markingAll}
              >
                {markingAll ? <RefreshCw className="h-3 w-3 animate-spin mr-1" /> : <Check className="h-3 w-3 mr-1" />}
                Đọc hết
              </Button>
            )}
          </div>
        </div>

        <div className="overflow-y-auto flex-1">
          {loading && notifications.length === 0 ? (
            <div className="flex items-center justify-center py-8">
              <RefreshCw className="h-5 w-5 animate-spin text-gray-400" />
            </div>
          ) : notifications.length === 0 ? (
            <div className="py-8 text-center text-sm text-gray-500">
              <Bell className="h-8 w-8 mx-auto mb-2 text-gray-300" />
              <p>Không có thông báo nào</p>
            </div>
          ) : (
            notifications.map((notification) => (
              <DropdownMenuItem
                key={notification._id}
                className={cn(
                  'flex flex-col items-start gap-1 py-3 px-4 cursor-pointer',
                  !notification.isRead && 'bg-[#4B3B70]/5'
                )}
                onClick={() => handleNotificationClick(notification)}
              >
                <div className="flex items-start justify-between w-full gap-2">
                  <div className="flex items-center gap-2">
                    {!notification.isRead && (
                      <span className="mt-1 min-w-[8px] h-[8px] rounded-full bg-[#4B3B70] flex-shrink-0" />
                    )}
                    <span className={cn('font-medium text-sm', !notification.isRead ? 'text-gray-900' : 'text-gray-600')}>
                      {notification.title}
                    </span>
                  </div>
                </div>
                <span className="text-xs text-gray-500 leading-relaxed">{notification.body}</span>
                <div className="flex items-center gap-2 mt-1 w-full">
                  <span className="text-[11px] text-gray-400">{timeAgo(notification.createdAt)}</span>
                  {!notification.isRead && (
                    <button
                      onClick={(e) => handleMarkAsRead(notification._id, e)}
                      className="ml-auto text-[11px] text-[#4B3B70] hover:underline"
                    >
                      Đánh dấu đã đọc
                    </button>
                  )}
                </div>
              </DropdownMenuItem>
            ))
          )}
        </div>

        <DropdownMenuSeparator />
        <DropdownMenuItem asChild className="py-3 justify-center">
          <Link href="/notifications" className="text-sm font-medium text-[#4B3B70] hover:text-[#3D2F5B] w-full text-center cursor-pointer">
            Xem tất cả thông báo
          </Link>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
