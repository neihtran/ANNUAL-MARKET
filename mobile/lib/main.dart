import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/server_config_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/order/order_bloc.dart';
import 'presentation/blocs/seller/seller_product_bloc.dart';
import 'presentation/blocs/seller/seller_order_bloc.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/cart/cart_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/buyer/buyer_home_screen.dart';
import 'presentation/screens/buyer/market_detail_screen.dart';
import 'presentation/screens/buyer/product_detail_screen.dart';
import 'presentation/screens/buyer/cart_screen.dart';
import 'presentation/screens/buyer/checkout_screen.dart';
import 'presentation/screens/buyer/order_detail_screen.dart';
import 'presentation/screens/buyer/notifications_screen.dart';
import 'presentation/screens/buyer/buyer_address_screen.dart';
import 'presentation/screens/seller/seller_home_screen.dart';
import 'presentation/screens/seller/products_screen.dart';
import 'presentation/screens/seller/add_product_screen.dart';
import 'presentation/screens/seller/orders_screen.dart';
import 'presentation/screens/seller/profile_screen.dart';
import 'presentation/screens/shipper/shipper_home_screen.dart';
import 'presentation/screens/shipper/available_orders_screen.dart';
import 'presentation/screens/shipper/active_order_screen.dart';
import 'presentation/screens/shipper/order_detail_screen.dart';
import 'presentation/screens/shipper/history_screen.dart';
import 'presentation/screens/shipper/profile_screen.dart';
import 'data/models/product_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-load saved server URL
  await ServerConfigService.getServerUrl();
  runApp(const ChotruyenthongApp());
}

class ChotruyenthongApp extends StatefulWidget {
  const ChotruyenthongApp({super.key});

  @override
  State<ChotruyenthongApp> createState() => _ChotruyenthongAppState();
}

class _ChotruyenthongAppState extends State<ChotruyenthongApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc(),
        ),
        BlocProvider<SellerProductBloc>(
          create: (context) => SellerProductBloc(),
        ),
        BlocProvider<SellerOrderBloc>(
          create: (context) => SellerOrderBloc(),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(),
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          final role = user?.role ?? 'buyer';

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: _getTheme(role),
            // home is set by _buildHome — no BlocListener navigation conflicts
            home: _buildHome(state, role),
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  ThemeData _getTheme(String role) {
    switch (role) {
      case 'buyer':
        return AppTheme.buyerTheme;
      case 'seller':
        return AppTheme.sellerTheme;
      case 'shipper':
        return AppTheme.shipperTheme;
      default:
        return AppTheme.buyerTheme;
    }
  }

  Widget _buildHome(AuthState state, String role) {
    // Show splash while checking auth
    if (state is AuthLoading || state is AuthInitial) {
      return const SplashScreen();
    }
    // Pending approval — show waiting screen
    if (state is AuthPendingApproval) {
      return const _PendingApprovalScreen();
    }
    // Rejected — show rejection screen
    if (state is AuthRejected) {
      return _RejectedScreen(reason: state.reason);
    }
    // Banned
    if (state is AuthBanned) {
      return const _BannedScreen();
    }
    // User is authenticated — go to their home screen
    if (state is AuthAuthenticated) {
      switch (role) {
        case 'buyer':
          return const BuyerHomeScreen();
        case 'seller':
          return const SellerHomeScreen();
        case 'shipper':
          return const ShipperHomeScreen();
        default:
          return const LoginScreen();
      }
    }
    // Not authenticated — show login
    return const LoginScreen();
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case '/buyer':
        return MaterialPageRoute(builder: (_) => const BuyerHomeScreen());
      case '/buyer/market':
        final marketId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => MarketDetailScreen(marketId: marketId ?? ''),
        );
      case '/buyer/product':
        final arg = settings.arguments;
        final productId = arg is String ? arg : (arg is Product ? arg.id : '');
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );
      case '/buyer/cart':
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case '/buyer/checkout':
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case '/buyer/order':
        final orderId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => BuyerOrderDetailScreen(orderId: orderId ?? ''),
        );
      case '/buyer/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case '/buyer/addresses':
        return MaterialPageRoute(builder: (_) => const BuyerAddressScreen());

      case '/seller':
        return MaterialPageRoute(builder: (_) => const SellerHomeScreen());
      case '/seller/products':
        return MaterialPageRoute(builder: (_) => const ProductsScreen());
      case '/seller/add-product':
        final product = settings.arguments as Product?;
        return MaterialPageRoute(
          builder: (_) => AddProductScreen(product: product),
        );
      case '/seller/orders':
        return MaterialPageRoute(builder: (_) => const SellerOrdersScreen());
      case '/seller/profile':
        return MaterialPageRoute(builder: (_) => const SellerProfileScreen());

      case '/shipper':
        return MaterialPageRoute(builder: (_) => const ShipperHomeScreen());
      case '/shipper/available':
        return MaterialPageRoute(builder: (_) => const AvailableOrdersScreen());
      case '/shipper/active':
        return MaterialPageRoute(builder: (_) => const ActiveOrderScreen());
      case '/shipper/order':
        final orderId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ShipperOrderDetailScreen(orderId: orderId ?? ''),
        );
      case '/shipper/history':
        return MaterialPageRoute(builder: (_) => const ShipperHistoryScreen());
      case '/shipper/profile':
        return MaterialPageRoute(builder: (_) => const ShipperProfileScreen());

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    // Show retry button after 10 seconds if still on splash
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        // Check if still on splash by reading context
        final bloc = context.read<AuthBloc>();
        if (bloc.state is AuthLoading || bloc.state is AuthInitial) {
          setState(() => _showRetry = true);
        }
      }
    });
  }

  void _retry() {
    setState(() => _showRetry = false);
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shopping_basket,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chợ Truyền Thống',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mua sắm thực phẩm tươi sạch',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            if (!_showRetry) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đang kết nối...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Không thể kết nối máy chủ',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingApprovalScreen extends StatelessWidget {
  const _PendingApprovalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top,
                  size: 56,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tài khoản đang chờ duyệt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a1a),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tài khoản của bạn đã được gửi và đang chờ quản trị viên phê duyệt.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn sẽ nhận được thông báo khi tài khoản được duyệt. Vui lòng đăng nhập lại sau.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                      'Liên hệ hỗ trợ: hotro@vinguoitiêudùng.vn',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectedScreen extends StatelessWidget {
  final String reason;

  const _RejectedScreen({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  size: 56,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tài khoản bị từ chối',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a1a),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                reason.isNotEmpty ? reason : 'Tài khoản của bạn đã bị từ chối.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannedScreen extends StatelessWidget {
  const _BannedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  size: 56,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tài khoản đã bị khóa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a1a),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên để được hỗ trợ.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
