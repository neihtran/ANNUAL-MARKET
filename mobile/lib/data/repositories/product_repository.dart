import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../services/api_client.dart';

class ProductRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Product>> getProducts({
    String? marketId,
    String? categoryId,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? sort,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        'isAvailable': 'true',
      };
      
      if (marketId != null) params['marketId'] = marketId;
      if (categoryId != null) params['categoryId'] = categoryId;
      if (keyword != null) params['keyword'] = keyword;
      if (minPrice != null) params['minPrice'] = minPrice;
      if (maxPrice != null) params['maxPrice'] = maxPrice;
      if (sort != null) params['sort'] = sort;

      final response = await _apiClient.get('/products', queryParameters: params);
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        List<dynamic> productsList;
        if (rawData is List) {
          productsList = rawData.cast<dynamic>();
        } else if (rawData is Map) {
          productsList = (rawData['products'] as List?)?.cast<dynamic>() ?? [];
        } else {
          productsList = [];
        }
        return productsList
            .map<Product>((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiClient.get('/products/$id');
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        final productData = rawData is Map<String, dynamic>
            ? (rawData['product'] as Map<String, dynamic>? ?? rawData)
            : <String, dynamic>{};
        return Product.fromJson(productData);
      }
      throw Exception(data['message'] ?? 'Failed to load product');
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _apiClient.post('/seller/products', data: productData);
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        final productData = rawData is Map<String, dynamic>
            ? (rawData['product'] as Map<String, dynamic>? ?? rawData)
            : <String, dynamic>{};
        return Product.fromJson(productData);
      }
      throw Exception(data['message'] ?? 'Failed to create product');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Failed to create product';
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final response = await _apiClient.put('/seller/products/$id', data: productData);
      final data = response.data;
      
      if (data['success'] == true) {
        final rawData = data['data'];
        final productData = rawData is Map<String, dynamic>
            ? (rawData['product'] as Map<String, dynamic>? ?? rawData)
            : <String, dynamic>{};
        return Product.fromJson(productData);
      }
      throw Exception(data['message'] ?? 'Failed to update product');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Failed to update product';
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await _apiClient.delete('/seller/products/$id');
      final data = response.data;
      
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete product');
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> toggleAvailability(String id) async {
    try {
      final response = await _apiClient.patch('/seller/products/$id/toggle-available');
      final data = response.data;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to toggle availability');
      }
    } catch (e) {
      throw Exception('Failed to toggle availability: $e');
    }
  }

  // Seller: get own products
  Future<List<Product>> getSellerProducts({
    String? categoryId,
    String? isAvailable,
    String? keyword,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (categoryId != null) params['categoryId'] = categoryId;
      if (isAvailable != null) params['isAvailable'] = isAvailable;
      if (keyword != null) params['search'] = keyword;

      final response = await _apiClient.get('/seller/products', queryParameters: params);
      final data = response.data;

      if (data['success'] == true) {
        final rawData = data['data'];
        List<dynamic> productsList;
        if (rawData is List) {
          productsList = rawData.cast<dynamic>();
        } else if (rawData is Map) {
          productsList = (rawData['products'] as List?)?.cast<dynamic>() ?? (rawData['data'] as List?)?.cast<dynamic>() ?? [];
        } else {
          productsList = [];
        }
        return productsList
            .map<Product>((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load seller products: $e');
    }
  }
}
