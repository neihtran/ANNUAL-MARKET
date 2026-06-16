import 'package:flutter/material.dart';

import '../../data/models/order_model.dart';

class OrderStatusTimeline extends StatelessWidget {
  final List<OrderStatusHistory> history;

  const OrderStatusTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text('Chưa có lịch sử trạng thái.');
    }

    final sortedHistory = [...history]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      children: List.generate(sortedHistory.length, (index) {
        final item = sortedHistory[index];
        final statusInfo = _statusInfo(item.status);
        final isLast = index == sortedHistory.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusInfo.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusInfo.color.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: statusInfo.color.withValues(alpha: 0.25),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: statusInfo.color.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: statusInfo.color,
                        ),
                      ),
                      if (item.note != null &&
                          item.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.note!,
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _formatDateTime(item.timestamp),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  ({String label, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return (label: 'Chờ xác nhận', color: Colors.orange);
      case 'finding_shipper':
        return (label: 'Đang tìm shipper', color: Colors.blue);
      case 'shipper_accepted':
        return (label: 'Shipper đã nhận đơn', color: Colors.purple);
      case 'heading_to_market':
        return (label: 'Shipper bắt đầu đến chợ', color: Colors.indigo);
      case 'arrived_at_market':
        return (label: 'Shipper đã tới chợ', color: Colors.deepPurple);
      case 'ready_for_pickup':
        return (label: 'Seller chuẩn bị xong', color: Colors.teal);
      case 'seller_handed_over':
        return (label: 'Seller đã giao đơn cho shipper', color: Colors.cyan);
      case 'picked_up':
        return (label: 'Shipper đã nhận hàng', color: Colors.lightBlue);
      case 'shopping':
        return (label: 'Đang mua hàng', color: Colors.teal);
      case 'delivering':
        return (label: 'Đang giao đến khách', color: Colors.blue);
      case 'delivered':
        return (label: 'Đã giao thành công', color: Colors.green);
      case 'cancelled':
        return (label: 'Đơn đã hủy', color: Colors.red);
      default:
        return (label: status.isEmpty ? 'Không rõ' : status, color: Colors.grey);
    }
  }

  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
