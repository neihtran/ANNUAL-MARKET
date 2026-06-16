import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await OrderRepository().getSellerOrders();
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: AppColors.sellerPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      ));
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      itemBuilder: (ctx, i) => _buildCard(_orders[i]),
    );
  }

  Widget _buildCard(Order order) {
    final si = _statusInfo(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: si.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(si.label,
                        style: TextStyle(fontSize: 12, color: si.color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 16),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${item.name} x${item.quantity}')),
                    Text('${_formatPrice(item.price * item.quantity)} đ', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.items.length} sản phẩm', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('Tổng: ${_formatPrice(order.total)} đ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sellerPrimary)),
                ],
              ),
              const SizedBox(height: 4),
              Text(_formatDateTime(order.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(order.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...order.items.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('${item.quantity} x ${_formatPrice(item.price)} ${item.unit}'),
              trailing: Text('${_formatPrice(item.price * item.quantity)} đ'),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_formatPrice(order.total)} đ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sellerPrimary, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({String label, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'pending': return (label: 'Mới', color: Colors.orange);
      case 'finding_shipper': return (label: 'Đang tìm shipper', color: Colors.blue);
      case 'shipper_accepted': return (label: 'Shipper nhận', color: Colors.purple);
      case 'shopping': return (label: 'Đang mua', color: Colors.teal);
      case 'delivering': return (label: 'Đang giao', color: Colors.orange);
      case 'delivered': return (label: 'Đã giao', color: Colors.green);
      case 'cancelled': return (label: 'Đã hủy', color: Colors.red);
      default: return (label: status.isEmpty ? 'Không rõ' : status, color: Colors.grey);
    }
  }

  String _formatPrice(double p) => p >= 1000 ? '${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}K' : p.toStringAsFixed(0);
  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
