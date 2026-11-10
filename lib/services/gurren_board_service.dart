import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gurren_auth_service.dart';

class ServerBoardItem {
  final String id;
  final String displayId;
  final String displayName;
  final String categoryId;
  final String title;
  final String content;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;

  ServerBoardItem({
    required this.id,
    required this.displayId,
    required this.displayName,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory ServerBoardItem.fromJson(Map<String, dynamic> json) {
    String parsedContent = '';
    final rawContent = json['content'];
    if (rawContent is String) {
      parsedContent = rawContent;
    } else if (rawContent is Map) {
      parsedContent = rawContent['body']?.toString() ?? jsonEncode(rawContent);
    } else if (rawContent != null) {
      parsedContent = rawContent.toString();
    }

    return ServerBoardItem(
      id: json['id'] as String? ?? '',
      displayId: json['display_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: parsedContent,
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ServerCommentItem {
  final String id;
  final String displayId;
  final String displayName;
  final String comment;
  final DateTime createdAt;

  ServerCommentItem({
    required this.id,
    required this.displayId,
    required this.displayName,
    required this.comment,
    required this.createdAt,
  });

  factory ServerCommentItem.fromJson(Map<String, dynamic> json) {
    return ServerCommentItem(
      id: json['id'] as String? ?? '',
      displayId: json['display_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class GurrenBoardService {
  final String baseUrl;
  final String packageName;
  final http.Client _client;

  GurrenBoardService({
    String? baseUrl,
    String? packageName,
    http.Client? client,
  })  : baseUrl = baseUrl ?? GurrenAuthService.defaultBaseUrl,
        packageName = packageName ?? GurrenAuthService.defaultPackageName,
        _client = client ?? http.Client();

  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{
      'Client-Package': packageName,
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 카테고리 목록 조회
  Future<String> getDefaultCategoryId(String? token) async {
    try {
      final uri = Uri.parse('$baseUrl/boards/categories');
      final res = await _client.get(uri, headers: _buildHeaders(token)).timeout(
            const Duration(seconds: 5),
          );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          return first['id'] as String? ?? 'cat-uuid-15000-free';
        }
      }
    } catch (_) {}
    return 'cat-uuid-15000-free';
  }

  /// 게시글 목록 조회
  Future<List<ServerBoardItem>> listBoards({
    String? token,
    int limit = 30,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/boards?limit=$limit&offset=$offset');
    final res = await _client.get(uri, headers: _buildHeaders(token)).timeout(
          const Duration(seconds: 7),
        );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((item) => ServerBoardItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('게시글 목록을 불러오지 못했습니다. (HTTP ${res.statusCode})');
    }
  }

  /// 새 게시글 작성
  Future<ServerBoardItem> createBoard({
    required String token,
    required String content,
    String? categoryId,
  }) async {
    final catId = categoryId ?? await getDefaultCategoryId(token);

    // 제목은 본문 첫 줄 또는 앞 30글자로 자동 생성
    final firstLine = content.trim().split('\n').first.trim();
    final title = firstLine.length > 30 ? '${firstLine.substring(0, 30)}...' : firstLine;

    final uri = Uri.parse('$baseUrl/boards');
    final body = jsonEncode({
      'category_id': catId,
      'title': title.isEmpty ? '새로운 게시글' : title,
      'content': content,
    });

    final res = await _client
        .post(uri, headers: _buildHeaders(token), body: body)
        .timeout(const Duration(seconds: 7));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ServerBoardItem.fromJson(data);
    } else {
      throw Exception('게시글 작성에 실패했습니다. (HTTP ${res.statusCode})');
    }
  }

  /// 게시글 좋아요 토글
  Future<void> toggleLike({
    required String token,
    required String boardId,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId/likes');
    final res = await _client
        .post(uri, headers: _buildHeaders(token))
        .timeout(const Duration(seconds: 5));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('좋아요 처리에 실패했습니다.');
    }
  }

  /// 댓글 목록 조회
  Future<List<ServerCommentItem>> listComments({
    String? token,
    required String boardId,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId/comments');
    final res = await _client.get(uri, headers: _buildHeaders(token)).timeout(
          const Duration(seconds: 6),
        );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return list
          .map((item) => ServerCommentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      return [];
    }
  }

  /// 댓글 작성
  Future<ServerCommentItem> createComment({
    required String token,
    required String boardId,
    required String comment,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId/comments');
    final body = jsonEncode({
      'comment': comment,
    });

    final res = await _client
        .post(uri, headers: _buildHeaders(token), body: body)
        .timeout(const Duration(seconds: 6));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ServerCommentItem.fromJson(data);
    } else {
      throw Exception('댓글 작성에 실패했습니다. (HTTP ${res.statusCode})');
    }
  }

  /// 게시글 수정
  Future<ServerBoardItem> updateBoard({
    required String token,
    required String boardId,
    required String content,
    String? categoryId,
  }) async {
    final catId = categoryId ?? await getDefaultCategoryId(token);
    final firstLine = content.trim().split('\n').first.trim();
    final title = firstLine.length > 30 ? '${firstLine.substring(0, 30)}...' : firstLine;

    final uri = Uri.parse('$baseUrl/boards/$boardId');
    final body = jsonEncode({
      'category_id': catId,
      'title': title.isEmpty ? '게시글 수정' : title,
      'content': content,
    });

    final res = await _client
        .put(uri, headers: _buildHeaders(token), body: body)
        .timeout(const Duration(seconds: 7));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ServerBoardItem.fromJson(data);
    } else {
      throw Exception('게시글 수정에 실패했습니다. (HTTP ${res.statusCode})');
    }
  }

  /// 게시글 삭제
  Future<void> deleteBoard({
    required String token,
    required String boardId,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId');
    final res = await _client
        .delete(uri, headers: _buildHeaders(token))
        .timeout(const Duration(seconds: 6));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('게시글 삭제에 실패했습니다. (HTTP ${res.statusCode})');
    }
  }

  /// 게시글 신고
  Future<void> reportBoard({
    required String token,
    required String boardId,
    required String reason,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId/reports');
    final body = jsonEncode({
      'reason': reason,
    });

    final res = await _client
        .post(uri, headers: _buildHeaders(token), body: body)
        .timeout(const Duration(seconds: 6));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('게시글 신고에 실패했습니다.');
    }
  }

  /// 댓글 수정
  Future<ServerCommentItem> updateComment({
    required String token,
    required String boardId,
    required String commentId,
    required String comment,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId/comments/$commentId');
    final body = jsonEncode({
      'comment': comment,
    });

    final res = await _client
        .put(uri, headers: _buildHeaders(token), body: body)
        .timeout(const Duration(seconds: 6));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ServerCommentItem.fromJson(data);
    } else {
      throw Exception('댓글 수정에 실패했습니다. (HTTP ${res.statusCode})');
    }
  }

  /// 댓글 삭제
  Future<void> deleteComment({
    required String token,
    required String boardId,
    required String commentId,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId/comments/$commentId');
    final res = await _client
        .delete(uri, headers: _buildHeaders(token))
        .timeout(const Duration(seconds: 6));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('댓글 삭제에 실패했습니다.');
    }
  }

  /// 댓글 신고
  Future<void> reportComment({
    required String token,
    required String boardId,
    required String commentId,
    required String reason,
  }) async {
    final uri = Uri.parse('$baseUrl/boards/$boardId/comments/$commentId/reports');
    final body = jsonEncode({
      'reason': reason,
    });

    final res = await _client
        .post(uri, headers: _buildHeaders(token), body: body)
        .timeout(const Duration(seconds: 6));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('댓글 신고에 실패했습니다.');
    }
  }
}

