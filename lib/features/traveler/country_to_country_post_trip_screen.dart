import 'package:flutter/material.dart';
// TEMPORARILY DISABLED - SUMSUB KYC
// import 'package:provider/provider.dart';

import '../../core/geo/world_airports.dart';
import '../../core/geo/world_countries.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';
import '../../data/trip_creation_wallet_validation.dart';
// TEMPORARILY DISABLED - SUMSUB KYC
// import '../../providers/auth_provider.dart';
import '../sender/widgets/airport_route_search_fields.dart';
import '../sender/widgets/travel_date_field.dart';
import 'trip_posting_actions.dart';
import 'widgets/available_luggage_capacity_field.dart';

class CountryToCountryPostTripScreen extends StatefulWidget {
  const CountryToCountryPostTripScreen({super.key});

  @override
  State<CountryToCountryPostTripScreen> createState() =>
      _CountryToCountryPostTripScreenState();
}

class _CountryToCountryPostTripScreenState
    extends State<CountryToCountryPostTripScreen> {
  WorldAirport? _fromAirport;
  WorldAirport? _toAirport;
  String? _fromAirportError;
  String? _toAirportError;
  late DateTime _travelDate;
  late int _luggageCapacityKg;
  late final TextEditingController _flightNumberController;

  @override
  void initState() {
    super.initState();
    final req = StaticData.deliveryRequests.first;
    _fromAirport = null;
    _toAirport = null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final travelDate = DateTime(
      req.travelDate.year,
      req.travelDate.month,
      req.travelDate.day,
    );
    _travelDate = travelDate.isBefore(todayDate) ? todayDate : travelDate;
    _luggageCapacityKg =
        StaticData.travelerAvailableLuggageCapacityKg.round();
    _flightNumberController = TextEditingController(text: 'AF718');
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  void _postTrip() {
    setState(() {
      _fromAirportError =
          _fromAirport == null ? 'Select an origin airport.' : null;
      _toAirportError = _toAirport == null
          ? 'Select a destination airport.'
          : (_fromAirport != null && _toAirport!.code == _fromAirport!.code
              ? 'Origin and destination airports must be different.'
              : (_fromAirport != null &&
                      _toAirport!.countryIso == _fromAirport!.countryIso
                  ? 'Origin and destination countries must be different.'
                  : null));
    });

    if (_fromAirportError != null || _toAirportError != null) return;

    final from = _fromAirport!;
    final to = _toAirport!;
    TripPostingActions.tryPostTrip(
      context,
      TravelerTrip(
        origin: WorldCountries.byIso(from.countryIso).name,
        destination: WorldCountries.byIso(to.countryIso).name,
        travelDate: _travelDate,
        luggageCapacityKg: _luggageCapacityKg.toDouble(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle =
        context.typo.h3.copyWith(fontWeight: FontWeight.w600);
    // TEMPORARILY DISABLED - SUMSUB KYC
    // final authUser = context.watch<AuthProvider>().user;
    // final kycOk = authUser?.isKycApproved ?? false;
    final reserveOk = TripCreationWalletValidation.hasMinimumBalance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Post a trip'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Post trip →',
            onPressed: _postTrip,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell senders where you\'re going and how much you can carry.',
              style: context.typo.sm,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // TEMPORARILY DISABLED - SUMSUB KYC
                // AppBadge(
                //   label: kycOk ? 'KYC approved' : 'KYC required',
                //   color: kycOk ? AppColors.success : AppColors.danger,
                //   backgroundColor:
                //       (kycOk ? AppColors.success : AppColors.danger)
                //           .withValues(alpha: 0.12),
                //   semiBold: true,
                // ),
                AppBadge(
                  label: TripCreationWalletValidation.helperLabel,
                  color: reserveOk ? AppColors.success : AppColors.danger,
                  backgroundColor:
                      (reserveOk ? AppColors.success : AppColors.danger)
                          .withValues(alpha: 0.12),
                  semiBold: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  AirportRouteSearchFields(
                    fromAirport: _fromAirport,
                    toAirport: _toAirport,
                    fromErrorText: _fromAirportError,
                    toErrorText: _toAirportError,
                    onFromChanged: (airport) => setState(() {
                      _fromAirport = airport;
                      _fromAirportError = null;
                      if (_toAirport != null &&
                          airport != null &&
                          _toAirport!.countryIso == airport.countryIso) {
                        _toAirportError =
                            'Origin and destination countries must be different.';
                      } else {
                        _toAirportError = null;
                      }
                    }),
                    onToChanged: (airport) => setState(() {
                      _toAirport = airport;
                      if (airport != null &&
                          _fromAirport != null &&
                          airport.countryIso == _fromAirport!.countryIso) {
                        _toAirportError =
                            'Origin and destination countries must be different.';
                      } else {
                        _toAirportError = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  TravelDateField(
                    value: _travelDate,
                    onChanged: (date) => setState(() => _travelDate = date),
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Luggage Capacity', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  AvailableLuggageCapacityField(
                    initialValue: _luggageCapacityKg,
                    onChanged: (kg) => _luggageCapacityKg = kg,
                  ),
                  AppLabeledField(
                    label: 'Flight number (optional)',
                    labelStyle: context.typo.inputLabel
                        .copyWith(fontWeight: FontWeight.w600),
                    child: TextField(
                      controller: _flightNumberController,
                      style: context.typo.input,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'e.g. AF718',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
