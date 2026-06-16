import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cart_item.dart';
import '../../blocs/cart/cart_cubit.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1a1a1a),
        title: Text(
          'Giỏ hàng',
          style: TextStyle(
            color: const Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return _emptyState(context);
          }
          return Column(
            children: [
              if (cart.marketName != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(
                    isSmallScreen ? 12 : 16,
                    isSmallScreen ? 4 : 8,
                    isSmallScreen ? 12 : 16,
                    0,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buyerPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isSmallScreen ? 28 : 32,
                        height: isSmallScreen ? 28 : 32,
                        decoration: BoxDecoration(
                          color: AppColors.buyerPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.store, size: isSmallScreen ? 14 : 16, color: AppColors.buyerPrimary),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mua tại',
                              style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: AppColors.buyerPrimary),
                            ),
                            Text(
                              cart.marketName!,
                              style: TextStyle(
                                color: AppColors.buyerPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: isSmallScreen ? 18 : 20),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) => _CartItemTile(item: cart.items[i], isSmallScreen: isSmallScreen),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) return const SizedBox.shrink();
          return _CartBottomBar(cart: cart, isSmallScreen: isSmallScreen);
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
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
              child: Icon(Icons.shopping_cart_outlined, size: 52, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Giỏ hàng trống',
              style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm sản phẩm vào giỏ hàng',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.buyerPrimary,
                side: const BorderSide(color: AppColors.buyerPrimary),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tiếp tục mua sắm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isSmallScreen;

  const _CartItemTile({required this.item, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: isSmallScreen ? 64 : 76,
                    height: isSmallScreen ? 64 : 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          SizedBox(width: isSmallScreen ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 12 : 14,
                    color: const Color(0xFF1a1a1a),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  '${_fmt(item.price)} đ / ${item.unit}',
                  style: TextStyle(
                    color: AppColors.buyerPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 10),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyBtn(
                            Icons.remove,
                            () {
                              if (item.quantity <= 1) {
                                context.read<CartCubit>().removeItem(item.productId);
                              } else {
                                context.read<CartCubit>().updateQuantity(item.productId, item.quantity - 1);
                              }
                            },
                            isSmallScreen,
                          ),
                          Container(
                            constraints: BoxConstraints(minWidth: isSmallScreen ? 24 : 30),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12 : 14),
                            ),
                          ),
                          _qtyBtn(
                            Icons.add,
                            item.quantity < item.stock
                                ? () => context.read<CartCubit>().updateQuantity(item.productId, item.quantity + 1)
                                : null,
                            isSmallScreen,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_fmt(item.total)} đ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 13 : 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
          GestureDetector(
            onTap: () => context.read<CartCubit>().removeItem(item.productId),
            child: Icon(Icons.delete_outline, color: Colors.grey[400], size: isSmallScreen ? 20 : 22),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: isSmallScreen ? 64 : 76,
        height: isSmallScreen ? 64 : 76,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        ),
        child: Icon(Icons.image, color: Colors.grey[400], size: isSmallScreen ? 26 : 30),
      );

  Widget _qtyBtn(IconData icon, VoidCallback? onTap, bool isSmall) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmall ? 24 : 28,
        height: isSmall ? 24 : 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
        ),
        child: Icon(
          icon,
          size: isSmall ? 14 : 16,
          color: onTap != null ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
    );
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
}

class _CartBottomBar extends StatelessWidget {
  final CartState cart;
  final bool isSmallScreen;

  const _CartBottomBar({required this.cart, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final shippingFee = cart.subtotal >= 200000 ? 0.0 : 15000.0;
    final total = cart.subtotal + shippingFee;
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 12 : 20,
      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.itemCount} sản phẩm',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey[600]),
                    ),
                    SizedBox(height: isSmallScreen ? 1 : 2),
                    Text(
                      '${_fmt(total)} đ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 22,
                        color: AppColors.buyerPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: isSmallScreen ? 46 : 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/buyer/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buyerPrimary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                      elevation: 0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Đặt hàng',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Icon(Icons.arrow_forward_ios, size: isSmallScreen ? 14 : 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
}
