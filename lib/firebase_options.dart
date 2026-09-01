import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase client config for project `chatapp-5c41d`.
///
/// Download `google-services.json` from Firebase Console → Project settings →
/// Your apps → Android (`com.wwngo.wwngo_app`), then copy:
/// - apiKey → current_key
/// - appId → mobilesdk_app_id
/// - messagingSenderId → project_number
class DefaultFirebaseOptions {
  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty;

  // Paste from Firebase Console / google-services.json (see comments above).
  static const String _apiKey = 'AIzaSyAHwBl9gvH9MKHixOgfh0L8SN7qI6rAG3I';
  static const String _appId = '1:707811310736:android:ad018119d4155ca6df6c15';
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
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: projectId,
    storageBucket: 'chatapp-5c41d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: projectId,
    iosBundleId: 'com.wwngo.wwngoApp',
  );
}
