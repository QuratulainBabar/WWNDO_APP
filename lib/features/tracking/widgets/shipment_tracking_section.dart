import 'package:flutter/material.dart';

import '../../../data/models/shipment.dart';
import 'parcel_photo_viewer.dart';
import 'shipment_route_map.dart';
import 'shipment_status_timeline.dart';

/// Shared tracking UI block for sender, traveler, and receiver detail screens.
class ShipmentTrackingSection extends StatelessWidget {
  const ShipmentTrackingSection({
    super.key,
    required this.shipment,
    required this.stepProgress,
    this.stepLabels,
  });

  final Shipment shipment;
  final int stepProgress;
  final List<String>? stepLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShipmentRouteMap(shipment: shipment, stepProgress: stepProgress),
        const SizedBox(height: 24),
        ShipmentStatusTimeline(
          stepProgress: stepProgress,
          stepLabels: stepLabels,
        ),
        const SizedBox(height: 24),
        ParcelPhotoViewer(photoCount: shipment.parcelPhotoCount),
      ],
    );
  }
}
