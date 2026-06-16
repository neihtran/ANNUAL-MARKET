class BuyerAddress {
  final String? id;
  final String address;
  final String? district;
  final String? city;
  final double lat;
  final double lng;
  final String contactName;
  final String contactPhone;
  final bool isDefault;
  final String? label;
  final String? instructions;

  BuyerAddress({
    this.id,
    required this.address,
    this.district,
    this.city,
    this.lat = 0,
    this.lng = 0,
    this.contactName = '',
    this.contactPhone = '',
    this.isDefault = false,
    this.label,
    this.instructions,
  });

  factory BuyerAddress.fromJson(Map<String, dynamic> json) {
    return BuyerAddress(
      id: json['_id'] ?? json['id'],
      address: json['address'] ?? json['fullAddress'] ?? '',
      district: json['district'],
      city: json['city'],
      lat: _toDouble(json['lat'] ?? json['location']?['lat']),
      lng: _toDouble(json['lng'] ?? json['location']?['lng']),
      contactName: json['contactName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      isDefault: json['isDefault'] ?? json['is_default'] ?? false,
      label: json['label'],
      instructions: json['instructions'],
    );
  }

  /// Serializes to backend-compatible JSON (uses `address` and nested `location`)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'address': address,
      if (district != null) 'district': district,
      if (city != null) 'city': city,
      'location': {
        'lat': lat,
        'lng': lng,
      },
      'contactName': contactName,
      'contactPhone': contactPhone,
      'isDefault': isDefault,
      if (label != null) 'label': label,
      if (instructions != null) 'instructions': instructions,
    };
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  BuyerAddress copyWith({
    String? id,
    String? address,
    String? district,
    String? city,
    double? lat,
    double? lng,
    String? contactName,
    String? contactPhone,
    bool? isDefault,
    String? label,
    String? instructions,
  }) {
    return BuyerAddress(
      id: id ?? this.id,
      address: address ?? this.address,
      district: district ?? this.district,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      instructions: instructions ?? this.instructions,
    );
  }
}
