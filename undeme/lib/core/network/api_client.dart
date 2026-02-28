import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_local_data_source.dart';
import '../config/app_config.dart';
import '../errors/api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, AuthLocalDataSource? authLocalDataSource})
      : _client = client ?? http.Client(),
        _authLocalDataSource =
            authLocalDataSource ?? AuthLocalDataSource.instance;

  final http.Client _client;
  final AuthLocalDataSource _authLocalDataSource;

  Future<Map<String, dynamic>> get(String path,
      {bool authRequired = true}) async {
    return _request('GET', path, authRequired: authRequired);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
  }) async {
    return _request('POST', path, body: body, authRequired: authRequired);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
  }) async {
    return _request('PUT', path, body: body, authRequired: authRequired);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
  }) async {
    return _request('DELETE', path, body: body, authRequired: authRequired);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authRequired) {
      final token = await _authLocalDataSource.getToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Сессия аяқталған. Қайта кіріңіз', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');

    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(AppConfig.requestTimeout);
          break;
        case 'POST':
          response = await _client
              .post(uri,
                  headers: headers,
                  body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(AppConfig.requestTimeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri,
                  headers: headers,
                  body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(AppConfig.requestTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri,
                  headers: headers,
                  body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(AppConfig.requestTimeout);
          break;
        default:
          throw ApiException('Unsupported method: $method');
      }
    } on TimeoutException {
      throw ApiException('Сервер уақыты өтіп кетті. Қайта көріңіз');
    } catch (_) {
      throw ApiException('Сервермен байланыс орнату мүмкін болмады');
    }

    Map<String, dynamic> data = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw ApiException(
      data['message']?.toString() ?? 'Қате пайда болды',
      statusCode: response.statusCode,
    );
  }
}
