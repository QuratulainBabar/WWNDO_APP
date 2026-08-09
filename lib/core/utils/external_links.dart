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
}
