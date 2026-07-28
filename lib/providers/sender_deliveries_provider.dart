import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/config/demo_mode.dart';
import '../data/models/created_delivery.dart';
import '../data/services/auth_repository.dart';
import '../data/services/delivery_repository.dart';
import '../features/sender/sender_delivery_status.dart';

/// Shared sender delivery list for Home "Active deliveries" and related screens.
///
/// Create flow upserts immediately so the home section updates even when the
/// shell route does not remount / SSE does not notify the creating sender.
class SenderDeliveriesProvider extends ChangeNotifier {
  SenderDeliveriesProvider();

  List<CreatedDelivery> _deliveries = const [];
  Map<String, int> _matchingTravelerCounts = const {};
  bool _loading = false;
  String? _error;
  int _loadGeneration = 0;

  bool get loading => _loading;
  String? get error => _error;
  List<CreatedDelivery> get deliveries => _deliveries;
  Map<String, int> get matchingTravelerCounts => _matchingTravelerCounts;

  List<CreatedDelivery> get activeDeliveries => _deliveries
      .where((d) => SenderDeliveryStatus.fromDelivery(d).isActive)
      .toList(growable: false);

  DeliveryRepository _repository({
    required AuthRepository authRepository,
    DemoModeProvider? demoMode,
  }) {
    return DeliveryRepository(
      apiClient: authRepository.apiClient,
      demoMode: demoMode,
    );
  }

  /// Insert/replace a delivery locally (e.g. right after POST succeeds).
  void upsert(CreatedDelivery delivery) {
    final id = delivery.displayId;
    final next = <CreatedDelivery>[
      delivery,
      ..._deliveries.where((d) => d.displayId != id && d.id != delivery.id),
    ];
    _deliveries = next;
    _error = null;
    notifyListeners();
  }

  void clear() {
    _deliveries = const [];
    _matchingTravelerCounts = const {};
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh({
    required AuthRepository authRepository,
    DemoModeProvider? demoMode,
    bool silent = false,
  }) async {
    final generation = ++_loadGeneration;
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final repo = _repository(
        authRepository: authRepository,
        demoMode: demoMode,
      );
      final list = await repo.listDeliveries(role: 'sender');
      if (generation != _loadGeneration) return;

      // Keep any optimistic rows the API has not returned yet (create race).
      final byKey = <String, CreatedDelivery>{};
      for (final d in list) {
        byKey[d.displayId] = d;
      }
      for (final d in _deliveries) {
        byKey.putIfAbsent(d.displayId, () => d);
      }
      final merged = byKey.values.toList();
      // Prefer API order when present; otherwise keep upsert-first order.
      merged.sort((a, b) {
        final ai = list.indexWhere((d) => d.displayId == a.displayId);
        final bi = list.indexWhere((d) => d.displayId == b.displayId);
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return 0;
      });

      _deliveries = merged;
      _loading = false;
      _error = null;
      notifyListeners();

      // Counts are secondary — never block showing the list.
      final active = activeDeliveries;
      final counts = await repo.fetchMatchingTravelerCounts(active);
      if (generation != _loadGeneration) return;
      _matchingTravelerCounts = counts;
      notifyListeners();
    } on ApiException catch (e) {
      if (generation != _loadGeneration) return;
      _loading = false;
      _error = e.message;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SenderDeliveriesProvider.refresh failed: $e');
      }
      if (generation != _loadGeneration) return;
      _loading = false;
      _error = 'Unable to load active deliveries.';
      notifyListeners();
    }
  }
}
