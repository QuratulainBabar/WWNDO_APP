/// API base URL for the WWNGO backend.
///
/// Default is the live API (`https://wwngo.com/backend`).
/// Local: `flutter run --dart-define=API_BASE_URL=http://172.16.11.31:3000`
/// or the "wwngo_app (local API)" launch configuration.
class ApiConfig {
  ApiConfig._();

  /// Production API.
  static const String liveBaseUrl = 'https://wwngo.com/backend';

  /// Production marketing site (legal pages, FAQ, contact).
  static const String liveWebsiteUrl = 'https://wwngo.com';

  /// Local Wi-Fi backend for testing.
  static const String localBaseUrl = 'http://172.16.11.31:3000';

  static const String _configuredBase = String.fromEnvironment(
    'API_BASE_URL',
    // Live API by default. Override with local launch config when needed.
    defaultValue: liveBaseUrl,
  );

  static const String _configuredWebsite = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: liveWebsiteUrl,
  );

  /// REST / Socket.io origin (no trailing slash).
  static String get baseUrl {
    var raw = _configuredBase.trim();
    if (raw.isEmpty) raw = liveBaseUrl;
    if (raw.endsWith('/')) return raw.substring(0, raw.length - 1);
    return raw;
  }

  /// Optional Stripe publishable key from build defines.
  /// Prefer live value from `GET /wallet/payments/config` when available.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String get apiV1 => '$baseUrl/api/v1';
  static String get authBase => '$apiV1/auth';
  static String get deliveriesBase => '$apiV1/deliveries';
  static String get tripsBase => '$apiV1/trips';
  static String get walletBase => '$apiV1/wallet';

  /// Marketing site (legal pages, FAQ, contact).
  static String get websiteUrl {
    final raw = _configuredWebsite.trim();
    if (raw.isEmpty) return liveWebsiteUrl;
    if (raw.endsWith('/')) return raw.substring(0, raw.length - 1);
    return raw;
  }

  static String legalUrl(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return '$websiteUrl$p';
  }

  /// Socket.io endpoint (same host as REST API).
  static String get socketUrl => baseUrl;

  /// Same Google Maps / Places key used by the backend (`GOOGLE_MAPS_API_KEY`).
  /// Pass at build/run time via `--dart-define-from-file=dart_defines.json`
  /// (see dart_defines.example.json).
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

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
