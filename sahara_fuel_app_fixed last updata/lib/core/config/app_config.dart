/// Application configuration.
/// In production, these values should be loaded from environment variables
/// or a secure configuration file (NOT committed to source control).
class AppConfig {
  AppConfig._();

  /// API base URL — override via environment or build-time flag.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  /// Whether we are running in production mode.
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Minimum password length enforced on the client.
  static const int minPasswordLength = 8;

  /// Maximum login attempts before temporary lockout.
  static const int maxLoginAttempts = 5;

  /// Lockout duration after max login attempts.
  static const Duration loginLockoutDuration = Duration(minutes: 15);

  /// Token refresh threshold — refresh when token is about to expire.
  static const Duration tokenRefreshThreshold = Duration(minutes: 2);

  /// Local database encryption — enable in production.
  static const bool encryptLocalDatabase = isProduction;
}
