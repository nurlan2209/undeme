import '../../../core/network/api_client.dart';
import '../domain/legal_topic.dart';

class LegalFeed {
  LegalFeed({
    required this.categories,
    required this.items,
    required this.total,
  });

  final List<String> categories;
  final List<LegalTopic> items;
  final int total;
}

class LegalRepository {
  LegalRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<LegalFeed> getTopics(
      {String category = 'Барлығы', String query = ''}) async {
    final params = <String, String>{};
    if (category.isNotEmpty) {
      params['category'] = category;
    }
    if (query.trim().isNotEmpty) {
      params['query'] = query.trim();
    }

    final queryString = params.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');

    final path =
        queryString.isEmpty ? '/legal/topics' : '/legal/topics?$queryString';
    final response = await _apiClient.get(path, authRequired: false);

    final categories = (response['categories'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .toList();

    final items = (response['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => LegalTopic.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return LegalFeed(
      categories: categories,
      items: items,
      total: (response['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
