class Shop {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String? coverImage;
  final bool isOpen;
  final bool isSelling;
  final bool isApproved;
  final double rating;
  final int totalReviews;

  Shop({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    this.coverImage,
    this.isOpen = true,
    this.isSelling = true,
    this.isApproved = false,
    this.rating = 0,
    this.totalReviews = 0,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      avatar: json['avatar'],
      coverImage: json['coverImage'],
      isOpen: json['isOpen'] ?? true,
      isSelling: json['isSelling'] ?? true,
      isApproved: json['isApproved'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'coverImage': coverImage,
      'isOpen': isOpen,
      'isSelling': isSelling,
      'isApproved': isApproved,
      'rating': rating,
      'totalReviews': totalReviews,
    };
  }
}
