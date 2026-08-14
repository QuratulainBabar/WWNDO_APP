class DeliveryRequest {
  const DeliveryRequest({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
    required this.maxBudget,
    required this.category,
    required this.weightKg,
    required this.size,
    required this.senderName,
    required this.senderInitial,
    required this.senderRating,
    this.description = '',
    this.senderMessage = '',
    this.meetupLocations = const [],
    this.photoCount = 0,
    this.photoUrls = const [],
    this.receiverName = '',
    this.receiverHandoffLocation = '',
  });

  final String id;
  final String fromCity;
  final String toCity;
  final DateTime travelDate;
  final double maxBudget;
  final String category;
  final double weightKg;
  final String size;
  final String senderName;
  final String senderInitial;
  final double senderRating;
  final String description;
  /// Note from the sender about the parcel (shown on traveler detail).
  final String senderMessage;
  /// Preferred meetup locations chosen by the sender.
  final List<String> meetupLocations;
  final int photoCount;
  final List<String> photoUrls;
  final String receiverName;
  final String receiverHandoffLocation;

  String get route => '$fromCity → $toCity';

  String get displayMeetupLocation {
    if (meetupLocations.isEmpty) return 'Not specified';
    return meetupLocations.join(', ');
  }

  String get displayReceiverName {
    final name = receiverName.trim();
    if (name.isNotEmpty) return name;
    return 'Receiver';
  }

  String get displayReceiverHandoffLocation {
    final location = receiverHandoffLocation.trim();
    if (location.isNotEmpty) return location;
    return '$toCity Airport';
  }

  /// Parcel category type shown to travelers: Document or Object.
  String get categoryTypeLabel {
    final normalized = category.trim().toLowerCase();
    if (normalized == 'documents' ||
        normalized == 'document' ||
        normalized.startsWith('doc')) {
      return 'Document';
    }
    return 'Object';
  }

  /// Description aligned to Document / Object category for traveler screens.
  String get displayDescription {
    final custom = description.trim();
    if (custom.isNotEmpty) return custom;
    if (categoryTypeLabel == 'Document') {
      return 'Sealed document package — papers or envelope only. Keep flat, dry, and unopened until delivery.';
    }
    return 'Physical object package — packed item(s) for hand delivery. Handle carefully in transit.';
  }

  /// Sender note aligned to Document / Object category.
  String get displaySenderMessage {
    final custom = senderMessage.trim();
    if (custom.isNotEmpty) return custom;
    if (categoryTypeLabel == 'Document') {
      return 'Please keep these documents flat and sealed. Do not bend or open the envelope.';
    }
    return 'Please handle this object carefully and keep it safe until delivery.';
  }
}
