import '../../../core/network/api_client.dart';
import 'auth_local_data_source.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, AuthLocalDataSource? localDataSource})
      : _apiClient = apiClient ?? ApiClient(),
        _localDataSource = localDataSource ?? AuthLocalDataSource.instance;

  final ApiClient _apiClient;
  final AuthLocalDataSource _localDataSource;

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      authRequired: false,
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );

    final token = response['token'] as String?;
    final user = response['user'] as Map<String, dynamic>?;
    final userId = user?['id']?.toString();

    if (token == null || userId == null) {
      throw Exception('Invalid auth response');
    }

    await _localDataSource.saveSession(token: token, userId: userId);
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      '/auth/login',
      authRequired: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final token = response['token'] as String?;
    final user = response['user'] as Map<String, dynamic>?;
    final userId = user?['id']?.toString();

    if (token == null || userId == null) {
      throw Exception('Invalid auth response');
    }

    await _localDataSource.saveSession(token: token, userId: userId);
  }

  Future<void> logout() => _localDataSource.clearSession();

  Future<bool> isLoggedIn() => _localDataSource.isLoggedIn();
}
