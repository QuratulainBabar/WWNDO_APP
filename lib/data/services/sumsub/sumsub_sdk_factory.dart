import 'sumsub_sdk_launcher_stub.dart' as impl;

import 'sumsub_sdk_launcher.dart';

/// Uses the stub launcher on all platforms for now.
///
/// The official Sumsub Android SDK (TensorFlow Lite) has been crashing the
/// Vivo/ColorOS process on startup. KYC UI still works; the live SDK can be
/// re-enabled via [sumsub_sdk_launcher_mobile.dart] once USB debugging works.
SumsubSdkLauncher createSumsubSdkLauncher() => impl.createSumsubSdkLauncher();
