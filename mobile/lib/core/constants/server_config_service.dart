import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_constants.dart';

class ServerConfigService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static String? _cachedUrl;

  static Future<String> getServerUrl() async {
    if (_cachedUrl != null) return _cachedUrl!;
    _cachedUrl = await _storage.read(key: AppConstants.apiBaseUrlKey) ??
        '${AppConstants.defaultServerIp}:3001/api/v1';
    return _cachedUrl!;
  }

  static Future<void> setServerUrl(String url) async {
    _cachedUrl = url;
    await _storage.write(key: AppConstants.apiBaseUrlKey, value: url);
  }

  static String get defaultUrl =>
      '${AppConstants.defaultServerIp}:3001/api/v1';
}
