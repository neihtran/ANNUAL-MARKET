class SellerReviewModel {
  final String? id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final int rating;
  final ReviewAspects? aspects;
  final String comment;
  final bool isVerified;
  final String? sellerReply;
  final DateTime? replyAt;
  final DateTime? createdAt;

  SellerReviewModel({
    this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.rating,
    this.aspects,
    this.comment = '',
    this.isVerified = true,
    this.sellerReply,
    this.replyAt,
    this.createdAt,
  });

  factory SellerReviewModel.fromJson(Map<String, dynamic> json) {
    return SellerReviewModel(
      id: json['_id']?.toString(),
      orderId: (json['orderId'] ?? '').toString(),
      buyerId: (json['buyerId'] ?? '').toString(),
      sellerId: (json['sellerId'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      aspects: json['aspects'] != null ? ReviewAspects.fromJson(json['aspects']) : null,
      comment: (json['comment'] ?? '').toString(),
      isVerified: json['isVerified'] ?? true,
      sellerReply: json['sellerReply']?.toString(),
      replyAt: json['replyAt'] != null ? DateTime.tryParse(json['replyAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'sellerId': sellerId,
      'rating': rating,
      if (aspects != null) 'aspects': aspects!.toJson(),
      'comment': comment,
    };
  }
}

class ShipperReviewModel {
  final String? id;
  final String orderId;
  final String buyerId;
  final String shipperId;
  final int rating;
  final ShipperReviewAspects? aspects;
  final String comment;
  final bool isVerified;
  final DateTime? createdAt;

  ShipperReviewModel({
    this.id,
    required this.orderId,
    required this.buyerId,
    required this.shipperId,
    required this.rating,
    this.aspects,
    this.comment = '',
    this.isVerified = true,
    this.createdAt,
  });

  factory ShipperReviewModel.fromJson(Map<String, dynamic> json) {
    return ShipperReviewModel(
      id: json['_id']?.toString(),
      orderId: (json['orderId'] ?? '').toString(),
      buyerId: (json['buyerId'] ?? '').toString(),
      shipperId: (json['shipperId'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      aspects: json['aspects'] != null ? ShipperReviewAspects.fromJson(json['aspects']) : null,
      comment: (json['comment'] ?? '').toString(),
      isVerified: json['isVerified'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'shipperId': shipperId,
      'rating': rating,
      if (aspects != null) 'aspects': aspects!.toJson(),
      'comment': comment,
    };
  }
}

class ReviewAspects {
  final int? quality;
  final int? communication;
  final int? delivery;

  ReviewAspects({this.quality, this.communication, this.delivery});

  factory ReviewAspects.fromJson(Map<String, dynamic> json) {
    return ReviewAspects(
      quality: (json['quality'] as num?)?.toInt(),
      communication: (json['communication'] as num?)?.toInt(),
      delivery: (json['delivery'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (quality != null) 'quality': quality,
      if (communication != null) 'communication': communication,
      if (delivery != null) 'delivery': delivery,
    };
  }
}

class ShipperReviewAspects {
  final int? punctuality;
  final int? attitude;
  final int? handling;

  ShipperReviewAspects({this.punctuality, this.attitude, this.handling});

  factory ShipperReviewAspects.fromJson(Map<String, dynamic> json) {
    return ShipperReviewAspects(
      punctuality: (json['punctuality'] as num?)?.toInt(),
      attitude: (json['attitude'] as num?)?.toInt(),
      handling: (json['handling'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (punctuality != null) 'punctuality': punctuality,
      if (attitude != null) 'attitude': attitude,
      if (handling != null) 'handling': handling,
    };
  }
}
