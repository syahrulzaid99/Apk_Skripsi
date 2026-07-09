class ApiConfig {
  // Ganti sesuai server kamu
  static const String baseUrl = 'http://192.168.8.103:3000';

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}
