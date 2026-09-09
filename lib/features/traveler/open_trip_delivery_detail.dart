import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/delivery_repository.dart';
import '../../providers/auth_provider.dart';

/// Opens the existing traveler Delivery/Trip detail screen (shipment timeline)
/// for the delivery linked to [trip], matching My Deliveries.
///
/// Falls back to read-only trip details when no delivery is linked yet.
Future<void> openTravelerTripDeliveryDetail(
  BuildContext context,
  TravelerTrip trip,
) async {
  final tripKey = trip.displayId.trim();
  if (tripKey.isEmpty) return;

  final demoMode = context.read<DemoModeProvider>();
  if (demoMode.enabled) {
    await context.push('/view-trip/$tripKey');
    return;
  }

  try {
    final auth = context.read<AuthProvider>();
    final repo = DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
    final delivery = await repo.getDelivery(tripKey, role: 'traveler');
    final deliveryId =
        delivery.publicId.isNotEmpty ? delivery.publicId : delivery.id;
    if (!context.mounted || deliveryId.isEmpty) return;
    await context.push('/shipment/$deliveryId?traveler=true');
  } on ApiException catch (e) {
    if (!context.mounted) return;
    final notFound = e.statusCode == 404 || e.code == 'NOT_FOUND';
    if (notFound) {
      await context.push('/view-trip/$tripKey');
      return;
    }
    // Backend can resolve TR-… directly on the shipment route.
    await context.push('/shipment/$tripKey?traveler=true');
  } catch (_) {
    if (!context.mounted) return;
    await context.push('/view-trip/$tripKey');
  }
}
