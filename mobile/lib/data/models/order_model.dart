import '../../core/constants/app_datetime.dart';

class OrderItem {
  final String productId;
  final String shopId;
  final String shopName;
  final String name;
  final String? imageUrl;
  final double price;
  final int quantity;
  final String unit;

  OrderItem({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.quantity,
    this.unit = 'kg',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String resolvedProductId = '';
    if (json['productId'] is Map) {
      resolvedProductId = json['productId']['_id'] ?? json['productId']['id'] ?? '';
    } else {
      resolvedProductId = json['productId'] ?? '';
    }

    // Safely parse quantity (handle string values)
    int parsedQty = 1;
    final qtyVal = json['quantity'];
    if (qtyVal is int) {
      parsedQty = qtyVal;
    } else if (qtyVal is double) {
      parsedQty = qtyVal.toInt();
    } else if (qtyVal is String) {
      parsedQty = int.tryParse(qtyVal) ?? 1;
    }

    return OrderItem(
      productId: resolvedProductId,
      shopId: json['shopId'] is Map ? (json['shopId']['_id'] ?? '') : (json['shopId'] ?? ''),
      shopName: (json['shopName'] ?? '').toString(),
      name: (json['productName'] ?? json['name'] ?? '').toString(),
      imageUrl: json['imageUrl'] ?? json['image'],
      price: _itemToDouble(json['price']),
      quantity: parsedQty,
      unit: json['unit'] ?? 'kg',
    );
  }

  static double _itemToDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'shopId': shopId,
      'shopName': shopName,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class DeliveryAddress {
  final String address;
  final double lat;
  final double lng;
  final String contactName;
  final String contactPhone;

  DeliveryAddress({
    required this.address,
    required this.lat,
    required this.lng,
    required this.contactName,
    required this.contactPhone,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      address: json['address'] ?? '',
      lat: _addrToDouble(json['lat']),
      lng: _addrToDouble(json['lng']),
      contactName: json['contactName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
    );
  }

  static double _addrToDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'lat': lat,
      'lng': lng,
      'contactName': contactName,
      'contactPhone': contactPhone,
    };
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String buyerId;
  final String marketId;
  final String? shipperId;
  final List<OrderItem> items;
  final DeliveryAddress deliveryAddress;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String note;
  final String cancelReason;
  final double shippingDistance;
  final int estimatedMinutes;
  final String? confirmImageUrl;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Populated fields from API
  final OrderMarket? market;
  final OrderUser? buyer;
  final OrderUser? shipper;
  final List<OrderStatusHistory>? statusHistory;
  /// GPS distance from shipper to market (km) — returned by /orders/shipper/available when lat/lng provided
  final double? distance;

  double get itemsTotal => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get sellerRevenue => itemsTotal;
  double get shipperRevenue => shippingFee;

  Order({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.marketId,
    this.shipperId,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    this.shippingFee = 0,
    this.discount = 0,
    required this.total,
    required this.status,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'unpaid',
    this.note = '',
    this.cancelReason = '',
    this.shippingDistance = 0,
    this.estimatedMinutes = 0,
    this.confirmImageUrl,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.market,
    this.buyer,
    this.shipper,
    this.statusHistory,
    this.distance,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Safely parse items
    List<OrderItem> parsedItems = [];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(OrderItem.fromJson(item));
        }
      }
    }

    // Safely parse deliveryAddress
    DeliveryAddress parsedAddress = DeliveryAddress(address: '', lat: 0, lng: 0, contactName: '', contactPhone: '');
    final rawAddress = json['deliveryAddress'];
    if (rawAddress is Map<String, dynamic>) {
      parsedAddress = DeliveryAddress.fromJson(rawAddress);
    }

    // Safely parse statusHistory
    List<OrderStatusHistory> parsedHistory = [];
    final rawHistory = json['statusHistory'];
    if (rawHistory is List) {
      for (final h in rawHistory) {
        if (h is Map<String, dynamic>) {
          parsedHistory.add(OrderStatusHistory.fromJson(h));
        }
      }
    }

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      buyerId: _extractId(json['buyerId'] ?? json['buyer']?['_id'] ?? json['buyer'] ?? ''),
      marketId: _extractId(json['marketId'] ?? json['market']?['_id'] ?? json['market'] ?? ''),
      shipperId: json['shipperId'] != null ? _extractId(json['shipperId']) : null,
      items: parsedItems,
      deliveryAddress: parsedAddress,
      subtotal: _toDouble(json['subtotal']),
      shippingFee: _toDouble(json['shippingFee']),
      discount: _toDouble(json['discount']),
      total: _toDouble(json['total']),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'cod',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      note: json['note'] ?? '',
      cancelReason: json['cancelReason'] ?? '',
      shippingDistance: _toDouble(json['shippingDistance']),
      estimatedMinutes: _toInt(json['estimatedMinutes']),
      confirmImageUrl: json['confirmImageUrl'],
      deliveredAt: json['deliveredAt'] != null
          ? AppDateTime.parseToLocal(json['deliveredAt'])
          : null,
      createdAt: AppDateTime.parseToLocal(json['createdAt']),
      updatedAt: AppDateTime.parseToLocal(json['updatedAt']),
      market: json['market'] != null && json['market'] is Map ? OrderMarket.fromJson(json['market']) : null,
      buyer: json['buyer'] != null && json['buyer'] is Map ? OrderUser.fromJson(json['buyer']) : null,
      shipper: json['shipper'] != null && json['shipper'] is Map ? OrderUser.fromJson(json['shipper']) : null,
      statusHistory: parsedHistory.isNotEmpty ? parsedHistory : null,
      distance: json['distance'] != null ? _toDouble(json['distance']) : null,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static String _extractId(dynamic val) {
    if (val == null) return '';
    if (val is String) return val;
    if (val is Map) return val['_id'] ?? val['id'] ?? '';
    return val.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'buyerId': buyerId,
      'marketId': marketId,
      'shipperId': shipperId,
      'items': items.map((e) => e.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'note': note,
      'cancelReason': cancelReason,
      'shippingDistance': shippingDistance,
      'estimatedMinutes': estimatedMinutes,
      'confirmImageUrl': confirmImageUrl,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class OrderMarket {
  final String id;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;

  OrderMarket({required this.id, required this.name, this.address, this.lat, this.lng});

  factory OrderMarket.fromJson(Map<String, dynamic> json) {
    return OrderMarket(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: json['address']?.toString(),
      lat: (json['location']?['lat'] ?? json['lat'] ?? 0).toDouble(),
      lng: (json['location']?['lng'] ?? json['lng'] ?? 0).toDouble(),
    );
  }
}

class OrderUser {
  final String id;
  final String fullName;
  final String? phone;
  final String? avatar;

  OrderUser({required this.id, required this.fullName, this.phone, this.avatar});

  factory OrderUser.fromJson(Map<String, dynamic> json) {
    return OrderUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }
}

class OrderStatusHistory {
  final String status;
  final DateTime timestamp;
  final String? note;

  OrderStatusHistory({required this.status, required this.timestamp, this.note});

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: (json['status'] ?? '').toString(),
      timestamp: AppDateTime.parseToLocal(json['timestamp']),
      note: json['note']?.toString(),
    );
  }
}
