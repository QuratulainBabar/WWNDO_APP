import '../../data/models/meetup_location.dart';
import 'meetup_location_match.dart';

/// Ensures receiver meetup spots belong to the selected To / destination location.
abstract final class MeetupDestinationValidation {
  static const message =
      'The selected meetup location must be within the sender\'s destination city. Please choose a valid meetup location.';

  /// Returns [message] when any meetup is outside [destinationCity]; otherwise null.
  /// Empty meetup lists are ignored (handled by required-field checks).
  static String? validateMeetupLocations({
    required List<MeetupLocation> meetups,
    required String destinationCity,
    String? destinationCountryCode,
    MeetupLocation? destinationPlace,
  }) {
    if (meetups.isEmpty) return null;
    final city = destinationCity.trim();
    if (city.isEmpty && destinationPlace == null) return null;

    for (final meetup in meetups) {
      if (!belongsToDestination(
        meetup: meetup,
        destinationCity: city,
        destinationCountryCode: destinationCountryCode,
        destinationPlace: destinationPlace,
      )) {
        return message;
      }
    }
    return null;
  }

  /// True when [meetup] appears to be inside [destinationCity].
  static bool belongsToDestination({
    required MeetupLocation meetup,
    required String destinationCity,
    String? destinationCountryCode,
    MeetupLocation? destinationPlace,
  }) {
    if (destinationPlace != null) {
      return MeetupLocationMatch.placesInSameArea(
        meetup: meetup,
        origin: destinationPlace,
        originCityHint: destinationCity,
        originCountryCode: destinationCountryCode,
      );
    }

    final city = destinationCity.trim();
    if (city.isEmpty) return false;

    return labelBelongsToDestination(
      '${meetup.name} ${meetup.address} ${meetup.locality ?? ''}',
      destinationCity,
      destinationCountryCode: destinationCountryCode,
      meetupCountryCode: meetup.countryCode,
    );
  }

  /// String-label check used by the local repository and mirrored on the API.
  static bool labelBelongsToDestination(
    String meetupLabel,
    String destinationCity, {
    String? destinationCountryCode,
    String? meetupCountryCode,
  }) {
    return MeetupLocationMatch.labelsInSameArea(
      meetupLabel,
      destinationCity,
      routeCountryCode: destinationCountryCode,
      meetupCountryCode: meetupCountryCode,
    );
  }
}
