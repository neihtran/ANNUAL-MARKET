import '../models/buyer_address.dart';
import '../services/api_client.dart';

class AddressRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<BuyerAddress>> getAddresses() async {
    try {
      final response = await _apiClient.get('/buyer/addresses');
      final data = response.data;
      if (data['success'] == true) {
        final rawData = data['data'];
        final list = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['addresses'] ?? []) : []);
        return (list as List)
            .map((e) => BuyerAddress.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<BuyerAddress> createAddress(BuyerAddress address) async {
    final response = await _apiClient.post('/buyer/addresses', data: address.toJson());
    final data = response.data;
    if (data['success'] == true) {
      final rawData = data['data'];
      final addressData = rawData is Map<String, dynamic>
          ? (rawData['address'] as Map<String, dynamic>? ?? rawData)
          : <String, dynamic>{};
      return BuyerAddress.fromJson(addressData);
    }
    throw Exception(data['message'] ?? 'Tạo địa chỉ thất bại');
  }

  Future<BuyerAddress> updateAddress(String id, BuyerAddress address) async {
    final response = await _apiClient.put('/buyer/addresses/$id', data: address.toJson());
    final data = response.data;
    if (data['success'] == true) {
      final rawData = data['data'];
      final addressData = rawData is Map<String, dynamic>
          ? (rawData['address'] as Map<String, dynamic>? ?? rawData)
          : <String, dynamic>{};
      return BuyerAddress.fromJson(addressData);
    }
    throw Exception(data['message'] ?? 'Cập nhật địa chỉ thất bại');
  }

  Future<void> deleteAddress(String id) async {
    final response = await _apiClient.delete('/buyer/addresses/$id');
    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Xóa địa chỉ thất bại');
    }
  }

  Future<void> setDefaultAddress(String id) async {
    final response = await _apiClient.patch('/buyer/addresses/$id/set-default');
    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Đặt địa chỉ mặc định thất bại');
    }
  }
}
