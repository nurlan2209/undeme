import '../../../core/network/api_client.dart';

class AiRepository {
  AiRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> sendMessage(
      {required String message, String context = 'general'}) async {
    return _apiClient
        .post('/ai/chat', body: {'message': message, 'context': context});
  }

  Future<List<Map<String, dynamic>>> history() async {
    final response = await _apiClient.get('/ai/history');
    final items = response['items'] as List<dynamic>? ?? <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
