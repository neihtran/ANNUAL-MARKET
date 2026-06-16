import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_datetime.dart';
import '../../data/models/order_model.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final String userRole;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;

  const OrderCard({
    super.key,
    required this.order,
    required this.userRole,
    this.onTap,
    this.onAccept,
    this.onCancel,
  });

  String _getStatusLabel() {
    switch (order.status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'finding_shipper':
        return 'Đang tìm shipper';
      case 'shipper_accepted':
        return 'Shipper đã nhận';
      case 'heading_to_market':
        return 'Đang đến chợ';
      case 'arrived_at_market':
        return 'Đã đến chợ';
      case 'ready_for_pickup':
        return 'Chờ lấy hàng';
      case 'seller_handed_over':
        return 'Seller đã bàn giao';
      case 'picked_up':
        return 'Đã nhận hàng';
      case 'shopping':
        return 'Đang mua hàng';
      case 'delivering':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return order.status;
    }
  }

  Color _getStatusColor() {
    switch (order.status) {
      case 'pending':
        return AppColors.statusPending;
      case 'finding_shipper':
        return AppColors.statusConfirmed;
      case 'shipper_accepted':
        return AppColors.statusPreparing;
      case 'heading_to_market':
        return AppColors.statusReady;
      case 'arrived_at_market':
        return const Color(0xFF7C3AED);
      case 'ready_for_pickup':
        return const Color(0xFF0F766E);
      case 'seller_handed_over':
        return const Color(0xFF0891B2);
      case 'picked_up':
        return const Color(0xFF2563EB);
      case 'shopping':
        return AppColors.statusReady;
      case 'delivering':
        return AppColors.statusDelivering;
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final headlineAmount = userRole == 'seller'
        ? order.sellerRevenue
        : userRole == 'shipper'
            ? order.shipperRevenue
            : order.total;
    final headlineLabel = userRole == 'seller'
        ? 'Tiền hàng'
        : userRole == 'shipper'
            ? 'Phí ship'
            : 'Tổng đơn';

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
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.85),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(order.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6b7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHighlightBox(
                              icon: Icons.payments_outlined,
                              label: headlineLabel,
                              value: '${headlineAmount.toStringAsFixed(0)} đ',
                              accentColor: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHighlightBox(
                              icon: Icons.inventory_2_outlined,
                              label: 'Sản phẩm',
                              value: '${order.items.length} món',
                              accentColor: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        order.deliveryAddress.address.isNotEmpty
                            ? order.deliveryAddress.address
                            : 'Chưa có địa chỉ',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.person_outline,
                        order.deliveryAddress.contactName.isNotEmpty
                            ? order.deliveryAddress.contactName
                            : 'Khách hàng',
                      ),
                    ],
                  ),
                ),
                if (userRole == 'shipper' && order.status == 'finding_shipper')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text('Bỏ qua'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.shipperPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Nhận đơn'),
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

  Widget _buildHighlightBox({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6b7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4b5563),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) => AppDateTime.formatDateTime(d);
}
