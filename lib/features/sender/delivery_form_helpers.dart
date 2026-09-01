import '../../../core/config/api_config.dart';
import '../../../core/geo/meetup_location_match.dart';
import '../../../core/geo/world_airports.dart';
import '../../../core/geo/world_cities.dart';
import '../../../core/geo/world_countries.dart';
import '../../../data/models/created_delivery.dart';
import '../../../data/models/meetup_location.dart';

String deliveryCityName(MeetupLocation place) {
  final label = place.displayLabel.trim();
  if (label.isNotEmpty) return label;
  return place.name.trim();
}

String deliveryCodeFromPlace(MeetupLocation place) {
  final code = place.countryCode?.trim().toUpperCase();
  if (code != null &&
      code.length == 2 &&
      code != 'XX' &&
      WorldCountries.containsIso(code)) {
    return code;
  }

  final airport = WorldAirports.matchFromLabel('${place.name} ${place.address}');
  if (airport != null) return airport.countryIso;

  final haystack = '${place.name} ${place.address}'.toLowerCase();
  WorldCountry? best;
  for (final country in WorldCountries.all) {
    if (!_haystackHasCountry(haystack, country.name)) continue;
    if (best == null || country.name.length > best.name.length) {
      best = country;
    }
  }
  if (best != null) return best.iso;

  final city = WorldCities.byName(place.name) ??
      WorldCities.byName(place.locality ?? '');
  if (city != null) return city.countryIso;

  return '';
}

bool _haystackHasCountry(String haystack, String countryName) {
  final name = countryName.trim().toLowerCase();
  if (name.isEmpty) return false;
  final pattern = RegExp(
    '\\b${RegExp.escape(name).replaceAll(' ', r'\s+')}\\b',
  );
  return pattern.hasMatch(haystack);
}

MeetupLocation meetupFromLabel(String label, {String? countryCode}) {
  return MeetupLocation(
    name: label,
    address: label,
    countryCode: countryCode,
  );
}

String deliveryCountryName(MeetupLocation place) {
  final code = place.countryCode?.trim().toUpperCase();
  if (code != null && code.length == 2 && WorldCountries.containsIso(code)) {
    return WorldCountries.byIso(code).name;
  }
  return place.displayLabel;
}

String deliveryAirportCity(MeetupLocation place) {
  return MeetupLocationMatch.resolveCityName(place);
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

  MeetupLocation? get fromAirportPlace {
    final label = originAirport?.trim();
    if (label == null || label.isEmpty) return null;
    return meetupFromLabel(label, countryCode: fromCode);
  }

  MeetupLocation? get toAirportPlace {
    final label = destinationAirport?.trim();
    if (label == null || label.isEmpty) return null;
    return meetupFromLabel(label, countryCode: toCode);
  }

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
