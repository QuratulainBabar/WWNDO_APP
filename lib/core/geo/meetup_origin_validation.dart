import '../../data/models/meetup_location.dart';
import 'meetup_location_match.dart';

/// Ensures sender meetup spots belong to the selected From / origin location.
abstract final class MeetupOriginValidation {
  static const message =
      'The selected meetup location must be within the selected From City. Please choose a valid meetup location.';

  /// Returns [message] when any meetup is outside [originCity]; otherwise null.
  /// Empty meetup lists are ignored (handled by required-field checks).
  static String? validateMeetupLocations({
    required List<MeetupLocation> meetups,
    required String originCity,
    String? originCountryCode,
    MeetupLocation? originPlace,
    bool sameCountrySufficient = false,
  }) {
    if (meetups.isEmpty) return null;
    final city = originCity.trim();
    if (city.isEmpty && originPlace == null) return null;

    for (final meetup in meetups) {
      if (!belongsToOrigin(
        meetup: meetup,
        originCity: city,
        originCountryCode: originCountryCode,
        originPlace: originPlace,
        sameCountrySufficient: sameCountrySufficient,
      )) {
        return message;
      }
    }
    return null;
  }

  /// True when [meetup] appears to be inside [originCity].
  static bool belongsToOrigin({
    required MeetupLocation meetup,
    required String originCity,
    String? originCountryCode,
    MeetupLocation? originPlace,
    bool sameCountrySufficient = false,
  }) {
    if (originPlace != null) {
      return MeetupLocationMatch.placesInSameArea(
        meetup: meetup,
        origin: originPlace,
        originCityHint: originCity,
        originCountryCode: originCountryCode,
        sameCountrySufficient: sameCountrySufficient,
      );
    }

    final city = originCity.trim();
    if (city.isEmpty) return false;

    return labelBelongsToOrigin(
      '${meetup.name} ${meetup.address} ${meetup.locality ?? ''}',
      originCity,
      originCountryCode: originCountryCode,
      meetupCountryCode: meetup.countryCode,
      sameCountrySufficient: sameCountrySufficient,
    );
  }

  /// String-label check used by the local repository and mirrored on the API.
  static bool labelBelongsToOrigin(
    String meetupLabel,
    String originCity, {
    String? originCountryCode,
    String? meetupCountryCode,
    bool sameCountrySufficient = false,
  }) {
    return MeetupLocationMatch.labelsInSameArea(
      meetupLabel,
      originCity,
      routeCountryCode: originCountryCode,
      meetupCountryCode: meetupCountryCode,
      sameCountrySufficient: sameCountrySufficient,
    );
  }
}
