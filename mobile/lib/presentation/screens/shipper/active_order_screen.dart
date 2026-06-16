import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  List<Order> _orders = [];
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
      final orders = await OrderRepository().getShipperActiveOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Đơn đang giao',
          style: TextStyle(
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.shipperPrimary));
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
    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.local_shipping,
                    size: 52, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              Text(
                'Không có đơn đang giao',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhận đơn từ tab "Đơn có sẵn"',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (ctx, i) => _buildCard(_orders[i]),
    );
  }

  Widget _buildCard(Order order) {
    final si = _statusInfo(order.status);
    final action = _primaryAction(order);
    final waitingForSeller = _isWaitingForSeller(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.shipperPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.shipperPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(order.market?.name ?? 'Chợ',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: si.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(si.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: si.color,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text('${order.items.length} sản phẩm',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.deliveryAddress.address,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${order.deliveryAddress.contactName} — ${order.deliveryAddress.contactPhone}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (action != null) ...[
            SizedBox(
              width: double.infinity,
              child: _buildPrimaryButton(order, action),
            ),
            if (order.status == 'shipper_accepted') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _returnOrder(order),
                  icon: const Icon(Icons.undo),
                  label: const Text('Trả đơn để shipper khác nhận'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ] else if (waitingForSeller) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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
    );
  }

  Widget _buildPrimaryButton(Order order,
      ({String label, String nextStatus, IconData icon, Color color}) action) {
    return ElevatedButton.icon(
      onPressed: () => _updateStatus(order, action.nextStatus),
      icon: Icon(action.icon),
      label: Text(action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: action.color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        return 'Đang chờ cập nhật từ seller.';
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
        _load();
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
        _load();
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

  ({String label, Color color}) _statusInfo(String? status) {
    if (status == null) return (label: 'Không rõ', color: Colors.grey);
    switch (status) {
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
        return (label: 'Đang mua', color: Colors.orange);
      case 'delivering':
        return (label: 'Đang giao', color: Colors.blue);
      case 'delivered':
        return (label: 'Đã giao', color: Colors.green);
      default:
        return (label: status, color: Colors.grey);
    }
  }
}
