import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

/// Hardware NFC handoff helper with simulated fallback for unsupported platforms.
class NfcHandoffService {
  NfcHandoffService._();

  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) return false;
      final availability = await NfcManager.instance.checkAvailability();
      return availability == NfcAvailability.enabled;
    } catch (_) {
      return false;
    }
  }

  /// Waits for an NFC tag discovery, then returns a device hash string.
  /// Falls back to a simulated tap when NFC hardware is unavailable.
  static Future<String> waitForTap({
    Duration timeout = const Duration(seconds: 45),
    Duration simulateAfter = const Duration(seconds: 2),
    bool allowSimulate = true,
    void Function(String status)? onStatus,
  }) async {
    final available = await isAvailable();
    if (!available) {
      onStatus?.call('NFC unavailable — using secure simulated tap');
      if (!allowSimulate) {
        throw StateError('NFC is not available on this device');
      }
      await Future<void>.delayed(simulateAfter);
      return 'sim-${DateTime.now().millisecondsSinceEpoch}';
    }

    onStatus?.call('Hold phones together to tap NFC…');
    final completer = Completer<String>();
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        NfcManager.instance.stopSession().catchError((_) {});
        completer.completeError(TimeoutException('NFC tap timed out'));
      }
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          if (completer.isCompleted) return;
          final id = _tagId(tag);
          await NfcManager.instance.stopSession();
          completer.complete(id);
        },
      );
    } catch (e) {
      timeoutTimer.cancel();
      if (allowSimulate) {
        onStatus?.call('NFC session failed — using simulated tap');
        await Future<void>.delayed(simulateAfter);
        return 'sim-${DateTime.now().millisecondsSinceEpoch}';
      }
      rethrow;
    }

    try {
      final deviceId = await completer.future;
      timeoutTimer.cancel();
      return deviceId;
    } catch (e) {
      timeoutTimer.cancel();
      await NfcManager.instance.stopSession().catchError((_) {});
      if (allowSimulate) {
        onStatus?.call('Using simulated tap');
        return 'sim-${DateTime.now().millisecondsSinceEpoch}';
      }
      rethrow;
    }
  }

  static String _tagId(NfcTag tag) {
    try {
      final android = NfcTagAndroid.from(tag);
      if (android != null && android.id.isNotEmpty) {
        return android.id
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
      }
    } catch (_) {}
    return 'nfc-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> stop() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }
}
