import 'package:shop_manager/config/environment.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Get the base URL for API calls
  /// Priority:
  /// 1. Environment variable (API_BASE_URL set at build time)
  /// 2. Environment helper (device-specific defaults)
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    return Environment.getBackendUrl();
  }
}

