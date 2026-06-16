class User {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? avatar;
  final String role;
  final String status;
  final bool isApproved;
  final Address? address;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.avatar,
    required this.role,
    required this.status,
    required this.isApproved,
    this.address,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'buyer',
      status: json['status'] ?? 'active',
      isApproved: json['isApproved'] ?? false,
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'status': status,
      'isApproved': isApproved,
      'address': address?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isBuyer => role == 'buyer';
  bool get isSeller => role == 'seller';
  bool get isShipper => role == 'shipper';
  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';
  bool get isPendingApproval => !isApproved && status == 'inactive';
  bool get isRejected => status == 'rejected';
}

class Address {
  final String? street;
  final String? ward;
  final String? district;
  final String? city;
  final Coordinates? coordinates;

  Address({
    this.street,
    this.ward,
    this.district,
    this.city,
    this.coordinates,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      ward: json['ward'],
      district: json['district'],
      city: json['city'],
      coordinates: json['coordinates'] != null 
          ? Coordinates.fromJson(json['coordinates']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'ward': ward,
      'district': district,
      'city': city,
      'coordinates': coordinates?.toJson(),
    };
  }

  String get fullAddress {
    final parts = [street, ward, district, city].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }
}

class Coordinates {
  final double lat;
  final double lng;

  Coordinates({required this.lat, required this.lng});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}
