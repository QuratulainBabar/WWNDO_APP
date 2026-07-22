// TEMPORARILY DISABLED - SUMSUB KYC
// Preserved conditional mobile SDK import:
// import 'sumsub_sdk_launcher_stub.dart'
//     if (dart.library.io) 'sumsub_sdk_launcher_mobile.dart' as impl;
import 'sumsub_sdk_launcher_stub.dart' as impl;

import 'sumsub_sdk_launcher.dart';

/// TEMPORARILY DISABLED - SUMSUB KYC
/// Always returns the inert launcher, including on Android and iOS.
SumsubSdkLauncher createSumsubSdkLauncher() => impl.createSumsubSdkLauncher();
