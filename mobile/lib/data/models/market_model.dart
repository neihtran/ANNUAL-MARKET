class Market {
  final String id;
  final String name;
  final String address;
  final Map<String, double> location;
  final List<String> images;
  final String openTime;
  final String closeTime;
  final String description;
  final bool isActive;
  final bool is24h;
  final bool isCurrentlyOpen;
  final DateTime createdAt;
  final double? distance;

  Market({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.images = const [],
    this.openTime = '06:00',
    this.closeTime = '18:00',
    this.description = '',
    this.isActive = true,
    this.is24h = false,
    this.isCurrentlyOpen = true,
    required this.createdAt,
    this.distance,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    // Calculate real-time open status
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final openTime = json['openTime'] ?? '06:00';
    final closeTime = json['closeTime'] ?? '18:00';
    final is24h = json['is24h'] ?? false;
    final isActive = json['isActive'] ?? true;
    final isCurrentlyOpen = is24h || (isActive && currentTime.compareTo(openTime) >= 0 && currentTime.compareTo(closeTime) <= 0);

    return Market(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      location: {
        'lat': (json['location']?['lat'] ?? 0).toDouble(),
        'lng': (json['location']?['lng'] ?? 0).toDouble(),
      },
      images: List<String>.from(json['images'] ?? []),
      openTime: openTime,
      closeTime: closeTime,
      description: json['description'] ?? '',
      isActive: isActive,
      is24h: is24h,
      isCurrentlyOpen: json['isCurrentlyOpen'] ?? isCurrentlyOpen,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': location,
      'images': images,
      'openTime': openTime,
      'closeTime': closeTime,
      'description': description,
      'isActive': isActive,
      'is24h': is24h,
      'isCurrentlyOpen': isCurrentlyOpen,
      'createdAt': createdAt.toIso8601String(),
      'distance': distance,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? icon;
  final String description;
  final String? parentId;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.description = '',
    this.parentId,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      description: json['description'] ?? '',
      parentId: json['parentId'],
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'parentId': parentId,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}
