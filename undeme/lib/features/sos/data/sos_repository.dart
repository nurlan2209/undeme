import '../../../core/network/api_client.dart';
import '../domain/sos_dispatch_result.dart';
import '../domain/sos_location.dart';

class SosRepository {
  SosRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<SosDispatchResult> triggerSos({
    required SosLocation location,
    String reason = '',
    bool force = false,
  }) async {
    final response = await _apiClient.post(
      '/sos/trigger',
      body: {
        'reason': reason,
        'location': location.toJson(),
        'force': force,
      },
    );

    final event = response['event'] as Map<String, dynamic>?;
    if (event == null) {
      throw Exception('SOS жауабы қате');
    }

    return SosDispatchResult(
      eventId: event['id']?.toString() ?? '',
      status: event['status']?.toString() ?? 'failed',
      attempts: _parseAttempts(event['attempts']),
    );
  }

  Future<SosDispatchResult> retrySos(String eventId) async {
    final response =
        await _apiClient.post('/sos/retry', body: {'eventId': eventId});
    final event = response['event'] as Map<String, dynamic>?;
    if (event == null) {
      throw Exception('SOS retry жауабы қате');
    }

    return SosDispatchResult(
      eventId: event['id']?.toString() ?? eventId,
      status: event['status']?.toString() ?? 'failed',
      attempts: _parseAttempts(event['attempts']),
    );
  }

  List<SosChannelAttempt> _parseAttempts(dynamic attemptsRaw) {
    final attemptsList = attemptsRaw as List<dynamic>? ?? <dynamic>[];
    return attemptsList
        .whereType<Map>()
        .map((item) => SosChannelAttempt.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
