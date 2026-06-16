'use client';

import * as React from 'react';
import { Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
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
import { orderApi } from '@/lib/api-service';
import { Order } from '@/types';
import { formatCurrency, formatDateShort, formatDate } from '@/lib/utils';
import { Eye, X, Check, AlertCircle, RefreshCw, MapPin, Phone, ShoppingBag } from 'lucide-react';
import { toast } from '@/hooks/use-toast';
import { useSocket } from '@/contexts/socket-context';

const statusOptions = [
  { value: '__all__', label: 'Tất cả trạng thái' },
  { value: 'pending', label: 'Chờ xử lý' },
  { value: 'finding_shipper', label: 'Đang tìm shipper' },
  { value: 'shipper_accepted', label: 'Shipper đã nhận đơn' },
  { value: 'heading_to_market', label: 'Đang đến chợ' },
  { value: 'arrived_at_market', label: 'Đã đến chợ' },
  { value: 'ready_for_pickup', label: 'Sẵn sàng lấy hàng' },
  { value: 'seller_handed_over', label: 'Seller đã giao hàng' },
  { value: 'picked_up', label: 'Shipper đã lấy hàng' },
  { value: 'shopping', label: 'Đang mua hàng' },
  { value: 'delivering', label: 'Đang giao hàng' },
  { value: 'delivered', label: 'Đã giao hàng' },
  { value: 'cancelled', label: 'Đã hủy' },
];

const statusColors: Record<string, { bg: string; text: string; label: string }> = {
  pending: { bg: 'bg-gray-100 dark:bg-gray-700', text: 'text-gray-800 dark:text-gray-200', label: 'Chờ xử lý' },
  finding_shipper: { bg: 'bg-yellow-100 dark:bg-yellow-900/40', text: 'text-yellow-800 dark:text-yellow-300', label: 'Đang tìm shipper' },
  shipper_accepted: { bg: 'bg-blue-100 dark:bg-blue-900/40', text: 'text-blue-800 dark:text-blue-300', label: 'Shipper đã nhận đơn' },
  heading_to_market: { bg: 'bg-sky-100 dark:bg-sky-900/40', text: 'text-sky-800 dark:text-sky-300', label: 'Đang đến chợ' },
  arrived_at_market: { bg: 'bg-cyan-100 dark:bg-cyan-900/40', text: 'text-cyan-800 dark:text-cyan-300', label: 'Đã đến chợ' },
  ready_for_pickup: { bg: 'bg-indigo-100 dark:bg-indigo-900/40', text: 'text-indigo-800 dark:text-indigo-300', label: 'Sẵn sàng lấy hàng' },
  seller_handed_over: { bg: 'bg-violet-100 dark:bg-violet-900/40', text: 'text-violet-800 dark:text-violet-300', label: 'Seller đã giao hàng' },
  picked_up: { bg: 'bg-fuchsia-100 dark:bg-fuchsia-900/40', text: 'text-fuchsia-800 dark:text-fuchsia-300', label: 'Shipper đã lấy hàng' },
  shopping: { bg: 'bg-purple-100 dark:bg-purple-900/40', text: 'text-purple-800 dark:text-purple-300', label: 'Đang mua hàng' },
  delivering: { bg: 'bg-orange-100 dark:bg-orange-900/40', text: 'text-orange-800 dark:text-orange-300', label: 'Đang giao hàng' },
  delivered: { bg: 'bg-green-100 dark:bg-green-900/40', text: 'text-green-800 dark:text-green-300', label: 'Đã giao hàng' },
  cancelled: { bg: 'bg-red-100 dark:bg-red-900/40', text: 'text-red-800 dark:text-red-300', label: 'Đã hủy' },
};

const paymentStatusColors: Record<string, { bg: string; text: string; label: string }> = {
  unpaid: { bg: 'bg-red-100 dark:bg-red-900/40', text: 'text-red-800 dark:text-red-300', label: 'Chưa thanh toán' },
  paid: { bg: 'bg-green-100 dark:bg-green-900/40', text: 'text-green-800 dark:text-green-300', label: 'Đã thanh toán' },
  refunded: { bg: 'bg-gray-100 dark:bg-gray-700', text: 'text-gray-800 dark:text-gray-300', label: 'Đã hoàn tiền' },
};

interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

interface OrdersResponse {
  orders?: Order[];
  pagination?: PaginationInfo;
}

function OrdersContent() {
  const searchParams = useSearchParams();
  const { onNotification } = useSocket();
  const [orders, setOrders] = React.useState<Order[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [status, setStatus] = React.useState('');
  const [search, setSearch] = React.useState(searchParams.get('search') || '');
  const [page, setPage] = React.useState(1);
  const [totalPages, setTotalPages] = React.useState(1);
  const [total, setTotal] = React.useState(0);
  const [selectedOrder, setSelectedOrder] = React.useState<Order | null>(null);
  const [lastUpdated, setLastUpdated] = React.useState<Date | null>(null);

  const fetchOrders = React.useCallback(async () => {
    try {
      setError(null);
      const response = await orderApi.getAll({
        page,
        limit: 20,
        status: status === '__all__' ? undefined : status || undefined,
        search: search || undefined,
      }) as OrdersResponse;

      const safeOrders = Array.isArray(response?.orders) ? response.orders : [];
      const safePagination = response?.pagination;

      setOrders(safeOrders);
      setLastUpdated(new Date());
      setTotalPages(safePagination?.totalPages || 1);
      setTotal(safePagination?.total || safeOrders.length || 0);
    } catch (err: unknown) {
      console.error('Error fetching orders:', err);
      const msg = (err as { response?: { data?: { message?: string } }; message?: string }).response?.data?.message || (err as { message?: string }).message || 'Không thể tải danh sách đơn hàng';
      setError(msg);
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, [page, status, search]);

  // Auto-refresh every 10 seconds to catch status updates from mobile
  React.useEffect(() => {
    fetchOrders();
    const interval = setInterval(fetchOrders, 10000);
    return () => clearInterval(interval);
  }, [fetchOrders]);

  React.useEffect(() => {
    const unsubscribe = onNotification((notification) => {
      if (notification.type === 'order_new' || notification.type === 'order_status' || notification.type === 'order') {
        fetchOrders();
      }
    });
    return unsubscribe;
  }, [fetchOrders, onNotification]);

  React.useEffect(() => {
    // Refresh immediately when status filter changes
    setPage(1);
  }, [status]);

  const handleUpdateStatus = async (orderId: string, newStatus: string) => {
    try {
      await orderApi.updateStatus(orderId, newStatus);
      toast({ title: 'Thành công', description: 'Đã cập nhật trạng thái đơn hàng' });
      fetchOrders();
      setSelectedOrder(null);
    } catch (err: any) {
      console.error('Error updating order status:', err);
      toast({
        title: 'Lỗi',
        description: err?.response?.data?.message || err?.message || 'Không thể cập nhật trạng thái đơn hàng',
        variant: 'destructive',
      });
    }
  };

  const handleCancel = async (orderId: string) => {
    const reason = window.prompt('Nhập lý do hủy đơn:');
    if (!reason) return;
    try {
      await orderApi.cancel(orderId, reason);
      toast({ title: 'Thành công', description: 'Đã hủy đơn hàng' });
      fetchOrders();
      setSelectedOrder(null);
    } catch (err: any) {
      console.error('Error cancelling order:', err);
      toast({
        title: 'Lỗi',
        description: err?.response?.data?.message || err?.message || 'Không thể hủy đơn hàng',
        variant: 'destructive',
      });
    }
  };

  const getBuyerInfo = (order: Order) => {
    const buyer = (order as any).buyer || order.buyerId;
    if (!buyer) return 'N/A';
    return typeof buyer === 'object' ? (buyer.fullName || buyer.name || 'N/A') : 'N/A';
  };

  const getMarketName = (order: Order) => {
    const market = (order as any).market || order.marketId;
    if (!market) return 'N/A';
    return typeof market === 'object' ? (market.name || 'N/A') : 'N/A';
  };

  const getBuyerPhone = (order: Order) => {
    const buyer = (order as any).buyer || order.buyerId;
    if (!buyer) return '-';
    return typeof buyer === 'object' ? (buyer.phone || '-') : '-';
  };

  const getDeliveryAddress = (order: Order) => {
    const addr = order.deliveryAddress;
    if (!addr) return '-';
    return addr.address || '-';
  };

  return (
    <div className="space-y-6">
      <div className="mb-6 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Đơn hàng</h1>
          <p className="text-gray-500 dark:text-gray-400">Quản lý đơn hàng trong hệ thống</p>
        </div>
        <div className="flex flex-col items-end gap-1">
          <span className="rounded-full bg-[#6B52A3]/10 px-3 py-1 text-xs font-medium text-[#6B52A3]">
            {total} đơn hàng
          </span>
          {lastUpdated && (
            <span className="text-xs text-gray-400">
              Cập nhật: {lastUpdated.toLocaleTimeString('vi-VN')}
            </span>
          )}
        </div>
      </div>

      <div>
        <Card className="dark:bg-gray-900 dark:border-gray-700">
          <div>
            <CardHeader>
              <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <div className="flex flex-col gap-3 md:flex-row md:items-center">
                  <Input
                    placeholder="Tìm kiếm theo mã đơn..."
                    value={search}
                    onChange={(e) => { setSearch(e.target.value); setPage(1); }}
                    className="w-[240px] dark:bg-gray-800 dark:border-gray-700 dark:text-gray-100"
                  />
                  <Select value={status} onValueChange={(v) => { setStatus(v); setPage(1); }}>
                    <SelectTrigger className="w-[200px] dark:bg-gray-800 dark:border-gray-700 dark:text-gray-100">
                      <SelectValue placeholder="Trạng thái" />
                    </SelectTrigger>
                    <SelectContent>
                      {statusOptions.map((opt) => (
                        <SelectItem key={opt.value} value={opt.value}>
                          {opt.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {search && (
                    <button
                      onClick={() => { setSearch(''); setPage(1); }}
                      className="text-sm text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
                    >
                      Xóa tìm kiếm
                    </button>
                  )}
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={fetchOrders}
                  className="text-gray-600 dark:text-gray-400"
                >
                  <RefreshCw className="mr-2 h-4 w-4" />
                  Làm mới
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="space-y-4">
                  {[...Array(5)].map((_, i) => (
                    <Skeleton key={i} className="h-16 w-full" />
                  ))}
                </div>
              ) : error ? (
                <div className="py-12 text-center">
                  <AlertCircle className="mx-auto h-12 w-12 text-red-400" />
                  <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">Không thể tải dữ liệu</h3>
                  <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">{error}</p>
                  <Button variant="outline" className="mt-4" onClick={fetchOrders}>
                    <RefreshCw className="mr-2 h-4 w-4" />
                    Thử lại
                  </Button>
                </div>
              ) : orders.length === 0 ? (
                <div className="py-16 text-center">
                  <ShoppingBag className="mx-auto h-16 w-16 text-gray-300 dark:text-gray-600" />
                  <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">
                    {search || status ? 'Không tìm thấy đơn hàng phù hợp' : 'Chưa có đơn hàng nào'}
                  </h3>
                  <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                    {search || status ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm' : 'Đơn hàng sẽ xuất hiện ở đây khi có khách đặt'}
                  </p>
                </div>
              ) : (
                <>
                  <Table>
                    <TableHeader>
                      <TableRow className="dark:border-gray-700">
                        <TableHead className="text-gray-700 dark:text-gray-300">Mã đơn</TableHead>
                        <TableHead className="text-gray-700 dark:text-gray-300">Khách hàng</TableHead>
                        <TableHead className="text-gray-700 dark:text-gray-300">Chợ</TableHead>
                        <TableHead className="text-right text-gray-700 dark:text-gray-300">Tổng tiền</TableHead>
                        <TableHead className="text-gray-700 dark:text-gray-300">Trạng thái</TableHead>
                        <TableHead className="text-gray-700 dark:text-gray-300">Thanh toán</TableHead>
                        <TableHead className="text-gray-700 dark:text-gray-300">Ngày tạo</TableHead>
                        <TableHead className="text-right text-gray-700 dark:text-gray-300">Hành động</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {orders.map((order) => (
                        <TableRow key={order._id} className="dark:border-gray-700">
                          <TableCell className="font-mono text-sm text-[#6B52A3] font-medium">{order.orderNumber}</TableCell>
                          <TableCell className="text-gray-700 dark:text-gray-300">
                            <div>
                              <div className="font-medium">{getBuyerInfo(order)}</div>
                              <div className="text-xs text-gray-400">{getBuyerPhone(order)}</div>
                            </div>
                          </TableCell>
                          <TableCell className="text-gray-700 dark:text-gray-300 text-sm">{getMarketName(order)}</TableCell>
                          <TableCell className="text-right font-medium text-gray-900 dark:text-gray-100">
                            {formatCurrency(order.total)}
                          </TableCell>
                          <TableCell>
                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-medium ${statusColors[order.status]?.bg || 'bg-gray-100 dark:bg-gray-700'} ${statusColors[order.status]?.text || 'text-gray-800 dark:text-gray-200'}`}>
                              {statusColors[order.status]?.label || order.status}
                            </span>
                          </TableCell>
                          <TableCell>
                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-medium ${paymentStatusColors[order.paymentStatus]?.bg || 'bg-gray-100 dark:bg-gray-700'} ${paymentStatusColors[order.paymentStatus]?.text || 'text-gray-800 dark:text-gray-200'}`}>
                              {paymentStatusColors[order.paymentStatus]?.label || order.paymentStatus}
                            </span>
                          </TableCell>
                          <TableCell className="text-gray-600 dark:text-gray-400 text-sm">{formatDateShort(order.createdAt)}</TableCell>
                          <TableCell className="text-right">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => setSelectedOrder(order)}
                              title="Xem chi tiết"
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>

                  <div className="mt-4 flex items-center justify-between">
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      Hiển thị {orders.length} / {total} đơn hàng
                    </p>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage(p => Math.max(1, p - 1))}
                        disabled={page <= 1}
                      >
                        Trước
                      </Button>
                      <span className="flex items-center px-3 text-sm text-gray-600 dark:text-gray-400">
                        Trang {page} / {totalPages}
                      </span>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                        disabled={page >= totalPages}
                      >
                        Sau
                      </Button>
                    </div>
                  </div>
                </>
              )}
            </CardContent>
          </div>
        </Card>
      </div>

      <Dialog open={!!selectedOrder} onOpenChange={() => setSelectedOrder(null)}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Chi tiết đơn hàng</DialogTitle>
            <DialogDescription className="font-mono text-[#6B52A3]">{selectedOrder?.orderNumber}</DialogDescription>
          </DialogHeader>

          {selectedOrder && (
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Trạng thái</h4>
                  <span className={`inline-flex rounded-full px-3 py-1 text-sm font-medium ${statusColors[selectedOrder.status]?.bg || 'bg-gray-100'} ${statusColors[selectedOrder.status]?.text || 'text-gray-800'}`}>
                    {statusColors[selectedOrder.status]?.label || selectedOrder.status}
                  </span>
                </div>
                <div>
                  <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Thanh toán</h4>
                  <span className={`inline-flex rounded-full px-3 py-1 text-sm font-medium ${paymentStatusColors[selectedOrder.paymentStatus]?.bg || 'bg-gray-100'} ${paymentStatusColors[selectedOrder.paymentStatus]?.text || 'text-gray-800'}`}>
                    {paymentStatusColors[selectedOrder.paymentStatus]?.label || selectedOrder.paymentStatus}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Khách hàng</h4>
                  <p className="font-medium text-gray-900 dark:text-gray-100">{getBuyerInfo(selectedOrder)}</p>
                  <p className="text-sm text-gray-500 flex items-center gap-1 mt-0.5">
                    <Phone className="h-3 w-3" /> {getBuyerPhone(selectedOrder)}
                  </p>
                </div>
                <div>
                  <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Chợ</h4>
                  <p className="font-medium text-gray-900 dark:text-gray-100">{getMarketName(selectedOrder)}</p>
                  <p className="text-sm text-gray-500 flex items-center gap-1 mt-0.5">
                    <MapPin className="h-3 w-3" /> {getDeliveryAddress(selectedOrder)}
                  </p>
                </div>
              </div>

              <div>
                <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-3">Sản phẩm ({selectedOrder.items.length})</h4>
                <div className="space-y-2">
                  {selectedOrder.items.map((item, idx) => (
                    <div key={idx} className="flex items-center justify-between rounded-lg border p-3 dark:border-gray-700 dark:bg-gray-800/50">
                      <div className="flex items-center gap-3">
                        {item.imageUrl ? (
                          <img src={item.imageUrl} alt={item.name} className="w-10 h-10 rounded-lg object-cover" />
                        ) : (
                          <div className="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-700 flex items-center justify-center">
                            <ShoppingBag className="h-5 w-5 text-gray-400" />
                          </div>
                        )}
                        <div>
                          <p className="font-medium text-gray-900 dark:text-gray-100">{item.name}</p>
                          <p className="text-xs text-gray-500">{item.quantity} x {formatCurrency(item.price)} · {item.shopName || 'N/A'}</p>
                        </div>
                      </div>
                      <p className="font-medium text-gray-900 dark:text-gray-100">
                        {formatCurrency(item.quantity * item.price)}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="border-t pt-4 dark:border-gray-700 space-y-1.5">
                <div className="flex justify-between text-sm text-gray-600 dark:text-gray-400">
                  <span>Tạm tính:</span>
                  <span className="text-gray-900 dark:text-gray-100">{formatCurrency(selectedOrder.subtotal)}</span>
                </div>
                <div className="flex justify-between text-sm text-gray-600 dark:text-gray-400">
                  <span>Phí vận chuyển:</span>
                  <span className="text-gray-900 dark:text-gray-100">{formatCurrency(selectedOrder.shippingFee)}</span>
                </div>
                {selectedOrder.discount > 0 && (
                  <div className="flex justify-between text-sm text-green-600">
                    <span>Giảm giá:</span>
                    <span>-{formatCurrency(selectedOrder.discount)}</span>
                  </div>
                )}
                <div className="flex justify-between font-bold text-gray-900 dark:text-gray-100 text-base pt-2 border-t dark:border-gray-700">
                  <span>Tổng cộng:</span>
                  <span>{formatCurrency(selectedOrder.total)}</span>
                </div>
              </div>

              {selectedOrder.statusHistory && selectedOrder.statusHistory.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Lịch sử trạng thái</h4>
                  <div className="space-y-2">
                    {selectedOrder.statusHistory.slice().reverse().map((h, i) => (
                      <div key={i} className="flex justify-between text-sm">
                        <span className="text-gray-700 dark:text-gray-300">
                          {statusColors[h.status]?.label || h.status}
                          {h.note ? ` — ${h.note}` : ''}
                        </span>
                        <span className="text-gray-400 text-xs">{formatDate(h.timestamp)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {selectedOrder.note && (
                <div>
                  <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Ghi chú</h4>
                  <p className="text-sm text-gray-700 dark:text-gray-300">{selectedOrder.note}</p>
                </div>
              )}

              {selectedOrder.cancelReason && (
                <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
                  <h4 className="text-sm font-medium text-red-700 dark:text-red-400 mb-1">Lý do hủy</h4>
                  <p className="text-sm text-red-600 dark:text-red-300">{selectedOrder.cancelReason}</p>
                </div>
              )}
            </div>
          )}

          <DialogFooter className="gap-2 sm:gap-0 flex-wrap">
            {selectedOrder?.status === 'pending' && (
              <>
                <Button
                  variant="destructive"
                  onClick={() => handleCancel(selectedOrder._id)}
                >
                  <X className="mr-2 h-4 w-4" />
                  Hủy đơn
                </Button>
                <Button onClick={() => handleUpdateStatus(selectedOrder._id, 'finding_shipper')}>
                  <Check className="mr-2 h-4 w-4" />
                  Xác nhận & Tìm shipper
                </Button>
              </>
            )}
            {selectedOrder?.status === 'finding_shipper' && (
              <p className="text-sm text-gray-500 dark:text-gray-400 w-full text-center">
                Đang chờ shipper nhận đơn...
              </p>
            )}
            {selectedOrder?.status === 'shipper_accepted' && (
              <p className="text-sm text-blue-500 w-full text-center">
                Shipper đã nhận đơn — Đang mua hàng
              </p>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

export default function OrdersPage() {
  return (
    <Suspense fallback={
      <div className="space-y-6">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Đơn hàng</h1>
        </div>
        <Card>
          <CardContent className="p-6">
            <div className="space-y-4">
              {[...Array(5)].map((_, i) => <Skeleton key={i} className="h-12 w-full" />)}
            </div>
          </CardContent>
        </Card>
      </div>
    }>
      <OrdersContent />
    </Suspense>
  );
}
