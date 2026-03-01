class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://93.170.72.89/api',
  );

  static const int sosCountdownSeconds = 4;
  static const int sosSendRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 15);
}
