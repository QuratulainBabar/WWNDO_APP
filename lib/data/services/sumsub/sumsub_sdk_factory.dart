import 'sumsub_sdk_launcher_stub.dart'
    if (dart.library.io) 'sumsub_sdk_launcher_mobile.dart' as impl;

import 'sumsub_sdk_launcher.dart';

/// Platform-aware Sumsub launcher (mobile SDK on Android/iOS; stub elsewhere).
SumsubSdkLauncher createSumsubSdkLauncher() => impl.createSumsubSdkLauncher();
