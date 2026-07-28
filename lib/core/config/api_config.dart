/// API base URL for the WWNGO backend.
///
/// Default is the LAN host so browser and USB-debugged physical devices
/// can reach the backend. Override with:
/// `flutter run --dart-define=API_BASE_URL=http://<ip>:3000`
class ApiConfig {
  ApiConfig._();

  static const String _configuredBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.6:3000',
  );

  /// Hosted / configured API origin (no trailing slash).
  static String get baseUrl {
    final raw = _configuredBase.trim();
    if (raw.endsWith('/')) return raw.substring(0, raw.length - 1);
    return raw;
  }

  static String get apiV1 => '$baseUrl/api/v1';
  static String get authBase => '$apiV1/auth';
  static String get deliveriesBase => '$apiV1/deliveries';
  static String get tripsBase => '$apiV1/trips';
  static String get walletBase => '$apiV1/wallet';

  /// Absolute URL for a relative upload path returned by the API.
  static String resolveUploadUrl(String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('http://') ||
        relativeOrAbsolute.startsWith('https://')) {
      return relativeOrAbsolute;
    }
    final path = relativeOrAbsolute.startsWith('/')
        ? relativeOrAbsolute
        : '/$relativeOrAbsolute';
    return '$baseUrl$path';
  }
}
