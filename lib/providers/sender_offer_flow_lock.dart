import 'package:flutter/foundation.dart';

/// Session lock so sender Accept / Pay Now cannot be reused after the action
/// has already been taken, including when those screens are opened again.
///
/// Singleton so a hot-reload (without restarting `main.dart`) cannot crash
/// Counter Offer / Payment screens with a missing Provider.
class SenderOfferFlowLock extends ChangeNotifier {
  SenderOfferFlowLock._();

  static final SenderOfferFlowLock instance = SenderOfferFlowLock._();
  final _acceptedOfferIds = <String>{};
  final _payStartedKeys = <String>{};
  final _payCompletedKeys = <String>{};

  static String _offerKey(String id) => 'offer:${id.trim()}';
  static String _shipmentKey(String id) => 'ship:${id.trim()}';

  bool isAcceptConsumed(String? offerId) {
    final id = (offerId ?? '').trim();
    if (id.isEmpty) return false;
    return _acceptedOfferIds.contains(id) ||
        isPayConsumed(offerId: id);
  }

  bool isPayCompleted({String? offerId, String? shipmentId}) =>
      _has(_payCompletedKeys, offerId, shipmentId);

  bool isPayConsumed({String? offerId, String? shipmentId}) =>
      _has(_payCompletedKeys, offerId, shipmentId) ||
      _has(_payStartedKeys, offerId, shipmentId);

  void markAcceptConsumed(String? offerId) {
    final id = (offerId ?? '').trim();
    if (id.isEmpty || !_acceptedOfferIds.add(id)) return;
    notifyListeners();
  }

  void markPayStarted({String? offerId, String? shipmentId}) {
    if (_addKeys(_payStartedKeys, offerId, shipmentId)) notifyListeners();
  }

  void markPayCompleted({String? offerId, String? shipmentId}) {
    var changed = _addKeys(_payCompletedKeys, offerId, shipmentId);
    changed = _removeKeys(_payStartedKeys, offerId, shipmentId) || changed;
    final id = (offerId ?? '').trim();
    if (id.isNotEmpty) {
      changed = _acceptedOfferIds.add(id) || changed;
    }
    if (changed) notifyListeners();
  }

  void clearPayStarted({String? offerId, String? shipmentId}) {
    if (_removeKeys(_payStartedKeys, offerId, shipmentId)) notifyListeners();
  }

  bool _has(Set<String> keys, String? offerId, String? shipmentId) {
    final offer = (offerId ?? '').trim();
    final shipment = (shipmentId ?? '').trim();
    if (offer.isNotEmpty && keys.contains(_offerKey(offer))) return true;
    if (shipment.isNotEmpty && keys.contains(_shipmentKey(shipment))) {
      return true;
    }
    return false;
  }

  bool _addKeys(Set<String> keys, String? offerId, String? shipmentId) {
    var changed = false;
    final offer = (offerId ?? '').trim();
    final shipment = (shipmentId ?? '').trim();
    if (offer.isNotEmpty) changed = keys.add(_offerKey(offer)) || changed;
    if (shipment.isNotEmpty) {
      changed = keys.add(_shipmentKey(shipment)) || changed;
    }
    return changed;
  }

  bool _removeKeys(Set<String> keys, String? offerId, String? shipmentId) {
    var changed = false;
    final offer = (offerId ?? '').trim();
    final shipment = (shipmentId ?? '').trim();
    if (offer.isNotEmpty) changed = keys.remove(_offerKey(offer)) || changed;
    if (shipment.isNotEmpty) {
      changed = keys.remove(_shipmentKey(shipment)) || changed;
    }
    return changed;
  }
}
