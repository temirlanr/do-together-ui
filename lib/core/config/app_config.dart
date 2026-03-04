/// App-wide configuration. Switch [baseUrl] via env or flavors.
class AppConfig {
  /// For Android emulator use 10.0.2.2; for iOS simulator use localhost.
  /// Override with --dart-define=API_BASE_URL=http://your-host:5000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Sync queue retry settings
  static const int maxRetryAttempts = 5;
  static const Duration initialRetryDelay = Duration(seconds: 2);
  static const double retryBackoffMultiplier = 2.0;
}
