'use client';

import * as React from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import { Switch } from '@/components/ui/switch';
import { useTheme } from 'next-themes';
import { Moon, Sun, Shield, Bell, Loader2 } from 'lucide-react';
import { toast } from '@/hooks/use-toast';
import { apiClient } from '@/lib/api';
import Cookies from 'js-cookie';

export default function SettingsPage() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const [notifications, setNotifications] = React.useState({
    email: true,
    push: true,
    orderUpdates: true,
    promotions: false,
  });

  const [passwords, setPasswords] = React.useState({
    current: '',
    newPassword: '',
    confirm: '',
  });
  const [changingPassword, setChangingPassword] = React.useState(false);
  const [passwordError, setPasswordError] = React.useState('');

  const handleChangePassword = async () => {
    setPasswordError('');
    if (!passwords.current) {
      setPasswordError('Vui lòng nhập mật khẩu hiện tại');
      return;
    }
    if (!passwords.newPassword) {
      setPasswordError('Vui lòng nhập mật khẩu mới');
      return;
    }
    if (passwords.newPassword.length < 6) {
      setPasswordError('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (passwords.newPassword !== passwords.confirm) {
      setPasswordError('Mật khẩu mới không khớp');
      return;
    }

    setChangingPassword(true);
    try {
      // Get current user id from auth/me
      const meResponse = await apiClient.get<{ user: { role: string; _id: string } }>('/auth/me');
      const user = (meResponse as any)?.user || meResponse;
      const userId = (user as any)?._id;
      
      if (!userId) {
        throw new Error('Không xác định được người dùng');
      }

      await apiClient.put(`/users/${userId}/change-password`, {
        currentPassword: passwords.current,
        newPassword: passwords.newPassword,
      });

      toast({
        title: 'Thành công',
        description: 'Mật khẩu đã được thay đổi',
      });
      setPasswords({ current: '', newPassword: '', confirm: '' });
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || 'Đã xảy ra lỗi';
      setPasswordError(msg);
      toast({ title: 'Lỗi', description: msg, variant: 'destructive' });
    } finally {
      setChangingPassword(false);
    }
  };

  const handleSave = () => {
    toast({
      title: 'Lưu thành công',
      description: 'Cài đặt đã được lưu',
    });
  };

  const handleThemeChange = (checked: boolean) => {
    setTheme(checked ? 'dark' : 'light');
    toast({
      title: checked ? 'Đã bật chế độ tối' : 'Đã bật chế độ sáng',
      description: checked ? 'Giao diện đã chuyển sang chế độ tối' : 'Giao diện đã chuyển sang chế độ sáng',
    });
  };

  if (!mounted) {
    return (
      <div className="space-y-6">
        <div className="mb-6">
          <h1 className="text-2xl font-bold">Cài đặt</h1>
          <p className="text-gray-500">Quản lý cài đặt hệ thống</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Cài đặt</h1>
        <p className="text-gray-500 dark:text-gray-400">Quản lý cài đặt hệ thống</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              {theme === 'dark' ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
              Giao diện
            </CardTitle>
            <CardDescription>Cài đặt giao diện hiển thị</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Chế độ tối</Label>
                <p className="text-sm text-gray-500 dark:text-gray-400">Bật giao diện màu tối</p>
              </div>
              <Switch
                checked={theme === 'dark'}
                onCheckedChange={handleThemeChange}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Bell className="h-5 w-5" />
              Thông báo
            </CardTitle>
            <CardDescription>Quản lý các thông báo bạn nhận được</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Thông báo qua email</Label>
                <p className="text-sm text-gray-500 dark:text-gray-400">Nhận thông báo qua email</p>
              </div>
              <Switch
                checked={notifications.email}
                onCheckedChange={(checked) =>
                  setNotifications({ ...notifications, email: checked })
                }
              />
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Thông báo đẩy</Label>
                <p className="text-sm text-gray-500 dark:text-gray-400">Nhận thông báo đẩy trên thiết bị</p>
              </div>
              <Switch
                checked={notifications.push}
                onCheckedChange={(checked) =>
                  setNotifications({ ...notifications, push: checked })
                }
              />
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Cập nhật đơn hàng</Label>
                <p className="text-sm text-gray-500 dark:text-gray-400">Thông báo khi đơn hàng thay đổi trạng thái</p>
              </div>
              <Switch
                checked={notifications.orderUpdates}
                onCheckedChange={(checked) =>
                  setNotifications({ ...notifications, orderUpdates: checked })
                }
              />
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Khuyến mãi</Label>
                <p className="text-sm text-gray-500 dark:text-gray-400">Nhận thông báo về khuyến mãi và ưu đãi</p>
              </div>
              <Switch
                checked={notifications.promotions}
                onCheckedChange={(checked) =>
                  setNotifications({ ...notifications, promotions: checked })
                }
              />
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="h-5 w-5" />
              Bảo mật
            </CardTitle>
            <CardDescription>Quản lý bảo mật tài khoản</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="current-password">Mật khẩu hiện tại</Label>
              <Input
                id="current-password"
                type="password"
                placeholder="Nhập mật khẩu hiện tại"
                value={passwords.current}
                onChange={(e) => setPasswords(p => ({ ...p, current: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="new-password">Mật khẩu mới</Label>
              <Input
                id="new-password"
                type="password"
                placeholder="Nhập mật khẩu mới (ít nhất 6 ký tự)"
                value={passwords.newPassword}
                onChange={(e) => setPasswords(p => ({ ...p, newPassword: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirm-password">Xác nhận mật khẩu mới</Label>
              <Input
                id="confirm-password"
                type="password"
                placeholder="Nhập lại mật khẩu mới"
                value={passwords.confirm}
                onChange={(e) => setPasswords(p => ({ ...p, confirm: e.target.value }))}
              />
            </div>
            {passwordError && (
              <p className="text-sm text-red-500">{passwordError}</p>
            )}
          </CardContent>
        </Card>
      </div>

      <div className="flex justify-end gap-3">
        <Button variant="outline" onClick={() => setPasswords({ current: '', newPassword: '', confirm: '' })}>
          Hủy
        </Button>
        <Button onClick={handleChangePassword} disabled={changingPassword}>
          {changingPassword && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Đổi mật khẩu
        </Button>
      </div>
    </div>
  );
}
