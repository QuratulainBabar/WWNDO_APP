/// API base URL for the WWNGO backend.
///
/// Default is this machine's current LAN IP (physical device must reach it on
/// the same network). Keep in sync with `ipconfig` / `hostname -I` when the
/// host IP changes. Override with:
/// `flutter run --dart-define=API_BASE_URL=https://wango.toolkitpro.cloud`
class ApiConfig {
  ApiConfig._();

  static const String _configuredBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.16.11.50:3000',
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
