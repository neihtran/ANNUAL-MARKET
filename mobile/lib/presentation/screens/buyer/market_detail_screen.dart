import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/product_filter_sheet.dart';

class MarketDetailScreen extends StatefulWidget {
  final String marketId;

  const MarketDetailScreen({super.key, required this.marketId});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  Market? _market;
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loading = true;
  String? _selectedCategoryId;
  final _searchCtrl = TextEditingController();
  String? _keyword;
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;
  String? _sortOrder;
  bool _filtersApplied = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      setState(() => _loading = true);
      final results = await Future.wait([
        MarketRepository().getMarketById(widget.marketId),
        MarketRepository().getMarketCategories(widget.marketId),
        MarketRepository().getMarketProducts(widget.marketId),
      ]);

      if (mounted) {
        setState(() {
          _market = results[0] as Market;
          _categories = results[1] as List<Category>;
          _products = results[2] as List<Product>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading market data: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadAllData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadProducts({
    String? categoryId,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) async {
    setState(() {
      _loading = true;
      if (categoryId != null) _selectedCategoryId = categoryId;
    });
    try {
      final products = await MarketRepository().getMarketProducts(
        widget.marketId,
        categoryId: categoryId,
        keyword: keyword,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductFilterSheet(
        categories: _categories,
        selectedCategoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        onApply: ({categoryId, minPrice, maxPrice, sortBy, sortOrder}) {
          setState(() {
            _selectedCategoryId = categoryId;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _sortBy = sortBy;
            _sortOrder = sortOrder;
            _filtersApplied = categoryId != null || minPrice != null || maxPrice != null || sortBy != null;
          });
          _loadProducts(
            categoryId: categoryId,
            keyword: _keyword,
            minPrice: minPrice,
            maxPrice: maxPrice,
            sortBy: sortBy,
            sortOrder: sortOrder,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_loading && _market == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.buyerPrimary),
              const SizedBox(height: 16),
              Text('Đang tải...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (_market == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy chợ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chợ này có thể đã bị xóa hoặc không tồn tại',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAllData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buyerPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isSmallScreen ? 180 : 220,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _market!.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _market!.images.first,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.buyerPrimary),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _market!.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white70, size: isSmallScreen ? 12 : 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _market!.address,
                                style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 11 : 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 3 : 4),
                              decoration: BoxDecoration(
                                color: _market!.isCurrentlyOpen ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _market!.isCurrentlyOpen ? 'Đang mở' : 'Đã đóng',
                                style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 10 : 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Icon(Icons.access_time, color: Colors.white70, size: isSmallScreen ? 12 : 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_market!.openTime} - ${_market!.closeTime}',
                              style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 11 : 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 12 : 16,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: isSmallScreen ? 13 : 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: isSmallScreen ? 20 : 22),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[400], size: isSmallScreen ? 16 : 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _keyword = null;
                                  _loadProducts(
                                    categoryId: _selectedCategoryId,
                                    keyword: null,
                                    minPrice: _minPrice,
                                    maxPrice: _maxPrice,
                                    sortBy: _sortBy,
                                    sortOrder: _sortOrder,
                                  );
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                      ),
                      onSubmitted: (v) {
                        _keyword = v.trim().isNotEmpty ? v.trim() : null;
                        _loadProducts(
                          categoryId: _selectedCategoryId,
                          keyword: _keyword,
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                          sortBy: _sortBy,
                          sortOrder: _sortOrder,
                        );
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  GestureDetector(
                    onTap: _openFilterSheet,
                    child: Container(
                      width: isSmallScreen ? 40 : 46,
                      height: isSmallScreen ? 40 : 46,
                      decoration: BoxDecoration(
                        color: _filtersApplied
                            ? const Color(0xFFf97316).withValues(alpha: 0.12)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.tune,
                              color: _filtersApplied ? const Color(0xFFf97316) : Colors.grey[600],
                              size: isSmallScreen ? 20 : 22,
                            ),
                          ),
                          if (_filtersApplied)
                            Positioned(
                              top: isSmallScreen ? 8 : 10,
                              right: isSmallScreen ? 8 : 10,
                              child: Container(
                                width: isSmallScreen ? 6 : 8,
                                height: isSmallScreen ? 6 : 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFf97316),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: isSmallScreen ? 44 : 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 6 : 8),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final isSelected = isAll
                        ? _selectedCategoryId == null
                        : _selectedCategoryId == _categories[index - 1].id;
                    return GestureDetector(
                      onTap: () {
                        final catId = isAll ? null : _categories[index - 1].id;
                        setState(() => _selectedCategoryId = catId);
                        _loadProducts(
                          categoryId: catId,
                          keyword: _keyword,
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                          sortBy: _sortBy,
                          sortOrder: _sortOrder,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 14 : 16,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.buyerPrimary
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAll ? 'Tất cả' : _categories[index - 1].name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.buyerPrimary)),
              ),
            )
          else if (_products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Không có sản phẩm nào', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 4 : 8,
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 80 : 100,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 400 ? 2 : 2,
                  mainAxisSpacing: isSmallScreen ? 10 : 12,
                  crossAxisSpacing: isSmallScreen ? 10 : 12,
                  childAspectRatio: isSmallScreen ? 0.75 : 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _products[index];
                    return _ProductCard(
                      product: product,
                      isSmallScreen: isSmallScreen,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/buyer/product',
                          arguments: product,
                        );
                      },
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _ProductCard({required this.product, required this.onTap, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(isSmallScreen ? 12 : 16)),
              child: SizedBox(
                height: isSmallScreen ? 100 : 120,
                width: double.infinity,
                child: Stack(
                  children: [
                    product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: isSmallScreen ? 100 : 120,
                            errorWidget: (_, __, ___) => _imgPlaceholder(),
                          )
                        : _imgPlaceholder(),
                    if (!product.isAvailable)
                      Container(
                        height: isSmallScreen ? 100 : 120,
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Center(
                          child: Text(
                            'Hết hàng',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 11 : 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1a1a1a),
                      ),
                    ),
                    if (product.sellerName.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: isSmallScreen ? 11 : 13, color: Colors.grey[600]),
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Expanded(
                            child: Text(
                              product.sellerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.price.toStringAsFixed(0)} đ',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buyerPrimary,
                                ),
                              ),
                              Text(
                                '/${product.unit}',
                                style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: isSmallScreen ? 28 : 32,
                          height: isSmallScreen ? 28 : 32,
                          decoration: BoxDecoration(
                            color: AppColors.buyerPrimary,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          ),
                          child: Icon(Icons.add, color: Colors.white, size: isSmallScreen ? 16 : 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        height: isSmallScreen ? 100 : 120,
        color: Colors.grey[200],
        child: Icon(Icons.image, size: isSmallScreen ? 34 : 40, color: Colors.grey[400]),
      );
}
