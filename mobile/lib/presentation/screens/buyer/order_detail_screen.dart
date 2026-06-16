import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/order_status_timeline.dart';
import 'review_order_screen.dart';

class BuyerOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const BuyerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<BuyerOrderDetailScreen> createState() => _BuyerOrderDetailScreenState();
}

class _BuyerOrderDetailScreenState extends State<BuyerOrderDetailScreen> {
  Order? _order;
  OrderTrack? _track;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await OrderRepository().getOrderById(widget.orderId);
      OrderTrack? track;
      if (_showTrackingMap(order.status)) {
        try {
          track = await OrderRepository().getOrderTrack(widget.orderId);
        } catch (_) {
          // Track may not be available yet — non-critical
        }
      }
      if (mounted) {
        setState(() {
          _order = order;
          _track = track;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1a1a1a),
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_canCancelOrder(_order?.status))
            TextButton.icon(
              onPressed: () => _showCancelDialog(),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  bool _canCancelOrder(String? status) {
    // Sync with backend orderService.js - buyer can cancel up to 'ready_for_pickup'
    const cancellable = [
      'pending',
      'finding_shipper',
      'shipper_accepted',
      'heading_to_market',
      'arrived_at_market',
      'ready_for_pickup',
    ];
    return cancellable.contains(status);
  }

  Future<void> _showCancelDialog() async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || !mounted) return;

    try {
      await OrderRepository().cancelOrder(widget.orderId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đơn hàng đã được hủy'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.buyerPrimary),
      );
    }
    if (_error != null) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buyerPrimary),
            child: const Text('Thử lại'),
          ),
        ],
      ));
    }
    final order = _order!;
    final si = _statusInfo(order.status);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Order header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFf97316), Color(0xFFea580c)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(si.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Đặt lúc ${_formatDateTime(order.createdAt)}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
              if (order.market != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.store,
                        size: 14, color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 4),
                    Text(order.market!.name,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Delivery address
        _sectionCard(
          children: [
            _sectionTitle('Địa chỉ giao hàng', Icons.location_on_outlined),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.buyerPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person,
                      size: 18, color: AppColors.buyerPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.deliveryAddress.contactName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(order.deliveryAddress.contactPhone,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(order.deliveryAddress.address,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Products
        _sectionCard(
          children: [
            _sectionTitle('Danh sách sản phẩm (${order.items.length})',
                Icons.inventory_2_outlined),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.imageUrl != null &&
                                item.imageUrl!.isNotEmpty
                            ? Image.network(item.imageUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imgPlaceholder())
                            : _imgPlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity} x ${item.price.toStringAsFixed(0)} đ / ${item.unit}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(item.price * item.quantity).toStringAsFixed(0)} đ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        const SizedBox(height: 12),

        // Payment summary
        _sectionCard(
          children: [
            _sectionTitle('Thanh toán', Icons.payment_outlined),
            const SizedBox(height: 12),
            _summaryRow('Tạm tính', '${_fmt(order.subtotal)} đ'),
            const SizedBox(height: 8),
            _summaryRow(
                'Phí vận chuyển',
                order.shippingFee > 0
                    ? '${_fmt(order.shippingFee)} đ'
                    : 'Miễn phí'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${_fmt(order.total)} đ',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.buyerPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(_paymentLabel(order.paymentMethod),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: order.paymentStatus == 'paid'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.paymentStatus == 'paid'
                          ? 'Đã thanh toán'
                          : 'Chưa thanh toán',
                      style: TextStyle(
                        color: order.paymentStatus == 'paid'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Map tracking — shown when order is being delivered (shipper accepted or beyond)
        if (_showTrackingMap(order.status)) _buildTrackingMap(_track),

        // Show review button only for delivered orders
        if (order.status == 'delivered') ...[
          const SizedBox(height: 12),
          _buildReviewButton(order),
        ],

        _sectionCard(
          children: [
            _sectionTitle('Lịch sử trạng thái', Icons.history),
            const SizedBox(height: 12),
            OrderStatusTimeline(history: order.statusHistory!),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.buyerPrimary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.image, color: Colors.grey[400], size: 24),
      );

  bool _showTrackingMap(String status) {
    return [
      'shipper_accepted',
      'heading_to_market',
      'arrived_at_market',
      'ready_for_pickup',
      'seller_handed_over',
      'picked_up',
      'shopping',
      'delivering',
    ].contains(status);
  }

  Widget _buildTrackingMap(OrderTrack? track) {
    if (track == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final points = <LatLng>[];
    if (track.market.hasCoords) {
      points.add(LatLng(track.market.lat!, track.market.lng!));
    }
    if (track.shipper != null) {
      points.add(LatLng(track.shipper!.lat, track.shipper!.lng));
    }
    if (track.delivery.hasCoords) {
      points.add(LatLng(track.delivery.lat!, track.delivery.lng!));
    }

    final center = points.isNotEmpty
        ? LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) /
                points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) /
                points.length)
        : const LatLng(10.76, 106.70);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.map_outlined,
                    size: 20, color: AppColors.buyerPrimary),
                const SizedBox(width: 8),
                const Text('Theo dõi vị trí giao hàng',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton(
                  onPressed: _refreshTrack,
                  child: const Text('Cập nhật'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16)),
              child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 13),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.chotruyenthong.app',
                  ),
                  if (points.length > 1)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: points,
                        color: AppColors.buyerPrimary,
                        strokeWidth: 3,
                      ),
                    ]),
                  MarkerLayer(markers: [
                    if (track.market.hasCoords)
                      Marker(
                        point: LatLng(track.market.lat!, track.market.lng!),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.store,
                            color: Colors.blue, size: 32),
                      ),
                    if (track.delivery.hasCoords)
                      Marker(
                        point: LatLng(track.delivery.lat!, track.delivery.lng!),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.home,
                            color: Colors.green, size: 32),
                      ),
                    if (track.shipper != null)
                      Marker(
                        point: LatLng(track.shipper!.lat, track.shipper!.lng),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.delivery_dining,
                            color: Colors.orange, size: 32),
                      ),
                  ]),
                ],
              ),
            ),
          ),
          if (track.shipper != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.delivery_dining,
                          color: Colors.orange, size: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.shipper!.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (track.shipper!.updatedAt != null)
                          Text(
                              'Cập nhật: ${_timeAgo(track.shipper!.updatedAt!)}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _callPhone(track.shipper!.phone),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.phone,
                          color: Colors.green.shade700, size: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshTrack() async {
    // Implemented via refresh indicator on the whole page
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildReviewButton(Order order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewOrderScreen(order: order),
            ),
          );
          if (result == true) {
            _load();
          }
        },
        icon: const Icon(Icons.star_outline, color: Colors.white),
        label: const Text(
          'Đánh giá đơn hàng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buyerPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s trước';
    if (diff.inMinutes < 60) return '${diff.inMinutes}ph trước';
    return '${diff.inHours}h trước';
  }

  ({String label, Color color}) _statusInfo(String? status) {
    if (status == null) return (label: 'Không rõ', color: Colors.grey);
    switch (status) {
      case 'pending':
        return (label: 'Chờ xác nhận', color: Colors.orange);
      case 'finding_shipper':
        return (label: 'Đang tìm shipper', color: Colors.blue);
      case 'shipper_accepted':
        return (label: 'Shipper đã nhận', color: Colors.purple);
      case 'heading_to_market':
        return (label: 'Đang đến chợ', color: Colors.indigo);
      case 'arrived_at_market':
        return (label: 'Đã đến chợ', color: Colors.deepPurple);
      case 'ready_for_pickup':
        return (label: 'Seller chuẩn bị xong', color: Colors.teal);
      case 'seller_handed_over':
        return (label: 'Seller đã bàn giao', color: Colors.cyan);
      case 'picked_up':
        return (label: 'Shipper đã nhận hàng', color: Colors.lightBlue);
      case 'shopping':
        return (label: 'Shipper đang mua', color: Colors.teal);
      case 'delivering':
        return (label: 'Đang giao', color: Colors.blue);
      case 'delivered':
        return (label: 'Đã giao', color: Colors.green);
      case 'cancelled':
        return (label: 'Đã hủy', color: Colors.red);
      default:
        return (label: status, color: Colors.grey);
    }
  }

  String _paymentLabel(String m) {
    switch (m) {
      case 'cod':
        return 'COD';
      case 'vnpay':
        return 'VNPay';
      case 'momo':
        return 'MoMo';
      default:
        return m;
    }
  }

  String _fmt(double p) {
    final s = p.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final parts = <String>[];
    var rest = s;
    while (rest.length > 3) {
      parts.insert(0, rest.substring(rest.length - 3));
      rest = rest.substring(0, rest.length - 3);
    }
    parts.insert(0, rest);
    return parts.join(',');
  }

  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
