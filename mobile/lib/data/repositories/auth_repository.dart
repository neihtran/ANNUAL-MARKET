import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(data['user']));

        return {
          'user': User.fromJson(data['user']),
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
        };
      }
      throw Exception(response.data['message'] ?? 'Login failed');
    } on DioException catch (e) {
      final errData = e.response?.data;
      if (errData != null && errData['error']?['code'] != null) {
        final code = errData['error']['code'] as String;
        if (code == 'UNAUTHORIZED') {
          throw Exception(errData['message'] ?? 'Email hoặc mật khẩu không đúng');
        }
      }
      if (errData != null && errData['error']?['details'] != null) {
        final details = errData['error']['details'] as List;
        final messages = details.map((d) => d['message'] as String).join('; ');
        throw Exception(messages);
      }
      throw Exception(errData?['message'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'buyer',
    String? marketId,
    List<String>? categoryIds,
    /// For sellers: [{ type: 'cccd', url: '...' }]
    List<Map<String, String>>? documents,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'role': role,
      };

      if (marketId != null) data['marketId'] = marketId;
      if (categoryIds != null) data['categoryIds'] = categoryIds;
      if (documents != null) data['documents'] = documents;

      final response = await _api.post('/auth/register', data: data);

      if (response.data['success'] == true) {
        final result = response.data['data'];
        await _storage.write(key: AppConstants.accessTokenKey, value: result['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: result['refreshToken']);
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(result['user']));

        return {
          'user': User.fromJson(result['user']),
          'accessToken': result['accessToken'],
          'refreshToken': result['refreshToken'],
        };
      }
      throw Exception(response.data['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      final errData = e.response?.data;
      if (errData != null && errData['error']?['details'] != null) {
        final details = errData['error']['details'] as List;
        final messages = details.map((d) => d['message'] as String).join('; ');
        throw Exception(messages);
      }
      throw Exception(errData?['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    // Don't call API if no token — avoids 401 loop / refresh cycle
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token == null) {
      await _clearStorage();
      return;
    }
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Ignore errors — clear local tokens regardless
    } finally {
      await _clearStorage();
    }
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<User?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }

      // Short timeout so app doesn't hang if server is unreachable
      final response = await _api.get(
        '/auth/me',
      );
      if (response.data['success'] == true) {
        final userData = response.data['data']?['user'];
        if (userData == null) return null;
        final user = User.fromJson(userData);
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (userJson == null) throw Exception('Không tìm thấy thông tin người dùng');

      final userData = jsonDecode(userJson);
      final userId = userData['_id'] ?? userData['id'];
      if (userId == null) throw Exception('Không xác định được người dùng');

      final response = await _api.put(
        '/users/$userId/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Đổi mật khẩu thất bại');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Đổi mật khẩu thất bại');
    }
  }

  Future<User> updateProfile(Map<String, dynamic> payload) async {
    try {
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (userJson == null) throw Exception('Không tìm thấy thông tin người dùng');

      final userData = jsonDecode(userJson);
      final userId = userData['_id'] ?? userData['id'];
      if (userId == null) throw Exception('Không xác định được người dùng');

      final response = await _api.put('/users/$userId', data: payload);
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Cập nhật hồ sơ thất bại');
      }

      final updatedUserData = response.data['data']?['user'];
      if (updatedUserData == null) {
        throw Exception('Không nhận được dữ liệu hồ sơ mới');
      }

      await _storage.write(key: AppConstants.userKey, value: jsonEncode(updatedUserData));
      return User.fromJson(updatedUserData);
    } on DioException catch (e) {
      final details = e.response?.data?['error']?['details'];
      if (details is List && details.isNotEmpty) {
        throw Exception(details.map((d) => d['message'] as String).join('; '));
      }
      throw Exception(e.response?.data?['message'] ?? 'Cập nhật hồ sơ thất bại');
    }
  }
}
