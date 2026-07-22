import '../../data/models/traveler_trip.dart';

/// Static wizard state for Section 4 parcel creation.
class ParcelCreationFlowData {
  ParcelCreationFlowData({TravelerTrip? selectedTrip}) : selectedTrip = selectedTrip;

  TravelerTrip? selectedTrip;
  String category = 'documents';
  double weightKg = 1.0;
  String volume = 'envelope';
  String? recipientId;
  double proposedBudgetUsd = 25;
  String description = '';
  List<String> photoPaths = [];

  static const categories = ['documents', 'objects'];
  static const volumes = ['envelope', 'small box', 'medium box', 'large bag'];

  String? validateStep(int step) {
    return switch (step) {
      0 => selectedTrip == null ? 'Select a traveler route to continue.' : null,
      1 => categories.contains(category) ? null : 'Select a parcel category.',
      2 => weightKg <= 0 ? 'Enter parcel weight.' : null,
      3 => volumes.contains(volume) ? null : 'Select parcel volume.',
      4 => recipientId == null ? 'Select a verified recipient.' : null,
      5 => proposedBudgetUsd <= 0 ? 'Enter a proposed payment amount.' : null,
      6 => _validateActivation(),
      _ => null,
    };
  }

  String? _validateActivation() {
    if (description.trim().length < 8) {
      return 'Add a short parcel description (min 8 characters).';
    }
    if (photoPaths.isEmpty) {
      return 'Upload at least 1 parcel photo before activation.';
    }
    if (photoPaths.length > 3) {
      return 'Maximum 3 parcel photos allowed.';
    }
    return null;
  }
}
