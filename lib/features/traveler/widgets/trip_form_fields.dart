import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/geo/world_countries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/models/meetup_location.dart';
import '../../../data/models/traveler_trip.dart';
import '../../../data/services/trip_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../sender/widgets/departure_time_field.dart';
import '../../sender/widgets/travel_date_field.dart';
import 'available_luggage_capacity_field.dart';
import 'route_city_dropdown.dart';

enum _TravelMethod { byAir, byLand }

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
  TimeOfDay? _departureTime;
  int _luggageCapacityKg = 0;
  String? _travelDateError;
  String? _departureTimeError;
  String? _capacityError;
  late final TextEditingController _flightNumberController;

  _TravelMethod _travelMethod = _TravelMethod.byAir;

  bool get _isCountry => widget.tripType == TripType.countryToCountry;

  bool get _isAirTravel {
    if (!_isCountry) return true;
    return _travelMethod == _TravelMethod.byAir;
  }

  @override
  void initState() {
    super.initState();
    final trip = widget.initialTrip;
    if (trip != null) {
      _fromLocation = trip.fromMeetupLocation;
      _toLocation = trip.toMeetupLocation;
      _travelDate = trip.travelDate;
      _departureTime = _parseDepartureTime(trip.departureTime);
      _luggageCapacityKg = trip.luggageCapacityKg.round();
      _flightNumberController = TextEditingController(
        text: trip.flightNumber?.trim() ?? '',
      );
      if (_isCountry) {
        _travelMethod = _travelMethodFromTrip(trip.travelMethod) ??
            _inferTravelMethodFromTrip(trip);
      }
    } else {
      _flightNumberController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  static _TravelMethod? _travelMethodFromTrip(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'air':
        return _TravelMethod.byAir;
      case 'land':
        return _TravelMethod.byLand;
      default:
        return null;
    }
  }

  static _TravelMethod _inferTravelMethodFromTrip(TravelerTrip trip) {
    final hasAirport = (trip.originAirport?.trim().isNotEmpty ?? false) ||
        (trip.destinationAirport?.trim().isNotEmpty ?? false);
    if (hasAirport) return _TravelMethod.byAir;
    final hasCity = (trip.fromCity?.trim().isNotEmpty ?? false) ||
        (trip.toCity?.trim().isNotEmpty ?? false);
    if (hasCity) return _TravelMethod.byLand;
    return _TravelMethod.byAir;
  }

  static TimeOfDay? _parseDepartureTime(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatDepartureTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _setTravelMethod(_TravelMethod method) {
    if (_travelMethod == method) return;
    setState(() {
      _travelMethod = method;
      _fromLocation = null;
      _toLocation = null;
      if (!_isAirTravel) {
        _flightNumberController.clear();
      }
    });
  }

  /// Validates the form. Returns `true` when valid.
  bool validate() {
    if (_fromLocation == null || _toLocation == null) {
      final endpointLabel = _isCountry
          ? (_isAirTravel ? 'airport' : 'city')
          : 'location';
      AppToast.error(
        context,
        _isCountry
            ? 'Select both From $endpointLabel and To $endpointLabel.'
            : 'Select both From and To locations.',
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
          'Origin and destination must be different.',
        );
        return false;
      }
    } else {
      final origin = _fromLocation!.displayLabel.trim();
      final destination = _toLocation!.displayLabel.trim();
      if (origin.isEmpty || destination.isEmpty) {
        AppToast.error(
          context,
          'Select both From and To locations.',
        );
        return false;
      }
    }

    setState(() {
      if (_travelDate == null) {
        _travelDateError = 'Select a travel date.';
      } else {
        _travelDateError = null;
      }
      _departureTimeError = _departureTime == null
          ? 'Select a departure time.'
          : null;
      _capacityError = _luggageCapacityKg <= 0
          ? 'Enter a valid capacity greater than 0.'
          : null;
    });
    return _travelDateError == null &&
        _departureTimeError == null &&
        _capacityError == null;
  }

  CreateTripRequest buildCreateRequest() {
    final flight = (_isCountry && _isAirTravel)
        ? _flightNumberController.text.trim()
        : '';
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
      final fromLabel = _fromLocation!.displayLabel.trim();
      final toLabel = _toLocation!.displayLabel.trim();
      return CreateTripRequest(
        tripType: TripType.countryToCountry,
        travelDate: _travelDate!,
        departureTime: _formatDepartureTime(_departureTime!),
        luggageCapacityKg: _luggageCapacityKg.toDouble(),
        originCountry: originCountry,
        destinationCountry: destinationCountry,
        originCountryCode: fromCode.isNotEmpty ? fromCode : null,
        destinationCountryCode: toCode.isNotEmpty ? toCode : null,
        originAirport: _isAirTravel ? fromLabel : null,
        destinationAirport: _isAirTravel ? toLabel : null,
        fromCity: _isAirTravel ? null : fromLabel,
        toCity: _isAirTravel ? null : toLabel,
        travelMethod: _isAirTravel ? 'air' : 'land',
        flightNumber: flight.isEmpty ? null : flight,
      );
    }

    final origin = _fromLocation!.displayLabel.trim();
    final destination = _toLocation!.displayLabel.trim();
    return CreateTripRequest(
      tripType: TripType.cityToCity,
      travelDate: _travelDate!,
      departureTime: _formatDepartureTime(_departureTime!),
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
        origin: create.originAirport ??
            create.fromCity ??
            create.originCountry ??
            '',
        destination: create.destinationAirport ??
            create.toCity ??
            create.destinationCountry ??
            '',
        travelDate: create.travelDate,
        departureTime: create.departureTime,
        luggageCapacityKg: create.luggageCapacityKg,
        tripType: 'country_to_country',
        originCountry: create.originCountry,
        destinationCountry: create.destinationCountry,
        originAirport: create.originAirport,
        destinationAirport: create.destinationAirport,
        fromCity: create.fromCity,
        toCity: create.toCity,
        travelMethod: create.travelMethod,
        flightNumber: create.flightNumber,
      );
    }
    return TravelerTrip(
      origin: create.fromCity ?? '',
      destination: create.toCity ?? '',
      travelDate: create.travelDate,
      departureTime: create.departureTime,
      luggageCapacityKg: create.luggageCapacityKg,
      tripType: 'city_to_city',
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle =
        context.typo.h3.copyWith(fontWeight: FontWeight.w600);
    final authUser = context.watch<AuthProvider>().user;
    final kycOk = authUser?.isKycApproved ?? false;

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
              if (_isCountry) ...[
                AppLabeledField(
                  label: 'Travel method',
                  labelStyle: context.typo.inputLabel
                      .copyWith(fontWeight: FontWeight.w600),
                  child: AppChipRow(
                    options: const ['By Air', 'By Land'],
                    selected: _travelMethod == _TravelMethod.byLand
                        ? 'By Land'
                        : 'By Air',
                    onSelected: (value) => _setTravelMethod(
                      value == 'By Land'
                          ? _TravelMethod.byLand
                          : _TravelMethod.byAir,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RouteCityDropdown(
                  label: _isAirTravel ? 'From airport' : 'From city',
                  value: _fromLocation,
                  hintText:
                      _isAirTravel ? 'Search Airport' : 'Search City',
                  mapTitle: _isAirTravel ? 'From airport' : 'From city',
                  searchHint:
                      _isAirTravel ? 'Search Airport' : 'Search City',
                  citySearch: !_isAirTravel,
                  airportSearch: _isAirTravel,
                  onChanged: (place) => setState(() => _fromLocation = place),
                ),
                RouteCityDropdown(
                  label: _isAirTravel ? 'To airport' : 'To city',
                  value: _toLocation,
                  hintText:
                      _isAirTravel ? 'Search Airport' : 'Search City',
                  mapTitle: _isAirTravel ? 'To airport' : 'To city',
                  searchHint:
                      _isAirTravel ? 'Search Airport' : 'Search City',
                  citySearch: !_isAirTravel,
                  airportSearch: _isAirTravel,
                  onChanged: (place) => setState(() => _toLocation = place),
                ),
              ] else ...[
                RouteCityDropdown(
                  label: 'From city',
                  value: _fromLocation,
                  hintText: 'Search Location',
                  mapTitle: 'From city',
                  searchHint: 'Search Location',
                  citySearch: true,
                  airportSearch: false,
                  onChanged: (place) => setState(() => _fromLocation = place),
                ),
                RouteCityDropdown(
                  label: 'To city',
                  value: _toLocation,
                  hintText: 'Search Location',
                  mapTitle: 'To city',
                  searchHint: 'Search Location',
                  citySearch: true,
                  airportSearch: false,
                  onChanged: (place) => setState(() => _toLocation = place),
                ),
              ],
              TravelDateField(
                value: _travelDate,
                errorText: _travelDateError,
                onChanged: (date) => setState(() {
                  _travelDate = date;
                  _travelDateError = null;
                }),
              ),
              const SizedBox(height: 4),
              DepartureTimeField(
                value: _departureTime,
                errorText: _departureTimeError,
                onChanged: (time) => setState(() {
                  _departureTime = time;
                  _departureTimeError = null;
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
              if (_isCountry && _isAirTravel)
                AppLabeledField(
                  label: 'Flight number (optional)',
                  labelStyle: context.typo.inputLabel
                      .copyWith(fontWeight: FontWeight.w600),
                  child: TextField(
                    controller: _flightNumberController,
                    onTap: ensureSoftKeyboardVisible,
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
  MeetupLocation get fromMeetupLocation {
    if (isCountryToCountry) {
      final airport = originAirport?.trim();
      if (airport != null && airport.isNotEmpty) {
        return MeetupLocation(
          name: airport,
          address: airport,
          countryCode: originCountryCode,
        );
      }
      final city = fromCity?.trim();
      if (city != null && city.isNotEmpty) {
        return MeetupLocation(
          name: city,
          address: city,
          countryCode: originCountryCode ?? fromCode,
        );
      }
      return MeetupLocation(
        name: origin,
        address: origin,
        countryCode: originCountryCode,
      );
    }
    return MeetupLocation(
      name: origin,
      address: origin,
      countryCode: fromCode,
    );
  }

  MeetupLocation get toMeetupLocation {
    if (isCountryToCountry) {
      final airport = destinationAirport?.trim();
      if (airport != null && airport.isNotEmpty) {
        return MeetupLocation(
          name: airport,
          address: airport,
          countryCode: destinationCountryCode,
        );
      }
      final city = toCity?.trim();
      if (city != null && city.isNotEmpty) {
        return MeetupLocation(
          name: city,
          address: city,
          countryCode: destinationCountryCode ?? toCode,
        );
      }
      return MeetupLocation(
        name: destination,
        address: destination,
        countryCode: destinationCountryCode,
      );
    }
    return MeetupLocation(
      name: destination,
      address: destination,
      countryCode: toCode,
    );
  }

  TripType get tripTypeEnum =>
      isCountryToCountry ? TripType.countryToCountry : TripType.cityToCity;
}
