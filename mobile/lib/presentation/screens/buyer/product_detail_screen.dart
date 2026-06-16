import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/cart/cart_cubit.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _quantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ProductRepository().getProductById(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator(color: AppColors.buyerPrimary)),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white),
        body: const Center(child: Text('Không tìm thấy sản phẩm')),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isSmallScreen ? 280 : 320,
                pinned: true,
                backgroundColor: AppColors.buyerPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: isSmallScreen ? 20 : 22),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => _shareProduct(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.share, color: Colors.white, size: isSmallScreen ? 20 : 22),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      product.images.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              onPageChanged: (i) => setState(() => _currentImageIndex = i),
                              itemCount: product.images.length,
                              itemBuilder: (ctx, i) => CachedNetworkImage(
                                imageUrl: product.images[i],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: isSmallScreen ? 70 : 80, color: Colors.grey[400]),
                            ),
                      if (product.images.length > 1)
                        Positioned(
                          bottom: isSmallScreen ? 12 : 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentImageIndex == i ? (isSmallScreen ? 16 : 20) : (isSmallScreen ? 6 : 8),
                                height: isSmallScreen ? 6 : 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == i
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${product.price.toStringAsFixed(0)} đ',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 22 : 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.buyerPrimary,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 2 : 4),
                          Text(
                            '/${product.unit}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 4 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: product.isAvailable
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.isAvailable
                                  ? 'Còn hàng (${product.stock})'
                                  : 'Hết hàng',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: product.isAvailable ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1a1a1a),
                        ),
                      ),
                      if (product.sellerName.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 14,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                color: AppColors.buyerPrimary,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Người bán',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 1 : 2),
                                    Text(
                                      product.sellerName,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1a1a1a),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mô tả sản phẩm',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1a1a1a),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              product.description.isNotEmpty
                                  ? product.description
                                  : 'Không có mô tả cho sản phẩm này.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                height: 1.6,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 80 : 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: isSmallScreen ? 18 : 20),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            color: Colors.grey[700],
                          ),
                          SizedBox(
                            width: isSmallScreen ? 28 : 32,
                            child: Text(
                              '$_quantity',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, size: isSmallScreen ? 18 : 20),
                            onPressed: _quantity < product.stock
                                ? () => setState(() => _quantity++)
                                : null,
                            color: AppColors.buyerPrimary,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: product.isAvailable ? _addToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buyerPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Thêm vào giỏ hàng',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chia sẻ sản phẩm đang được phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addToCart() {
    final product = _product!;
    context.read<CartCubit>().addItem(
      productId: product.id,
      shopId: product.shopId,
      shopName: 'Shop',
      productName: product.name,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
      price: product.price,
      quantity: _quantity,
      unit: product.unit,
      stock: product.stock,
      marketId: product.marketId,
      marketName: 'Chợ',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_quantity ${product.unit} "${product.name}" vào giỏ hàng'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/buyer/cart');
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
