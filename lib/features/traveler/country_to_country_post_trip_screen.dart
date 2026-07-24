import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/geo/world_countries.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/meetup_location.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/trip_creation_wallet_validation.dart';
import '../../providers/auth_provider.dart';
import '../sender/widgets/travel_date_field.dart';
import 'trip_posting_actions.dart';
import 'widgets/available_luggage_capacity_field.dart';
import 'widgets/route_city_dropdown.dart';

class CountryToCountryPostTripScreen extends StatefulWidget {
  const CountryToCountryPostTripScreen({super.key});

  @override
  State<CountryToCountryPostTripScreen> createState() =>
      _CountryToCountryPostTripScreenState();
}

class _CountryToCountryPostTripScreenState
    extends State<CountryToCountryPostTripScreen> {
  MeetupLocation? _fromLocation;
  MeetupLocation? _toLocation;
  DateTime? _travelDate;
  int _luggageCapacityKg = 0;
  String? _travelDateError;
  String? _capacityError;
  late final TextEditingController _flightNumberController;

  @override
  void initState() {
    super.initState();
    _flightNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  void _postTrip() {
    if (_fromLocation == null || _toLocation == null) {
      AppToast.error(context, 'Select both From and To locations.');
      return;
    }

    final fromCode = _fromLocation!.countryCode?.toUpperCase();
    final toCode = _toLocation!.countryCode?.toUpperCase();
    if (fromCode != null &&
        toCode != null &&
        fromCode.isNotEmpty &&
        toCode.isNotEmpty &&
        fromCode == toCode) {
      AppToast.error(
        context,
        'Origin and destination countries must be different.',
      );
      return;
    }

    if (_fromLocation!.displayLabel == _toLocation!.displayLabel) {
      AppToast.error(
        context,
        'Origin and destination locations must be different.',
      );
      return;
    }

    setState(() {
      _travelDateError =
          _travelDate == null ? 'Select a travel date.' : null;
      _capacityError = _luggageCapacityKg <= 0
          ? 'Enter a valid capacity greater than 0.'
          : null;
    });
    if (_travelDateError != null || _capacityError != null) return;

    final fromIso = fromCode ?? '';
    final toIso = toCode ?? '';
    final originCountry = fromIso.isNotEmpty && WorldCountries.containsIso(fromIso)
        ? WorldCountries.byIso(fromIso).name
        : _fromLocation!.displayLabel;
    final destinationCountry =
        toIso.isNotEmpty && WorldCountries.containsIso(toIso)
            ? WorldCountries.byIso(toIso).name
            : _toLocation!.displayLabel;

    TripPostingActions.tryPostTrip(
      context,
      TravelerTrip(
        origin: originCountry,
        destination: destinationCountry,
        travelDate: _travelDate!,
        luggageCapacityKg: _luggageCapacityKg.toDouble(),
      ),
      request: CreateTripRequest(
        tripType: TripType.countryToCountry,
        travelDate: _travelDate!,
        luggageCapacityKg: _luggageCapacityKg.toDouble(),
        originCountry: originCountry,
        destinationCountry: destinationCountry,
        originCountryCode: fromIso.isNotEmpty ? fromIso : null,
        destinationCountryCode: toIso.isNotEmpty ? toIso : null,
        flightNumber: _flightNumberController.text.trim().isEmpty
            ? null
            : _flightNumberController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle =
        context.typo.h3.copyWith(fontWeight: FontWeight.w600);
    final authUser = context.watch<AuthProvider>().user;
    final kycOk = authUser?.isKycApproved ?? false;
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
                AppBadge(
                  label: kycOk ? 'KYC approved' : 'KYC required',
                  color: kycOk ? AppColors.success : AppColors.danger,
                  backgroundColor:
                      (kycOk ? AppColors.success : AppColors.danger)
                          .withValues(alpha: 0.12),
                  semiBold: true,
                ),
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
                  RouteCityDropdown(
                    label: 'From',
                    value: _fromLocation,
                    hintText: 'Search location',
                    mapTitle: 'From location',
                    searchHint: 'Search from location',
                    citySearch: false,
                    onChanged: (place) => setState(() => _fromLocation = place),
                  ),
                  RouteCityDropdown(
                    label: 'To',
                    value: _toLocation,
                    hintText: 'Search location',
                    mapTitle: 'To location',
                    searchHint: 'Search to location',
                    citySearch: false,
                    onChanged: (place) => setState(() => _toLocation = place),
                  ),
                  TravelDateField(
                    value: _travelDate,
                    errorText: _travelDateError,
                    onChanged: (date) => setState(() {
                      _travelDate = date;
                      _travelDateError = null;
                    }),
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
                    onChanged: (kg) => setState(() {
                      _luggageCapacityKg = kg;
                      _capacityError = null;
                    }),
                  ),
                  if (_capacityError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _capacityError!,
                      style: context.typo.sm.copyWith(color: AppColors.danger),
                    ),
                  ],
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
