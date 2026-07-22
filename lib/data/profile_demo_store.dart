import 'package:flutter/foundation.dart';

import 'models/wallet_role.dart';

/// In-memory profile photo paths for static/demo mode.
abstract final class ProfileDemoStore {
  static final version = ValueNotifier<int>(0);

  static final Map<WalletRole, String?> _photoPaths = {};

  static String? photoPathFor(WalletRole role) => _photoPaths[role];

  static void setPhotoPath(WalletRole role, String? path) {
    _photoPaths[role] = path;
    version.value++;
  }

  static WalletRole roleFromEditProfile(String? roleParam) => switch (roleParam) {
        'receiver' => WalletRole.receiver,
        'traveler' => WalletRole.traveler,
        _ => WalletRole.sender,
      };
}
