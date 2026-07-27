import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/geo/world_countries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/models/meetup_location.dart';
import '../../../data/models/traveler_trip.dart';
import '../../../data/services/trip_repository.dart';
import '../../../data/trip_creation_wallet_validation.dart';
import '../../../providers/auth_provider.dart';
import '../../sender/widgets/travel_date_field.dart';
import 'available_luggage_capacity_field.dart';
import 'route_city_dropdown.dart';

/// Shared trip form used for create and edit (city-to-city and country-to-country).
class TripFormFields extends StatefulWidget {
  const TripFormFields({
    super.key,
    required this.tripType,
    this.initialTrip,
    this.showCreateBadges = false,
  });

  final TripType tripType;
  final TravelerTrip? initialTrip;
  final bool showCreateBadges;

  @override
  TripFormFieldsState createState() => TripFormFieldsState();
}

class TripFormFieldsState extends State<TripFormFields> {
  MeetupLocation? _fromLocation;
  MeetupLocation? _toLocation;
  DateTime? _travelDate;
  int _luggageCapacityKg = 0;
  String? _travelDateError;
  String? _capacityError;
  late final TextEditingController _flightNumberController;

  bool get _isCountry => widget.tripType == TripType.countryToCountry;

  @override
  void initState() {
    super.initState();
    final trip = widget.initialTrip;
    if (trip != null) {
      _fromLocation = trip.fromMeetupLocation;
      _toLocation = trip.toMeetupLocation;
      _travelDate = trip.travelDate;
      _luggageCapacityKg = trip.luggageCapacityKg.round();
      _flightNumberController = TextEditingController(
        text: trip.flightNumber?.trim() ?? '',
      );
    } else {
      _flightNumberController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  /// Validates the form. Returns `true` when valid.
  bool validate() {
    if (_fromLocation == null || _toLocation == null) {
      AppToast.error(
        context,
        _isCountry
            ? 'Select both From and To locations.'
            : 'Select both From and To locations on the map.',
      );
      return false;
    }

    if (_isCountry) {
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
        return false;
      }
      if (_fromLocation!.displayLabel == _toLocation!.displayLabel) {
        AppToast.error(
          context,
          'Origin and destination locations must be different.',
        );
        return false;
      }
    } else {
      final origin = _fromLocation!.name.trim();
      final destination = _toLocation!.name.trim();
      if (origin.isEmpty || destination.isEmpty) {
        AppToast.error(
          context,
          'Select both From and To locations on the map.',
        );
        return false;
      }
    }

    setState(() {
      _travelDateError =
          _travelDate == null ? 'Select a travel date.' : null;
      _capacityError = _luggageCapacityKg <= 0
          ? 'Enter a valid capacity greater than 0.'
          : null;
    });
    return _travelDateError == null && _capacityError == null;
  }

  CreateTripRequest buildCreateRequest() {
    final flight = _flightNumberController.text.trim();
    if (_isCountry) {
      final fromCode = _fromLocation!.countryCode?.toUpperCase() ?? '';
      final toCode = _toLocation!.countryCode?.toUpperCase() ?? '';
      final originCountry =
          fromCode.isNotEmpty && WorldCountries.containsIso(fromCode)
              ? WorldCountries.byIso(fromCode).name
              : _fromLocation!.displayLabel;
      final destinationCountry =
          toCode.isNotEmpty && WorldCountries.containsIso(toCode)
              ? WorldCountries.byIso(toCode).name
              : _toLocation!.displayLabel;
      return CreateTripRequest(
        tripType: TripType.countryToCountry,
        travelDate: _travelDate!,
        luggageCapacityKg: _luggageCapacityKg.toDouble(),
        originCountry: originCountry,
        destinationCountry: destinationCountry,
        originCountryCode: fromCode.isNotEmpty ? fromCode : null,
        destinationCountryCode: toCode.isNotEmpty ? toCode : null,
        flightNumber: flight.isEmpty ? null : flight,
      );
    }

    final origin = _fromLocation!.name.trim();
    final destination = _toLocation!.name.trim();
    return CreateTripRequest(
      tripType: TripType.cityToCity,
      travelDate: _travelDate!,
      luggageCapacityKg: _luggageCapacityKg.toDouble(),
      fromCity: origin,
      toCity: destination,
      fromCode: _fromLocation!.countryCode?.toUpperCase(),
      toCode: _toLocation!.countryCode?.toUpperCase(),
      flightNumber: flight.isEmpty ? null : flight,
    );
  }

  UpdateTripRequest buildUpdateRequest() {
    final create = buildCreateRequest();
    return UpdateTripRequest.fromCreateRequest(create);
  }

  TravelerTrip buildPreviewTrip() {
    final create = buildCreateRequest();
    if (_isCountry) {
      return TravelerTrip(
        origin: create.originCountry ?? '',
        destination: create.destinationCountry ?? '',
        travelDate: create.travelDate,
        luggageCapacityKg: create.luggageCapacityKg,
      );
    }
    return TravelerTrip(
      origin: create.fromCity ?? '',
      destination: create.toCity ?? '',
      travelDate: create.travelDate,
      luggageCapacityKg: create.luggageCapacityKg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle =
        context.typo.h3.copyWith(fontWeight: FontWeight.w600);
    final authUser = context.watch<AuthProvider>().user;
    final kycOk = authUser?.isKycApproved ?? false;
    final reserveOk = TripCreationWalletValidation.hasMinimumBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showCreateBadges) ...[
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
                backgroundColor: (kycOk ? AppColors.success : AppColors.danger)
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
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Route', style: sectionTitleStyle),
              const SizedBox(height: 12),
              RouteCityDropdown(
                label: _isCountry ? 'From' : 'From city',
                value: _fromLocation,
                hintText: 'Search location',
                mapTitle: _isCountry ? 'From location' : 'From city',
                searchHint:
                    _isCountry ? 'Search from location' : 'Search from city',
                citySearch: !_isCountry,
                onChanged: (place) => setState(() => _fromLocation = place),
              ),
              RouteCityDropdown(
                label: _isCountry ? 'To' : 'To city',
                value: _toLocation,
                hintText: 'Search location',
                mapTitle: _isCountry ? 'To location' : 'To city',
                searchHint: _isCountry ? 'Search to location' : 'Search to city',
                citySearch: !_isCountry,
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
                initialValue:
                    _luggageCapacityKg > 0 ? _luggageCapacityKg : null,
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
                  onTapOutside: dismissKeyboardOnTapOutside,
                  style: context.typo.input,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. BA083',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension TravelerTripFormX on TravelerTrip {
  MeetupLocation get fromMeetupLocation => MeetupLocation(
        name: origin,
        address: origin,
        countryCode: isCountryToCountry ? originCountryCode : fromCode,
      );

  MeetupLocation get toMeetupLocation => MeetupLocation(
        name: destination,
        address: destination,
        countryCode: isCountryToCountry ? destinationCountryCode : toCode,
      );

  TripType get tripTypeEnum =>
      isCountryToCountry ? TripType.countryToCountry : TripType.cityToCity;
}
