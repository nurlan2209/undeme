class SosLocation {
  SosLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.provider,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? provider;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (provider != null) 'provider': provider,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory SosLocation.fromJson(Map<String, dynamic> json) {
    return SosLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      provider: json['provider']?.toString(),
      capturedAt: DateTime.tryParse(json['capturedAt']?.toString() ?? ''),
    );
  }
}
