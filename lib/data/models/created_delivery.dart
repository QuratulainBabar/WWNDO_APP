import 'dart:convert';

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
    this.destinationCountry,
    this.destinationAirport,
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
  final String? destinationCountry;
  final String? destinationAirport;

  final double? platformFee;
  final double? platformFeeShare;
  final bool paysReceiverFee;

  String get routeLabel {
    if (deliveryType == DeliveryType.countryToCountry) {
      return '${originCountry ?? ''} → ${destinationCountry ?? ''}';
    }
    return '${fromCity ?? ''} → ${toCity ?? ''}';
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
      'receiverEmail': receiverEmail,
      'receiverPhone': receiverPhone,
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
      fields['destinationCountry'] = destinationCountry ?? '';
      fields['destinationAirport'] = destinationAirport ?? '';
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
    return DeliveryPhoto(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
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
    this.receiverEmail,
    this.receiverPhone,
    this.receiverMeetupLocation,
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
  final String? receiverEmail;
  final String? receiverPhone;
  final String? receiverMeetupLocation;

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
              .whereType<Map<String, dynamic>>()
              .map(DeliveryPhoto.fromJson)
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
      receiverEmail: json['receiverEmail'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      receiverMeetupLocation: json['receiverMeetupLocation'] as String?,
    );
  }
}
