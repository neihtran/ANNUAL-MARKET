import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';

class ReviewOrderScreen extends StatefulWidget {
  final Order order;

  const ReviewOrderScreen({super.key, required this.order});

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  int _sellerRating = 5;
  int? _sellerQuality;
  int? _sellerCommunication;
  int? _sellerDelivery;

  int _shipperRating = 5;
  int? _shipperPunctuality;
  int? _shipperAttitude;
  int? _shipperHandling;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _hasSeller => widget.order.market != null;
  bool get _hasShipper => widget.order.shipper != null;

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = ReviewRepository();

      if (_hasSeller) {
        await repo.createSellerReview(
          orderId: widget.order.id,
          sellerId: widget.order.marketId,
          rating: _sellerRating,
          aspects: ReviewAspects(
            quality: _sellerQuality,
            communication: _sellerCommunication,
            delivery: _sellerDelivery,
          ),
          comment: _commentCtrl.text.trim(),
        );
      }

      if (_hasShipper) {
        await repo.createShipperReview(
          orderId: widget.order.id,
          shipperId: widget.order.shipperId!,
          rating: _shipperRating,
          aspects: ShipperReviewAspects(
            punctuality: _shipperPunctuality,
            attitude: _shipperAttitude,
            handling: _shipperHandling,
          ),
          comment: _commentCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã đánh giá!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1a1a1a),
        title: const Text(
          'Đánh giá đơn hàng',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOrderInfo(),
          const SizedBox(height: 16),
          if (_hasSeller) ...[
            _buildSellerReviewCard(),
            const SizedBox(height: 16),
          ],
          if (_hasShipper) ...[
            _buildShipperReviewCard(),
            const SizedBox(height: 16),
          ],
          _buildCommentCard(),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buyerPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Gửi đánh giá',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.buyerPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.order.items.length} sản phẩm • ${_formatMoney(widget.order.total)} đ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Đã giao',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerReviewCard() {
    return _ReviewCard(
      title: 'Đánh giá chợ',
      icon: Icons.store,
      iconColor: Colors.blue,
      avatar: widget.order.market?.id,
      name: widget.order.market?.name ?? 'Chợ',
      overallRating: _sellerRating,
      onOverallChanged: (v) => setState(() => _sellerRating = v),
      aspects: [
        _AspectItem(
          label: 'Chất lượng sản phẩm',
          icon: Icons.inventory_2_outlined,
          value: _sellerQuality,
          onChanged: (v) => setState(() => _sellerQuality = v),
        ),
        _AspectItem(
          label: 'Liên lạc',
          icon: Icons.chat_bubble_outline,
          value: _sellerCommunication,
          onChanged: (v) => setState(() => _sellerCommunication = v),
        ),
        _AspectItem(
          label: 'Giao hàng đúng hạn',
          icon: Icons.local_shipping_outlined,
          value: _sellerDelivery,
          onChanged: (v) => setState(() => _sellerDelivery = v),
        ),
      ],
    );
  }

  Widget _buildShipperReviewCard() {
    return _ReviewCard(
      title: 'Đánh giá tài xế',
      icon: Icons.delivery_dining,
      iconColor: Colors.orange,
      avatar: widget.order.shipper?.avatar,
      name: widget.order.shipper?.fullName ?? 'Tài xế',
      overallRating: _shipperRating,
      onOverallChanged: (v) => setState(() => _shipperRating = v),
      aspects: [
        _AspectItem(
          label: 'Đúng giờ',
          icon: Icons.access_time,
          value: _shipperPunctuality,
          onChanged: (v) => setState(() => _shipperPunctuality = v),
        ),
        _AspectItem(
          label: 'Thái độ',
          icon: Icons.sentiment_satisfied_alt,
          value: _shipperAttitude,
          onChanged: (v) => setState(() => _shipperAttitude = v),
        ),
        _AspectItem(
          label: 'Bảo quản hàng',
          icon: Icons.inventory,
          value: _shipperHandling,
          onChanged: (v) => setState(() => _shipperHandling = v),
        ),
      ],
    );
  }

  Widget _buildCommentCard() {
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
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text(
                'Bình luận',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '(tùy chọn)',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Chia sẻ trải nghiệm của bạn về đơn hàng này...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.buyerPrimary, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double p) {
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
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? avatar;
  final String name;
  final int overallRating;
  final ValueChanged<int> onOverallChanged;
  final List<_AspectItem> aspects;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.avatar,
    required this.name,
    required this.overallRating,
    required this.onOverallChanged,
    required this.aspects,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                backgroundImage: avatar != null && avatar!.isNotEmpty
                    ? NetworkImage(avatar!)
                    : null,
                child: avatar == null || avatar!.isEmpty
                    ? Icon(icon, color: iconColor, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => onOverallChanged(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= overallRating ? Icons.star : Icons.star_border,
                    size: 36,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _ratingText(overallRating),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...aspects.map((aspect) => _buildAspectRow(aspect)),
        ],
      ),
    );
  }

  Widget _buildAspectRow(_AspectItem aspect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(aspect.icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aspect.label,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              final isSelected = aspect.value != null && star <= aspect.value!;
              return GestureDetector(
                onTap: () => aspect.onChanged(isSelected ? (aspect.value == star ? null : star) : star),
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: 22,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _ratingText(int rating) {
    switch (rating) {
      case 1:
        return 'Rất không hài lòng';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
        return 'Rất hài lòng';
      default:
        return '';
    }
  }
}

class _AspectItem {
  final String label;
  final IconData icon;
  final int? value;
  final ValueChanged<int?> onChanged;

  _AspectItem({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
}
