import 'package:dio/dio.dart';
import '../models/review_model.dart';
import '../services/api_client.dart';

class ReviewRepository {
  final ApiClient _apiClient = ApiClient();

  Future<SellerReviewModel> createSellerReview({
    required String orderId,
    required String sellerId,
    required int rating,
    ReviewAspects? aspects,
    String comment = '',
  }) async {
    try {
      final response = await _apiClient.post('/seller-reviews', data: {
        'orderId': orderId,
        'sellerId': sellerId,
        'rating': rating,
        if (aspects != null) 'aspects': aspects.toJson(),
        'comment': comment,
      });
      final data = response.data;
      if (data['success'] == true) {
        return SellerReviewModel.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to create seller review');
    } on DioException catch (e) {
      final errData = e.response?.data;
      throw Exception(errData?['message'] ?? e.message ?? 'Failed to create seller review');
    } catch (e) {
      throw Exception('Failed to create seller review: $e');
    }
  }

  Future<ShipperReviewModel> createShipperReview({
    required String orderId,
    required String shipperId,
    required int rating,
    ShipperReviewAspects? aspects,
    String comment = '',
  }) async {
    try {
      final response = await _apiClient.post('/shipper-reviews', data: {
        'orderId': orderId,
        'shipperId': shipperId,
        'rating': rating,
        if (aspects != null) 'aspects': aspects.toJson(),
        'comment': comment,
      });
      final data = response.data;
      if (data['success'] == true) {
        return ShipperReviewModel.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to create shipper review');
    } on DioException catch (e) {
      final errData = e.response?.data;
      throw Exception(errData?['message'] ?? e.message ?? 'Failed to create shipper review');
    } catch (e) {
      throw Exception('Failed to create shipper review: $e');
    }
  }

  Future<List<SellerReviewModel>> getSellerReviews({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/reviews/seller/me',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      if (data['success'] == true) {
        final reviewsData = data['data'];
        final List<dynamic> rawList;
        if (reviewsData is List) {
          rawList = reviewsData.cast<dynamic>();
        } else if (reviewsData is Map) {
          rawList = (reviewsData['reviews'] as List?)?.cast<dynamic>() ?? [];
        } else {
          rawList = [];
        }
        return rawList.map((e) => SellerReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load seller reviews: $e');
    }
  }

  Future<List<ShipperReviewModel>> getShipperReviews({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/reviews/shipper/me',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      if (data['success'] == true) {
        final reviewsData = data['data'];
        final List<dynamic> rawList;
        if (reviewsData is List) {
          rawList = reviewsData.cast<dynamic>();
        } else if (reviewsData is Map) {
          rawList = (reviewsData['reviews'] as List?)?.cast<dynamic>() ?? [];
        } else {
          rawList = [];
        }
        return rawList.map((e) => ShipperReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load shipper reviews: $e');
    }
  }
}
