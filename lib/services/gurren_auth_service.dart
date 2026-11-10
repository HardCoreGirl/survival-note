import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GurrenAuthResult {
  final String token;
  final String refreshToken;
  final String displayId;
  final String displayName;

  const GurrenAuthResult({
    required this.token,
    required this.refreshToken,
    required this.displayId,
    required this.displayName,
  });

  factory GurrenAuthResult.fromJson(Map<String, dynamic> json) {
    return GurrenAuthResult(
      token: json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      displayId: json['display_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}

class GurrenAuthService {
  static const String defaultPackageName = 'com.ratsoft.survivalnote';

  static const String productionBaseUrl =
      'https://gurren-api-prd-865345517214.asia-northeast3.run.app/api/v1';

  /// 디바이스/플랫폼 및 빌드 모드별 기본 Base URL 반환
  static String get defaultBaseUrl {
    // 1. --dart-define=API_BASE_URL=... 로 직접 지정한 경우 최우선 사용
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/api/v1') ? envUrl : '$envUrl/api/v1';
    }

    // 2. 릴리즈 빌드(flutter build web 등 상용 배포)인 경우 Cloud Run 실서버 자동 참조
    if (kReleaseMode) {
      return productionBaseUrl;
    }

    // 3. 로컬 개발/디버그 모드(flutter run)인 경우 로컬 서버 참조
    if (kIsWeb) {
      return 'http://localhost:7575/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // 안드로이드 에뮬레이터에서는 호스트 머신이 10.0.2.2 입니다.
        return 'http://10.0.2.2:7575/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:7575/api/v1';
  }

  final String baseUrl;
  final String packageName;
  final http.Client _client;

  GurrenAuthService({
    String? baseUrl,
    String? packageName,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        packageName = packageName ?? defaultPackageName,
        _client = client ?? http.Client();

  /// 게스트 계정 신규 생성 및 로그인 토큰 발급
  /// POST /api/v1/auth/guest
  Future<GurrenAuthResult> registerGuest() async {
    final uri = Uri.parse('$baseUrl/auth/guest');
    final response = await _client.post(
      uri,
      headers: {
        'Client-Package': packageName,
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return GurrenAuthResult.fromJson(data);
    } else {
      String errorMessage = '게스트 로그인에 실패했습니다. (HTTP ${response.statusCode})';
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (errJson.containsKey('message')) {
          errorMessage = errJson['message'] as String;
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  /// 구글 ID 토큰으로 로그인 또는 회원가입
  /// POST /api/v1/auth/google
  Future<GurrenAuthResult> loginWithGoogle(String idToken) async {
    final uri = Uri.parse('$baseUrl/auth/google');
    final response = await _client.post(
      uri,
      headers: {
        'Client-Package': packageName,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id_token': idToken}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return GurrenAuthResult.fromJson(data);
    } else {
      String errorMessage = '구글 로그인에 실패했습니다. (HTTP ${response.statusCode})';
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (errJson.containsKey('message')) {
          errorMessage = errJson['message'] as String;
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  /// 토큰 갱신
  /// POST /api/v1/auth/refresh
  Future<GurrenAuthResult> refreshToken(String currentRefreshToken) async {
    final uri = Uri.parse('$baseUrl/auth/refresh');
    final response = await _client.post(
      uri,
      headers: {
        'Client-Package': packageName,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh_token': currentRefreshToken,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return GurrenAuthResult.fromJson(data);
    } else {
      throw Exception('토큰 갱신에 실패했습니다.');
    }
  }
}

