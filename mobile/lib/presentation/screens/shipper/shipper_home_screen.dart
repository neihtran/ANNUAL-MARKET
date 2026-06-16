import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../blocs/blocs.dart';
import '../../widgets/widgets.dart';

class ShipperHomeScreen extends StatefulWidget {
  const ShipperHomeScreen({super.key});

  @override
  State<ShipperHomeScreen> createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AvailableTab(),
          _ActiveTab(),
          _HistoryTab(),
          _ShipperProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.shipperPrimary,
          unselectedItemColor: Colors.grey[400],
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              activeIcon: Icon(Icons.inbox),
              label: 'Đơn có sẵn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Đang giao',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableTab extends StatelessWidget {
  const _AvailableTab();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const _AvailableOrdersWrapper(),
        );
      },
    );
  }
}

class _AvailableOrdersWrapper extends StatelessWidget {
  const _AvailableOrdersWrapper();

  @override
  Widget build(BuildContext context) {
    return const _ShipperAvailableOrdersScreen();
  }
}

class _ShipperAvailableOrdersScreen extends StatefulWidget {
  const _ShipperAvailableOrdersScreen();

  @override
  State<_ShipperAvailableOrdersScreen> createState() =>
      _ShipperAvailableOrdersScreenState();
}

class _ShipperAvailableOrdersScreenState
    extends State<_ShipperAvailableOrdersScreen> {
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
      final orders = await _fetchAvailableOrders();
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

  Future<List<Order>> _fetchAvailableOrders() async {
    try {
      return await OrderRepository().getAvailableOrders();
    } catch (_) {
      return [];
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
        foregroundColor: Colors.white,
        title: const Text(
          'Đơn hàng có sẵn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
            ),
          ),
        ),
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
        child: CircularProgressIndicator(color: AppColors.shipperPrimary),
      );
    }
    if (_error != null) {
      return ErrorState(
        message: _error!,
        accentColor: AppColors.shipperPrimary,
        onRetry: _load,
      );
    }
    if (_orders.isEmpty) {
      return EmptyState(
        icon: Icons.delivery_dining,
        title: 'Không có đơn hàng nào',
        subtitle: 'Nhấn làm mới để kiểm tra lại',
        buttonText: 'Làm mới',
        onButtonPressed: _load,
        accentColor: AppColors.shipperPrimary,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (ctx, i) => OrderCard(
        order: _orders[i],
        userRole: 'shipper',
        onTap: () async {
          final changed = await Navigator.pushNamed(
            context,
            '/shipper/order',
            arguments: _orders[i].id,
          );
          if (changed == true && mounted) {
            _load();
          }
        },
        onAccept: () => _acceptOrder(_orders[i].id),
        onCancel: () {},
      ),
    );
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await OrderRepository().acceptOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã nhận đơn hàng!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _ActiveTab extends StatefulWidget {
  const _ActiveTab();

  @override
  State<_ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends State<_ActiveTab> {
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

  Future<void> _advanceStatus(
      Order order, String nextStatus, String successMessage) async {
    try {
      await OrderRepository().updateShipperStatus(order.id, nextStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  ({String label, String nextStatus, IconData icon})? _nextAction(Order order) {
    switch (order.status) {
      case 'shipper_accepted':
        return (
          label: 'Bắt đầu đến chợ',
          nextStatus: 'heading_to_market',
          icon: Icons.directions_bike
        );
      case 'heading_to_market':
        return (
          label: 'Đã tới chợ',
          nextStatus: 'arrived_at_market',
          icon: Icons.store_mall_directory
        );
      case 'seller_handed_over':
        return (
          label: 'Xác nhận đã nhận đơn',
          nextStatus: 'picked_up',
          icon: Icons.inventory_2
        );
      case 'picked_up':
      case 'shopping':
        return (
          label: 'Bắt đầu đi đơn',
          nextStatus: 'delivering',
          icon: Icons.local_shipping
        );
      case 'delivering':
        return (
          label: 'Đã giao xong',
          nextStatus: 'delivered',
          icon: Icons.task_alt
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
        return 'Bạn đã đến chợ, chờ seller xác nhận chuẩn bị xong.';
      case 'ready_for_pickup':
        return 'Seller đã báo chuẩn bị xong, chờ seller bàn giao đơn.';
      default:
        return 'Đang chờ seller cập nhật tiến độ.';
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
        foregroundColor: Colors.white,
        title: const Text(
          'Đơn đang giao',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorState(
        message: _error!,
        accentColor: AppColors.shipperPrimary,
        onRetry: _load,
      );
    }
    if (_orders.isEmpty) {
      return const EmptyState(
        icon: Icons.local_shipping,
        title: 'Không có đơn đang giao',
        subtitle: 'Đơn của bạn sẽ xuất hiện ở đây khi nhận giao',
        accentColor: AppColors.shipperPrimary,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final action = _nextAction(order);
          return _ShipperActiveOrderCard(
            order: order,
            action: action,
            waitingMessage: _isWaitingForSeller(order.status)
                ? _waitingMessage(order.status)
                : null,
            onAdvance: action == null
                ? null
                : () => _advanceStatus(order, action.nextStatus, action.label),
            onTap: () async {
              final changed = await Navigator.pushNamed(
                context,
                '/shipper/order',
                arguments: order.id,
              );
              if (changed == true && mounted) {
                _load();
              }
            },
          );
        },
      ),
    );
  }
}

class _ShipperActiveOrderCard extends StatelessWidget {
  final Order order;
  final ({String label, String nextStatus, IconData icon})? action;
  final String? waitingMessage;
  final VoidCallback? onAdvance;
  final VoidCallback onTap;

  const _ShipperActiveOrderCard({
    required this.order,
    required this.action,
    required this.waitingMessage,
    required this.onAdvance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.85),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.orderNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF111827)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                  color: status.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoBox(
                              icon: Icons.storefront_outlined,
                              label: 'Điểm lấy hàng',
                              value: order.market?.name ?? 'Chợ truyền thống',
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoBox(
                              icon: Icons.local_shipping_outlined,
                              label: 'Chặng hiện tại',
                              value: _subtitle(order),
                              color: AppColors.shipperPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDetailRow(Icons.location_on_outlined,
                          'Giao đến: ${order.deliveryAddress.address}'),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.shopping_bag_outlined,
                          '${order.items.length} sản phẩm cần giao'),
                      const SizedBox(height: 16),
                      if (action != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onAdvance,
                            icon: Icon(action!.icon),
                            label: Text(action!.label),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.shipperPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        )
                      else if (waitingMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.shipperPrimary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            waitingMessage!,
                            style: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: Color(0xFF111827),
                height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF6b7280)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                  color: Color(0xFF4b5563), fontSize: 13, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _subtitle(Order order) {
    switch (order.status) {
      case 'shipper_accepted':
        return 'Bắt đầu đến chợ';
      case 'heading_to_market':
        return 'Đang di chuyển đến chợ';
      case 'arrived_at_market':
        return 'Đã đến chợ';
      case 'ready_for_pickup':
        return 'Chờ seller bàn giao';
      case 'seller_handed_over':
        return 'Xác nhận đã nhận đơn';
      case 'picked_up':
        return 'Sẵn sàng bắt đầu giao';
      case 'shopping':
        return 'Đơn legacy, sẵn sàng giao';
      case 'delivering':
        return 'Đang trên đường giao';
      default:
        return 'Theo dõi tiến độ';
    }
  }

  ({String label, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'shipper_accepted':
        return (label: 'Shipper đã nhận', color: Colors.purple);
      case 'heading_to_market':
        return (label: 'Đang đến chợ', color: Colors.indigo);
      case 'arrived_at_market':
        return (label: 'Đã đến chợ', color: Colors.deepPurple);
      case 'ready_for_pickup':
        return (label: 'Chờ lấy hàng', color: Colors.teal);
      case 'seller_handed_over':
        return (label: 'Seller đã bàn giao', color: Colors.cyan);
      case 'picked_up':
        return (label: 'Đã lấy hàng', color: Colors.cyan);
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

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  double _totalRevenue = 0;
  int _deliveredCount = 0;

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
      final orders = await OrderRepository().getShipperHistory();
      final deliveredOrders =
          orders.where((o) => o.status == 'delivered').toList();
      if (mounted) {
        setState(() {
          _orders = orders;
          _deliveredCount = deliveredOrders.length;
          _totalRevenue = deliveredOrders.fold<double>(
              0, (sum, o) => sum + o.shipperRevenue);
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
        foregroundColor: Colors.white,
        title: const Text(
          'Lịch sử giao hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
            ),
          ),
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard('Đơn đã giao', '$_deliveredCount',
                  Icons.task_alt, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                  'Doanh thu ship',
                  _formatPrice(_totalRevenue),
                  Icons.payments,
                  AppColors.shipperPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_orders.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.history, size: 52, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chưa có đơn giao hoàn tất',
                  style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ..._orders.map(_buildHistoryCard),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Order order) {
    return OrderCard(
      order: order,
      userRole: 'shipper',
      onTap: () =>
          Navigator.pushNamed(context, '/shipper/order', arguments: order.id),
    );
  }

  String _formatPrice(double amount) {
    final raw = amount.toStringAsFixed(0);
    if (raw.length <= 3) return '$raw đ';
    final parts = <String>[];
    var rest = raw;
    while (rest.length > 3) {
      parts.insert(0, rest.substring(rest.length - 3));
      rest = rest.substring(0, rest.length - 3);
    }
    parts.insert(0, rest);
    return '${parts.join(',')} đ';
  }
}

class _ShipperProfileTab extends StatelessWidget {
  const _ShipperProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
        title: const Text(
          'Hồ sơ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/shipper/profile'),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
            ),
          ),
        ),
      ),
      body: const ShipperProfileBody(),
    );
  }
}

class ShipperProfileBody extends StatefulWidget {
  const ShipperProfileBody({super.key});

  @override
  State<ShipperProfileBody> createState() => _ShipperProfileBodyState();
}

class _ShipperProfileBodyState extends State<ShipperProfileBody> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0d9488).withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarOptions(context),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 68,
                                    height: 68,
                                    child: user.avatar != null &&
                                            user.avatar!.isNotEmpty
                                        ? Image.network(user.avatar!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildInitials(user.fullName))
                                        : _buildInitials(user.fullName),
                                  ),
                                ),
                              ),
                              if (_uploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                        color: Colors.black38,
                                        shape: BoxShape.circle),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0d9488),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(user.email,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildProfileBadge('Shipper'),
                                  _buildProfileBadge(user.isApproved
                                      ? 'Sẵn sàng nhận đơn'
                                      : 'Chờ duyệt'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                            child: _buildHeroInfoCard(
                                'Điện thoại',
                                user.phone.isNotEmpty
                                    ? user.phone
                                    : 'Chưa cập nhật',
                                Icons.phone_outlined)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildHeroInfoCard(
                                'Khu vực',
                                user.address?.city?.isNotEmpty == true
                                    ? user.address!.city!
                                    : 'Linh hoạt',
                                Icons.map_outlined)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildProfileSection(
                title: 'Thông tin cá nhân',
                children: [
                  _buildMenuItem(
                    icon: Icons.edit_outlined,
                    label: 'Chỉnh sửa thông tin',
                    onTap: () async {
                      final request = await showEditProfileSheet(
                        context,
                        user: user,
                        accentColor: AppColors.shipperPrimary,
                        roleLabel: 'shipper',
                      );
                      if (request == null || !context.mounted) return;
                      try {
                        final updatedUser = await AuthRepository()
                            .updateProfile(request.toJson());
                        if (!context.mounted) return;
                        context
                            .read<AuthBloc>()
                            .add(AuthUserUpdated(updatedUser));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Cập nhật hồ sơ thành công'),
                              behavior: SnackBarBehavior.floating),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  e.toString().replaceFirst('Exception: ', '')),
                              behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại',
                    trailing: Text(
                        user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ),
                  _buildMenuItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    trailing: Text(user.email,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Địa chỉ',
                    trailing: SizedBox(
                      width: 170,
                      child: Text(
                        user.address?.fullAddress.isNotEmpty == true
                            ? user.address!.fullAddress
                            : 'Chưa cập nhật',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProfileSection(
                title: 'Tiện ích',
                children: [
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    label: 'Trợ giúp & Hỗ trợ',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Liên hệ: hotro@vinguoitiêudùng.vn'),
                            behavior: SnackBarBehavior.floating),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    label: 'Về ứng dụng',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Chợ Truyền Thống',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 Chợ Truyền Thống',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    color: Colors.red,
                    onTap: () =>
                        context.read<AuthBloc>().add(AuthLogoutRequested()),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        }
        if (state is AuthLoading || state is AuthInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _buildHeroInfoCard(String label, String value, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 10),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );

  Widget _buildProfileSection(
          {required String title, required List<Widget> children}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      );

  Widget _buildInitials(String name) => Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0d9488),
          ),
        ),
      );

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    (color ?? AppColors.shipperPrimary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: color ?? AppColors.shipperPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? Colors.grey[800],
                  fontWeight:
                      color != null ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _showAvatarOptions(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;

      setState(() => _uploading = true);

      if (!mounted) return;

      final apiClient = ApiClient();
      final avatarPart = kIsWeb
          ? MultipartFile.fromBytes(
              await image.readAsBytes(),
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            )
          : await MultipartFile.fromFile(
              image.path,
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
      final response = await apiClient.put(
        '/auth/avatar',
        data: FormData.fromMap({
          'avatar': avatarPart,
        }),
      );

      if (response.data['success'] == true) {
        final updatedUser = User.fromJson(response.data['data']['user']);
        if (!mounted) {
          return;
        }
        authBloc.add(AuthUserUpdated(updatedUser));
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Cập nhật thất bại'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
