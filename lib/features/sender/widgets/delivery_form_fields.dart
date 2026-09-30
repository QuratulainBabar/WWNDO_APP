import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/geo/meetup_destination_validation.dart';
import '../../../core/geo/meetup_origin_validation.dart';
import '../../../core/geo/world_countries.dart';
import '../../../data/platform_fees.dart';
import '../../../core/platform/keyboard_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validation/receiver_contact_validation.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/models/created_delivery.dart';
import '../../../data/models/meetup_location.dart';
import '../../../data/models/traveler_trip.dart';
import '../../../data/static_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../traveler/widgets/route_city_dropdown.dart';
import '../delivery_form_helpers.dart';
import 'airport_route_search_fields.dart';
import 'description_field.dart';
import 'maximum_budget_field.dart';
import 'meetup_locations_card.dart';
import 'parcel_acknowledgement_section.dart';
import 'parcel_photos_section.dart';
import 'platform_fee_section.dart';
import 'receiver_info_section.dart';
import 'travel_date_field.dart';
import 'weight_kg_field.dart';

/// Shared delivery form for create and edit (city-to-city and country-to-country).
class DeliveryFormFields extends StatefulWidget {
  const DeliveryFormFields({
    super.key,
    required this.deliveryType,
    this.initialDelivery,
    this.initialTrip,
    this.isEditMode = false,
  });

  final DeliveryType deliveryType;
  final CreatedDelivery? initialDelivery;
  final TravelerTrip? initialTrip;
  final bool isEditMode;

  @override
  DeliveryFormFieldsState createState() => DeliveryFormFieldsState();
}

class DeliveryFormFieldsState extends State<DeliveryFormFields> {
  late String _category;
  late String _size;
  bool _parcelAcknowledged = false;
  bool _paysReceiverFee = false;
  final List<String> _photoPaths = [];
  List<MeetupLocation> _meetupLocations = const [];
  List<MeetupLocation> _receiverMeetupLocations = const [];
  late double _maxBudget;
  String? _photosError;
  String? _meetupError;
  String? _receiverMeetupError;
  String? _budgetError;
  String? _fromError;
  String? _toError;
  String? _receiverEmailError;
  String? _receiverPhoneError;
  String? _descriptionError;
  String? _travelDateError;
  String? _weightError;
  String? _ackError;

  final _routeFromKey = GlobalKey();
  final _routeToKey = GlobalKey();
  final _travelDateKey = GlobalKey();
  final _weightKey = GlobalKey();
  final _photosKey = GlobalKey();
  final _budgetKey = GlobalKey();
  final _meetupKey = GlobalKey();
  final _descriptionKey = GlobalKey();
  final _receiverEmailKey = GlobalKey();
  final _receiverPhoneKey = GlobalKey();
  final _receiverMeetupKey = GlobalKey();
  final _ackKey = GlobalKey();

  MeetupLocation? _fromLocation;
  MeetupLocation? _toLocation;
  MeetupLocation? _fromAirport;
  MeetupLocation? _toAirport;
  String? _fromAirportError;
  String? _toAirportError;
  DateTime? _travelDate;
  late double _weightKg;
  String _receiverEmail = '';
  String _receiverPhone = '';
  late final TextEditingController _descriptionController;

  final Map<String, ({String id, String url})> _existingPhotos = {};
  final Set<String> _removedExistingPhotoIds = {};

  bool get _isCountry =>
      widget.deliveryType == DeliveryType.countryToCountry;

  @override
  void initState() {
    super.initState();
    final delivery = widget.initialDelivery;
    if (delivery != null) {
      _category = delivery.parcelCategory;
      _size = delivery.parcelSize;
      _parcelAcknowledged = true;
      _maxBudget = delivery.maxBudget;
      _weightKg = delivery.weightKg > 0 ? delivery.weightKg : 1;
      _travelDate = delivery.travelDateParsed ?? DateTime.now();
      _meetupLocations = delivery.preferredMeetupLocationModels;
      _receiverMeetupLocations = delivery.receiverMeetupLocationModels;
      _receiverEmail = delivery.receiverEmail ?? '';
      _receiverPhone = delivery.receiverPhone ?? '';
      _fromLocation = delivery.fromMeetupLocation;
      _toLocation = delivery.toMeetupLocation;
      _fromAirport = delivery.fromRoutePlace;
      _toAirport = delivery.toRoutePlace;
      for (final photo in delivery.existingPhotoItems) {
        _existingPhotos[photo.id] = photo;
      }
      _descriptionController = TextEditingController(text: delivery.description);
    } else {
      _category = 'documents';
      _size = 'small box';
      _maxBudget = 0;
      _weightKg = 0;
      _descriptionController = TextEditingController();
      _applyInitialTrip(widget.initialTrip);
    }
  }

  void _applyInitialTrip(TravelerTrip? trip) {
    if (trip == null) return;

    _travelDate = trip.travelDate;

    if (_isCountry) {
      final originIso = trip.originCountryCode?.trim().isNotEmpty == true
          ? trip.originCountryCode!.trim().toUpperCase()
          : WorldCountries.all
              .where(
                (c) =>
                    c.name.toLowerCase() ==
                    (trip.originCountry ?? trip.origin).trim().toLowerCase(),
              )
              .map((c) => c.iso)
              .firstOrNull;
      final destinationIso =
          trip.destinationCountryCode?.trim().isNotEmpty == true
              ? trip.destinationCountryCode!.trim().toUpperCase()
              : WorldCountries.all
                  .where(
                    (c) =>
                        c.name.toLowerCase() ==
                        (trip.destinationCountry ?? trip.destination)
                            .trim()
                            .toLowerCase(),
                  )
                  .map((c) => c.iso)
                  .firstOrNull;

      final fromAirport = trip.originAirport?.trim() ?? '';
      final fromCity = trip.fromCity?.trim() ?? '';
      final toAirport = trip.destinationAirport?.trim() ?? '';
      final toCity = trip.toCity?.trim() ?? '';

      if (fromAirport.isNotEmpty) {
        _fromAirport = meetupFromLabel(fromAirport, countryCode: originIso);
      } else if (fromCity.isNotEmpty) {
        _fromAirport = meetupFromLabel(fromCity, countryCode: originIso);
      } else if (originIso != null) {
        _fromAirport = meetupFromLabel(
          WorldCountries.byIso(originIso).name,
          countryCode: originIso,
        );
      }

      if (toAirport.isNotEmpty) {
        _toAirport = meetupFromLabel(toAirport, countryCode: destinationIso);
      } else if (toCity.isNotEmpty) {
        _toAirport = meetupFromLabel(toCity, countryCode: destinationIso);
      } else if (destinationIso != null) {
        _toAirport = meetupFromLabel(
          WorldCountries.byIso(destinationIso).name,
          countryCode: destinationIso,
        );
      }
    } else {
      _fromLocation = MeetupLocation(
        name: trip.origin,
        address: trip.origin,
        countryCode: trip.fromCode,
      );
      _toLocation = MeetupLocation(
        name: trip.destination,
        address: trip.destination,
        countryCode: trip.toCode,
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<({String id, String url})> get _visibleExistingPhotos =>
      _existingPhotos.values
          .where((photo) => !_removedExistingPhotoIds.contains(photo.id))
          .toList();

  List<String> get _retainedPhotoIds => _visibleExistingPhotos
      .map((photo) => photo.id)
      .where((id) => id.isNotEmpty)
      .toList();

  int get _totalPhotoCount =>
      _visibleExistingPhotos.length + _photoPaths.length;

  bool validate() {
    final ok = _isCountry ? _validateCountry() : _validateCity();
    if (!ok) scrollToFirstError();
    return ok;
  }

  /// Maps a server/local validation message to the matching field and scrolls to it.
  bool applyServerValidationMessage(String message) {
    final text = message.trim();
    if (text.isEmpty) return false;

    var matched = true;
    setState(() {
      _clearFieldErrors();
      final lower = text.toLowerCase();

      if (lower.contains('acknowledg') || lower.contains('parcel terms')) {
        _ackError = text;
      } else if (text == MeetupOriginValidation.message ||
          lower.contains('within the selected from')) {
        _meetupError = text;
      } else if (text == MeetupDestinationValidation.message ||
          lower.contains('destination city')) {
        _receiverMeetupError = text;
      } else if (lower.contains('origin airport') ||
          (lower.contains('from') && lower.contains('airport'))) {
        _fromAirportError = text;
      } else if (lower.contains('destination airport') ||
          (lower.contains('to') && lower.contains('airport'))) {
        _toAirportError = text;
      } else if (lower.contains('fromcity') || lower.contains('from city')) {
        _fromError = text;
      } else if (lower.contains('tocity') || lower.contains('to city')) {
        _toError = text;
      } else if (lower.contains('travel date') || lower.contains('traveldate')) {
        _travelDateError = text;
      } else if (lower.contains('weight')) {
        _weightError = text;
      } else if (lower.contains('photo')) {
        _photosError = text;
      } else if (lower.contains('budget')) {
        _budgetError = text;
      } else if (lower.contains('preferred meetup') ||
          lower.contains('at least one meetup location')) {
        _meetupError = text;
      } else if (lower.contains('receiver email') ||
          lower.contains("receiver's email")) {
        _receiverEmailError = text;
      } else if (lower.contains('receiver phone') ||
          lower.contains("receiver's phone")) {
        _receiverPhoneError = text;
      } else if (lower.contains('select a meetup location')) {
        _receiverMeetupError = text;
      } else if (lower.contains('description')) {
        _descriptionError = text;
      } else {
        matched = false;
      }
    });

    if (!matched) return false;
    scrollToFirstError();
    return true;
  }

  void scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final key in _errorFieldKeysInOrder()) {
        final context = key.currentContext;
        if (context == null) continue;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );
        break;
      }
    });
  }

  void _clearFieldErrors() {
    _photosError = null;
    _meetupError = null;
    _receiverMeetupError = null;
    _budgetError = null;
    _fromError = null;
    _toError = null;
    _receiverEmailError = null;
    _receiverPhoneError = null;
    _descriptionError = null;
    _travelDateError = null;
    _weightError = null;
    _fromAirportError = null;
    _toAirportError = null;
    _ackError = null;
  }

  List<GlobalKey> _errorFieldKeysInOrder() {
    if (_isCountry) {
      return [
        if (_fromAirportError != null) _routeFromKey,
        if (_toAirportError != null) _routeToKey,
        if (_travelDateError != null) _travelDateKey,
        if (_weightError != null) _weightKey,
        if (_photosError != null) _photosKey,
        if (_budgetError != null) _budgetKey,
        if (_meetupError != null) _meetupKey,
        if (_descriptionError != null) _descriptionKey,
        if (_receiverEmailError != null) _receiverEmailKey,
        if (_receiverPhoneError != null) _receiverPhoneKey,
        if (_receiverMeetupError != null) _receiverMeetupKey,
        if (_ackError != null) _ackKey,
      ];
    }

    return [
      if (_fromError != null) _routeFromKey,
      if (_toError != null) _routeToKey,
      if (_travelDateError != null) _travelDateKey,
      if (_weightError != null) _weightKey,
      if (_photosError != null) _photosKey,
      if (_budgetError != null) _budgetKey,
      if (_meetupError != null) _meetupKey,
      if (_descriptionError != null) _descriptionKey,
      if (_receiverEmailError != null) _receiverEmailKey,
      if (_receiverPhoneError != null) _receiverPhoneKey,
      if (_receiverMeetupError != null) _receiverMeetupKey,
      if (_ackError != null) _ackKey,
    ];
  }

  bool _validateCity() {
    final fromCity = _fromLocation == null ? '' : deliveryCityName(_fromLocation!);
    final toCity = _toLocation == null ? '' : deliveryCityName(_toLocation!);
    final fromCode =
        _fromLocation == null ? '' : deliveryCodeFromPlace(_fromLocation!);
    final toCode = _toLocation == null ? '' : deliveryCodeFromPlace(_toLocation!);

    setState(() {
      _photosError =
          _totalPhotoCount == 0 ? 'Upload at least 1 parcel photo.' : null;
      _meetupError = _meetupLocations.isEmpty
          ? 'Add at least one meetup location.'
          : MeetupOriginValidation.validateMeetupLocations(
              meetups: _meetupLocations,
              originCity: fromCity,
              originCountryCode: fromCode.isEmpty ? null : fromCode,
              originPlace: _fromLocation,
            );
      _receiverMeetupError = _receiverMeetupLocations.isEmpty
          ? 'Select a meetup location.'
          : MeetupDestinationValidation.validateMeetupLocations(
              meetups: _receiverMeetupLocations,
              destinationCity: toCity,
              destinationCountryCode: toCode.isEmpty ? null : toCode,
              destinationPlace: _toLocation,
            );
      _budgetError = _maxBudget <= 0 ? 'Enter a valid maximum budget.' : null;
      _weightError =
          _weightKg <= 0 ? 'Enter a valid weight greater than 0.' : null;
      _travelDateError =
          _travelDate == null ? 'Select a travel date.' : null;
      _fromError =
          fromCity.isEmpty ? 'Select a from location.' : null;
      _toError = toCity.isEmpty
          ? 'Select a to location.'
          : (toCity.toLowerCase() == fromCity.toLowerCase()
              ? 'From and To cities must be different.'
              : null);
      _receiverEmailError = _validateReceiverEmail(_receiverEmail);
      _receiverPhoneError = _validateReceiverPhone(_receiverPhone);
      _descriptionError = _descriptionController.text.trim().isEmpty
          ? 'Enter a parcel description.'
          : null;
      _ackError = widget.isEditMode || _parcelAcknowledged
          ? null
          : 'Please acknowledge the parcel terms before posting.';
    });

    return _ackError == null &&
        _photosError == null &&
        _meetupError == null &&
        _receiverMeetupError == null &&
        _budgetError == null &&
        _weightError == null &&
        _travelDateError == null &&
        _fromError == null &&
        _toError == null &&
        _receiverEmailError == null &&
        _receiverPhoneError == null &&
        _descriptionError == null;
  }

  bool _validateCountry() {
    setState(() {
      _photosError =
          _totalPhotoCount == 0 ? 'Upload at least 1 parcel photo.' : null;
      _meetupError = _meetupLocations.isEmpty
          ? 'Add at least one meetup location.'
          : (_fromAirport == null
              ? null
              : MeetupOriginValidation.validateMeetupLocations(
                  meetups: _meetupLocations,
                  originCity: deliveryAirportCity(_fromAirport!),
                  originCountryCode: deliveryCodeFromPlace(_fromAirport!),
                  originPlace: _fromAirport,
                  sameCountrySufficient: true,
                ));
      _receiverMeetupError = _receiverMeetupLocations.isEmpty
          ? 'Select a meetup location.'
          : (_toAirport == null
              ? null
              : MeetupDestinationValidation.validateMeetupLocations(
                  meetups: _receiverMeetupLocations,
                  destinationCity: deliveryAirportCity(_toAirport!),
                  destinationCountryCode: deliveryCodeFromPlace(_toAirport!),
                  destinationPlace: _toAirport,
                  sameCountrySufficient: true,
                ));
      _budgetError = _maxBudget <= 0 ? 'Enter a valid maximum budget.' : null;
      _weightError =
          _weightKg <= 0 ? 'Enter a valid weight greater than 0.' : null;
      _travelDateError =
          _travelDate == null ? 'Select a travel date.' : null;
      _receiverEmailError = _validateReceiverEmail(_receiverEmail);
      _receiverPhoneError = _validateReceiverPhone(_receiverPhone);
      _fromAirportError =
          _fromAirport == null ? 'Select an origin airport.' : null;
      _toAirportError = _toAirport == null
          ? 'Select a destination airport.'
          : (_sameAirportSelected()
              ? 'Origin and destination must be different.'
              : (_sameCountryAirports()
                  ? 'Origin and destination countries must be different.'
                  : null));
      _descriptionError = _descriptionController.text.trim().isEmpty
          ? 'Enter a parcel description.'
          : null;
      _ackError = widget.isEditMode || _parcelAcknowledged
          ? null
          : 'Please acknowledge the parcel terms before posting.';
    });

    return _ackError == null &&
        _photosError == null &&
        _meetupError == null &&
        _receiverMeetupError == null &&
        _budgetError == null &&
        _weightError == null &&
        _travelDateError == null &&
        _receiverEmailError == null &&
        _receiverPhoneError == null &&
        _fromAirportError == null &&
        _toAirportError == null &&
        _descriptionError == null;
  }

  CreateDeliveryRequest buildCreateRequest() {
    final common = _commonFields();
    if (_isCountry) {
      final from = _fromAirport!;
      final to = _toAirport!;
      return CreateDeliveryRequest(
        deliveryType: DeliveryType.countryToCountry,
        travelDate: common.travelDate,
        travelMethod: 'air',
        parcelCategory: common.parcelCategory,
        parcelSize: common.parcelSize,
        weightKg: common.weightKg,
        maxBudget: common.maxBudget,
        description: common.description,
        preferredMeetupLocations: common.preferredMeetupLocations,
        acknowledged: common.acknowledged,
        photoPaths: List<String>.from(_photoPaths),
        receiverEmail: common.receiverEmail,
        receiverPhone: common.receiverPhone,
        receiverMeetupLocation: common.receiverMeetupLocation,
        originCountry: deliveryCountryName(from),
        originAirport: from.displayLabel,
        destinationCountry: deliveryCountryName(to),
        destinationAirport: to.displayLabel,
        fromCity: null,
        toCity: null,
        originCity: deliveryAirportCity(from),
        destinationCity: deliveryAirportCity(to),
        fromCode: deliveryCodeFromPlace(from),
        toCode: deliveryCodeFromPlace(to),
        platformFee: common.platformFee,
        platformFeeShare: common.platformFeeShare,
        paysReceiverFee: common.paysReceiverFee,
      );
    }

    return CreateDeliveryRequest(
      deliveryType: DeliveryType.cityToCity,
      travelDate: common.travelDate,
      parcelCategory: common.parcelCategory,
      parcelSize: common.parcelSize,
      weightKg: common.weightKg,
      maxBudget: common.maxBudget,
      description: common.description,
      preferredMeetupLocations: common.preferredMeetupLocations,
      acknowledged: common.acknowledged,
      photoPaths: List<String>.from(_photoPaths),
      receiverEmail: common.receiverEmail,
      receiverPhone: common.receiverPhone,
      receiverMeetupLocation: common.receiverMeetupLocation,
      fromCity: deliveryCityName(_fromLocation!),
      fromCode: deliveryCodeFromPlace(_fromLocation!),
      toCity: deliveryCityName(_toLocation!),
      toCode: deliveryCodeFromPlace(_toLocation!),
      platformFee: common.platformFee,
      platformFeeShare: common.platformFeeShare,
      paysReceiverFee: common.paysReceiverFee,
    );
  }

  UpdateDeliveryRequest buildUpdateRequest() {
    return UpdateDeliveryRequest.fromCreateRequest(
      buildCreateRequest(),
      newPhotoPaths: List<String>.from(_photoPaths),
      retainedPhotoIds: _retainedPhotoIds,
    );
  }

  ({
    DateTime travelDate,
    String parcelCategory,
    String parcelSize,
    double weightKg,
    double maxBudget,
    String description,
    List<String> preferredMeetupLocations,
    bool acknowledged,
    String receiverEmail,
    String receiverPhone,
    String? receiverMeetupLocation,
    double? platformFee,
    double? platformFeeShare,
    bool paysReceiverFee,
  }) _commonFields() {
    return (
      travelDate: _travelDate!,
      parcelCategory: _category,
      parcelSize: _size,
      weightKg: _weightKg,
      maxBudget: _maxBudget,
      description: _descriptionController.text.trim(),
      preferredMeetupLocations:
          _meetupLocations.map((l) => l.displayLabel).toList(),
      acknowledged: true,
      receiverEmail: _receiverEmail,
      receiverPhone: _receiverPhone,
      receiverMeetupLocation: _receiverMeetupLocations.isEmpty
          ? null
          : _receiverMeetupLocations.first.displayLabel,
      platformFee: PlatformFees.senderPlatformFeeUsd(
        category: _category,
        paysReceiverFee: _paysReceiverFee,
      ),
      platformFeeShare: PlatformFees.platformFeeShareFor(
        category: _category,
        paysReceiverFee: _paysReceiverFee,
      ),
      paysReceiverFee: _paysReceiverFee,
    );
  }

  String? _validateReceiverEmail(String email) {
    final user = context.read<AuthProvider>().user;
    return ReceiverContactValidation.validateEmailForUser(email, user);
  }

  String? _validateReceiverPhone(String phone) {
    final user = context.read<AuthProvider>().user;
    return ReceiverContactValidation.validatePhoneForUser(phone, user);
  }

  bool _sameAirportSelected() {
    if (_fromAirport == null || _toAirport == null) return false;
    final fromId = _fromAirport!.placeId?.trim();
    final toId = _toAirport!.placeId?.trim();
    if (fromId != null &&
        toId != null &&
        fromId.isNotEmpty &&
        toId.isNotEmpty) {
      return fromId == toId;
    }
    return _fromAirport!.displayLabel.trim().toLowerCase() ==
        _toAirport!.displayLabel.trim().toLowerCase();
  }

  bool _sameCountryAirports() {
    if (_fromAirport == null || _toAirport == null) return false;
    final fromCode = deliveryCodeFromPlace(_fromAirport!);
    final toCode = deliveryCodeFromPlace(_toAirport!);
    if (fromCode.isEmpty ||
        toCode.isEmpty ||
        fromCode == 'XX' ||
        toCode == 'XX') {
      return false;
    }
    return fromCode == toCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.routeSection, style: context.typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_isCountry) ...[
          AirportRouteSearchFields(
            fromAirport: _fromAirport,
            toAirport: _toAirport,
            fromErrorText: _fromAirportError,
            toErrorText: _toAirportError,
            fromFieldKey: _routeFromKey,
            toFieldKey: _routeToKey,
            fromSearchAirports: true,
            toSearchAirports: true,
            onFromChanged: (airport) => setState(() {
              _fromAirport = airport;
              _fromAirportError = null;
            }),
            onToChanged: (airport) => setState(() {
              _toAirport = airport;
              _toAirportError = null;
            }),
          ),
        ] else ...[
          KeyedSubtree(
            key: _routeFromKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteCityDropdown(
                  label: l10n.fromCity,
                  value: _fromLocation,
                  hintText: l10n.searchLocation,
                  mapTitle: l10n.fromCity,
                  searchHint: l10n.searchLocation,
                  onChanged: (place) => setState(() {
                    _fromLocation = place;
                    _fromError = null;
                  }),
                ),
                if (_fromError != null) _errorText(_fromError!),
              ],
            ),
          ),
          KeyedSubtree(
            key: _routeToKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteCityDropdown(
                  label: l10n.toCity,
                  value: _toLocation,
                  hintText: l10n.searchLocation,
                  mapTitle: l10n.toCity,
                  searchHint: l10n.searchLocation,
                  onChanged: (place) => setState(() {
                    _toLocation = place;
                    _toError = null;
                  }),
                ),
                if (_toError != null) _errorText(_toError!),
              ],
            ),
          ),
        ],
        KeyedSubtree(
          key: _travelDateKey,
          child: TravelDateField(
            value: _travelDate,
            errorText: _travelDateError,
            onChanged: (date) => setState(() {
              _travelDate = date;
              _travelDateError = null;
            }),
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.parcelSection, style: context.typo.h3.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AppChipRow(
          options: StaticData.parcelCategories,
          selected: _category,
          onSelected: (v) => setState(() => _category = v),
          labelOf: (o) {
            if (o.isEmpty) return o;
            final capitalized = '${o[0].toUpperCase()}${o.substring(1)}';
            return context.tr(capitalized);
          },
        ),
        KeyedSubtree(
          key: _weightKey,
          child: WeightKgField(
            initialValue: _weightKg > 0 ? _weightKg : null,
            errorText: _weightError,
            onChanged: (value) => setState(() {
              _weightKg = value;
              _weightError = null;
            }),
          ),
        ),
        KeyedSubtree(
          key: _photosKey,
          child: ParcelPhotosSection(
            photoPaths: _photoPaths,
            existingPhotos: _visibleExistingPhotos,
            errorText: _photosError,
            onExistingPhotoRemoved: (id) => setState(() {
              _removedExistingPhotoIds.add(id);
              _photosError = null;
            }),
            onChanged: (paths) => setState(() {
              _photoPaths
                ..clear()
                ..addAll(paths);
              _photosError = null;
            }),
          ),
        ),
        KeyedSubtree(
          key: _budgetKey,
          child: MaximumBudgetField(
            initialValue: _maxBudget > 0 ? _maxBudget : null,
            errorText: _budgetError,
            onChanged: (value) => setState(() {
              _maxBudget = value;
              _budgetError = null;
            }),
          ),
        ),
        KeyedSubtree(
          key: _meetupKey,
          child: MeetupLocationsCard(
            locations: _meetupLocations,
            errorText: _meetupError,
            onTap: () async {
              final result = await context.push<List<MeetupLocation>>(
                '/add-meetup-locations',
                extra: _meetupLocations,
              );
              if (result != null) {
                setState(() => _meetupLocations = result);
              }
            },
          ),
        ),
        KeyedSubtree(
          key: _descriptionKey,
          child: DescriptionField(
            controller: _descriptionController,
            errorText: _descriptionError,
          ),
        ),
        const SizedBox(height: 12),
        ReceiverInfoSection(
          initialEmail: _receiverEmail,
          initialPhone: _receiverPhone,
          emailErrorText: _receiverEmailError,
          phoneErrorText: _receiverPhoneError,
          meetupErrorText: _receiverMeetupError,
          meetupLocations: _receiverMeetupLocations,
          emailFieldKey: _receiverEmailKey,
          phoneFieldKey: _receiverPhoneKey,
          meetupFieldKey: _receiverMeetupKey,
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
        if (!widget.isEditMode) ...[
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _ackKey,
            child: ParcelAcknowledgementSection(
              errorText: _ackError,
              onChanged: (acknowledged) => setState(() {
                _parcelAcknowledged = acknowledged;
                _ackError = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          PlatformFeeSection(
            onChanged: (pays) => setState(() => _paysReceiverFee = pays),
          ),
        ],
      ],
    );
  }

  Widget _errorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        message,
        style: context.typo.sm.copyWith(color: AppColors.danger),
      ),
    );
  }
}
