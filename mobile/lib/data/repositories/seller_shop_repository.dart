import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_client.dart';

class SellerShopRepository {
  final ApiClient _apiClient = ApiClient();
  
  Future<Shop?> getShop() async {
    try {
      final response = await _apiClient.get('/seller/shop');
      final data = response.data;
      
      // Handle both {shop: {...}} and direct shop object
      if (data['success'] == true) {
        final shopData = data['data'];
        if (shopData is Map && shopData['shop'] != null) {
          return Shop.fromJson(Map<String, dynamic>.from(shopData['shop'] as Map));
        }
        if (shopData is Map && shopData['_id'] != null) {
          return Shop.fromJson(Map<String, dynamic>.from(shopData as Map));
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> ensureShopExists({
    required String categoryId,
  }) async {
    try {
      final response = await _apiClient.get('/seller/shop');
      final data = response.data;
      final shop = data['data']?['shop'];
      if (data['success'] == true && shop != null) {
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        rethrow;
      }
    }

    try {
      final response = await _apiClient.post('/seller/shop', data: {
        'name': 'Gian hàng của tôi',
        'description': '',
        'phone': '',
        'address': '',
        'avatar': '',
        'banner': '',
        'categoryId': categoryId,
      });
      return response.data['success'] == true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        return true;
      }
      final details = e.response?.data?['error']?['details'];
      if (details is List && details.isNotEmpty) {
        final messages = details.map((d) => d['message'] as String).join('; ');
        throw Exception(messages);
      }
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Không thể tạo cửa hàng');
    }
  }

  Future<Shop?> toggleSelling() async {
    try {
      final response = await _apiClient.patch('/seller/shop/toggle-selling');
      final data = response.data;
      
      if (data['success'] == true) {
        final shopData = data['data'];
        if (shopData is Map && shopData['shop'] != null) {
          return Shop.fromJson(Map<String, dynamic>.from(shopData['shop'] as Map));
        }
      }
      return null;
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái bán hàng: $e');
    }
  }
}
