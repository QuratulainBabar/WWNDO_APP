import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase client config for project `chatapp-5c41d`.
///
/// Download `google-services.json` from Firebase Console → Project settings →
/// Your apps → Android (`com.wwngo.wwngo_app`), then copy:
/// - apiKey → current_key
/// - appId → mobilesdk_app_id
/// - messagingSenderId → project_number
///
/// iOS: add an iOS app with bundle id `com.wwngo.app`, then set
/// `FIREBASE_IOS_APP_ID` via `--dart-define-from-file=dart_defines.json`.
class DefaultFirebaseOptions {
  static bool get isConfigured {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return _apiKey.isNotEmpty &&
          _iosAppId.isNotEmpty &&
          _messagingSenderId.isNotEmpty;
    }
    return _apiKey.isNotEmpty &&
        _androidAppId.isNotEmpty &&
        _messagingSenderId.isNotEmpty;
  }

  // Paste from Firebase Console / google-services.json (see comments above).
  static const String _apiKey = 'AIzaSyAHwBl9gvH9MKHixOgfh0L8SN7qI6rAG3I';
  static const String _androidAppId =
      '1:707811310736:android:ad018119d4155ca6df6c15';
  static const String _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '',
  );
  static const String _messagingSenderId = '707811310736';

  static const String projectId = 'chatapp-5c41d';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase push is only configured for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _androidAppId,
    messagingSenderId: _messagingSenderId,
    projectId: projectId,
    storageBucket: 'chatapp-5c41d.firebasestorage.app',
  );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: projectId,
        iosBundleId: 'com.wwngo.app',
        storageBucket: 'chatapp-5c41d.firebasestorage.app',
      );
}
