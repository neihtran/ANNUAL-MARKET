import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConstants {
  static const String appName = 'Chợ Truyền Thống';
  static const String appVersion = '1.0.0';
  // API URL priority:
  // 1. --dart-define=API_BASE_URL=...
  // 2. Web uses localhost
  // 3. Native devices use the local network IP below
  // Use `androidEmulatorBaseUrl` explicitly when running on an emulator.
  static String get baseUrl {
    const envUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:3001/api/v1';

    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://$defaultServerIp:3001/api/v1';
    }

    return 'http://$defaultServerIp:3001/api/v1';
  }

  static String get baseDomain => 'http://$defaultServerIp:3001';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String userRoleKey = 'user_role';
  static const String apiBaseUrlKey = 'api_base_url';
  static const String defaultServerIp = '172.20.10.2';

  // User Roles
  static const String roleBuyer = 'buyer';
  static const String roleSeller = 'seller';
  static const String roleShipper = 'shipper';
  static const String roleAdmin = 'admin';

  // Order Status — matches backend Order.status enum
  static const String statusPending = 'pending';
  static const String statusFindingShipper = 'finding_shipper';
  static const String statusShipperAccepted = 'shipper_accepted';
  static const String statusHeadingToMarket = 'heading_to_market';
  static const String statusArrivedAtMarket = 'arrived_at_market';
  static const String statusReadyForPickup = 'ready_for_pickup';
  static const String statusSellerHandedOver = 'seller_handed_over';
  static const String statusPickedUp = 'picked_up';
  static const String statusShopping = 'shopping';
  static const String statusDelivering = 'delivering';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Payment Methods
  static const String paymentCod = 'cod';
  static const String paymentMomo = 'momo';
  static const String paymentVnpay = 'vnpay';

  // Categories
  static const Map<String, String> categoryLabels = {
    'vegetables': 'Rau củ',
    'fruits': 'Trái cây',
    'meat': 'Thịt',
    'seafood': 'Hải sản',
    'eggs': 'Trứng',
    'others': 'Khác',
  };

  // Order Status Labels — Vietnamese
  static const Map<String, String> orderStatusLabels = {
    'pending': 'Chờ xử lý',
    'finding_shipper': 'Đang tìm shipper',
    'shipper_accepted': 'Shipper đã nhận',
    'heading_to_market': 'Đang đến chợ',
    'arrived_at_market': 'Đã đến chợ',
    'ready_for_pickup': 'Chờ lấy hàng',
    'seller_handed_over': 'Seller đã bàn giao',
    'picked_up': 'Đã nhận hàng',
    'shopping': 'Đang mua hàng',
    'delivering': 'Đang giao',
    'delivered': 'Đã giao',
    'cancelled': 'Đã hủy',
  };

  // Pagination
  static const int defaultPageSize = 20;

  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 300);
}
