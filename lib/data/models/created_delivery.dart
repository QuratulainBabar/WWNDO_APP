import 'dart:convert';

import '../../core/config/api_config.dart';
import '../route_display.dart';

/// Delivery type selected on the Choose Delivery Type screen.
enum DeliveryType {
  cityToCity('city_to_city'),
  countryToCountry('country_to_country');

  const DeliveryType(this.apiValue);
  final String apiValue;

  static DeliveryType fromApi(String? value) {
    switch (value) {
      case 'country_to_country':
        return DeliveryType.countryToCountry;
      case 'city_to_city':
      default:
        return DeliveryType.cityToCity;
    }
  }
}

/// Payload + result for POST /api/v1/deliveries.
class CreateDeliveryRequest {
  const CreateDeliveryRequest({
    required this.deliveryType,
    required this.travelDate,
    required this.parcelCategory,
    required this.parcelSize,
    required this.weightKg,
    required this.maxBudget,
    required this.description,
    required this.preferredMeetupLocations,
    required this.acknowledged,
    required this.photoPaths,
    required this.receiverEmail,
    required this.receiverPhone,
    this.receiverMeetupLocation,
    this.fromCity,
    this.fromCode,
    this.toCity,
    this.toCode,
    this.originCountry,
    this.originAirport,
    this.originCity,
    this.destinationCountry,
    this.destinationAirport,
    this.destinationCity,
    this.platformFee,
    this.platformFeeShare,
    this.paysReceiverFee = false,
  });

  final DeliveryType deliveryType;
  final DateTime travelDate;
  final String parcelCategory;
  final String parcelSize;
  final double weightKg;
  final double maxBudget;
  final String description;
  final List<String> preferredMeetupLocations;
  final bool acknowledged;
  final List<String> photoPaths;
  final String receiverEmail;
  final String receiverPhone;
  final String? receiverMeetupLocation;

  final String? fromCity;
  final String? fromCode;
  final String? toCity;
  final String? toCode;

  final String? originCountry;
  final String? originAirport;
  /// Airport city used to validate meetup locations (country-to-country).
  final String? originCity;
  final String? destinationCountry;
  final String? destinationAirport;
  /// Airport city used to validate receiver meetup (country-to-country).
  final String? destinationCity;

  final double? platformFee;
  final double? platformFeeShare;
  final bool paysReceiverFee;

  String get routeLabel {
    if (deliveryType == DeliveryType.countryToCountry) {
      return formatRouteArrow(
        displayRouteEndpoint(
          airport: originAirport,
          country: originCountry,
        ),
        displayRouteEndpoint(
          airport: destinationAirport,
          country: destinationCountry,
        ),
      );
    }
    return formatRouteArrow(fromCity ?? '', toCity ?? '');
  }

  Map<String, String> toFormFields() {
    final fields = <String, String>{
      'deliveryType': deliveryType.apiValue,
      'travelDate':
          '${travelDate.year.toString().padLeft(4, '0')}-'
          '${travelDate.month.toString().padLeft(2, '0')}-'
          '${travelDate.day.toString().padLeft(2, '0')}',
      'parcelCategory': parcelCategory,
      'parcelSize': parcelSize,
      'weightKg': weightKg.toString(),
      'maxBudget': maxBudget.toString(),
      'description': description,
      'preferredMeetupLocations': jsonEncode(preferredMeetupLocations),
      'acknowledged': acknowledged ? 'true' : 'false',
      'receiverEmail': receiverEmail.trim().toLowerCase(),
      'receiverPhone': receiverPhone.trim(),
    };

    if (receiverMeetupLocation != null && receiverMeetupLocation!.trim().isNotEmpty) {
      fields['receiverMeetupLocation'] = receiverMeetupLocation!.trim();
    }

    if (platformFee != null) {
      fields['platformFee'] = platformFee!.toString();
    }
    if (platformFeeShare != null) {
      fields['platformFeeShare'] = platformFeeShare!.toString();
    }
    fields['paysReceiverFee'] = paysReceiverFee ? 'true' : 'false';

    if (deliveryType == DeliveryType.cityToCity) {
      fields['fromCity'] = fromCity ?? '';
      fields['fromCode'] = fromCode ?? '';
      fields['toCity'] = toCity ?? '';
      fields['toCode'] = toCode ?? '';
    } else {
      fields['originCountry'] = originCountry ?? '';
      fields['originAirport'] = originAirport ?? '';
      if (originCity != null && originCity!.trim().isNotEmpty) {
        fields['originCity'] = originCity!.trim();
      }
      fields['destinationCountry'] = destinationCountry ?? '';
      fields['destinationAirport'] = destinationAirport ?? '';
      if (destinationCity != null && destinationCity!.trim().isNotEmpty) {
        fields['destinationCity'] = destinationCity!.trim();
      }
      if (fromCode != null && fromCode!.trim().isNotEmpty) {
        fields['fromCode'] = fromCode!.trim().toUpperCase();
      }
      if (toCode != null && toCode!.trim().isNotEmpty) {
        fields['toCode'] = toCode!.trim().toUpperCase();
      }
    }

    return fields;
  }
}

/// PATCH /api/v1/deliveries/:id — same fields as create (multipart when photos change).
class UpdateDeliveryRequest {
  const UpdateDeliveryRequest({
    required this.deliveryType,
    required this.travelDate,
    required this.parcelCategory,
    required this.parcelSize,
    required this.weightKg,
    required this.maxBudget,
    required this.description,
    required this.preferredMeetupLocations,
    required this.acknowledged,
    required this.receiverEmail,
    required this.receiverPhone,
    this.receiverMeetupLocation,
    this.fromCity,
    this.fromCode,
    this.toCity,
    this.toCode,
    this.originCountry,
    this.originAirport,
    this.originCity,
    this.destinationCountry,
    this.destinationAirport,
    this.destinationCity,
    this.platformFee,
    this.platformFeeShare,
    this.paysReceiverFee = false,
    this.newPhotoPaths = const [],
    this.retainedPhotoIds = const [],
  });

  final DeliveryType deliveryType;
  final DateTime travelDate;
  final String parcelCategory;
  final String parcelSize;
  final double weightKg;
  final double maxBudget;
  final String description;
  final List<String> preferredMeetupLocations;
  final bool acknowledged;
  final String receiverEmail;
  final String receiverPhone;
  final String? receiverMeetupLocation;
  final String? fromCity;
  final String? fromCode;
  final String? toCity;
  final String? toCode;
  final String? originCountry;
  final String? originAirport;
  final String? originCity;
  final String? destinationCountry;
  final String? destinationAirport;
  final String? destinationCity;
  final double? platformFee;
  final double? platformFeeShare;
  final bool paysReceiverFee;
  final List<String> newPhotoPaths;
  final List<String> retainedPhotoIds;

  factory UpdateDeliveryRequest.fromCreateRequest(
    CreateDeliveryRequest request, {
    List<String> newPhotoPaths = const [],
    List<String> retainedPhotoIds = const [],
  }) {
    return UpdateDeliveryRequest(
      deliveryType: request.deliveryType,
      travelDate: request.travelDate,
      parcelCategory: request.parcelCategory,
      parcelSize: request.parcelSize,
      weightKg: request.weightKg,
      maxBudget: request.maxBudget,
      description: request.description,
      preferredMeetupLocations: request.preferredMeetupLocations,
      acknowledged: request.acknowledged,
      receiverEmail: request.receiverEmail,
      receiverPhone: request.receiverPhone,
      receiverMeetupLocation: request.receiverMeetupLocation,
      fromCity: request.fromCity,
      fromCode: request.fromCode,
      toCity: request.toCity,
      toCode: request.toCode,
      originCountry: request.originCountry,
      originAirport: request.originAirport,
      originCity: request.originCity,
      destinationCountry: request.destinationCountry,
      destinationAirport: request.destinationAirport,
      destinationCity: request.destinationCity,
      platformFee: request.platformFee,
      platformFeeShare: request.platformFeeShare,
      paysReceiverFee: request.paysReceiverFee,
      newPhotoPaths: newPhotoPaths,
      retainedPhotoIds: retainedPhotoIds,
    );
  }

  Map<String, String> toFormFields() {
    final create = CreateDeliveryRequest(
      deliveryType: deliveryType,
      travelDate: travelDate,
      parcelCategory: parcelCategory,
      parcelSize: parcelSize,
      weightKg: weightKg,
      maxBudget: maxBudget,
      description: description,
      preferredMeetupLocations: preferredMeetupLocations,
      acknowledged: acknowledged,
      photoPaths: const [],
      receiverEmail: receiverEmail,
      receiverPhone: receiverPhone,
      receiverMeetupLocation: receiverMeetupLocation,
      fromCity: fromCity,
      fromCode: fromCode,
      toCity: toCity,
      toCode: toCode,
      originCountry: originCountry,
      originAirport: originAirport,
      originCity: originCity,
      destinationCountry: destinationCountry,
      destinationAirport: destinationAirport,
      destinationCity: destinationCity,
      platformFee: platformFee,
      platformFeeShare: platformFeeShare,
      paysReceiverFee: paysReceiverFee,
    );
    final fields = create.toFormFields();
    if (retainedPhotoIds.isNotEmpty) {
      fields['retainedPhotoIds'] = jsonEncode(retainedPhotoIds);
    }
    return fields;
  }
}

class DeliveryPhoto {
  const DeliveryPhoto({
    required this.id,
    required this.url,
    this.originalName,
    this.mimeType,
    this.sizeBytes,
    this.sortOrder,
  });

  final String id;
  final String url;
  final String? originalName;
  final String? mimeType;
  final int? sizeBytes;
  final int? sortOrder;

  factory DeliveryPhoto.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['url'] as String?)?.trim().isNotEmpty == true
        ? (json['url'] as String).trim()
        : (json['file_path'] as String?)?.trim() ?? '';
    return DeliveryPhoto(
      id: json['id'] as String? ?? '',
      url: ApiConfig.resolveUploadUrl(rawUrl),
      originalName: json['originalName'] as String?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
    );
  }
}

class CreatedDelivery {
  const CreatedDelivery({
    required this.id,
    required this.publicId,
    required this.deliveryType,
    required this.route,
    required this.travelDate,
    required this.parcelCategory,
    required this.parcelSize,
    required this.weightKg,
    required this.maxBudget,
    required this.description,
    required this.preferredMeetupLocations,
    required this.acknowledged,
    required this.photos,
    this.status,
    this.fromCity,
    this.fromCode,
    this.toCity,
    this.toCode,
    this.originCountry,
    this.originAirport,
    this.destinationCountry,
    this.destinationAirport,
    this.platformFee,
    this.platformFeeShare,
    this.paysReceiverFee = false,
    this.receiverEmail,
    this.receiverPhone,
    this.receiverMeetupLocation,
    this.senderName,
    this.senderId,
    this.travelerId,
    this.travelerName,
    this.tripId,
    this.tripPublicId,
    this.bidAmount,
    this.receiverId,
    this.receiverName,
    this.receiverAcceptedAt,
    this.disputed = false,
  });

  final String id;
  final String publicId;
  final DeliveryType deliveryType;
  final String route;
  final String travelDate;
  final String parcelCategory;
  final String parcelSize;
  final double weightKg;
  final double maxBudget;
  final String description;
  final List<String> preferredMeetupLocations;
  final bool acknowledged;
  final List<DeliveryPhoto> photos;
  final String? status;
  final String? fromCity;
  final String? fromCode;
  final String? toCity;
  final String? toCode;
  final String? originCountry;
  final String? originAirport;
  final String? destinationCountry;
  final String? destinationAirport;
  final double? platformFee;
  final double? platformFeeShare;
  final bool paysReceiverFee;
  final String? receiverEmail;
  final String? receiverPhone;
  final String? receiverMeetupLocation;
  final String? senderName;
  final String? senderId;
  final String? travelerId;
  final String? travelerName;
  /// Linked traveler trip UUID, when the backend includes it.
  final String? tripId;
  /// Linked traveler trip public id (TR-…), when the backend includes it.
  final String? tripPublicId;
  final double? bidAmount;
  final String? receiverId;
  final String? receiverName;
  final String? receiverAcceptedAt;
  final bool disputed;

  bool get isReceiverAccepted =>
      receiverAcceptedAt != null && receiverAcceptedAt!.trim().isNotEmpty;

  String get displayId => publicId.isNotEmpty ? publicId : id;

  /// Compact map place when available, else city / country / API route segment.
  String get displayFrom => displayRouteEndpoint(
        airport: originAirport,
        city: fromCity,
        country: originCountry,
        routeFallback: routeLeft(route),
      );

  String get displayTo => displayRouteEndpoint(
        airport: destinationAirport,
        city: toCity,
        country: destinationCountry,
        routeFallback: routeRight(route),
      );

  String get displayRoute {
    final exact = formatRouteArrow(displayFrom, displayTo);
    if (exact.isNotEmpty) return exact;
    return route;
  }

  /// Full sender-selected map / airport place (no City, Country compaction).
  String get exactDisplayFrom => exactRouteEndpoint(
        airport: originAirport,
        city: fromCity,
        country: originCountry,
        routeFallback: routeLeft(route),
      );

  String get exactDisplayTo => exactRouteEndpoint(
        airport: destinationAirport,
        city: toCity,
        country: destinationCountry,
        routeFallback: routeRight(route),
      );

  String get exactDisplayRoute {
    final exact = formatRouteArrow(exactDisplayFrom, exactDisplayTo);
    if (exact.isNotEmpty) return exact;
    return route;
  }

  DateTime? get travelDateParsed {
    if (travelDate.isEmpty) return null;
    return DateTime.tryParse(travelDate);
  }

  factory CreatedDelivery.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['photos'];
    return CreatedDelivery(
      id: json['id'] as String? ?? '',
      publicId: json['publicId'] as String? ?? '',
      deliveryType: DeliveryType.fromApi(json['deliveryType'] as String?),
      route: json['route'] as String? ?? '',
      travelDate: json['travelDate'] as String? ?? '',
      parcelCategory: json['parcelCategory'] as String? ?? '',
      parcelSize: json['parcelSize'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      maxBudget: (json['maxBudget'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      preferredMeetupLocations: (json['preferredMeetupLocations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      acknowledged: json['acknowledged'] as bool? ?? false,
      photos: photosRaw is List
          ? photosRaw
              .whereType<Map>()
              .map((e) => DeliveryPhoto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      status: json['status'] as String?,
      fromCity: json['fromCity'] as String?,
      fromCode: json['fromCode'] as String?,
      toCity: json['toCity'] as String?,
      toCode: json['toCode'] as String?,
      originCountry: json['originCountry'] as String?,
      originAirport: json['originAirport'] as String?,
      destinationCountry: json['destinationCountry'] as String?,
      destinationAirport: json['destinationAirport'] as String?,
      platformFee: (json['platformFee'] as num?)?.toDouble(),
      platformFeeShare: (json['platformFeeShare'] as num?)?.toDouble(),
      paysReceiverFee: json['paysReceiverFee'] == true ||
          ((json['platformFeeShare'] as num?)?.toDouble() ?? 1) <= 0,
      receiverEmail: json['receiverEmail'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      receiverMeetupLocation: json['receiverMeetupLocation'] as String?,
      senderName: json['senderName'] as String?,
      senderId: json['senderId'] as String?,
      travelerId: json['travelerId'] as String?,
      travelerName: json['travelerName'] as String?,
      tripId: json['tripId'] as String?,
      tripPublicId: json['tripPublicId'] as String?,
      bidAmount: (json['bidAmount'] as num?)?.toDouble(),
      receiverId: json['receiverId'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverAcceptedAt: json['receiverAcceptedAt']?.toString(),
      disputed: json['disputed'] == true || json['status'] == 'disputed',
    );
  }
}
