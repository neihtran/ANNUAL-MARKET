import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_datetime.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/seller_shop_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../blocs/blocs.dart';
import '../../widgets/order_status_timeline.dart';
import '../../widgets/edit_profile_sheet.dart';
import '../../widgets/widgets.dart';

bool _sellerCanManageProducts(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  return state is AuthAuthenticated && state.user.role == 'seller' && state.user.isApproved;
}

Future<bool> _guardSellerProductAccess(BuildContext context) async {
  if (_sellerCanManageProducts(context)) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Tài khoản chưa được duyệt. Vui lòng chờ admin phê duyệt.'),
      backgroundColor: Colors.orange,
    ),
  );
  return false;
}

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _SellerDashboardTab(),
          _ProductsTab(),
          _OrdersTab(),
          _ProfileTab(),
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
          selectedItemColor: AppColors.sellerPrimary,
          unselectedItemColor: Colors.grey[400],
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Sản phẩm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Đơn hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () async {
                if (!await _guardSellerProductAccess(context)) return;
                final result = await Navigator.pushNamed(context, '/seller/add-product');
                if (result == true) {
                  context.read<SellerProductBloc>().add(RefreshSellerProducts());
                }
              },
              backgroundColor: AppColors.sellerPrimary,
              elevation: 4,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _SellerDashboardTab extends StatefulWidget {
  const _SellerDashboardTab();

  @override
  State<_SellerDashboardTab> createState() => _SellerDashboardTabState();
}

class _SellerDashboardTabState extends State<_SellerDashboardTab> {
  int _todayOrders = 0;
  double _monthRevenue = 0;
  int _totalProducts = 0;
  double _avgRating = 0;
  bool _loading = true;
  Shop? _shop;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final productRepo = ProductRepository();
      final orderRepo = OrderRepository();
      final shopRepo = SellerShopRepository();

      final products = await productRepo.getSellerProducts();
      final orders = await orderRepo.getSellerOrders();
      final shop = await shopRepo.getShop();

      final now = DateTime.now();
      final todayOrders = orders.where((o) {
        final d = o.createdAt;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).length;

      final monthOrders = orders.where((o) {
        final d = o.createdAt;
        return d.year == now.year && d.month == now.month;
      }).toList();

      final monthRevenue = monthOrders
          .where((o) => o.status == 'delivered')
          .fold<double>(0, (sum, o) => sum + o.sellerRevenue);

      if (mounted) {
        setState(() {
          _todayOrders = todayOrders;
          _monthRevenue = monthRevenue;
          _totalProducts = products.length;
          _avgRating = products.isEmpty
              ? 0.0
              : products.map((p) => p.rating).reduce((a, b) => a + b) / products.length;
          _shop = shop;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSelling() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      final shop = await SellerShopRepository().toggleSelling();
      if (mounted) {
        setState(() {
          _shop = shop;
          _toggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shop?.isSelling == false
                  ? 'Đã tắt bán hàng - Sạp tạm đóng'
                  : 'Đã bật bán hàng - Sạp đang mở',
            ),
            backgroundColor: shop?.isSelling == false ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _toggling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.sellerPrimary,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563eb), Color(0xFF1d4ed8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Quản lý cửa hàng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            _buildIconBtn(Icons.notifications_outlined, () {
                              Navigator.pushNamed(context, '/buyer/notifications');
                            }),
                            const SizedBox(width: 8),
                            _buildIconBtn(Icons.settings_outlined, () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng sẽ sớm có mặt!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 2),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final name = state is AuthAuthenticated ? state.user.fullName : 'Người bán';
                            return Text(
                              'Xin chào, $name!',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        StatCardShimmer(),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: StatCardShimmer()),
                            SizedBox(width: 12),
                            Expanded(child: StatCardShimmer()),
                          ],
                        ),
                        SizedBox(height: 12),
                        StatCardShimmer(),
                      ],
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Selling Status Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (_shop?.isSelling ?? true) 
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (_shop?.isSelling ?? true)
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: (_shop?.isSelling ?? true)
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  (_shop?.isSelling ?? true) 
                                      ? Icons.storefront
                                      : Icons.storefront_outlined,
                                  color: (_shop?.isSelling ?? true) 
                                      ? Colors.green 
                                      : Colors.red,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Trạng thái bán hàng',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (_shop?.isSelling ?? true) 
                                          ? 'Đang mở bán' 
                                          : 'Tạm ngưng bán',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: (_shop?.isSelling ?? true) 
                                            ? Colors.green 
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _toggling
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Switch(
                                      value: _shop?.isSelling ?? true,
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                      inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
                                      onChanged: (value) => _toggleSelling(),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Đơn hàng hôm nay',
                          _todayOrders.toString(),
                          Icons.shopping_cart,
                          AppColors.sellerPrimary,
                          _todayOrders > 0 ? 'Tăng trưởng' : 'Chưa có đơn',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                'Doanh thu tháng',
                                _formatCurrency(_monthRevenue),
                                Icons.attach_money,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMiniStatCard(
                                'Sản phẩm',
                                _totalProducts.toString(),
                                Icons.inventory,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          'Đánh giá trung bình',
                          _avgRating > 0 ? '${_avgRating.toStringAsFixed(1)} ★' : 'Chưa có',
                          Icons.star,
                          Colors.amber,
                          _avgRating > 0 ? 'Rất tốt' : 'Chưa có đánh giá',
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Hướng dẫn nhanh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGuideCard(
                          Icons.add_circle_outline,
                          'Thêm sản phẩm mới',
                          'Bắt đầu bán hàng bằng cách thêm sản phẩm vào cửa hàng',
                          Colors.blue,
                        ),
                        const SizedBox(height: 10),
                        _buildGuideCard(
                          Icons.inventory_2_outlined,
                          'Quản lý sản phẩm',
                          'Cập nhật giá, số lượng và trạng thái sản phẩm',
                          Colors.orange,
                        ),
                        const SizedBox(height: 10),
                        _buildGuideCard(
                          Icons.receipt_long_outlined,
                          'Theo dõi đơn hàng',
                          'Xem và xử lý đơn hàng từ khách hàng',
                          Colors.green,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SellerProductBloc>().add(LoadSellerProducts());
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
          'Sản phẩm của tôi',
          style: TextStyle(
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.sellerPrimary),
            onPressed: () async {
              if (!await _guardSellerProductAccess(context)) return;
              final result = await Navigator.pushNamed(context, '/seller/add-product');
              if (result == true) context.read<SellerProductBloc>().add(RefreshSellerProducts());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (v) {
                  if (v.isEmpty) {
                    context.read<SellerProductBloc>().add(LoadSellerProducts());
                  } else {
                    context.read<SellerProductBloc>().add(LoadSellerProducts(keyword: v));
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SellerProductBloc, SellerProductState>(
              builder: (context, state) {
                if (state is SellerProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SellerProductLoaded) {
                  if (state.products.isEmpty) {
                    return _emptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<SellerProductBloc>().add(LoadSellerProducts());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.products.length,
                      itemBuilder: (ctx, i) => _buildTile(state.products[i]),
                    ),
                  );
                }
                return _emptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return EmptyState(
      icon: Icons.inventory_2,
      title: 'Chưa có sản phẩm nào',
      subtitle: 'Thêm sản phẩm đầu tiên để bắt đầu bán hàng ngay hôm nay',
      buttonText: 'Thêm sản phẩm',
      accentColor: AppColors.sellerPrimary,
      onButtonPressed: () async {
        if (!await _guardSellerProductAccess(context)) return;
        final result = await Navigator.pushNamed(context, '/seller/add-product');
        if (result == true) context.read<SellerProductBloc>().add(RefreshSellerProducts());
      },
    );
  }

  Widget _buildTile(Product product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          if (!await _guardSellerProductAccess(context)) return;
          final result = await Navigator.pushNamed(context, '/seller/add-product', arguments: product);
          if (result == true) context.read<SellerProductBloc>().add(RefreshSellerProducts());
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgPlaceholder(),
                          )
                        : _imgPlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: product.isAvailable ? const Color(0xFF111827) : Colors.grey,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: product.isAvailable
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                product.isAvailable ? 'Đang bán' : 'Tạm ngưng',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: product.isAvailable ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_formatPrice(product.price)} đ / ${product.unit}',
                          style: const TextStyle(
                            color: AppColors.sellerPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildProductChip(Icons.inventory_2_outlined, 'Tồn: ${product.stock}', const Color(0xFF4B5563), const Color(0xFFF3F4F6)),
                            _buildProductChip(Icons.shopping_basket_outlined, 'Tối thiểu ${product.minOrder}', AppColors.sellerPrimary, AppColors.sellerPrimary.withValues(alpha: 0.1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductChip(IconData icon, String text, Color foreground, Color background) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(fontSize: 11.5, color: foreground, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _imgPlaceholder() => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.image, color: Colors.grey[400], size: 24),
      );

  String _formatPrice(double p) {
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Đơn hàng',
          style: TextStyle(
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
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
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadOrders, child: const Text('Thử lại')),
        ],
      ));
    }
    if (_orders.isEmpty) {
      return Center(
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
              child: Icon(Icons.receipt_long, size: 52, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 17, color: Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (ctx, i) => _buildOrderCard(_orders[i]),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusInfo = _statusInfo(order.status);
    return GestureDetector(
      onTap: () => _showOrderDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(fontSize: 12, color: statusInfo.color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...order.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Color(0xFFcccccc)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${item.name} x${item.quantity} / ${item.unit}')),
                  Text('${_formatPrice(item.price * item.quantity)} đ', style: const TextStyle(fontSize: 13)),
                ],
              ),
            )),
            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${order.items.length - 3} sản phẩm khác',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            const Divider(height: 20),
            if (_sellerAction(order) != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatusFromCard(order, _sellerAction(order)!.nextStatus),
                  icon: Icon(_sellerAction(order)!.icon),
                  label: Text(_sellerAction(order)!.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sellerPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} sản phẩm',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  'Tổng hàng: ${_formatPrice(order.sellerRevenue)} đ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sellerPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(order.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatusFromCard(Order order, String newStatus) async {
    try {
      await OrderRepository().updateSellerOrderStatus(order.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái đơn hàng thành công'), backgroundColor: Colors.green),
      );
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateStatusAndClose(Order order, String newStatus) async {
    try {
      await OrderRepository().updateSellerOrderStatus(order.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái đơn hàng thành công'), backgroundColor: Colors.green),
      );
      await _loadOrders();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  ({String label, String nextStatus, IconData icon})? _sellerAction(Order order) {
    switch (order.status) {
      case 'shipper_accepted':
      case 'heading_to_market':
      case 'arrived_at_market':
        return (label: 'Xác nhận chuẩn bị xong', nextStatus: 'ready_for_pickup', icon: Icons.inventory);
      case 'ready_for_pickup':
        return (label: 'Xác nhận đã giao shipper', nextStatus: 'seller_handed_over', icon: Icons.local_shipping);
      default:
        return null;
    }
  }

  void _showOrderDetail(Order order) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(order.orderNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...order.items.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('${item.quantity} x ${_formatPrice(item.price)} ${item.unit}'),
              trailing: Text('${_formatPrice(item.price * item.quantity)} đ'),
            )),
            if (order.statusHistory != null && order.statusHistory!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Tiến trình đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              OrderStatusTimeline(history: order.statusHistory!),
            ],
            if (_sellerAction(order) != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatusAndClose(order, _sellerAction(order)!.nextStatus),
                  icon: Icon(_sellerAction(order)!.icon),
                  label: Text(_sellerAction(order)!.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sellerPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng hàng:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${_formatPrice(order.sellerRevenue)} đ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.sellerPrimary,
                    fontSize: 16,
                  ),
                ),
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
      case 'heading_to_market': return (label: 'Shipper đến chợ', color: Colors.indigo);
      case 'arrived_at_market': return (label: 'Shipper đã tới chợ', color: Colors.deepPurple);
      case 'ready_for_pickup': return (label: 'Đang chuẩn bị giao', color: Colors.teal);
      case 'seller_handed_over': return (label: 'Đã giao shipper', color: Colors.cyan);
      case 'picked_up': return (label: 'Shipper đã nhận đơn', color: Colors.lightBlue);
      case 'shopping': return (label: 'Đang mua', color: Colors.teal);
      case 'delivering': return (label: 'Đang giao', color: Colors.orange);
      case 'delivered': return (label: 'Đã giao', color: Colors.green);
      case 'cancelled': return (label: 'Đã hủy', color: Colors.red);
      default: return (label: status.isEmpty ? 'Không rõ' : status, color: Colors.grey);
    }
  }

  String _formatPrice(double p) {
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

  String _formatDateTime(DateTime d) => AppDateTime.formatDateTime(d);
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Hồ sơ',
          style: TextStyle(
            color: Color(0xFF1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                      colors: [Color(0xFF2563eb), Color(0xFF1d4ed8)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563eb).withValues(alpha: 0.22),
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
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563eb),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildBadge('Người bán'),
                                    _buildBadge(user.isApproved ? 'Đã duyệt' : 'Chờ duyệt'),
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
                          Expanded(child: _buildHeroStat('Điện thoại', user.phone, Icons.phone_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildHeroStat('Địa chỉ', user.address?.city?.isNotEmpty == true ? user.address!.city! : 'Chưa cập nhật', Icons.location_on_outlined)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Thông tin cá nhân',
                  children: [
                    _buildMenuItem(
                      icon: Icons.edit_outlined,
                      label: 'Chỉnh sửa thông tin',
                      onTap: () async {
                        final request = await showEditProfileSheet(
                          context,
                          user: user,
                          accentColor: AppColors.sellerPrimary,
                          roleLabel: 'người bán',
                        );
                        if (request == null || !context.mounted) return;
                        try {
                          final updatedUser = await AuthRepository().updateProfile(request.toJson());
                          if (!context.mounted) return;
                          context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cập nhật hồ sơ thành công'), behavior: SnackBarBehavior.floating),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      label: 'Họ tên',
                      trailing: Text(user.fullName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                    _buildMenuItem(
                      icon: Icons.phone_outlined,
                      label: 'Số điện thoại',
                      trailing: Text(user.phone, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                    _buildMenuItem(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      trailing: Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'Địa chỉ',
                      trailing: SizedBox(
                        width: 170,
                        child: Text(
                          user.address?.fullAddress.isNotEmpty == true ? user.address!.fullAddress : 'Chưa cập nhật',
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
                _buildSectionCard(
                  title: 'Tiện ích',
                  children: [
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      label: 'Trợ giúp & Hỗ trợ',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Liên hệ: hotro@vinguoitiêudùng.vn'), behavior: SnackBarBehavior.floating),
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
                      onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
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
      ),
    );
  }

  Widget _buildBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _buildHeroStat(String label, String value, IconData icon) => Container(
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
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ),
  );

  Widget _buildSectionCard({required String title, required List<Widget> children}) => Container(
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...children,
      ],
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
                color: (color ?? AppColors.sellerPrimary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color ?? AppColors.sellerPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? Colors.grey[800],
                  fontWeight: color != null ? FontWeight.normal : FontWeight.w500,
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
}
