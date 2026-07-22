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
import '../sender/widgets/route_airport_dropdown.dart';
import '../sender/widgets/route_country_dropdown.dart';
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
  late String _originCountryIso;
  late String _destinationCountryIso;
  late String _originAirport;
  late String _destinationAirport;
  late DateTime _travelDate;
  late int _luggageCapacityKg;
  late final TextEditingController _flightNumberController;

  @override
  void initState() {
    super.initState();
    final req = StaticData.deliveryRequests.first;
    _originCountryIso =
        _isoFromCountryName(StaticData.countryToCountryOriginCountry) ?? 'FR';
    _destinationCountryIso =
        _isoFromCountryName(StaticData.countryToCountryDestinationCountry) ??
            'SN';
    _originAirport = StaticData.countryToCountryOriginAirport;
    _destinationAirport = StaticData.countryToCountryDestinationAirport;
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

  String? _isoFromCountryName(String name) {
    final needle = name.trim().toLowerCase();
    for (final country in WorldCountries.all) {
      if (country.name.toLowerCase() == needle) return country.iso;
    }
    return null;
  }

  void _onOriginCountryChanged(String iso) {
    final airport = WorldAirports.firstForCountry(iso);
    setState(() {
      _originCountryIso = iso;
      _originAirport = airport?.label ?? '';
    });
  }

  void _onDestinationCountryChanged(String iso) {
    final airport = WorldAirports.firstForCountry(iso);
    setState(() {
      _destinationCountryIso = iso;
      _destinationAirport = airport?.label ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle =
        context.typo.h3.copyWith(fontWeight: FontWeight.w600);
    // TEMPORARILY DISABLED - SUMSUB KYC
    // final authUser = context.watch<AuthProvider>().user;
    // final kycOk = authUser?.isKycApproved ?? false;
    final reserveOk = TripCreationWalletValidation.hasMinimumBalance;
    final airportCountries = WorldAirports.countryIsosWithAirports;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Post a trip'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Post trip →',
            onPressed: () {
              TripPostingActions.tryPostTrip(
                context,
                TravelerTrip(
                  origin: WorldCountries.byIso(_originCountryIso).name,
                  destination:
                      WorldCountries.byIso(_destinationCountryIso).name,
                  travelDate: _travelDate,
                  luggageCapacityKg: _luggageCapacityKg.toDouble(),
                ),
              );
            },
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
                  RouteCountryDropdown(
                    label: 'Origin country',
                    value: _originCountryIso,
                    hintText: 'Select origin country',
                    allowedIsos: airportCountries,
                    onChanged: _onOriginCountryChanged,
                  ),
                  RouteAirportDropdown(
                    label: 'Origin airport',
                    countryIso: _originCountryIso,
                    value: _originAirport,
                    hintText: 'Select origin airport',
                    onChanged: (airport) =>
                        setState(() => _originAirport = airport),
                  ),
                  RouteCountryDropdown(
                    label: 'Destination country',
                    value: _destinationCountryIso,
                    hintText: 'Select destination country',
                    allowedIsos: airportCountries,
                    onChanged: _onDestinationCountryChanged,
                  ),
                  RouteAirportDropdown(
                    label: 'Destination airport',
                    countryIso: _destinationCountryIso,
                    value: _destinationAirport,
                    hintText: 'Select destination airport',
                    onChanged: (airport) =>
                        setState(() => _destinationAirport = airport),
                  ),
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
