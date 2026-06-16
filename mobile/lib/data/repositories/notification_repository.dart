import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notification_model.dart';
import '../../core/constants/app_constants.dart';

class NotificationRepository {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  NotificationRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<List<NotificationModel>> getNotifications({int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'limit': limit},
      );

      if (response.data['success'] == true) {
        final rawData = response.data['data'];
        final notifsList = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['notifications'] ?? []) : []);
        return (notifsList as List)
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('/notifications/$notificationId');
      return true;
    } catch (_) {
      return false;
    }
  }
}
