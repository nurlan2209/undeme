class SosChannelAttempt {
  SosChannelAttempt({
    required this.channel,
    required this.success,
    this.error,
  });

  final String channel;
  final bool success;
  final String? error;

  factory SosChannelAttempt.fromJson(Map<String, dynamic> json) {
    return SosChannelAttempt(
      channel: json['channel']?.toString() ?? '',
      success: json['success'] == true,
      error: json['error']?.toString(),
    );
  }
}

class SosDispatchResult {
  SosDispatchResult({
    required this.eventId,
    required this.status,
    required this.attempts,
  });

  final String eventId;
  final String status;
  final List<SosChannelAttempt> attempts;

  bool get delivered => status == 'sent' || status == 'partially_sent';

  bool get hasWhatsAppBusinessSuccess => attempts.any(
        (attempt) => attempt.channel == 'whatsapp_business' && attempt.success,
      );

  String? get whatsappBusinessError {
    final failedAttempt = attempts.where((attempt) {
      return attempt.channel == 'whatsapp_business' && !attempt.success;
    }).toList();
    if (failedAttempt.isEmpty) {
      return null;
    }
    return failedAttempt.last.error;
  }
}
