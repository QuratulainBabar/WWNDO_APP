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
import '../../data/models/meetup_location.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'delivery_posting_actions.dart';
import 'widgets/airport_route_search_fields.dart';
import 'widgets/description_field.dart';
import 'widgets/maximum_budget_field.dart';
import 'widgets/meetup_locations_card.dart';
import 'widgets/parcel_acknowledgement_section.dart';
import 'widgets/parcel_photos_section.dart';
import 'widgets/platform_fee_section.dart';
import 'widgets/receiver_info_section.dart';
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

  WorldAirport? _fromAirport;
  WorldAirport? _toAirport;
  String? _fromAirportError;
  String? _toAirportError;
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

    _fromAirport = null;
    _toAirport = null;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) {
      return;
    }

    setState(() {
      _photosError =
          _photoPaths.isEmpty ? 'Upload at least 1 parcel photo.' : null;
      _meetupError = _meetupLocations.isEmpty
          ? 'Add at least one meetup location.'
          : null;
      _receiverMeetupError = _receiverMeetupLocations.isEmpty
          ? 'Select a meetup location.'
          : null;
      _budgetError = _maxBudget <= 0 ? 'Enter a valid maximum budget.' : null;
      _weightError =
          _weightKg <= 0 ? 'Enter a valid weight greater than 0.' : null;
      _receiverEmailError = _validateReceiverEmail(_receiverEmail);
      _receiverPhoneError = _validateReceiverPhone(_receiverPhone);
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
        _fromAirportError != null ||
        _toAirportError != null ||
        _descriptionError != null) {
      return;
    }

    final from = _fromAirport!;
    final to = _toAirport!;
    final originCountry = WorldCountries.byIso(from.countryIso).name;
    final destinationCountry = WorldCountries.byIso(to.countryIso).name;
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
          originAirport: from.label,
          destinationCountry: destinationCountry,
          destinationAirport: to.label,
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
        fromCode: from.countryIso,
        toCode: to.countryIso,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(
        title: 'Post delivery',
        fallbackRoute: '/delivery-type',
      ),
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
            Text(
              'Route',
              style: context.typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
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
            const SizedBox(height: 12),
            Text(
              'Parcel',
              style: context.typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
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
              onChanged: (acknowledged) =>
                  setState(() => _parcelAcknowledged = acknowledged),
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
