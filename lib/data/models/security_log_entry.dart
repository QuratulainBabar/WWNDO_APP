class SecurityLogEntry {
  const SecurityLogEntry({
    required this.action,
    required this.device,
    required this.location,
    required this.timestamp,
  });

  final String action;
  final String device;
  final String location;
  final DateTime timestamp;
}
