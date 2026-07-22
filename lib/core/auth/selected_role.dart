import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/auth_user.dart';
import '../../data/models/wallet_role.dart';

/// Maps and persists the user's app role for home-screen routing.
abstract final class SelectedRoleStore {
  static const _idPrefix = 'user_role_id_';
  static const _emailPrefix = 'user_role_email_';

  static WalletRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'traveler' => WalletRole.traveler,
      'receiver' => WalletRole.receiver,
      'sender' => WalletRole.sender,
      _ => null,
    };
  }

  static WalletRole? roleFromUser(AuthUser? user) => tryParse(user?.role);

  static String homeRouteFor(WalletRole role) => switch (role) {
        WalletRole.sender => '/home',
        WalletRole.traveler => '/traveler-home',
        WalletRole.receiver => '/receiver-home',
      };

  static String? homeRouteForUser(AuthUser? user) {
    final role = roleFromUser(user);
    if (role == null) return null;
    return homeRouteFor(role);
  }

  static String apiValue(WalletRole role) => role.queryParam;

  /// Saves role locally so login can restore it even if the API/demo session resets.
  static Future<void> saveForUser({
    required String userId,
    required String email,
    required WalletRole role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final value = role.queryParam;
    await prefs.setString('$_idPrefix$userId', value);
    await prefs.setString('$_emailPrefix${email.trim().toLowerCase()}', value);
  }

  static Future<WalletRole?> loadForUser({
    String? userId,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      final byId = tryParse(prefs.getString('$_idPrefix$userId'));
      if (byId != null) return byId;
    }
    if (email != null && email.trim().isNotEmpty) {
      final byEmail = tryParse(
        prefs.getString('$_emailPrefix${email.trim().toLowerCase()}'),
      );
      if (byEmail != null) return byEmail;
    }
    return null;
  }
}
