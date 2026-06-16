import 'package:dio/dio.dart';
import '../models/market_model.dart';
import '../models/product_model.dart';
import '../services/api_client.dart';

class MarketRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Market>> getNearbyMarkets({double? lat, double? lng, int limit = 20, String? search}) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (lat != null) params['lat'] = lat;
      if (lng != null) params['lng'] = lng;
      if (search != null && search.trim().isNotEmpty) params['search'] = search;

      final response = await _apiClient.get('/markets/nearby', queryParameters: params);
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        
        // Backend returns markets as direct array inside data
        // Format: {success: true, data: [market1, market2, ...]}
        List<dynamic> marketsList;
        if (rawData is List) {
          marketsList = (rawData as List).cast<dynamic>();
        } else if (rawData is Map) {
          marketsList = (rawData['markets'] as List?)?.cast<dynamic>() ?? (rawData['data'] as List?)?.cast<dynamic>() ?? [];
        } else {
          marketsList = [];
        }
        
        return marketsList
            .map<Market>((e) => Market.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load markets: $e');
    }
  }

  Future<Market> getMarketById(String id) async {
    try {
      final response = await _apiClient.get('/markets/$id');
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        
        // Handle different response formats
        Map<String, dynamic> marketData;
        if (rawData is Map<String, dynamic>) {
          marketData = rawData['market'] ?? rawData;
        } else {
          throw Exception('Dữ liệu chợ không hợp lệ');
        }
        
        // Check if we have valid market data
        if (marketData.isEmpty || marketData['_id'] == null) {
          throw Exception('Không tìm thấy chợ này');
        }
        
        return Market.fromJson(marketData);
      }
      
      // Handle error response from server
      final message = data['message'] ?? 'Không thể tải thông tin chợ';
      throw Exception(message);
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 404) {
          throw Exception('Không tìm thấy chợ này');
        }
        if (statusCode == 400) {
          throw Exception('ID chợ không hợp lệ');
        }
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Kết nối chậm, vui lòng thử lại');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối mạng.');
      }
      throw Exception('Lỗi kết nối: ${e.message}');
    } catch (e) {
      if (e.toString().contains('Không tìm thấy') || 
          e.toString().contains('không hợp lệ') ||
          e.toString().contains('Dữ liệu') ||
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Lỗi khi tải thông tin chợ: $e');
    }
  }

  Future<List<Category>> getMarketCategories(String marketId) async {
    try {
      final response = await _apiClient.get('/markets/$marketId/categories');
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        List<dynamic> catsList;
        if (rawData is List) {
          catsList = rawData;
        } else if (rawData is Map) {
          catsList = (rawData['categories'] as List?)?.cast<dynamic>() ?? [];
        } else {
          catsList = [];
        }
        return catsList
            .map<Category>((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<Product>> getMarketProducts(
    String marketId, {
    String? categoryId,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'marketId': marketId,
        'page': page,
        'limit': limit,
        'isAvailable': 'true',
      };
      if (categoryId != null) params['categoryId'] = categoryId;
      if (keyword != null) params['keyword'] = keyword;
      if (minPrice != null) params['minPrice'] = minPrice;
      if (maxPrice != null) params['maxPrice'] = maxPrice;
      if (sortBy != null) params['sortBy'] = sortBy;
      if (sortOrder != null) params['sortOrder'] = sortOrder;

      final response = await _apiClient.get('/products', queryParameters: params);
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        List<dynamic> prodsList;
        if (rawData is List) {
          prodsList = rawData;
        } else if (rawData is Map) {
          prodsList = (rawData['products'] as List?)?.cast<dynamic>() ?? (rawData['data'] as List?)?.cast<dynamic>() ?? [];
        } else {
          prodsList = [];
        }
        return prodsList
            .map<Product>((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
