/// Centralized API configuration constants for Phase 08+ networking.
class AppConfig {
  AppConfig._();

  static const apiBaseUrl = 'https://your-domain.com/api/v1';

  static const apiKeyHeaderName = 'X-API-Key';
  static const apiKeyHeaderValue = 'secret_app_key_123';

  static const connectTimeout = Duration(seconds: 5);
  static const readTimeout = Duration(seconds: 10);
  static const transientRetryDelay = Duration(seconds: 1);
}
