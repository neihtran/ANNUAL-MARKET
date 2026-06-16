'use client';

import * as React from 'react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { adminUserApi, adminMarketApi } from '@/lib/api-service';
import { User, Market } from '@/types';
import { formatDate } from '@/lib/utils';
import {
  Search,
  RefreshCw,
  CheckCircle,
  XCircle,
  Ban,
  Eye,
  UserCheck,
  MoreVertical,
  Trash2,
  FileText,
} from 'lucide-react';
import { toast } from '@/hooks/use-toast';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

const roleLabels: Record<string, string> = {
  buyer: 'Người mua',
  seller: 'Người bán',
  shipper: 'Shipper',
  admin: 'Admin',
};

const statusColors: Record<string, { bg: string; text: string }> = {
  active: { bg: 'bg-green-100 dark:bg-green-900/40', text: 'text-green-800 dark:text-green-300' },
  inactive: { bg: 'bg-gray-100 dark:bg-gray-700', text: 'text-gray-800 dark:text-gray-300' },
  banned: { bg: 'bg-red-100 dark:bg-red-900/40', text: 'text-red-800 dark:text-red-300' },
  rejected: { bg: 'bg-orange-100 dark:bg-orange-900/40', text: 'text-orange-800 dark:text-orange-300' },
};

const roleColors: Record<string, { bg: string; text: string }> = {
  buyer: { bg: 'bg-blue-100 dark:bg-blue-900/40', text: 'text-blue-800 dark:text-blue-300' },
  seller: { bg: 'bg-purple-100 dark:bg-purple-900/40', text: 'text-purple-800 dark:text-purple-300' },
  shipper: { bg: 'bg-orange-100 dark:bg-orange-900/40', text: 'text-orange-800 dark:text-orange-300' },
  admin: { bg: 'bg-gray-100 dark:bg-gray-700', text: 'text-gray-800 dark:text-gray-300' },
};

export default function UsersPage() {
  const [users, setUsers] = React.useState<User[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [search, setSearch] = React.useState('');
  const [role, setRole] = React.useState<string>('all');
  const [markets, setMarkets] = React.useState<Market[]>([]);
  const [marketFilter, setMarketFilter] = React.useState<string>('all');
  const [page, setPage] = React.useState(1);
  const [totalPages, setTotalPages] = React.useState(1);
  const [total, setTotal] = React.useState(0);
  const [selectedUser, setSelectedUser] = React.useState<User | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = React.useState(false);
  const [rejectDialogOpen, setRejectDialogOpen] = React.useState(false);
  const [rejectReason, setRejectReason] = React.useState('');
  const [banDialogOpen, setBanDialogOpen] = React.useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = React.useState(false);
  const [actionLoading, setActionLoading] = React.useState(false);

  const limit = 20;

  const fetchMarkets = React.useCallback(async () => {
    try {
      const response = await adminMarketApi.getAll({ limit: 100, isActive: true });
      const data = response as unknown as { markets?: Market[] };
      setMarkets(data?.markets || []);
    } catch {
      setMarkets([]);
    }
  }, []);

  const fetchUsers = React.useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const params: Record<string, unknown> = { page, limit };
      if (search.trim()) params.search = search.trim();
      if (role !== 'all') params.role = role;
      if (role === 'seller' && marketFilter !== 'all') params.marketId = marketFilter;

      const response = await adminUserApi.getAll(params);
      const data = (response as any);
      setUsers(data?.users || []);
      const pagination = data?.pagination;
      if (pagination) {
        setTotalPages(pagination.totalPages || 1);
        setTotal(pagination.total || 0);
      }
    } catch (err: any) {
      setError(err?.message || 'Không thể tải danh sách người dùng');
    } finally {
      setLoading(false);
    }
  }, [page, search, role, marketFilter]);

  React.useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  React.useEffect(() => {
    fetchMarkets();
  }, [fetchMarkets]);

  React.useEffect(() => {
    if (role !== 'seller' && marketFilter !== 'all') {
      setMarketFilter('all');
    }
  }, [role, marketFilter]);

  const handleApprove = async (id: string) => {
    setActionLoading(true);
    try {
      await adminUserApi.approve(id);
      toast({ title: 'Thành công', description: 'Đã phê duyệt tài khoản' });
      fetchUsers();
    } catch (err: any) {
      toast({ title: 'Lỗi', description: err?.message || 'Không thể phê duyệt', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await adminUserApi.reject(selectedUser._id, rejectReason);
      toast({ title: 'Thành công', description: 'Đã từ chối tài khoản' });
      setRejectDialogOpen(false);
      setRejectReason('');
      setSelectedUser(null);
      fetchUsers();
    } catch (err: any) {
      toast({ title: 'Lỗi', description: err?.message || 'Không thể từ chối', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleBan = async (id: string) => {
    setActionLoading(true);
    try {
      await adminUserApi.ban(id);
      toast({ title: 'Thành công', description: 'Đã khóa tài khoản' });
      setBanDialogOpen(false);
      setSelectedUser(null);
      fetchUsers();
    } catch (err: any) {
      toast({ title: 'Lỗi', description: err?.message || 'Không thể khóa', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleUnban = async (id: string) => {
    setActionLoading(true);
    try {
      await adminUserApi.unban(id);
      toast({ title: 'Thành công', description: 'Đã mở khóa tài khoản' });
      fetchUsers();
    } catch (err: any) {
      toast({ title: 'Lỗi', description: err?.message || 'Không thể mở khóa', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      await adminUserApi.delete(selectedUser._id);
      toast({ title: 'Thành công', description: 'Đã xóa tài khoản' });
      setDeleteDialogOpen(false);
      setSelectedUser(null);
      fetchUsers();
    } catch (err: any) {
      toast({ title: 'Lỗi', description: err?.message || 'Không thể xóa tài khoản', variant: 'destructive' });
    } finally {
      setActionLoading(false);
    }
  };

  const openViewDialog = (user: User) => {
    setSelectedUser(user);
    setViewDialogOpen(true);
  };

  const openRejectDialog = (user: User) => {
    setSelectedUser(user);
    setRejectReason('');
    setRejectDialogOpen(true);
  };

  const openBanDialog = (user: User) => {
    setSelectedUser(user);
    setBanDialogOpen(true);
  };

  const filteredUsers = users;

  const getUserMarketLabel = (user: User) => {
    if (!user.marketId) return 'Chưa đăng ký chợ';
    return typeof user.marketId === 'object'
      ? user.marketId.name || 'Chưa đăng ký chợ'
      : 'Đã gán chợ';
  };

  const getUserCategoryLabels = (user: User) => {
    if (!user.categoryIds || user.categoryIds.length === 0) return [];
    return user.categoryIds.map((category) => {
      if (typeof category === 'object') {
        return category.icon ? `${category.icon} ${category.name}` : category.name;
      }
      return category;
    }).filter(Boolean);
  };

  return (
    <div className="space-y-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Quản lý người dùng</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
          {total > 0 ? `${total} người dùng` : 'Tất cả người dùng'}
        </p>
      </div>

      <Card className="dark:bg-gray-900 dark:border-gray-700">
        <CardHeader>
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
            <div className="relative w-full sm:w-80">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Tìm theo tên, email, số điện thoại..."
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1); }}
                className="pl-10"
              />
            </div>
            <div className="flex gap-3 w-full sm:w-auto">
              <Select value={role} onValueChange={(v) => { setRole(v); setPage(1); }}>
                <SelectTrigger className="w-40">
                  <SelectValue placeholder="Vai trò" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả vai trò</SelectItem>
                  <SelectItem value="buyer">Người mua</SelectItem>
                  <SelectItem value="seller">Người bán</SelectItem>
                  <SelectItem value="shipper">Shipper</SelectItem>
                </SelectContent>
              </Select>
              {role === 'seller' && (
                <Select value={marketFilter} onValueChange={(v) => { setMarketFilter(v); setPage(1); }}>
                  <SelectTrigger className="w-52">
                    <SelectValue placeholder="Lọc theo chợ" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Tất cả chợ</SelectItem>
                    {markets.map((market) => (
                      <SelectItem key={market._id} value={market._id}>
                        {market.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
              <Button variant="outline" size="icon" onClick={fetchUsers} disabled={loading}>
                <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {loading && users.length === 0 ? (
            <div className="space-y-4">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : error ? (
            <div className="py-12 text-center">
              <p className="text-red-500 dark:text-red-400">{error}</p>
              <Button variant="outline" className="mt-4" onClick={fetchUsers}>
                Thử lại
              </Button>
            </div>
          ) : filteredUsers.length === 0 ? (
            <div className="py-12 text-center">
              <p className="text-gray-500 dark:text-gray-400">Không tìm thấy người dùng nào</p>
            </div>
          ) : (
            <>
              <div className="overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Người dùng</TableHead>
                      <TableHead>Vai trò</TableHead>
                      <TableHead>Trạng thái</TableHead>
                      <TableHead>Ngày tạo</TableHead>
                      <TableHead className="text-right">Thao tác</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredUsers.map((user) => {
                      const sc = statusColors[user.status] || statusColors.inactive;
                      const rc = roleColors[user.role] || roleColors.buyer;
                      return (
                        <TableRow key={user._id}>
                          <TableCell>
                            <div className="flex items-center gap-3">
                              <div className="w-9 h-9 rounded-full bg-[#4B3B70]/10 flex items-center justify-center text-[#4B3B70] font-semibold text-sm">
                                {user.fullName ? user.fullName[0].toUpperCase() : 'U'}
                              </div>
                              <div>
                                <p className="font-medium text-sm text-gray-900 dark:text-gray-100">{user.fullName || 'Chưa có tên'}</p>
                                <p className="text-xs text-gray-500">{user.email}</p>
                                {user.phone && <p className="text-xs text-gray-500">{user.phone}</p>}
                              </div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${rc.bg} ${rc.text}`}>
                              {roleLabels[user.role] || user.role}
                            </span>
                          </TableCell>
                          <TableCell>
                            <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${sc.bg} ${sc.text}`}>
                              {user.status === 'banned' ? 'Đã khóa' : user.status === 'rejected' ? 'Từ chối' : user.isApproved ? 'Đã duyệt' : 'Chờ duyệt'}
                            </span>
                          </TableCell>
                          <TableCell className="text-sm text-gray-500">
                            {formatDate(user.createdAt)}
                          </TableCell>
                          <TableCell className="text-right">
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-8 w-8">
                                  <MoreVertical className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuItem onClick={() => openViewDialog(user)}>
                                  <Eye className="mr-2 h-4 w-4" />
                                  Xem chi tiết
                                </DropdownMenuItem>
                                {!user.isApproved && user.role !== 'admin' && (
                                  <DropdownMenuItem onClick={() => handleApprove(user._id)}>
                                    <CheckCircle className="mr-2 h-4 w-4 text-green-600" />
                                    Phê duyệt
                                  </DropdownMenuItem>
                                )}
                                {!user.isApproved && user.role !== 'admin' && (
                                  <DropdownMenuItem onClick={() => openRejectDialog(user)}>
                                    <XCircle className="mr-2 h-4 w-4 text-orange-600" />
                                    Từ chối
                                  </DropdownMenuItem>
                                )}
                                {user.isApproved && user.status === 'active' && user.role !== 'admin' && (
                                  <DropdownMenuItem onClick={() => openBanDialog(user)}>
                                    <Ban className="mr-2 h-4 w-4 text-red-600" />
                                    Khóa tài khoản
                                  </DropdownMenuItem>
                                )}
                                {user.status === 'banned' && (
                                  <DropdownMenuItem onClick={() => handleUnban(user._id)}>
                                    <UserCheck className="mr-2 h-4 w-4 text-green-600" />
                                    Mở khóa
                                  </DropdownMenuItem>
                                )}
                                {user.role !== 'admin' && (
                                  <DropdownMenuItem onClick={() => { setSelectedUser(user); setDeleteDialogOpen(true); }} className="text-red-600 hover:text-red-700">
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    Xóa tài khoản
                                  </DropdownMenuItem>
                                )}
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </div>

              {totalPages > 1 && (
                <div className="flex items-center justify-center gap-2 mt-6">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage(p => Math.max(1, p - 1))}
                    disabled={page === 1 || loading}
                  >
                    Trước
                  </Button>
                  <span className="text-sm text-gray-500">
                    Trang {page} / {totalPages}
                  </span>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages || loading}
                  >
                    Sau
                  </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* View User Dialog */}
      <Dialog open={viewDialogOpen} onOpenChange={setViewDialogOpen}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Chi tiết người dùng</DialogTitle>
            <DialogDescription />
          </DialogHeader>
          {selectedUser && (
            <div className="space-y-4">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-full bg-[#4B3B70]/10 flex items-center justify-center text-[#4B3B70] font-bold text-2xl">
                  {selectedUser.fullName ? selectedUser.fullName[0].toUpperCase() : 'U'}
                </div>
                <div>
                  <h3 className="font-semibold text-lg">{selectedUser.fullName || 'Chưa có tên'}</h3>
                  <p className="text-sm text-gray-500">{selectedUser.email}</p>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium mt-1 ${roleColors[selectedUser.role]?.bg} ${roleColors[selectedUser.role]?.text}`}>
                    {roleLabels[selectedUser.role] || selectedUser.role}
                  </span>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-gray-500">Số điện thoại</p>
                  <p className="font-medium">{selectedUser.phone || 'Chưa cập nhật'}</p>
                </div>
                <div>
                  <p className="text-gray-500">Trạng thái</p>
                  <p className="font-medium">{selectedUser.status === 'banned' ? 'Đã khóa' : selectedUser.status === 'rejected' ? 'Từ chối' : selectedUser.isApproved ? 'Đã duyệt' : 'Chưa duyệt'}</p>
                </div>
                <div>
                  <p className="text-gray-500">Ngày đăng ký</p>
                  <p className="font-medium">{formatDate(selectedUser.createdAt)}</p>
                </div>
                <div>
                  <p className="text-gray-500">Xác minh</p>
                  <p className="font-medium">{selectedUser.isVerified ? 'Đã xác minh' : 'Chưa xác minh'}</p>
                </div>
                {selectedUser.role === 'seller' && (
                  <div className="col-span-2">
                    <p className="text-gray-500">Chợ đăng ký bán hàng</p>
                    <p className="font-medium">{getUserMarketLabel(selectedUser)}</p>
                  </div>
                )}
                {selectedUser.role === 'seller' && (
                  <div className="col-span-2">
                    <p className="text-gray-500">Danh mục hàng bán</p>
                    {getUserCategoryLabels(selectedUser).length > 0 ? (
                      <div className="mt-2 flex flex-wrap gap-2">
                        {getUserCategoryLabels(selectedUser).map((label) => (
                          <span
                            key={label}
                            className="inline-flex items-center rounded-full bg-[#4B3B70]/10 px-3 py-1 text-xs font-medium text-[#4B3B70]"
                          >
                            {label}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <p className="font-medium">Chưa chọn danh mục</p>
                    )}
                  </div>
                )}
                {/* Documents for sellers (CCCD image preview) */}
                {(selectedUser as any).documents?.filter((d: any) => d.type === 'cccd').length > 0 && (
                  <div className="col-span-2">
                    <p className="text-gray-500 mb-2">Tài liệu định danh (CCCD)</p>
                    <div className="flex gap-3 flex-wrap">
                      {(selectedUser as any).documents
                        .filter((d: any) => d.type === 'cccd')
                        .map((doc: any, i: number) => (
                          <div key={i} className="flex flex-col items-center">
                            <button
                              onClick={() => window.open(doc.url, '_blank')}
                              className="w-24 h-24 rounded-lg overflow-hidden border-2 border-gray-200 hover:border-blue-400 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-400"
                              title="Click để xem ảnh lớn"
                            >
                              <img
                                src={doc.url}
                                alt={`CCCD ${i + 1}`}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).style.display = 'none';
                                  (e.target as HTMLImageElement).nextElementSibling?.classList.remove('hidden');
                                }}
                              />
                              <div className="hidden w-full h-full flex-col items-center justify-center bg-gray-100 text-gray-400">
                                <FileText className="h-8 w-8 mb-1" />
                                <span className="text-xs">Lỗi tải</span>
                              </div>
                            </button>
                            <span className="text-xs text-gray-400 mt-1">CCCD {i + 1}</span>
                          </div>
                        ))}
                    </div>
                  </div>
                )}
                {/* Documents for shippers (driver license image preview) */}
                {(selectedUser as any).documents?.filter((d: any) => d.type === 'driver_license').length > 0 && (
                  <div className="col-span-2">
                    <p className="text-gray-500 mb-2">Tài liệu định danh (Bằng lái xe)</p>
                    <div className="flex gap-3 flex-wrap">
                      {(selectedUser as any).documents
                        .filter((d: any) => d.type === 'driver_license')
                        .map((doc: any, i: number) => (
                          <div key={i} className="flex flex-col items-center">
                            <button
                              onClick={() => window.open(doc.url, '_blank')}
                              className="w-24 h-24 rounded-lg overflow-hidden border-2 border-gray-200 hover:border-teal-400 transition-colors focus:outline-none focus:ring-2 focus:ring-teal-400"
                              title="Click để xem ảnh lớn"
                            >
                              <img
                                src={doc.url}
                                alt={`BLX ${i + 1}`}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).style.display = 'none';
                                  (e.target as HTMLImageElement).nextElementSibling?.classList.remove('hidden');
                                }}
                              />
                              <div className="hidden w-full h-full flex-col items-center justify-center bg-gray-100 text-gray-400">
                                <FileText className="h-8 w-8 mb-1" />
                                <span className="text-xs">Lỗi tải</span>
                              </div>
                            </button>
                            <span className="text-xs text-gray-400 mt-1">BLX {i + 1}</span>
                          </div>
                        ))}
                    </div>
                  </div>
                )}
                {selectedUser.bankInfo?.bankName && (
                  <div className="col-span-2">
                    <p className="text-gray-500">Thông tin ngân hàng</p>
                    <p className="font-medium">
                      {selectedUser.bankInfo.bankName} - {selectedUser.bankInfo.accountNumber}
                    </p>
                  </div>
                )}
                {selectedUser.rejectedReason && (
                  <div className="col-span-2">
                    <p className="text-gray-500">Lý do từ chối</p>
                    <p className="font-medium text-orange-600">{selectedUser.rejectedReason}</p>
                  </div>
                )}
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setViewDialogOpen(false)}>
              Đóng
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reject Dialog */}
      <AlertDialog open={rejectDialogOpen} onOpenChange={setRejectDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Từ chối tài khoản</AlertDialogTitle>
            <AlertDialogDescription>
              Nhập lý do từ chối tài khoản &quot;{selectedUser?.fullName}&quot;. Bước này không bắt buộc.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <textarea
            className="w-full border rounded-md p-3 text-sm dark:bg-gray-800 dark:border-gray-700 dark:text-gray-100 resize-none"
            rows={3}
            placeholder="Lý do từ chối (tùy chọn)"
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
          />
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setRejectDialogOpen(false)}>Hủy</AlertDialogCancel>
            <AlertDialogAction
              className="bg-orange-600 hover:bg-orange-700"
              onClick={handleReject}
              disabled={actionLoading}
            >
              {actionLoading ? 'Đang xử lý...' : 'Từ chối'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Ban Dialog */}
      <AlertDialog open={banDialogOpen} onOpenChange={setBanDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Khóa tài khoản</AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn khóa tài khoản &quot;{selectedUser?.fullName}&quot;? Người dùng sẽ không thể đăng nhập.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setBanDialogOpen(false)}>Hủy</AlertDialogCancel>
            <AlertDialogAction
              className="bg-red-600 hover:bg-red-700"
              onClick={() => selectedUser && handleBan(selectedUser._id)}
              disabled={actionLoading}
            >
              {actionLoading ? 'Đang xử lý...' : 'Khóa tài khoản'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Delete Account Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Xóa tài khoản</AlertDialogTitle>
            <AlertDialogDescription>
              Bạn có chắc muốn xóa tài khoản &quot;{selectedUser?.fullName}&quot;? Hành động này không thể hoàn tác.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setDeleteDialogOpen(false)}>Hủy</AlertDialogCancel>
            <AlertDialogAction
              className="bg-red-600 hover:bg-red-700"
              onClick={handleDelete}
              disabled={actionLoading}
            >
              {actionLoading ? 'Đang xóa...' : 'Xóa tài khoản'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
