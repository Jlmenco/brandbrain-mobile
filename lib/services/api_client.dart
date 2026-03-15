import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiClient {
  static const _tokenKey = 'bb_token';
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> setToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? queryParams,
    Object? body,
    String? contentType,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _headers();
    if (contentType != null) headers['Content-Type'] = contentType;

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
      case 'POST':
        response = await http.post(uri, headers: headers, body: body is String ? body : (body != null ? jsonEncode(body) : null));
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: body is String ? body : (body != null ? jsonEncode(body) : null));
      default:
        throw Exception('Unsupported method: $method');
    }

    if (response.statusCode >= 400) {
      String detail = 'HTTP ${response.statusCode}';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('detail')) {
          detail = data['detail'] as String;
        }
      } catch (_) {}
      throw ApiException(detail, response.statusCode);
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  // --- Auth ---

  Future<String> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/auth/token');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
    );
    if (response.statusCode >= 400) {
      throw ApiException('Credenciais inválidas', response.statusCode);
    }
    final data = jsonDecode(response.body);
    final token = data['access_token'] as String;
    await setToken(token);
    return token;
  }

  // --- Organizations ---

  Future<List<Organization>> listOrgs() async {
    final data = await _request('GET', '/orgs');
    return (data as List).map((e) => Organization.fromJson(e)).toList();
  }

  // --- Cost Centers ---

  Future<List<CostCenter>> listCostCenters(String orgId) async {
    final data = await _request('GET', '/cost-centers', queryParams: {'org_id': orgId});
    return (data as List).map((e) => CostCenter.fromJson(e)).toList();
  }

  // --- Content Items ---

  Future<PaginatedContent> listContent(
    String ccId, {
    String? status,
    String? search,
    int skip = 0,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'cc_id': ccId,
      'skip': '$skip',
      'limit': '$limit',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _request('GET', '/content-items', queryParams: params);
    return PaginatedContent.fromJson(data);
  }

  Future<ContentItem> getContent(String id) async {
    final data = await _request('GET', '/content-items/$id');
    return ContentItem.fromJson(data);
  }

  Future<ContentItem> submitReview(String id) async {
    final data = await _request('POST', '/content-items/$id/submit-review');
    return ContentItem.fromJson(data);
  }

  Future<ContentItem> approveContent(String id) async {
    final data = await _request('POST', '/content-items/$id/approve');
    return ContentItem.fromJson(data);
  }

  Future<ContentItem> rejectContent(String id, String reason) async {
    final data = await _request('POST', '/content-items/$id/reject', body: {'reason': reason});
    return ContentItem.fromJson(data);
  }

  Future<ContentItem> createContent({
    required String ccId,
    required String influencerId,
    required String providerTarget,
    required String text,
  }) async {
    final data = await _request('POST', '/content-items', body: {
      'cc_id': ccId,
      'influencer_id': influencerId,
      'provider_target': providerTarget,
      'text': text,
    });
    return ContentItem.fromJson(data);
  }

  // --- Influencers ---

  Future<List<Influencer>> listInfluencers(String orgId) async {
    final data = await _request('GET', '/influencers', queryParams: {'org_id': orgId});
    return (data as List).map((e) => Influencer.fromJson(e)).toList();
  }

  // --- Metrics ---

  Future<MetricsOverview> getMetricsOverview(String ccId) async {
    final data = await _request('GET', '/metrics/overview', queryParams: {'cc_id': ccId});
    return MetricsOverview.fromJson(data);
  }

  // --- Notifications ---

  Future<List<AppNotification>> listNotifications({int skip = 0, int limit = 20}) async {
    final data = await _request('GET', '/notifications', queryParams: {
      'skip': '$skip',
      'limit': '$limit',
    });
    final items = data['items'] as List;
    return items.map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _request('POST', '/notifications/$id/read');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
