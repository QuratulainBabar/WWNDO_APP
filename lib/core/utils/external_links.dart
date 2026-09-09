import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

/// Open external URLs (website legal pages, mailto support).
class ExternalLinks {
  ExternalLinks._();

  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openWebsitePath(String path) =>
      openUrl(ApiConfig.legalUrl(path));

  static Future<bool> openPrivacyPolicy() => openWebsitePath('/legal/privacy');

  static Future<bool> openTermsOfService() => openWebsitePath('/legal/terms');

  static Future<bool> openCookiePolicy() => openWebsitePath('/legal/cookies');

  static Future<bool> openFaq() => openWebsitePath('/faq');

  static Future<bool> openAbout() => openWebsitePath('/about');

  static Future<bool> openSafety() => openWebsitePath('/safety');

  static Future<bool> openContactPage() => openWebsitePath('/contact');

  static Future<bool> emailSupport({
    required String subject,
    required String body,
    String to = 'support@wwngo.com',
  }) {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    return openUrl(uri.toString());
  }

  /// Opens a place / address in the device Maps app (or browser).
  ///
  /// Uses Google Maps search so the exact sender-selected label
  /// (city street, airport, etc.) resolves to that pin.
  static Future<bool> openMapPlace(String query) async {
    final q = query.trim();
    if (q.isEmpty) return false;
    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': q},
    );
    return openUrl(uri.toString());
  }
}
