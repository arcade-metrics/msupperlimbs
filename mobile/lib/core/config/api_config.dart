/// Base URL for the MS Upper Limbs API.
///
/// Emulador Android: http://10.0.2.2:8000
/// Device físico (mesma Wi-Fi): http://<IP-do-PC>:8000
/// Ex.: flutter run --dart-define=API_BASE_URL=http://192.168.0.4:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.4:8000',
  );

  static const String apiPrefix = '/api/v1';
}
