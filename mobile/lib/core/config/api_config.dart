/// Base URL of the ciatec-core API (produção por omissão).
///
/// API local no emulador Android: http://10.0.2.2:8000
/// API local num device físico (mesma Wi-Fi): `http://<IP-do-PC>:8000`
/// Ex.: `flutter run --dart-define=API_BASE_URL=http://192.168.0.4:8000`
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ciatec.org',
  );

  static const String apiPrefix = '/api/v1';
}
