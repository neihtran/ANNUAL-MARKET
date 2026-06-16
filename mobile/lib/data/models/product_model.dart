class Product {
  final String id;
  final String shopId;
  final String sellerId;
  final String sellerName;
  final String marketId;
  final String categoryId;
  final String name;
  final String description;
  final List<String> images;
  final double price;
  final String unit;
  final int stock;
  final int minOrder;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.shopId,
    required this.sellerId,
    this.sellerName = '',
    required this.marketId,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.images = const [],
    required this.price,
    this.unit = 'kg',
    this.stock = 0,
    this.minOrder = 1,
    this.isAvailable = true,
    this.rating = 0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      shopId: _extractId(json['shopId']),
      sellerId: _extractId(json['sellerId']),
      sellerName: _extractSellerName(json),
      marketId: _extractId(json['marketId']),
      categoryId: _extractId(json['categoryId']),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      price: _pToDouble(json['price']),
      unit: json['unit'] ?? 'kg',
      stock: _pToInt(json['stock']),
      minOrder: _pToInt(json['minOrder'], fallback: 1),
      isAvailable: json['isAvailable'] ?? true,
      rating: _pToDouble(json['rating']),
      reviewCount: _pToInt(json['reviewCount']),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  static String _extractId(dynamic val) {
    if (val == null) return '';
    if (val is String) return val;
    if (val is Map) return val['_id']?.toString() ?? val['id']?.toString() ?? '';
    return val.toString();
  }

  static String _extractSellerName(Map<String, dynamic> json) {
    final directName = json['sellerName'] ?? json['shopName'] ?? json['seller']?['fullName'];
    if (directName is String && directName.trim().isNotEmpty) {
      return directName.trim();
    }

    final seller = json['sellerId'];
    if (seller is Map) {
      final nestedName = seller['fullName'] ?? seller['name'] ?? seller['shopName'];
      if (nestedName is String && nestedName.trim().isNotEmpty) {
        return nestedName.trim();
      }
    }

    final shop = json['shopId'];
    if (shop is Map) {
      final shopOwner = shop['ownerId'];
      final shopName = shop['name'];
      if (shopName is String && shopName.trim().isNotEmpty) {
        return shopName.trim();
      }
      if (shopOwner is Map) {
        final ownerName = shopOwner['fullName'] ?? shopOwner['name'];
        if (ownerName is String && ownerName.trim().isNotEmpty) {
          return ownerName.trim();
        }
      }
    }

    return '';
  }

  static double _pToDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  static int _pToInt(dynamic val, {int fallback = 0}) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'marketId': marketId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'images': images,
      'price': price,
      'unit': unit,
      'stock': stock,
      'minOrder': minOrder,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
