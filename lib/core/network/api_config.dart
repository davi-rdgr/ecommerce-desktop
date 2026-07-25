class ApiConfig {
  /// Sobrescrevível no build: `flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080`
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const timeout = Duration(seconds: 15);
}
