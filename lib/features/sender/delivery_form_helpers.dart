import '../../../core/config/api_config.dart';
import '../../../core/geo/world_airports.dart';
import '../../../core/geo/world_cities.dart';
import '../../../core/geo/world_countries.dart';
import '../../../data/models/created_delivery.dart';
import '../../../data/models/meetup_location.dart';

String deliveryCityName(MeetupLocation place) {
  final name = place.name.trim();
  if (name.isNotEmpty) return name;
  return place.displayLabel;
}

String deliveryCodeFromPlace(MeetupLocation place) {
  final code = place.countryCode?.trim().toUpperCase();
  if (code != null && code.length == 2) return code;

  final haystack = '${place.name} ${place.address}'.toLowerCase();
  WorldCountry? best;
  for (final country in WorldCountries.all) {
    if (haystack.contains(country.name.toLowerCase())) {
      if (best == null || country.name.length > best.name.length) {
        best = country;
      }
    }
  }
  if (best != null) return best.iso;

  final city = WorldCities.byName(place.name);
  if (city != null) return city.countryIso;

  return 'XX';
}

MeetupLocation meetupFromLabel(String label, {String? countryCode}) {
  return MeetupLocation(
    name: label,
    address: label,
    countryCode: countryCode,
  );
}

extension CreatedDeliveryFormX on CreatedDelivery {
  bool get isCountryDelivery =>
      deliveryType == DeliveryType.countryToCountry;

  MeetupLocation? get fromMeetupLocation {
    if (isCountryDelivery) {
      return meetupFromLabel(
        originCountry ?? route.split('→').first.trim(),
        countryCode: fromCode,
      );
    }
    return meetupFromLabel(fromCity ?? '', countryCode: fromCode);
  }

  MeetupLocation? get toMeetupLocation {
    if (isCountryDelivery) {
      return meetupFromLabel(
        destinationCountry ?? route.split('→').last.trim(),
        countryCode: toCode,
      );
    }
    return meetupFromLabel(toCity ?? '', countryCode: toCode);
  }

  WorldAirport? get fromAirport =>
      WorldAirports.byLabel(originAirport ?? '');

  WorldAirport? get toAirport =>
      WorldAirports.byLabel(destinationAirport ?? '');

  List<MeetupLocation> get preferredMeetupLocationModels =>
      preferredMeetupLocations
          .map((label) => meetupFromLabel(label))
          .toList();

  List<MeetupLocation> get receiverMeetupLocationModels {
    final label = receiverMeetupLocation?.trim();
    if (label == null || label.isEmpty) return const [];
    return [meetupFromLabel(label)];
  }

  List<({String id, String url})> get existingPhotoItems => photos
      .map(
        (photo) => (
          id: photo.id,
          url: ApiConfig.resolveUploadUrl(photo.url),
        ),
      )
      .toList();
}
