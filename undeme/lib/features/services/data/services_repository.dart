import '../../../core/network/api_client.dart';
import '../domain/emergency_service.dart';

class ServicesFeed {
  ServicesFeed({
    required this.items,
    required this.note,
  });

  final List<EmergencyService> items;
  final String note;
}

class ServicesRepository {
  ServicesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ServicesFeed> getEmergencyServices() async {
    final response =
        await _apiClient.get('/services/emergency', authRequired: false);

    final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) =>
            EmergencyService.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return ServicesFeed(
      items: items,
      note: response['note']?.toString() ?? '',
    );
  }
}
