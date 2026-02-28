class EmergencyService {
  EmergencyService({
    required this.id,
    required this.emoji,
    required this.number,
    required this.label,
    required this.description,
    required this.priority,
  });

  final String id;
  final String emoji;
  final String number;
  final String label;
  final String description;
  final int priority;

  factory EmergencyService.fromJson(Map<String, dynamic> json) {
    return EmergencyService(
      id: json['id']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '🆘',
      number: json['number']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 999,
    );
  }
}
