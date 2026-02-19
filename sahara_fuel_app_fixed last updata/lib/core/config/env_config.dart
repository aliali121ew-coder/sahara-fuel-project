/// Environment-specific configuration.
/// Values are injected via --dart-define at build time:
///   flutter run --dart-define=API_BASE_URL=https://api.sahara-fuel.com
///   flutter run --dart-define=LICENSE_SECRET=xxx
class EnvConfig {
  EnvConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  /// License encryption secret — MUST be provided at build time for production.
  static const String licenseSecret = String.fromEnvironment(
    'LICENSE_SECRET',
    defaultValue: '', // empty = use development fallback
  );

  /// License salt — MUST be provided at build time for production.
  static const String licenseSalt = String.fromEnvironment(
    'LICENSE_SALT',
    defaultValue: '',
  );

  /// Whether debug features are enabled.
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  /// Whether to show test account credentials on login page.
  static const bool showTestCredentials = bool.fromEnvironment(
    'SHOW_TEST_CREDENTIALS',
    defaultValue: true,
  );
}
