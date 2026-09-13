/// API base URL for the WWNGO backend.
///
/// Default is the live API. Override with:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.100.16:3000`
class ApiConfig {
  ApiConfig._();

  /// Production API / website.
  static const String liveBaseUrl = 'https://wango.toolkitpro.cloud';

  /// Wi-Fi backend used for local testing.
  static const String localBaseUrl = 'http://192.168.100.16:3000';

  static const String _configuredBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: liveBaseUrl,
  );

  static const String _configuredWebsite = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: liveBaseUrl,
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
    defaultValue:
        'pk_test_51OA4nvIEpGwAXljxC6aR5qOitILlMryDu09aMbb8i8u9oyY9EXQkCL8kFAJTGzIBR44HB6UKHncDFYZnDhsIoGcR0045ktGHtU',
  );

  static String get apiV1 => '$baseUrl/api/v1';
  static String get authBase => '$apiV1/auth';
  static String get deliveriesBase => '$apiV1/deliveries';
  static String get tripsBase => '$apiV1/trips';
  static String get walletBase => '$apiV1/wallet';

  /// Marketing site (legal pages, FAQ, contact).
  static String get websiteUrl {
    final raw = _configuredWebsite.trim();
    if (raw.isEmpty) return liveBaseUrl;
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
  /// Override with: `flutter run --dart-define=GOOGLE_MAPS_API_KEY=...`
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBM9mGr8VU88NzvMs0CD1up5panX8Ec8Go',
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
