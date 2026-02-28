import '../../../core/network/api_client.dart';
import '../domain/emergency_contact.dart';
import '../domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserProfile> getProfile() async {
    final response = await _apiClient.get('/auth/profile');
    final user = response['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw Exception('Профиль деректері қате');
    }
    return UserProfile.fromJson(user);
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? phone,
    Map<String, dynamic>? settings,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (settings != null) body['settings'] = settings;

    final response = await _apiClient.put('/auth/profile', body: body);
    final user = response['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw Exception('Профиль жаңартылмады');
    }
    return UserProfile.fromJson(user);
  }

  Future<List<EmergencyContact>> addContact(EmergencyContact contact) async {
    final response = await _apiClient.post(
      '/auth/profile/contacts',
      body: contact.toJson(),
    );
    return _parseContacts(response);
  }

  Future<List<EmergencyContact>> updateContact(EmergencyContact contact) async {
    final response = await _apiClient.put(
      '/auth/profile/contacts/${contact.id}',
      body: contact.toJson(),
    );
    return _parseContacts(response);
  }

  Future<List<EmergencyContact>> deleteContact(String contactId) async {
    final response =
        await _apiClient.delete('/auth/profile/contacts/$contactId');
    return _parseContacts(response);
  }

  Future<void> deleteAccount(String password) async {
    await _apiClient
        .delete('/auth/profile/account', body: {'password': password});
  }

  List<EmergencyContact> _parseContacts(Map<String, dynamic> response) {
    final list = (response['contacts'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(EmergencyContact.fromJson)
        .toList();
    return list;
  }
}
