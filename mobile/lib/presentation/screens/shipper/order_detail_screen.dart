import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_datetime.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class ShipperOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const ShipperOrderDetailScreen({super.key, required this.orderId});

  @override
  State<ShipperOrderDetailScreen> createState() =>
      _ShipperOrderDetailScreenState();
}

class _ShipperOrderDetailScreenState extends State<ShipperOrderDetailScreen> {
  Order? _order;
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
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
      }
    } catch (_) {
      try {
        final activeOrders = await OrderRepository().getShipperActiveOrders();
        final fallbackOrder = activeOrders.cast<Order?>().firstWhere(
              (item) => item?.id == widget.orderId,
              orElse: () => null,
            );
        if (mounted && fallbackOrder != null) {
          setState(() {
            _order = fallbackOrder;
            _loading = false;
          });
          return;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _error = 'Không thể tải chi tiết đơn hàng';
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
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.shipperPrimary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.shipperPrimary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    final order = _order!;
    final si = _statusInfo(order.status);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
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
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            si.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${order.items.length} sản phẩm — ${order.market?.name ?? "Chợ"}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                children: [
                  _sectionTitle(
                      'Địa chỉ giao hàng', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              AppColors.shipperPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person,
                            size: 18, color: AppColors.shipperPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.deliveryAddress.contactName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(order.deliveryAddress.contactPhone,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _callBuyer(order.deliveryAddress.contactPhone),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone,
                              size: 18, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on,
                          size: 18, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(order.deliveryAddress.address,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sectionCard(
                children: [
                  _sectionTitle(
                      'Danh sách sản phẩm', Icons.inventory_2_outlined),
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.shipperPrimary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.shipperPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${item.name} / ${item.unit}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${(item.price * item.quantity).toStringAsFixed(0)} đ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${order.total.toStringAsFixed(0)} đ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.shipperPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sectionCard(
                children: [
                  _sectionTitle('Thông tin đơn hàng', Icons.info_outline),
                  const SizedBox(height: 12),
                  _infoRow('Mã đơn', order.orderNumber),
                  _infoRow('Chợ', order.market?.name ?? 'Không có'),
                  _infoRow(
                      'Phí ship',
                      order.shippingFee > 0
                          ? '${order.shippingFee.toStringAsFixed(0)} đ'
                          : 'Miễn phí'),
                  _infoRow('Thanh toán', _paymentLabel(order.paymentMethod)),
                  if (order.note.isNotEmpty) _infoRow('Ghi chú', order.note),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        _buildActionSection(order),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.shipperPrimary),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActionSection(Order order) {
    final action = _primaryAction(order);
    final waitingForSeller = _isWaitingForSeller(order.status);
    final showReturn = order.status == 'shipper_accepted';

    if (action == null && !waitingForSeller && !showReturn) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(order, action.nextStatus),
                  icon: Icon(action.icon),
                  label: Text(action.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action.color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (showReturn) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _returnOrder(order),
                  icon: const Icon(Icons.undo),
                  label: const Text('Trả đơn cho shipper khác'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (waitingForSeller) ...[
              if (action != null) const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.shipperPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _waitingMessage(order.status),
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({String label, String nextStatus, IconData icon, Color color})?
      _primaryAction(Order order) {
    switch (order.status) {
      case 'shipper_accepted':
        return (
          label: 'Bắt đầu đến chợ',
          nextStatus: 'heading_to_market',
          icon: Icons.directions_bike,
          color: Colors.orange,
        );
      case 'heading_to_market':
        return (
          label: 'Đã tới chợ',
          nextStatus: 'arrived_at_market',
          icon: Icons.store_mall_directory,
          color: Colors.indigo,
        );
      case 'seller_handed_over':
        return (
          label: 'Xác nhận đã nhận đơn',
          nextStatus: 'picked_up',
          icon: Icons.inventory_2,
          color: Colors.cyan,
        );
      case 'picked_up':
      case 'shopping':
        return (
          label: 'Bắt đầu giao hàng',
          nextStatus: 'delivering',
          icon: Icons.local_shipping,
          color: Colors.blue,
        );
      case 'delivering':
        return (
          label: 'Xác nhận đã giao',
          nextStatus: 'delivered',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      default:
        return null;
    }
  }

  bool _isWaitingForSeller(String status) {
    return status == 'arrived_at_market' || status == 'ready_for_pickup';
  }

  String _waitingMessage(String status) {
    switch (status) {
      case 'arrived_at_market':
        return 'Bạn đã đến chợ. Chờ seller xác nhận chuẩn bị xong.';
      case 'ready_for_pickup':
        return 'Seller đã báo chuẩn bị xong. Chờ seller bàn giao đơn cho bạn.';
      default:
        return 'Đang chờ seller cập nhật.';
    }
  }

  Future<void> _returnOrder(Order order) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Trả đơn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Nếu trả đơn ${order.orderNumber}, đơn sẽ hiện lại để shipper khác nhận.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Lý do trả đơn (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Giữ đơn')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Trả đơn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await OrderRepository()
          .cancelOrder(order.id, reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã trả đơn để shipper khác có thể nhận'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _callBuyer(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Liên hệ: $phone'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Liên hệ: $phone'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    try {
      await OrderRepository().updateShipperStatus(order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cập nhật thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
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

  ({String label, Color color}) _statusInfo(String? status) {
    if (status == null) return (label: 'Không rõ', color: Colors.grey);
    switch (status) {
      case 'pending':
        return (label: 'Mới', color: Colors.orange);
      case 'finding_shipper':
        return (label: 'Tìm shipper', color: Colors.blue);
      case 'shipper_accepted':
        return (label: 'Đã nhận', color: Colors.purple);
      case 'heading_to_market':
        return (label: 'Đang đến chợ', color: Colors.indigo);
      case 'arrived_at_market':
        return (label: 'Đã đến chợ', color: Colors.deepPurple);
      case 'ready_for_pickup':
        return (label: 'Chờ lấy hàng', color: Colors.teal);
      case 'seller_handed_over':
        return (label: 'Seller đã bàn giao', color: Colors.cyan);
      case 'picked_up':
        return (label: 'Đã nhận hàng', color: Colors.lightBlue);
      case 'shopping':
        return (label: 'Đang mua', color: Colors.teal);
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
}
