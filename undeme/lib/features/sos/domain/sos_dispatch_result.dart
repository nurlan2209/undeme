class SosDispatchResult {
  SosDispatchResult({required this.eventId, required this.status});

  final String eventId;
  final String status;

  bool get delivered => status == 'sent' || status == 'partially_sent';
}
