import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 18);

  static Future<Map<String, String>> _authHeaders() async {
    final t = await AuthService.token();
    return t == null ? {} : {'Authorization': 'Bearer $t'};
  }

  // ======================== AUTH ========================

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final res = await http
        .post(
          ApiConfig.uri('/api/v1/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Login gagal (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.trim().isEmpty) {
      throw Exception('Token kosong dari server');
    }

    final user = data['user'] as Map<String, dynamic>? ?? {};
    await AuthService.setAuth(
      token: token.trim(),
      username: username,
      role: user['role']?.toString() ?? 'cabang',
    );
    return user;
  }

  // ======================== CABANG SHIPMENTS ========================

  static Future<http.Response> getShipment(String kode) async {
    final headers = await _authHeaders();
    return http
        .get(
          ApiConfig.uri('/api/v1/cabang/shipments/${Uri.encodeComponent(kode)}'),
          headers: headers,
        )
        .timeout(_timeout);
  }

  static Future<http.StreamedResponse> confirmShipment({
    required String kode,
    required String aksi,
    required String keterangan,
    required List<Map<String, dynamic>> items,
    required List<XFile> photos,
  }) async {
    final headers = await _authHeaders();
    final req = http.MultipartRequest(
      'POST',
      ApiConfig.uri(
          '/api/v1/cabang/shipments/${Uri.encodeComponent(kode)}/confirm'),
    );
    req.headers.addAll(headers);
    req.fields['aksi'] = aksi;
    req.fields['keterangan'] = keterangan;
    req.fields['items_json'] = jsonEncode(items);
    for (final ph in photos) {
      final bytes = await ph.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes(
        'photos',
        bytes,
        filename: p.basename(ph.path),
      ));
    }
    return req.send().timeout(_timeout);
  }

  static Future<http.Response> getShipments() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/cabang/shipments'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> getProducts() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/cabang/products'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> createOrder({
    required List<Map<String, dynamic>> items,
    String keterangan = '',
  }) async {
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    return http
        .post(
          ApiConfig.uri('/api/v1/cabang/orders'),
          headers: headers,
          body: jsonEncode({'items': items, 'keterangan': keterangan}),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> getOrders() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/cabang/orders'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> payOrder(String id) async {
    final headers = await _authHeaders();
    return http
        .post(
            ApiConfig.uri(
                '/api/v1/cabang/orders/${Uri.encodeComponent(id)}/pay'),
            headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> confirmPayment(String id) async {
    final headers = await _authHeaders();
    return http
        .post(
            ApiConfig.uri(
                '/api/v1/cabang/orders/${Uri.encodeComponent(id)}/confirm-payment'),
            headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> getMe() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/auth/me'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> updateProfile(
      Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    return http
        .put(
          ApiConfig.uri('/api/v1/auth/profile'),
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(_timeout);
  }

  // ======================== BRANCH STOCKS & SALES ========================

  static Future<http.Response> getDashboard() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/cabang/dashboard'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> getBranchProducts() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/cabang/branch-products'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> createSale({
    required List<Map<String, dynamic>> items,
    String keterangan = '',
    int totalBayar = 0,
  }) async {
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    return http
        .post(
          ApiConfig.uri('/api/v1/cabang/sales'),
          headers: headers,
          body: jsonEncode(
              {'items': items, 'keterangan': keterangan, 'total_bayar': totalBayar}),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> getSales() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/cabang/sales'), headers: headers)
        .timeout(_timeout);
  }

  // ======================== SALES API ========================

  static Future<http.Response> getSalesOrders() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/sales/orders'), headers: headers)
        .timeout(_timeout);
  }

  /// Sales: buat order untuk cabang (wajib pilih cabang_id)
  static Future<http.Response> createSalesOrder({
    required List<Map<String, dynamic>> items,
    required String cabangId,
    String keterangan = '',
  }) async {
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    return http
        .post(
          ApiConfig.uri('/api/v1/sales/orders'),
          headers: headers,
          body: jsonEncode({
            'items': items,
            'cabang_id': cabangId,
            'keterangan': keterangan,
          }),
        )
        .timeout(_timeout);
  }


  // ======================== GUDANG API ========================

  static Future<http.Response> getGudangOrders() async {
    final headers = await _authHeaders();
    return http
        .get(ApiConfig.uri('/api/v1/gudang/orders'), headers: headers)
        .timeout(_timeout);
  }

  static Future<http.Response> packOrder(String id,
      {String catatan = ''}) async {
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    return http
        .post(
          ApiConfig.uri(
              '/api/v1/gudang/orders/${Uri.encodeComponent(id)}/pack'),
          headers: headers,
          body: jsonEncode({'catatan_packing': catatan}),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> sendOrder(String id) async {
    final headers = await _authHeaders();
    return http
        .post(
          ApiConfig.uri(
              '/api/v1/gudang/orders/${Uri.encodeComponent(id)}/send'),
          headers: headers,
        )
        .timeout(_timeout);
  }
}
