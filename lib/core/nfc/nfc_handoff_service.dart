import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

/// Hardware NFC handoff helper with simulated fallback for unsupported platforms.
class NfcHandoffService {
  NfcHandoffService._();

  /// How long to wait for a physical NFC tag before confirming via the server.
  /// Phone-to-phone tap is not a readable tag, so this must stay short.
  static const Duration defaultTimeout = Duration(milliseconds: 1500);

  /// Brief pause before a simulated tap (web / unsupported devices).
  /// Kept short so CP1/CP2 feel instant in Chrome and on devices without NFC.
  static const Duration defaultSimulateAfter = Duration(milliseconds: 200);

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
    Duration timeout = defaultTimeout,
    Duration? simulateAfter,
    bool allowSimulate = true,
    void Function(String status)? onStatus,
  }) async {
    final simDelay = simulateAfter ??
        (kIsWeb ? Duration.zero : defaultSimulateAfter);

    final available = await isAvailable();
    if (!available) {
      onStatus?.call(
        kIsWeb
            ? 'Confirming secure tap…'
            : 'NFC unavailable — using secure simulated tap',
      );
      if (!allowSimulate) {
        throw StateError('NFC is not available on this device');
      }
      if (simDelay > Duration.zero) {
        await Future<void>.delayed(simDelay);
      }
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
      // iso14443 is the fast path for phone NFC; extra RF tech slows polling.
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          if (completer.isCompleted) return;
          final id = _tagId(tag);
          // Complete first so API confirm starts immediately; stop session after.
          completer.complete(id);
          unawaited(NfcManager.instance.stopSession().catchError((_) {}));
        },
      );
    } catch (e) {
      timeoutTimer.cancel();
      if (allowSimulate) {
        onStatus?.call('NFC session failed — using simulated tap');
        if (simDelay > Duration.zero) {
          await Future<void>.delayed(simDelay);
        }
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
        // Already waited through [timeout] — return immediately.
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
