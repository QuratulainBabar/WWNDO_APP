import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';
import '../sender/widgets/travel_date_field.dart';
import 'widgets/available_luggage_capacity_field.dart';

class EditTripScreen extends StatefulWidget {
  const EditTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  late final TravelerTrip _trip;
  late DateTime _travelDate;
  late int _luggageCapacityKg;
  String? _capacityError;

  @override
  void initState() {
    super.initState();
    _trip = StaticData.travelerTripById(widget.tripId) ??
        StaticData.travelerPostedTrips.first;
    _travelDate = _trip.travelDate;
    _luggageCapacityKg = _trip.luggageCapacityKg.round();
  }

  void _save() {
    if (_luggageCapacityKg <= 0) {
      setState(() => _capacityError = 'Enter a valid capacity greater than 0.');
      return;
    }

    StaticData.updateTravelerTrip(
      TravelerTrip(
        id: _trip.id,
        origin: _trip.origin,
        destination: _trip.destination,
        travelDate: _travelDate,
        luggageCapacityKg: _luggageCapacityKg.toDouble(),
        status: _trip.status,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_trip.id} updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Edit ${_trip.id}',
        fallbackRoute: '/traveler-trips',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(label: 'Save changes', onPressed: _save),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trip.id,
                      style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(_trip.route, style: typo.smPrimary),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(_trip.travelDate),
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TravelDateField(
              value: _travelDate,
              onChanged: (date) => setState(() => _travelDate = date),
            ),
            const SizedBox(height: 16),
            Text('Available luggage capacity', style: typo.label),
            const SizedBox(height: 8),
            AvailableLuggageCapacityField(
              initialValue: _luggageCapacityKg,
              onChanged: (value) => setState(() {
                _luggageCapacityKg = value;
                _capacityError = null;
              }),
            ),
            if (_capacityError != null) ...[
              const SizedBox(height: 8),
              Text(
                _capacityError!,
                style: typo.sm.copyWith(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
