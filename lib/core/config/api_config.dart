/// API base URL for the WWNGO backend.
///
/// Default is the local Wi-Fi API. Hosted `wango.toolkitpro.cloud` is never
/// used as the REST origin (a stale dart-define can otherwise send login to
/// the hosted DB and return "Invalid email or password"). Override with
/// another LAN host: `flutter run --dart-define=API_BASE_URL=http://<ip>:3000`
class ApiConfig {
  ApiConfig._();

  /// Wi-Fi backend used for local testing.
  static const String localBaseUrl = 'http://172.16.11.26:3000';

  static const String _hostedOriginHost = 'wango.toolkitpro.cloud';

  static const String _configuredBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: localBaseUrl,
  );

  static const String _configuredWebsite = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'https://wango.toolkitpro.cloud',
  );

  /// REST / Socket.io origin (no trailing slash). Always the local API unless
  /// a non-hosted `API_BASE_URL` dart-define is provided.
  static String get baseUrl {
    var raw = _configuredBase.trim();
    if (raw.isEmpty || _isHostedApiOrigin(raw)) {
      raw = localBaseUrl;
    }
    if (raw.endsWith('/')) return raw.substring(0, raw.length - 1);
    return raw;
  }

  static bool _isHostedApiOrigin(String url) {
    return url.toLowerCase().contains(_hostedOriginHost);
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
