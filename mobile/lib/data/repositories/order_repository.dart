import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../services/api_client.dart';
import '../../core/constants/app_datetime.dart';

class OrderRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Order>> getOrders({String? status, int page = 1, int limit = 20}) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) params['status'] = status;

      final response = await _apiClient.get('/orders/buyer', queryParameters: params);
      final data = response.data;
      
      if (data['success'] == true) {
        // sendPaginated sends orders[] directly in data field
        final ordersData = data['data'];
        final List<dynamic> rawList;
        if (ordersData is List) {
          rawList = ordersData.cast<dynamic>();
        } else if (ordersData is Map) {
          rawList = (ordersData['orders'] as List?)?.cast<dynamic>() ?? [];
        } else {
          rawList = [];
        }
        final orders = rawList
            .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return orders;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<Order> getOrderById(String id) async {
    try {
      final response = await _apiClient.get('/orders/$id');
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        // Handle both direct object and {order: ...} format
        Map<String, dynamic> orderData;
        if (rawData is Map<String, dynamic>) {
          // If data is {order: {...}}, extract it; otherwise use directly
          if (rawData.containsKey('order') && rawData['order'] is Map) {
            orderData = Map<String, dynamic>.from(rawData['order'] as Map);
          } else if (rawData.containsKey('_id')) {
            orderData = rawData;
          } else {
            orderData = {};
          }
        } else {
          throw Exception('Dữ liệu đơn hàng không hợp lệ');
        }
        return Order.fromJson(orderData);
      }
      throw Exception(data['message'] ?? 'Failed to load order');
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  Future<Order> createOrder({
    required String marketId,
    required List<Map<String, dynamic>> items,
    required DeliveryAddress deliveryAddress,
    required String paymentMethod,
    String? note,
  }) async {
    try {
      final response = await _apiClient.post('/orders', data: {
        'marketId': marketId,
        'items': items,
        'deliveryAddress': deliveryAddress.toJson(),
        'paymentMethod': paymentMethod,
        'note': note ?? '',
      });
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        final orderData = rawData is Map<String, dynamic>
            ? (rawData['order'] as Map<String, dynamic>? ?? rawData)
            : <String, dynamic>{};
        return Order.fromJson(orderData);
      }
      throw Exception(data['message'] ?? 'Failed to create order');
    } on DioException catch (e) {
      final errData = e.response?.data;
      if (errData != null && errData['error']?['details'] is List) {
        final details = errData['error']['details'] as List;
        final message = details.map((d) => d['message'] as String).join('; ');
        throw Exception(message);
      }
      final message = errData?['message'] ?? e.message ?? 'Failed to create order';
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> cancelOrder(String id, String reason) async {
    try {
      final response = await _apiClient.patch('/orders/$id/cancel', data: {'reason': reason});
      final data = response.data;
      
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Shipper endpoints
  Future<List<Order>> getAvailableOrders({double? lat, double? lng, double? maxDistance}) async {
    try {
      final params = <String, dynamic>{};
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lng'] = lng;
      if (maxDistance != null) params['maxDistance'] = maxDistance;

      final response = await _apiClient.get('/orders/shipper/available', queryParameters: params);
      final data = response.data;
      
      if (data['success'] == true) {
        final ordersData = data['data'];
        final List<dynamic> rawList;
        if (ordersData is List) {
          rawList = ordersData.cast<dynamic>();
        } else if (ordersData is Map) {
          rawList = (ordersData['orders'] as List?)?.cast<dynamic>() ?? [];
        } else {
          rawList = [];
        }
        return List<Order>.from(
          rawList.map<Order>((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load available orders: $e');
    }
  }

  Future<Order> acceptOrder(String orderId) async {
    try {
      final response = await _apiClient.patch('/orders/$orderId/accept');
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        final orderData = rawData is Map<String, dynamic>
            ? (rawData['order'] as Map<String, dynamic>? ?? rawData)
            : <String, dynamic>{};
        return Order.fromJson(orderData);
      }
      throw Exception(data['message'] ?? 'Failed to accept order');
    } catch (e) {
      throw Exception('Failed to accept order: $e');
    }
  }

  Future<void> updateShipperStatus(String orderId, String status, {String? note, String? confirmImageUrl}) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (note != null) body['note'] = note;
      if (confirmImageUrl != null) body['confirmImageUrl'] = confirmImageUrl;

      final response = await _apiClient.patch('/orders/$orderId/status', data: body);
      final data = response.data;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Seller: get own orders
  Future<List<Order>> getSellerOrders({String? status, int page = 1, int limit = 20}) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) params['status'] = status;

      final response = await _apiClient.get('/orders/seller', queryParameters: params);
      final data = response.data;

      if (data['success'] == true) {
        final ordersData = data['data'];
        final List<dynamic> rawList;
        if (ordersData is List) {
          rawList = ordersData.cast<dynamic>();
        } else if (ordersData is Map) {
          rawList = (ordersData['orders'] as List?)?.cast<dynamic>() ?? [];
        } else {
          rawList = [];
        }
        return List<Order>.from(
          rawList.map<Order>((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load seller orders: $e');
    }
  }

  Future<void> updateSellerOrderStatus(String orderId, String status, {String? note}) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (note != null) body['note'] = note;

      final response = await _apiClient.patch('/orders/$orderId/status', data: body);
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update seller order status');
      }
    } on DioException catch (e) {
      final errData = e.response?.data;
      if (errData != null && errData['error']?['details'] is List) {
        final details = errData['error']['details'] as List;
        throw Exception(details.map((d) => d['message'] as String).join('; '));
      }
      throw Exception(errData?['message'] ?? e.message ?? 'Failed to update seller order status');
    } catch (e) {
      throw Exception('Failed to update seller order status: $e');
    }
  }

  // Shipper: active orders
  Future<List<Order>> getShipperActiveOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/orders/shipper/active',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;

      if (data['success'] == true) {
        final ordersData = data['data'];
        final List<dynamic> rawList;
        if (ordersData is List) {
          rawList = ordersData.cast<dynamic>();
        } else if (ordersData is Map) {
          rawList = (ordersData['orders'] as List?)?.cast<dynamic>() ?? [];
        } else {
          rawList = [];
        }
        return List<Order>.from(
          rawList.map<Order>((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load active orders: $e');
    }
  }

  // Shipper: history orders
  Future<List<Order>> getShipperHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/orders/shipper/history',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;

      if (data['success'] == true) {
        final ordersData = data['data'];
        final List<dynamic> rawList;
        if (ordersData is List) {
          rawList = ordersData.cast<dynamic>();
        } else if (ordersData is Map) {
          rawList = (ordersData['orders'] as List?)?.cast<dynamic>() ?? [];
        } else {
          rawList = [];
        }
        return List<Order>.from(
          rawList.map<Order>((e) => Order.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }

  // Payment: VNPay
  Future<Map<String, dynamic>> createVNPayPayment(String orderId) async {
    try {
      final response = await _apiClient.post('/payment/vnpay/create', data: {'orderId': orderId});
      final data = response.data;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to create VNPay payment');
    } catch (e) {
      throw Exception('Failed to create VNPay payment: $e');
    }
  }

  // Payment: MoMo
  Future<Map<String, dynamic>> createMoMoPayment(String orderId) async {
    try {
      final response = await _apiClient.post('/payment/momo/create', data: {'orderId': orderId});
      final data = response.data;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to create MoMo payment');
    } catch (e) {
      throw Exception('Failed to create MoMo payment: $e');
    }
  }

  // ── GPS Tracking ──────────────────────────────────────────────
  // Buyer/Shipper: get real-time tracking data (shipper location, market, delivery)
  Future<OrderTrack> getOrderTrack(String orderId) async {
    try {
      final response = await _apiClient.get('/orders/$orderId/track');
      final data = response.data;
      if (data['success'] == true) {
        final rawData = data['data'];
        final trackData = rawData is Map<String, dynamic>
            ? (rawData['order'] as Map<String, dynamic>? ?? rawData)
            : <String, dynamic>{};
        return OrderTrack.fromJson(trackData);
      }
      throw Exception(data['message'] ?? 'Failed to load tracking data');
    } catch (e) {
      throw Exception('Failed to load tracking data: $e');
    }
  }

  // Shipper: update current GPS location while delivering
  Future<void> updateShipperLocation(String orderId, double lat, double lng) async {
    try {
      final response = await _apiClient.patch('/orders/$orderId/shipper-location', data: {'lat': lat, 'lng': lng});
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }
}

class OrderTrack {
  final String orderId;
  final String orderNumber;
  final String status;
  final TrackLocation market;
  final TrackLocation delivery;
  final ShipperTrackInfo? shipper;

  OrderTrack({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.market,
    required this.delivery,
    this.shipper,
  });

  factory OrderTrack.fromJson(Map<String, dynamic> json) {
    return OrderTrack(
      orderId: (json['orderId'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      market: TrackLocation.fromJson(json['market'] ?? {}),
      delivery: TrackLocation.fromJson(json['delivery'] ?? {}),
      shipper: json['shipper'] != null ? ShipperTrackInfo.fromJson(json['shipper']) : null,
    );
  }
}

class TrackLocation {
  final String name;
  final String address;
  final double? lat;
  final double? lng;

  TrackLocation({required this.name, required this.address, this.lat, this.lng});

  factory TrackLocation.fromJson(Map<String, dynamic> json) {
    return TrackLocation(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  bool get hasCoords => lat != null && lng != null;
}

class ShipperTrackInfo {
  final String name;
  final String phone;
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  ShipperTrackInfo({required this.name, required this.phone, required this.lat, required this.lng, this.updatedAt});

  factory ShipperTrackInfo.fromJson(Map<String, dynamic> json) {
    return ShipperTrackInfo(
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      updatedAt: json['updatedAt'] != null
          ? AppDateTime.parseToLocal(json['updatedAt'])
          : null,
    );
  }
}
