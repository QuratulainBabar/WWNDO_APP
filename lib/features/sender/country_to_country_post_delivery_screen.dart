import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/geo/world_airports.dart';
import '../../core/geo/world_countries.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/created_delivery.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'delivery_posting_actions.dart';
import 'widgets/description_field.dart';
import 'widgets/maximum_budget_field.dart';
import 'widgets/parcel_acknowledgement_section.dart';
import 'widgets/parcel_photos_section.dart';
import 'widgets/platform_fee_section.dart';
import '../../data/models/meetup_location.dart';
import 'widgets/meetup_locations_card.dart';
import 'widgets/receiver_info_section.dart';
import 'widgets/route_airport_dropdown.dart';
import 'widgets/route_country_dropdown.dart';
import 'widgets/travel_date_field.dart';
import 'widgets/weight_kg_field.dart';

class CountryToCountryPostDeliveryScreen extends StatefulWidget {
  const CountryToCountryPostDeliveryScreen({super.key});

  @override
  State<CountryToCountryPostDeliveryScreen> createState() =>
      _CountryToCountryPostDeliveryScreenState();
}

class _CountryToCountryPostDeliveryScreenState
    extends State<CountryToCountryPostDeliveryScreen> {
  String _category = 'documents';
  String _size = 'small box';
  bool _parcelAcknowledged = false;
  bool _submitting = false;
  bool _paysReceiverFee = false;
  final List<String> _photoPaths = [];
  List<MeetupLocation> _meetupLocations = const [];
  List<MeetupLocation> _receiverMeetupLocations = const [];
  double _maxBudget = StaticData.postDeliveryMaximumBudget;
  String? _photosError;
  String? _meetupError;
  String? _receiverMeetupError;
  String? _budgetError;
  late DateTime _travelDate;
  late double _weightKg;
  String? _weightError;
  String? _receiverEmailError;
  String? _receiverPhoneError;
  String _receiverEmail = '';
  String _receiverPhone = '';

  late String _originCountryIso;
  late String _destinationCountryIso;
  late String _originAirport;
  late String _destinationAirport;
  String? _originCountryError;
  String? _destinationCountryError;
  String? _originAirportError;
  String? _destinationAirportError;
  String? _descriptionError;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final shipment = StaticData.activeShipment;
    _weightKg = shipment.parcelWeightKg;
    _descriptionController = TextEditingController(text: shipment.description);
    final today = DateTime.now();
    final shipmentDate = DateTime(
      shipment.travelDate.year,
      shipment.travelDate.month,
      shipment.travelDate.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    _travelDate = shipmentDate.isBefore(todayDate) ? todayDate : shipmentDate;

    _originCountryIso = _isoFromCountryName(StaticData.countryToCountryOriginCountry) ?? 'FR';
    _destinationCountryIso =
        _isoFromCountryName(StaticData.countryToCountryDestinationCountry) ?? 'SN';
    _originAirport = StaticData.countryToCountryOriginAirport;
    _destinationAirport = StaticData.countryToCountryDestinationAirport;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String? _isoFromCountryName(String name) {
    final needle = name.trim().toLowerCase();
    for (final country in WorldCountries.all) {
      if (country.name.toLowerCase() == needle) return country.iso;
    }
    return null;
  }

  String _countryName(String iso) => WorldCountries.byIso(iso).name;

  void _onOriginCountryChanged(String iso) {
    final airport = WorldAirports.firstForCountry(iso);
    setState(() {
      _originCountryIso = iso;
      _originCountryError = null;
      _originAirport = airport?.label ?? '';
      _originAirportError = null;
      if (_destinationCountryIso == iso) {
        _destinationCountryError = 'Origin and destination countries must be different.';
      } else {
        _destinationCountryError = null;
      }
    });
  }

  void _onDestinationCountryChanged(String iso) {
    final airport = WorldAirports.firstForCountry(iso);
    setState(() {
      _destinationCountryIso = iso;
      _destinationCountryError = iso == _originCountryIso
          ? 'Origin and destination countries must be different.'
          : null;
      _destinationAirport = airport?.label ?? '';
      _destinationAirportError = null;
    });
  }

  Future<void> _submit() async {
    if (!DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) return;

    setState(() {
      _photosError = _photoPaths.isEmpty ? 'Upload at least 1 parcel photo.' : null;
      _meetupError = _meetupLocations.isEmpty
          ? 'Add at least one meetup location.'
          : null;
      _receiverMeetupError = _receiverMeetupLocations.isEmpty
          ? 'Select a meetup location.'
          : null;
      _budgetError = _maxBudget <= 0 ? 'Enter a valid maximum budget.' : null;
      _weightError = _weightKg <= 0 ? 'Enter a valid weight greater than 0.' : null;
      _receiverEmailError = _validateReceiverEmail(_receiverEmail);
      _receiverPhoneError = _validateReceiverPhone(_receiverPhone);
      _originCountryError =
          _originCountryIso.isEmpty ? 'Select an origin country.' : null;
      _destinationCountryError = _destinationCountryIso.isEmpty
          ? 'Select a destination country.'
          : (_destinationCountryIso == _originCountryIso
              ? 'Origin and destination countries must be different.'
              : null);
      _originAirportError =
          _originAirport.isEmpty ? 'Select an origin airport.' : null;
      _destinationAirportError =
          _destinationAirport.isEmpty ? 'Select a destination airport.' : null;
      _descriptionError = _descriptionController.text.trim().isEmpty
          ? 'Enter a parcel description.'
          : null;
    });

    if (!_parcelAcknowledged ||
        _photosError != null ||
        _meetupError != null ||
        _receiverMeetupError != null ||
        _budgetError != null ||
        _weightError != null ||
        _receiverEmailError != null ||
        _receiverPhoneError != null ||
        _originCountryError != null ||
        _destinationCountryError != null ||
        _originAirportError != null ||
        _destinationAirportError != null ||
        _descriptionError != null) {
      return;
    }

    final originCountry = _countryName(_originCountryIso);
    final destinationCountry = _countryName(_destinationCountryIso);
    final route = '$originCountry → $destinationCountry';
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    final repository = DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );

    setState(() => _submitting = true);
    try {
      final created = await repository.createDelivery(
        CreateDeliveryRequest(
          deliveryType: DeliveryType.countryToCountry,
          originCountry: originCountry,
          originAirport: _originAirport,
          destinationCountry: destinationCountry,
          destinationAirport: _destinationAirport,
          travelDate: _travelDate,
          parcelCategory: _category,
          parcelSize: _size,
          weightKg: _weightKg,
          maxBudget: _maxBudget,
          description: _descriptionController.text.trim(),
          preferredMeetupLocations:
              _meetupLocations.map((l) => l.displayLabel).toList(),
          acknowledged: _parcelAcknowledged,
          photoPaths: List<String>.from(_photoPaths),
          receiverEmail: _receiverEmail,
          receiverPhone: _receiverPhone,
          receiverMeetupLocation: _receiverMeetupLocations.isEmpty
              ? null
              : _receiverMeetupLocations.first.displayLabel,
          platformFee: StaticData.senderPlatformFeeUsd(
            category: _category,
            paysReceiverFee: _paysReceiverFee,
          ),
          platformFeeShare: StaticData.travelerPlatformFeeUsd(_category),
          paysReceiverFee: _paysReceiverFee,
        ),
      );

      StaticData.registerPostedDelivery(
        shipmentId: created.publicId,
        fromCity: originCountry,
        toCity: destinationCountry,
        fromCode: _originCountryIso,
        toCode: _destinationCountryIso,
        travelDate: _travelDate,
        parcelCategory: _category,
        parcelWeightKg: _weightKg,
        parcelSize: _size,
        description: _descriptionController.text.trim(),
        parcelPhotoCount: _photoPaths.length,
        paysReceiverFee: _paysReceiverFee,
      );

      if (!mounted) return;
      context.pushReplacement(
        '/post-delivery/success',
        extra: created.route.isNotEmpty ? created.route : route,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to post delivery. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final airportCountries = WorldAirports.countryIsosWithAirports;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Post delivery', fallbackRoute: '/delivery-type'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: _submitting ? 'Posting…' : 'Post delivery →',
            onPressed: (_parcelAcknowledged && !_submitting) ? _submit : null,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route', style: context.typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            RouteCountryDropdown(
              label: 'Origin country',
              value: _originCountryIso,
              hintText: 'Select origin country',
              allowedIsos: airportCountries,
              onChanged: _onOriginCountryChanged,
            ),
            if (_originCountryError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _originCountryError!,
                  style: context.typo.sm.copyWith(color: AppColors.danger),
                ),
              ),
            RouteAirportDropdown(
              label: 'Origin airport',
              countryIso: _originCountryIso,
              value: _originAirport,
              hintText: 'Select origin airport',
              onChanged: (airport) => setState(() {
                _originAirport = airport;
                _originAirportError = null;
              }),
            ),
            if (_originAirportError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _originAirportError!,
                  style: context.typo.sm.copyWith(color: AppColors.danger),
                ),
              ),
            RouteCountryDropdown(
              label: 'Destination country',
              value: _destinationCountryIso,
              hintText: 'Select destination country',
              allowedIsos: airportCountries,
              onChanged: _onDestinationCountryChanged,
            ),
            if (_destinationCountryError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _destinationCountryError!,
                  style: context.typo.sm.copyWith(color: AppColors.danger),
                ),
              ),
            RouteAirportDropdown(
              label: 'Destination airport',
              countryIso: _destinationCountryIso,
              value: _destinationAirport,
              hintText: 'Select destination airport',
              onChanged: (airport) => setState(() {
                _destinationAirport = airport;
                _destinationAirportError = null;
              }),
            ),
            if (_destinationAirportError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _destinationAirportError!,
                  style: context.typo.sm.copyWith(color: AppColors.danger),
                ),
              ),
            TravelDateField(
              value: _travelDate,
              onChanged: (date) => setState(() => _travelDate = date),
            ),
            const SizedBox(height: 12),
            Text('Parcel', style: context.typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            AppChipRow(
              options: StaticData.parcelCategories,
              selected: _category,
              onSelected: (v) => setState(() => _category = v),
            ),
            WeightKgField(
              initialValue: _weightKg,
              errorText: _weightError,
              onChanged: (value) => setState(() {
                _weightKg = value;
                _weightError = null;
              }),
            ),
            ParcelPhotosSection(
              photoPaths: _photoPaths,
              errorText: _photosError,
              onChanged: (paths) => setState(() {
                _photoPaths
                  ..clear()
                  ..addAll(paths);
                _photosError = null;
              }),
            ),
            MaximumBudgetField(
              initialValue: _maxBudget,
              errorText: _budgetError,
              onChanged: (value) => setState(() {
                _maxBudget = value;
                _budgetError = null;
              }),
            ),
            MeetupLocationsCard(
              locations: _meetupLocations,
              errorText: _meetupError,
              onTap: () async {
                final result = await context.push<List<MeetupLocation>>(
                  '/add-meetup-locations',
                  extra: _meetupLocations,
                );
                if (result != null) {
                  setState(() {
                    _meetupLocations = result;
                    _meetupError = null;
                  });
                }
              },
            ),
            DescriptionField(
              controller: _descriptionController,
              errorText: _descriptionError,
            ),
            const SizedBox(height: 12),
            ReceiverInfoSection(
              emailErrorText: _receiverEmailError,
              phoneErrorText: _receiverPhoneError,
              meetupErrorText: _receiverMeetupError,
              meetupLocations: _receiverMeetupLocations,
              onEmailChanged: (email) => setState(() {
                _receiverEmail = email;
                _receiverEmailError = null;
              }),
              onPhoneChanged: (phone) => setState(() {
                _receiverPhone = phone;
                _receiverPhoneError = null;
              }),
              onMeetupLocationsChanged: (locations) => setState(() {
                _receiverMeetupLocations = locations;
                _receiverMeetupError = null;
              }),
            ),
            const SizedBox(height: 12),
            ParcelAcknowledgementSection(
              onChanged: (acknowledged) => setState(() => _parcelAcknowledged = acknowledged),
            ),
            const SizedBox(height: 12),
            PlatformFeeSection(
              onChanged: (pays) => setState(() => _paysReceiverFee = pays),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateReceiverEmail(String email) {
    if (email.isEmpty) return 'Enter the receiver\'s email.';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) return 'Enter a valid receiver email.';
    return null;
  }

  String? _validateReceiverPhone(String phone) {
    if (phone.isEmpty) return 'Enter the receiver\'s phone number.';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Enter a valid receiver phone number.';
    return null;
  }
}
