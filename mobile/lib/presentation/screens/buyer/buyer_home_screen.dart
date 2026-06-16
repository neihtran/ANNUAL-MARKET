import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/blocs.dart';
import '../../widgets/edit_profile_sheet.dart';
import '../../widgets/widgets.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;

  void setTabIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // SocketService().connect(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ExploreTab(),
          _SearchTab(),
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
          selectedItemColor: AppColors.buyerPrimary,
          unselectedItemColor: Colors.grey[400],
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search),
              label: 'Tìm kiếm',
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
    );
  }
}

class _ExploreTab extends StatefulWidget {
  const _ExploreTab();

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  List<Market> _markets = [];
  bool _loading = true;
  String? _errorMessage;
  final _searchCtrl = TextEditingController();
  String? _searchQuery;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  Future<void> _loadMarkets([String? searchQuery]) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
        _searchQuery = searchQuery;
      });
    }
    try {
      final repository = MarketRepository();
      final position = await _getCurrentPosition();
      var markets = await repository.getNearbyMarkets(
        lat: position?.latitude,
        lng: position?.longitude,
        search: searchQuery,
      );

      if (markets.isEmpty) {
        markets = await repository.getNearbyMarkets(search: searchQuery);
      }

      if (mounted) {
        setState(() {
          _markets = markets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _markets = [];
          _loading = false;
          _errorMessage = 'Không thể tải danh sách chợ lúc này';
        });
      }
      debugPrint('Failed to load markets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isSmallScreen ? 140 : 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.buyerPrimary,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFf97316), Color(0xFFea580c)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 4 : 8,
                      isSmallScreen ? 16 : 20,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Khám phá chợ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 22 : 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            _buildIconBtn(Icons.notifications_outlined, () {
                              Navigator.pushNamed(context, '/buyer/notifications');
                            }, isSmallScreen),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            _buildIconBtn(Icons.shopping_cart_outlined, () {
                              Navigator.pushNamed(context, '/buyer/cart');
                            }, isSmallScreen),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 0 : 2),
                        Text(
                          'Mua sắm thực phẩm tươi sạch',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(color: Colors.black87, fontSize: isSmallScreen ? 13 : 14),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm chợ hoặc sản phẩm...',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: isSmallScreen ? 13 : 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: isSmallScreen ? 20 : 24),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[400], size: isSmallScreen ? 16 : 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _loadMarkets();
                                        setState(() => _isSearching = false);
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 20,
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (v) {
                              _loadMarkets(v.trim().isNotEmpty ? v.trim() : null);
                              setState(() => _isSearching = v.trim().isNotEmpty);
                            },
                          ),
                        ),
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
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.buyerPrimary)),
                  )
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap, [bool isSmall = false]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmall ? 36 : 40,
        height: isSmall ? 36 : 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: isSmall ? 20 : 22),
      ),
    );
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        accentColor: AppColors.buyerPrimary,
        onRetry: _loadMarkets,
      );
    }
    if (_markets.isEmpty) {
      return EmptyState(
        icon: Icons.store_outlined,
        title: 'Chưa tìm thấy chợ phù hợp',
        subtitle: 'Hãy thử cập nhật vị trí của bạn',
        buttonText: 'Làm mới',
        onButtonPressed: _loadMarkets,
        accentColor: AppColors.buyerPrimary,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isSmallScreen ? 12 : 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          child: Row(
            children: [
              Icon(Icons.location_on, size: isSmallScreen ? 14 : 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _searchQuery != null && _searchQuery!.isNotEmpty
                    ? 'Kết quả tìm kiếm: "$_searchQuery"'
                    : 'Chợ gần bạn',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                '${_markets.length} chợ',
                style: TextStyle(fontSize: isSmallScreen ? 11 : 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        ..._markets.map((m) => _MarketCard(
          market: m,
          onTap: () => Navigator.pushNamed(context, '/buyer/market', arguments: m.id),
        )),
        SizedBox(height: isSmallScreen ? 80 : 100),
      ],
    );
  }

  Widget _buildEmptyState({
    String title = 'Chưa tìm thấy chợ phù hợp',
    String subtitle = 'Hãy thử cập nhật vị trí của bạn',
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 17, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadMarkets,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.buyerPrimary,
              side: const BorderSide(color: AppColors.buyerPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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

class _MarketCard extends StatelessWidget {
  final Market market;
  final VoidCallback onTap;

  const _MarketCard({required this.market, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final imageHeight = isSmallScreen ? 140.0 : 168.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        market.images.isNotEmpty
                            ? Image.network(
                                market.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imgPlaceholder(isSmall: isSmallScreen),
                              )
                            : _imgPlaceholder(isSmall: isSmallScreen),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.04), Colors.black.withValues(alpha: 0.35)],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 5 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront, size: isSmallScreen ? 12 : 14, color: AppColors.buyerPrimary),
                                SizedBox(width: isSmallScreen ? 4 : 6),
                                Flexible(
                                  child: Text(
                                    'Chợ truyền thống',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 5 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: (market.isCurrentlyOpen ? Colors.green : Colors.grey).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  market.isCurrentlyOpen ? Icons.check_circle : Icons.cancel,
                                  color: Colors.white,
                                  size: isSmallScreen ? 10 : 12,
                                ),
                                SizedBox(width: isSmallScreen ? 4 : 5),
                                Text(
                                  market.isCurrentlyOpen ? 'Đang mở' : 'Đã đóng',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 10 : 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  market.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.arrow_forward, color: Colors.white, size: isSmallScreen ? 16 : 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: isSmallScreen ? 28 : 32,
                            height: isSmallScreen ? 28 : 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.location_on_outlined, size: isSmallScreen ? 14 : 17, color: AppColors.buyerPrimary),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 10),
                          Expanded(
                            child: Text(
                              market.address,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: const Color(0xFF6B7280),
                                height: 1.45,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetaChip(
                            icon: Icons.access_time,
                            text: '${market.openTime} - ${market.closeTime}',
                            foreground: AppColors.buyerPrimary,
                            background: AppColors.buyerPrimary.withValues(alpha: 0.1),
                            isSmall: isSmallScreen,
                          ),
                          if (market.distance != null)
                            _buildMetaChip(
                              icon: Icons.route,
                              text: '~${market.distance!.toStringAsFixed(1)} km',
                              foreground: const Color(0xFF4B5563),
                              background: const Color(0xFFF3F4F6),
                              isSmall: isSmallScreen,
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
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String text,
    required Color foreground,
    required Color background,
    bool isSmall = false,
  }) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 12,
          vertical: isSmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isSmall ? 11 : 13, color: foreground),
            SizedBox(width: isSmall ? 4 : 6),
            Text(
              text,
              style: TextStyle(fontSize: isSmall ? 10 : 12, color: foreground, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _imgPlaceholder({bool isSmall = false}) => Container(
        color: const Color(0xFFF3F4F6),
        child: Icon(Icons.store, size: isSmall ? 46 : 54, color: Colors.grey[400]),
      );
}

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _searchCtrl = TextEditingController();
  List<Product> _results = [];
  bool _loading = false;
  bool _searched = false;

  // Filter state
  List<Category> _categories = [];
  String? _selectedCategoryId;
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;
  String? _sortOrder;
  bool _filtersApplied = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await MarketRepository().getMarketCategories('all');
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _doSearch([String? overrideQuery]) async {
    final q = overrideQuery ?? _searchCtrl.text.trim();
    if (q.isEmpty && !_filtersApplied) {
      setState(() { _results = []; _searched = false; });
      return;
    }
    setState(() { _loading = true; _searched = true; });
    try {
      final products = await ProductRepository().getProducts(
        keyword: q.isNotEmpty ? q : null,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sort: _sortBy,
      );
      if (mounted) setState(() { _results = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _results = []; _loading = false; });
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
          _doSearch();
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() { _results = []; _searched = false; });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: _doSearch,
            textInputAction: TextInputAction.search,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _filtersApplied
                    ? const Color(0xFFf97316).withValues(alpha: 0.12)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    color: _filtersApplied ? const Color(0xFFf97316) : Colors.grey[600],
                    size: 20,
                  ),
                  if (_filtersApplied) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFf97316),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _doSearch(),
            child: const Text('Tìm', style: TextStyle(color: AppColors.buyerPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.buyerPrimary));
    }
    if (!_searched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Tìm kiếm sản phẩm', style: TextStyle(fontSize: 17, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Nhập tên sản phẩm bạn muốn tìm', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Không tìm thấy sản phẩm nào', style: TextStyle(fontSize: 17, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Thử từ khóa khác', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _buildProductItem(_results[i]),
    );
  }

  Widget _buildProductItem(Product product) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/buyer/product', arguments: product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: product.images.isNotEmpty
                    ? Image.network(product.images.first, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder())
                    : _imgPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${_formatPrice(product.price)} đ / ${product.unit}',
                    style: const TextStyle(color: AppColors.buyerPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  if (product.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text('${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: Colors.grey[200],
    child: Icon(Icons.image, size: 30, color: Colors.grey[400]),
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
      final orders = await OrderRepository().getOrders();
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
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
            onPressed: () {
              Navigator.pushNamed(context, '/buyer/notifications');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.buyerPrimary));
    if (_error != null) {
      return ErrorState(
        message: _error!,
        accentColor: AppColors.buyerPrimary,
        onRetry: _loadOrders,
      );
    }
    if (_orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Chưa có đơn hàng nào',
        subtitle: 'Bắt đầu mua sắm ngay hôm nay',
        buttonText: 'Khám phá chợ',
        accentColor: AppColors.buyerPrimary,
        onButtonPressed: () {
          final parent = context.findAncestorStateOfType<_BuyerHomeScreenState>();
          parent?.setTabIndex(0);
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (ctx, i) => OrderCard(
        order: _orders[i],
        userRole: 'buyer',
        onTap: () => Navigator.pushNamed(context, '/buyer/order', arguments: _orders[i].id),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final si = _statusInfo(order.status);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/buyer/order', arguments: order.id),
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
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: si.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    si.label,
                    style: TextStyle(fontSize: 12, color: si.color, fontWeight: FontWeight.w600),
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
                  Text(
                    '${_formatPrice(item.price * item.quantity)} đ',
                    style: const TextStyle(fontSize: 13),
                  ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} sản phẩm',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  'Tổng: ${_formatPrice(order.total)} đ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.buyerPrimary),
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

  ({String label, Color color}) _statusInfo(String? status) {
    switch (status) {
      case 'pending': return (label: 'Chờ xác nhận', color: Colors.orange);
      case 'finding_shipper': return (label: 'Đang tìm shipper', color: Colors.blue);
      case 'shipper_accepted': return (label: 'Shipper đã nhận', color: Colors.purple);
      case 'heading_to_market': return (label: 'Đang đến chợ', color: Colors.indigo);
      case 'arrived_at_market': return (label: 'Đã đến chợ', color: Colors.deepPurple);
      case 'ready_for_pickup': return (label: 'Seller đang chuẩn bị giao', color: Colors.teal);
      case 'seller_handed_over': return (label: 'Seller đã giao shipper', color: Colors.cyan);
      case 'picked_up': return (label: 'Shipper đã nhận đơn', color: Colors.lightBlue);
      case 'shopping': return (label: 'Đang mua', color: Colors.teal);
      case 'delivering': return (label: 'Đang giao', color: Colors.blue);
      case 'delivered': return (label: 'Đã giao', color: Colors.green);
      case 'cancelled': return (label: 'Đã hủy', color: Colors.red);
      default: return (label: status == null || status.isEmpty ? 'Không rõ' : status, color: Colors.grey);
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

  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng sẽ sớm có mặt!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
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
                      colors: [Color(0xFFf97316), Color(0xFFea580c)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFf97316).withValues(alpha: 0.22),
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
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFf97316)),
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
                                    _buildProfileBadge('Người mua'),
                                    _buildProfileBadge(user.phone),
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
                          Expanded(child: _buildHeroInfoCard('Đơn hàng', 'Quản lý đơn nhanh', Icons.shopping_bag_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildHeroInfoCard('Địa chỉ', user.address?.city?.isNotEmpty == true ? user.address!.city! : 'Chưa có', Icons.location_on_outlined)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildProfileSection(
                  title: 'Tài khoản',
                  children: [
                    _buildMenuItem(
                      icon: Icons.edit_outlined,
                      label: 'Chỉnh sửa thông tin',
                      onTap: () async {
                        final request = await showEditProfileSheet(
                          context,
                          user: user,
                          accentColor: AppColors.buyerPrimary,
                          roleLabel: 'người mua',
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
                      icon: Icons.shopping_bag_outlined,
                      label: 'Đơn hàng của tôi',
                      onTap: () {
                        final parent = context.findAncestorStateOfType<_BuyerHomeScreenState>();
                        parent?.setTabIndex(2);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'Địa chỉ giao hàng',
                      onTap: () {
                        Navigator.pushNamed(context, '/buyer/addresses');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      label: 'Họ tên',
                      onTap: () {},
                      trailing: Text(user.fullName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                    _buildMenuItem(
                      icon: Icons.phone_outlined,
                      label: 'Số điện thoại',
                      onTap: () {},
                      trailing: Text(user.phone, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfileSection(
                  title: 'Tiện ích',
                  children: [
                    _buildMenuItem(
                      icon: Icons.favorite_outline,
                      label: 'Sản phẩm yêu thích',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng sẽ sớm có mặt!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Thông báo',
                      onTap: () {
                        Navigator.pushNamed(context, '/buyer/notifications');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      label: 'Đổi mật khẩu',
                      onTap: () => _showChangePasswordDialog(context),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? AppColors.buyerPrimary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color ?? AppColors.buyerPrimary, size: 20),
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
            if (trailing == null) Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _buildHeroInfoCard(String label, String value, IconData icon) => Container(
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

  Widget _buildProfileSection({required String title, required List<Widget> children}) => Container(
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

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Nhập mật khẩu hiện tại' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nhập mật khẩu mới';
                    if (v.length < 6) return 'Mật khẩu mới ít nhất 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != newCtrl.text) return 'Mật khẩu không khớp';
                    return null;
                  },
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() { loading = true; errorMsg = null; });
                      try {
                        await AuthRepository().changePassword(
                          currentPassword: currentCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() { loading = false; errorMsg = e.toString().replaceFirst('Exception: ', ''); });
                      }
                    },
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}
