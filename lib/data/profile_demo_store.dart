import 'package:flutter/foundation.dart';

import 'models/wallet_role.dart';

/// In-memory profile photo paths / bytes for static/demo mode and local preview.
abstract final class ProfileDemoStore {
  static final version = ValueNotifier<int>(0);

  static final Map<WalletRole, String?> _photoPaths = {};
  static final Map<WalletRole, Uint8List?> _photoBytes = {};

  static String? photoPathFor(WalletRole role) => _photoPaths[role];

  static Uint8List? photoBytesFor(WalletRole role) => _photoBytes[role];

  static void setPhotoPath(WalletRole role, String? path) {
    _photoPaths[role] = path;
    version.value++;
  }

  /// Applies the same photo to Sender, Traveler, and Receiver locally.
  static void setPhotoForAllRoles({String? path, Uint8List? bytes}) {
    for (final role in WalletRole.values) {
      if (path != null) _photoPaths[role] = path;
      if (bytes != null) _photoBytes[role] = bytes;
    }
    version.value++;
  }

  /// Clears local profile photo preview for all roles.
  static void clearPhotoForAllRoles() {
    for (final role in WalletRole.values) {
      _photoPaths[role] = null;
      _photoBytes[role] = null;
    }
    version.value++;
  }

  static WalletRole roleFromEditProfile(String? roleParam) => switch (roleParam) {
        'receiver' => WalletRole.receiver,
        'traveler' => WalletRole.traveler,
        _ => WalletRole.sender,
      };
}
