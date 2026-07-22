import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API base URL for the WWNGO backend.
///
/// - Android emulator: `10.0.2.2` maps to the host machine's localhost.
/// - iOS simulator / desktop: use `localhost`.
/// - Physical device: set your machine's LAN IP, e.g. `http://192.168.1.10:3000`.
class ApiConfig {
  ApiConfig._();

  static const int port = 3000;

  /// Override with `--dart-define=API_HOST=192.168.x.x` on a physical device.
  static const String androidHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$port';
    if (Platform.isAndroid) return 'http://$androidHost:$port';
    return 'http://localhost:$port';
  }

  static String get apiV1 => '$baseUrl/api/v1';
  static String get authBase => '$apiV1/auth';
  static String get deliveriesBase => '$apiV1/deliveries';

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
