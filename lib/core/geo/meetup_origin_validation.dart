import '../../data/models/meetup_location.dart';

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
  }) {
    if (meetups.isEmpty) return null;
    final city = originCity.trim();
    if (city.isEmpty) return null;

    for (final meetup in meetups) {
      if (!belongsToOrigin(
        meetup: meetup,
        originCity: city,
        originCountryCode: originCountryCode,
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
  }) {
    final city = originCity.trim().toLowerCase();
    if (city.isEmpty) return false;

    final originCc = originCountryCode?.trim().toUpperCase();
    final meetupCc = meetup.countryCode?.trim().toUpperCase();
    if (originCc != null &&
        originCc.length == 2 &&
        meetupCc != null &&
        meetupCc.length == 2 &&
        originCc != meetupCc) {
      return false;
    }

    return labelBelongsToOrigin(
      '${meetup.name} ${meetup.address}',
      originCity,
    );
  }

  /// String-label check used by the local repository and mirrored on the API.
  static bool labelBelongsToOrigin(String meetupLabel, String originCity) {
    final city = originCity.trim().toLowerCase();
    final label = meetupLabel.trim().toLowerCase();
    if (city.isEmpty || label.isEmpty) return false;
    return label.contains(city);
  }
}
