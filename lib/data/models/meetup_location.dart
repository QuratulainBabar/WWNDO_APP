/// A Google Maps place selected as a route or meetup location.
class MeetupLocation {
  const MeetupLocation({
    required this.name,
    required this.address,
    this.placeId,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.locality,
  });

  final String name;
  final String address;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  /// ISO 3166-1 alpha-2 when resolved via Places Details.
  final String? countryCode;

  /// City / locality from Places address components (e.g. "Lahore").
  final String? locality;

  /// Display label sent to the API and shown in lists.
  String get displayLabel =>
      address.trim().isNotEmpty ? address.trim() : name.trim();

  MeetupLocation copyWith({
    String? name,
    String? address,
    String? placeId,
    double? latitude,
    double? longitude,
    String? countryCode,
    String? locality,
  }) {
    return MeetupLocation(
      name: name ?? this.name,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      countryCode: countryCode ?? this.countryCode,
      locality: locality ?? this.locality,
    );
  }

  factory MeetupLocation.fromJson(Map<String, dynamic> json) {
    return MeetupLocation(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      placeId: json['placeId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      countryCode: json['countryCode'] as String?,
      locality: json['locality'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        if (placeId != null) 'placeId': placeId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (countryCode != null) 'countryCode': countryCode,
        if (locality != null) 'locality': locality,
      };
}
