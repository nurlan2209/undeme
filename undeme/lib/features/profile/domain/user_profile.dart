import 'emergency_contact.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.emergencyContacts,
    required this.settings,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final List<EmergencyContact> emergencyContacts;
  final Map<String, dynamic> settings;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawContacts =
        (json['emergencyContacts'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(EmergencyContact.fromJson)
            .toList();

    return UserProfile(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      emergencyContacts: rawContacts,
      settings: Map<String, dynamic>.from(
          json['settings'] as Map? ?? <String, dynamic>{}),
    );
  }
}
