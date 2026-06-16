'use client';

import * as React from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { apiClient } from '@/lib/api';
import { formatDate } from '@/lib/utils';
import { Bell, Trash2, CheckCheck, AlertCircle } from 'lucide-react';
import { toast } from '@/hooks/use-toast';
import { Notification } from '@/types';

export default function NotificationsPage() {
  const router = useRouter();
  const [notifications, setNotifications] = React.useState<Notification[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [search, setSearch] = React.useState('');

  const fetchNotifications = React.useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const notificationsData = await apiClient.get<{ notifications: Notification[] }>('/notifications', { limit: 50 });
      setNotifications(notificationsData.notifications || []);
    } catch (err: any) {
      console.error('Error fetching notifications:', err);
      setError(err?.response?.data?.message || err?.message || 'Không thể tải thông báo');
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  const handleMarkAsRead = async (id: string) => {
    try {
      await apiClient.patch(`/notifications/${id}/read`);
      setNotifications(notifications.map(n =>
        n._id === id ? { ...n, isRead: true } : n
      ));
      toast({ title: 'Thành công', description: 'Đã đánh dấu đã đọc' });
    } catch (err: any) {
      toast({
        title: 'Lỗi',
        description: err?.message || 'Không thể đánh dấu đã đọc',
        variant: 'destructive',
      });
    }
  };

  const handleMarkAllAsRead = async () => {
    try {
      setLoading(true);
      await apiClient.put('/notifications/read-all');
      setNotifications(notifications.map(n => ({ ...n, isRead: true })));
      toast({ title: 'Thành công', description: 'Đã đánh dấu tất cả đã đọc' });
    } catch (err: any) {
      toast({
        title: 'Lỗi',
        description: err?.message || 'Không thể đánh dấu tất cả',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await apiClient.delete(`/notifications/${id}`);
      setNotifications(notifications.filter(n => n._id !== id));
      toast({ title: 'Thành công', description: 'Đã xóa thông báo' });
    } catch (err: any) {
      toast({
        title: 'Lỗi',
        description: err?.message || 'Không thể xóa thông báo',
        variant: 'destructive',
      });
    }
  };

  const handleNotificationClick = async (notification: Notification) => {
    if (!notification.isRead) {
      try {
        await apiClient.patch(`/notifications/${notification._id}/read`);
        setNotifications(prev =>
          prev.map(n => n._id === notification._id ? { ...n, isRead: true } : n)
        );
      } catch {
        // continue even if mark as read fails
      }
    }
    const type = notification.type;
    const hasUserData = !!(notification as any).data?.userId || !!(notification as any).referenceId;
    if (type === 'user_register' || (hasUserData && notification.title.includes('Đăng ký'))) {
      router.push('/users');
    } else if (type === 'order_new' || type === 'order_status' || type === 'order') {
      router.push('/orders');
    }
  };

  const filteredNotifications = notifications.filter(n =>
    n.title.toLowerCase().includes(search.toLowerCase()) ||
    n.body.toLowerCase().includes(search.toLowerCase())
  );

  const unreadCount = notifications.filter(n => !n.isRead).length;

  return (
    <div className="space-y-6">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Thông báo</h1>
          <p className="text-gray-500 dark:text-gray-400">
            {unreadCount > 0 ? `${unreadCount} thông báo chưa đọc` : 'Tất cả đã đọc'}
          </p>
        </div>
        {unreadCount > 0 && (
          <Button variant="outline" onClick={handleMarkAllAsRead} disabled={loading}>
            <CheckCheck className="mr-2 h-4 w-4" />
            Đánh dấu tất cả đã đọc
          </Button>
        )}
      </div>

      <div>
        <Card className="dark:bg-gray-900 dark:border-gray-700">
          <div>
            <CardHeader>
              <div className="relative">
                <Input
                  placeholder="Tìm kiếm thông báo..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-10"
                />
              </div>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="space-y-4">
                  {[...Array(5)].map((_, i) => (
                    <Skeleton key={i} className="h-20 w-full" />
                  ))}
                </div>
              ) : error ? (
                <div className="py-12 text-center">
                  <AlertCircle className="mx-auto h-12 w-12 text-red-400" />
                  <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">Không thể tải dữ liệu</h3>
                  <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">{error}</p>
                </div>
              ) : filteredNotifications.length === 0 ? (
                <div className="py-12 text-center">
                  <Bell className="mx-auto h-12 w-12 text-gray-400" />
                  <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">Không có thông báo</h3>
                  <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                    {search ? 'Không tìm thấy thông báo nào' : 'Bạn sẽ nhận được thông báo khi có cập nhật'}
                  </p>
                </div>
              ) : (
                <div className="space-y-2">
                  {filteredNotifications.map((notification) => (
                    <div
                      key={notification._id}
                      className={`flex items-start gap-4 rounded-lg border p-4 transition-colors cursor-pointer hover:bg-gray-50 ${
                        notification.isRead
                          ? 'bg-white dark:bg-gray-900 dark:border-gray-700'
                          : 'bg-blue-50 dark:bg-blue-900/20 border-blue-100 dark:border-blue-800/50'
                      }`}
                      onClick={() => handleNotificationClick(notification)}
                    >
                      <div className={`rounded-full p-2 ${
                        notification.isRead ? 'bg-gray-100 dark:bg-gray-800' : 'bg-blue-100 dark:bg-blue-900/50'
                      }`}>
                        <Bell className={`h-5 w-5 ${
                          notification.isRead ? 'text-gray-400' : 'text-blue-600 dark:text-blue-400'
                        }`} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h4 className={`font-medium ${!notification.isRead ? 'text-blue-600 dark:text-blue-400' : 'text-gray-900 dark:text-gray-100'}`}>
                            {notification.title}
                          </h4>
                          {!notification.isRead && (
                            <span className="h-2 w-2 rounded-full bg-blue-500" />
                          )}
                        </div>
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                          {notification.body}
                        </p>
                        <p className="mt-2 text-xs text-gray-400 dark:text-gray-500">
                          {formatDate(notification.createdAt)}
                        </p>
                      </div>
                      <div className="flex gap-2">
                        {!notification.isRead && (
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleMarkAsRead(notification._id)}
                            title="Đánh dấu đã đọc"
                          >
                            <CheckCheck className="h-4 w-4" />
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleDelete(notification._id)}
                          className="text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20"
                          title="Xóa"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </div>
        </Card>
      </div>
    </div>
  );
}
