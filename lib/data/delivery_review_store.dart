import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/wallet_role.dart';

/// Persists whether the current user already submitted a review for a given
/// shipment + reviewee role (e.g. traveler → sender vs traveler → receiver).
abstract final class DeliveryReviewStore {
  static const _prefix = 'delivery_review_submitted_';

  /// Bumps when a review is marked submitted so open screens can refresh.
  static final version = ValueNotifier<int>(0);

  static String _key({
    required String reviewerUserId,
    required String shipmentId,
    required WalletRole reviewerRole,
    required WalletRole revieweeRole,
  }) {
    final user = reviewerUserId.trim().isEmpty ? 'local' : reviewerUserId.trim();
    return '$_prefix${user}_'
        '${shipmentId.trim()}_'
        '${reviewerRole.queryParam}_'
        '${revieweeRole.queryParam}';
  }

  static Future<bool> hasSubmitted({
    required String reviewerUserId,
    required String shipmentId,
    required WalletRole reviewerRole,
    required WalletRole revieweeRole,
  }) async {
    if (shipmentId.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(
          _key(
            reviewerUserId: reviewerUserId,
            shipmentId: shipmentId,
            reviewerRole: reviewerRole,
            revieweeRole: revieweeRole,
          ),
        ) ??
        false;
  }

  static Future<void> markSubmitted({
    required String reviewerUserId,
    required String shipmentId,
    required WalletRole reviewerRole,
    required WalletRole revieweeRole,
  }) async {
    if (shipmentId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _key(
        reviewerUserId: reviewerUserId,
        shipmentId: shipmentId,
        reviewerRole: reviewerRole,
        revieweeRole: revieweeRole,
      ),
      true,
    );
    version.value++;
  }
}
