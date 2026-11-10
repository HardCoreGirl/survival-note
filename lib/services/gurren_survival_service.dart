import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'gurren_auth_service.dart';

class GurrenSurvivalService {
  final String baseUrl;
  final String packageName;
  final http.Client _client;

  GurrenSurvivalService({
    String? baseUrl,
    String? packageName,
    http.Client? client,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? GurrenAuthService.defaultBaseUrl),
        packageName = packageName ?? GurrenAuthService.defaultPackageName,
        _client = client ?? http.Client();

  static String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/api/v1')) {
      trimmed = '$trimmed/api/v1';
    }
    return trimmed;
  }

  Map<String, String> _buildHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Client-Package': packageName,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 1. Fetch official catalog items (public, mode: bag | shelter | all)
  Future<List<Map<String, dynamic>>> fetchCatalog({String? mode}) async {
    final uri = Uri.parse('$baseUrl/survival/catalog').replace(
      queryParameters: mode != null ? {'mode': mode} : null,
    );

    final res = await _client.get(uri, headers: _buildHeaders());
    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes)) as List? ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load catalog: ${res.statusCode}');
  }

  /// 2. Fetch user items (authenticated)
  Future<List<Item>> fetchUserItems({
    required String token,
    String? mode,
  }) async {
    final uri = Uri.parse('$baseUrl/survival/items').replace(
      queryParameters: mode != null ? {'mode': mode} : null,
    );

    final res = await _client.get(
      uri,
      headers: _buildHeaders(token: token),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes)) as List? ?? [];
      return data.map((json) => Item.fromServer(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch user items: ${res.statusCode}');
  }

  /// 3. Initialize user items from official catalog (first-time setup)
  Future<List<Item>> initUserItems({required String token}) async {
    final uri = Uri.parse('$baseUrl/survival/items/init');
    final res = await _client.post(
      uri,
      headers: _buildHeaders(token: token),
      body: '{}',
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes)) as List? ?? [];
      return data.map((json) => Item.fromServer(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to initialize items: ${res.statusCode}');
  }

  /// 4. Create custom item (authenticated)
  Future<Item> createCustomItem({
    required String token,
    required String mode,
    required String category,
    required String name,
    int quantity = 1,
    String unit = '개',
    int importance = 2,
    bool hasExpiry = false,
    DateTime? expiryDate,
    String? storageLocation,
    String? memo,
  }) async {
    final uri = Uri.parse('$baseUrl/survival/items');
    final body = jsonEncode({
      'mode': mode,
      'category': category,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'importance': importance,
      'has_expiry': hasExpiry,
      if (expiryDate != null)
        'expiry_date':
            '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}',
      if (storageLocation != null) 'storage_location': storageLocation,
      if (memo != null) 'memo': memo,
    });

    final res = await _client.post(
      uri,
      headers: _buildHeaders(token: token),
      body: body,
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return Item.fromServer(data);
    }
    throw Exception('Failed to create custom item: ${res.statusCode}');
  }

  /// 5. Update user item (is_owned, quantity, expiry_date, memo, custom_name)
  Future<Item> updateUserItem({
    required String token,
    required String itemId,
    bool? isOwned,
    int? quantity,
    DateTime? expiryDate,
    String? storageLocation,
    String? memo,
    String? customName,
  }) async {
    final uri = Uri.parse('$baseUrl/survival/items/$itemId');
    final Map<String, dynamic> bodyMap = {};
    if (isOwned != null) bodyMap['is_owned'] = isOwned;
    if (quantity != null) bodyMap['quantity'] = quantity;
    if (expiryDate != null) {
      bodyMap['expiry_date'] =
          '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
    }
    if (storageLocation != null) bodyMap['storage_location'] = storageLocation;
    if (memo != null) bodyMap['memo'] = memo;
    if (customName != null) bodyMap['custom_name'] = customName;

    final res = await _client.put(
      uri,
      headers: _buildHeaders(token: token),
      body: jsonEncode(bodyMap),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return Item.fromServer(data);
    }
    throw Exception('Failed to update item: ${res.statusCode}');
  }

  /// 6. Delete user item
  Future<void> deleteUserItem({
    required String token,
    required String itemId,
  }) async {
    final uri = Uri.parse('$baseUrl/survival/items/$itemId');
    final res = await _client.delete(
      uri,
      headers: _buildHeaders(token: token),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete item: ${res.statusCode}');
    }
  }

  /// 7. Fetch user settings
  Future<Map<String, dynamic>> fetchSettings({required String token}) async {
    final uri = Uri.parse('$baseUrl/survival/settings');
    final res = await _client.get(
      uri,
      headers: _buildHeaders(token: token),
    );

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch settings: ${res.statusCode}');
  }

  /// 8. Update user settings
  Future<Map<String, dynamic>> updateSettings({
    required String token,
    int? householdCount,
    int? inspectionCycleMonths,
    DateTime? lastInspectedAt,
  }) async {
    final uri = Uri.parse('$baseUrl/survival/settings');
    final Map<String, dynamic> bodyMap = {};
    if (householdCount != null) bodyMap['household_count'] = householdCount;
    if (inspectionCycleMonths != null) {
      bodyMap['inspection_cycle_months'] = inspectionCycleMonths;
    }
    if (lastInspectedAt != null) {
      bodyMap['last_inspected_at'] = lastInspectedAt.toIso8601String();
    }

    final res = await _client.put(
      uri,
      headers: _buildHeaders(token: token),
      body: jsonEncode(bodyMap),
    );

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Failed to update settings: ${res.statusCode}');
  }
}

