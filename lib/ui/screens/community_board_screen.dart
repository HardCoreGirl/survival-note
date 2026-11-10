import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tactical_theme.dart';
import '../../providers/survival_providers.dart';
import '../../services/gurren_board_service.dart';

class BoardComment {
  final String id;
  final String displayId;
  final String author;
  final String date;
  final String content;

  BoardComment({
    required this.id,
    required this.displayId,
    required this.author,
    required this.date,
    required this.content,
  });
}

class BoardPost {
  final String id;
  final String displayId;
  final String contentKo;
  final String contentEn;
  final String author;
  final String date;
  int likes;
  bool isLiked;
  int commentCount;
  List<BoardComment> comments;
  bool isCommentsLoaded;

  BoardPost({
    required this.id,
    required this.displayId,
    required this.contentKo,
    required this.contentEn,
    required this.author,
    required this.date,
    required this.likes,
    this.isLiked = false,
    required this.commentCount,
    required this.comments,
    this.isCommentsLoaded = false,
  });

  String content(bool isKo) => isKo ? contentKo : contentEn;

  BoardPost copyWith({
    String? id,
    String? displayId,
    String? contentKo,
    String? contentEn,
    String? author,
    String? date,
    int? likes,
    bool? isLiked,
    int? commentCount,
    List<BoardComment>? comments,
    bool? isCommentsLoaded,
  }) {
    return BoardPost(
      id: id ?? this.id,
      displayId: displayId ?? this.displayId,
      contentKo: contentKo ?? this.contentKo,
      contentEn: contentEn ?? this.contentEn,
      author: author ?? this.author,
      date: date ?? this.date,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? this.comments,
      isCommentsLoaded: isCommentsLoaded ?? this.isCommentsLoaded,
    );
  }
}

final gurrenBoardServiceProvider = Provider<GurrenBoardService>((ref) {
  return GurrenBoardService();
});

class BoardPostsNotifier extends StateNotifier<List<BoardPost>> {
  final GurrenBoardService _boardService;
  final Ref _ref;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BoardPostsNotifier(this._boardService, this._ref) : super([]) {
    // 계정 상태(토큰)가 준비되거나 갱신되면 자동으로 서버 글 목록 다시 로드
    _ref.listen<AccountState>(accountProvider, (previous, next) {
      if (previous?.authToken != next.authToken && next.authToken != null) {
        loadBoards();
      }
    });

    loadBoards();
  }

  /// 서버에서 게시글 목록 로드
  Future<void> loadBoards() async {
    _isLoading = true;
    String? token = _ref.read(accountProvider).authToken;

    // 토큰이 없으면 게스트 로그인을 먼저 수행하여 서버 인증 토큰 획득
    if (token == null || token.isEmpty) {
      await _ref.read(accountProvider.notifier).loginAsGuest();
      token = _ref.read(accountProvider).authToken;
    }

    try {
      final serverItems = await _boardService.listBoards(token: token);
      if (serverItems.isNotEmpty) {
        state = serverItems.map((s) {
          final dateStr =
              '${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}-${s.createdAt.day.toString().padLeft(2, '0')} ${s.createdAt.hour.toString().padLeft(2, '0')}:${s.createdAt.minute.toString().padLeft(2, '0')}';
          return BoardPost(
            id: s.id,
            displayId: s.displayId,
            contentKo: s.content,
            contentEn: s.content,
            author: s.displayName.isNotEmpty ? s.displayName : s.displayId,
            date: dateStr,
            likes: s.likeCount,
            isLiked: s.isLiked,
            commentCount: s.commentCount,
            comments: [],
            isCommentsLoaded: false,
          );
        }).toList();
        _isLoading = false;
        return;
      }
    } catch (e) {
      debugPrint('[Board] loadBoards failed: $e');
      if (e.toString().contains('401')) {
        await _ref.read(accountProvider.notifier).loginAsGuest(force: true);
        final freshToken = _ref.read(accountProvider).authToken;
        if (freshToken != null && freshToken.isNotEmpty) {
          try {
            final retryItems = await _boardService.listBoards(token: freshToken);
            if (retryItems.isNotEmpty) {
              state = retryItems.map((s) {
                final dateStr =
                    '${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}-${s.createdAt.day.toString().padLeft(2, '0')} ${s.createdAt.hour.toString().padLeft(2, '0')}:${s.createdAt.minute.toString().padLeft(2, '0')}';
                return BoardPost(
                  id: s.id,
                  displayId: s.displayId,
                  contentKo: s.content,
                  contentEn: s.content,
                  author: s.displayName.isNotEmpty ? s.displayName : s.displayId,
                  date: dateStr,
                  likes: s.likeCount,
                  isLiked: s.isLiked,
                  commentCount: s.commentCount,
                  comments: [],
                  isCommentsLoaded: false,
                );
              }).toList();
              _isLoading = false;
              return;
            }
          } catch (_) {}
        }
      }
    }

    // 서버에 글이 아직 없거나 첫 실행 시 초기 샘플 피드 유지
    if (state.isEmpty) {
      state = _buildInitialFallbackPosts();
    }
    _isLoading = false;
  }

  /// 특정 게시글의 댓글 목록 서버에서 불러오기
  Future<void> loadComments(String postId) async {
    final token = _ref.read(accountProvider).authToken;
    try {
      final serverComments =
          await _boardService.listComments(token: token, boardId: postId);

      final comments = serverComments.map((c) {
        final dateStr =
            '${c.createdAt.year}-${c.createdAt.month.toString().padLeft(2, '0')}-${c.createdAt.day.toString().padLeft(2, '0')} ${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}';
        return BoardComment(
          id: c.id,
          displayId: c.displayId,
          author: c.displayName.isNotEmpty ? c.displayName : c.displayId,
          date: dateStr,
          content: c.comment,
        );
      }).toList();

      state = [
        for (final post in state)
          if (post.id == postId)
            post.copyWith(
              comments: comments,
              commentCount: comments.length,
              isCommentsLoaded: true,
            )
          else
            post
      ];
    } catch (_) {}
  }

  /// 좋아요 토글
  Future<void> toggleLike(String postId) async {
    final token = _ref.read(accountProvider).authToken;

    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            likes: post.isLiked ? post.likes - 1 : post.likes + 1,
            isLiked: !post.isLiked,
          )
        else
          post
    ];

    if (token != null && token.isNotEmpty) {
      try {
        await _boardService.toggleLike(token: token, boardId: postId);
      } catch (_) {}
    }
  }

  /// 새 글 작성
  Future<void> addPost({
    required String content,
    required String author,
  }) async {
    var account = _ref.read(accountProvider);
    String? token = account.authToken;

    if (token == null || token.isEmpty) {
      await _ref.read(accountProvider.notifier).loginAsGuest();
      account = _ref.read(accountProvider);
      token = account.authToken;
    }

    final currentDisplayId = account.serverDisplayId ?? account.guestId;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (token != null && token.isNotEmpty) {
      try {
        final serverItem = await _boardService.createBoard(
          token: token,
          content: content,
        );

        final newPost = BoardPost(
          id: serverItem.id,
          displayId: serverItem.displayId.isNotEmpty
              ? serverItem.displayId
              : currentDisplayId,
          contentKo: serverItem.content,
          contentEn: serverItem.content,
          author: serverItem.displayName.isNotEmpty
              ? serverItem.displayName
              : author,
          date: dateStr,
          likes: 0,
          commentCount: 0,
          comments: [],
          isCommentsLoaded: true,
        );

        state = [newPost, ...state];
        return;
      } catch (e) {
        debugPrint('[Board] addPost server error: $e');
      }
    }

    // 오프라인 fallback
    final newPost = BoardPost(
      id: 'post-${now.millisecondsSinceEpoch}',
      displayId: currentDisplayId,
      contentKo: content,
      contentEn: content,
      author: author,
      date: dateStr,
      likes: 0,
      commentCount: 0,
      comments: [],
      isCommentsLoaded: true,
    );
    state = [newPost, ...state];
  }

  /// 게시글 수정
  Future<bool> updatePost({
    required String postId,
    required String content,
  }) async {
    final token = _ref.read(accountProvider).authToken;

    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            contentKo: content,
            contentEn: content,
          )
        else
          post
    ];

    if (token != null && token.isNotEmpty) {
      try {
        await _boardService.updateBoard(
          token: token,
          boardId: postId,
          content: content,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// 게시글 삭제
  Future<bool> deletePost(String postId) async {
    final token = _ref.read(accountProvider).authToken;

    state = state.where((p) => p.id != postId).toList();

    if (token != null && token.isNotEmpty) {
      try {
        await _boardService.deleteBoard(token: token, boardId: postId);
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// 게시글 신고
  Future<bool> reportPost({
    required String postId,
    required String reason,
  }) async {
    final token = _ref.read(accountProvider).authToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _boardService.reportBoard(
          token: token,
          boardId: postId,
          reason: reason,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// 댓글 작성
  Future<void> addComment({
    required String postId,
    required String author,
    required String content,
  }) async {
    final account = _ref.read(accountProvider);
    final token = account.authToken;
    final currentDisplayId = account.serverDisplayId ?? account.guestId;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final tempComment = BoardComment(
      id: 'c-${now.millisecondsSinceEpoch}',
      displayId: currentDisplayId,
      author: author,
      date: dateStr,
      content: content,
    );

    // UI 선반영
    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            comments: [...post.comments, tempComment],
            commentCount: post.commentCount + 1,
            isCommentsLoaded: true,
          )
        else
          post
    ];

    if (token != null && token.isNotEmpty) {
      try {
        final serverComment = await _boardService.createComment(
          token: token,
          boardId: postId,
          comment: content,
        );

        // 실제 서버 ID 및 정보로 업데이트
        state = [
          for (final post in state)
            if (post.id == postId)
              post.copyWith(
                comments: [
                  for (final c in post.comments)
                    if (c.id == tempComment.id)
                      BoardComment(
                        id: serverComment.id,
                        displayId: serverComment.displayId.isNotEmpty
                            ? serverComment.displayId
                            : currentDisplayId,
                        author: serverComment.displayName.isNotEmpty
                            ? serverComment.displayName
                            : author,
                        date: dateStr,
                        content: serverComment.comment,
                      )
                    else
                      c
                ],
              )
            else
              post
        ];
      } catch (_) {}
    }
  }

  /// 댓글 수정
  Future<bool> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    final token = _ref.read(accountProvider).authToken;

    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            comments: [
              for (final c in post.comments)
                if (c.id == commentId)
                  BoardComment(
                    id: c.id,
                    displayId: c.displayId,
                    author: c.author,
                    date: c.date,
                    content: content,
                  )
                else
                  c
            ],
          )
        else
          post
    ];

    if (token != null && token.isNotEmpty) {
      try {
        await _boardService.updateComment(
          token: token,
          boardId: postId,
          commentId: commentId,
          comment: content,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// 댓글 삭제
  Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final token = _ref.read(accountProvider).authToken;

    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            comments: post.comments.where((c) => c.id != commentId).toList(),
            commentCount: post.commentCount > 0 ? post.commentCount - 1 : 0,
          )
        else
          post
    ];

    if (token != null && token.isNotEmpty) {
      try {
        await _boardService.deleteComment(
          token: token,
          boardId: postId,
          commentId: commentId,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// 댓글 신고
  Future<bool> reportComment({
    required String postId,
    required String commentId,
    required String reason,
  }) async {
    final token = _ref.read(accountProvider).authToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _boardService.reportComment(
          token: token,
          boardId: postId,
          commentId: commentId,
          reason: reason,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  List<BoardPost> _buildInitialFallbackPosts() {
    return [
      BoardPost(
        id: 'post-1',
        displayId: 'SAMPLE_ADMIN',
        contentKo:
            '🎒 72시간 생존가방 패킹 실전 팁 공유합니다!\n\n'
            '1. 가장 무거운 생수와 통조림은 배낭 등판 쪽(어깨뼈 높이)에 밀착시켜야 이동 시 허리 부담이 적습니다.\n'
            '2. 즉시 꺼내야 하는 구급 파우치, 헤드랜턴, 방진 마스크는 상단 포켓이나 외부 몰리(MOLLE)에 배치하세요.\n'
            '3. 의류와 침낭/은박 보온포는 가방 가장 바닥에 깔아 충격을 흡수하게 만듭니다.\n'
            '4. 전체 배낭 무게는 본인 체중의 20% 이내(성인 기준 12~15kg)로 맞추는 것이 도보 이동 시 안전합니다.',
        contentEn:
            '🎒 Practical tips for packing a 72-hour bug-out bag!\n\n'
            '1. Place heavy water and canned food close to your spine to reduce back strain.\n'
            '2. Keep first aid kits, headlamps, and dust masks in top or exterior pockets for instant access.\n'
            '3. Pack clothing and thermal blankets at the bottom as shock absorbers.',
        author: 'TacticalPrep_KR',
        date: '2026-11-01 14:20',
        likes: 42,
        commentCount: 2,
        comments: [
          BoardComment(
            id: 'c-1',
            displayId: 'GEAR_01',
            author: 'GearPrep_01',
            date: '2026-11-01 14:22',
            content: '생수를 등판 쪽에 붙이니까 체감 무게가 확 줄어드네요! 유용한 팁 감사합니다.',
          ),
          BoardComment(
            id: 'c-2',
            displayId: 'KIM_02',
            author: 'Survivor_Kim',
            date: '2026-11-01 16:05',
            content: '방진마스크랑 은박담요는 바로 꺼낼 수 있게 외부 파우치에 넣었습니다.',
          ),
        ],
        isCommentsLoaded: true,
      ),
    ];
  }
}

final boardPostsProvider =
    StateNotifierProvider<BoardPostsNotifier, List<BoardPost>>((ref) {
  final boardService = ref.watch(gurrenBoardServiceProvider);
  return BoardPostsNotifier(boardService, ref);
});

class CommunityBoardScreen extends ConsumerWidget {
  const CommunityBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKo = ref.watch(localeProvider).languageCode == 'ko';
    final allPosts = ref.watch(boardPostsProvider);

    return Scaffold(
      backgroundColor: TacticalTheme.slate900,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.forum_outlined, color: TacticalTheme.amber500),
            const SizedBox(width: 8),
            Text(
              isKo ? '자유 피드' : 'Community Feed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: TacticalTheme.amber500,
        backgroundColor: TacticalTheme.slate800,
        onRefresh: () async {
          await ref.read(boardPostsProvider.notifier).loadBoards();
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: allPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = allPosts[index];
            return _FeedPostCard(post: post, isKo: isKo);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWritePostSheet(context, ref, isKo),
        icon: const Icon(Icons.edit_note),
        label: Text(
          isKo ? '글쓰기' : 'Post',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _showWritePostSheet(
    BuildContext context,
    WidgetRef ref,
    bool isKo,
  ) {
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TacticalTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    color: TacticalTheme.amber500,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isKo ? '새 글 작성' : 'New Post',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: contentCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                maxLines: 5,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isKo
                      ? '생존 비축 팁, 질문, 인증 등을 자유롭게 공유해보세요...'
                      : 'Share your survival prep tips, questions, or setups...',
                  hintStyle: const TextStyle(
                    color: TacticalTheme.slate500,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: TacticalTheme.amber500,
                    foregroundColor: TacticalTheme.slate900,
                  ),
                  onPressed: () async {
                    final c = contentCtrl.text.trim();
                    if (c.isNotEmpty) {
                      final account = ref.read(accountProvider);
                      final author = account.serverDisplayName ??
                          (account.isGoogleLinked && account.linkedEmail != null
                              ? account.linkedEmail!.split('@').first
                              : account.guestId);

                      Navigator.of(ctx).pop();
                      await ref.read(boardPostsProvider.notifier).addPost(
                            content: c,
                            author: author,
                          );
                    }
                  },
                  child: Text(
                    isKo ? '게시하기' : 'Publish',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedPostCard extends ConsumerStatefulWidget {
  final BoardPost post;
  final bool isKo;

  const _FeedPostCard({
    required this.post,
    required this.isKo,
  });

  @override
  ConsumerState<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<_FeedPostCard> {
  bool _isExpanded = false;
  bool _isCommentsOpen = false;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final account = ref.read(accountProvider);
    final authorName = account.serverDisplayName ??
        (account.isGoogleLinked && account.linkedEmail != null
            ? account.linkedEmail!.split('@').first
            : account.guestId);

    ref.read(boardPostsProvider.notifier).addComment(
          postId: widget.post.id,
          author: authorName,
          content: text,
        );

    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  // --- 게시글 수정 다이얼로그 ---
  void _showEditPostDialog() {
    final ctrl = TextEditingController(text: widget.post.content(widget.isKo));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TacticalTheme.slate800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: TacticalTheme.slate700),
        ),
        title: Text(
          widget.isKo ? '게시글 수정' : 'Edit Post',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 6,
          decoration: InputDecoration(
            hintText: widget.isKo ? '수정할 내용을 입력하세요' : 'Enter updated content',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              widget.isKo ? '취소' : 'Cancel',
              style: const TextStyle(color: TacticalTheme.slate400),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TacticalTheme.amber500,
              foregroundColor: TacticalTheme.slate900,
            ),
            onPressed: () async {
              final newContent = ctrl.text.trim();
              if (newContent.isNotEmpty) {
                Navigator.of(ctx).pop();
                final ok = await ref
                    .read(boardPostsProvider.notifier)
                    .updatePost(postId: widget.post.id, content: newContent);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.isKo ? '게시글이 수정되었습니다.' : 'Post updated successfully.',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              widget.isKo ? '저장' : 'Save',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- 게시글 삭제 확인 다이얼로그 ---
  void _showDeletePostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TacticalTheme.slate800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: TacticalTheme.slate700),
        ),
        title: Text(
          widget.isKo ? '게시글 삭제' : 'Delete Post',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isKo
              ? '정말로 이 게시글을 삭제하시겠습니까?'
              : 'Are you sure you want to delete this post?',
          style: const TextStyle(color: TacticalTheme.slate300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              widget.isKo ? '취소' : 'Cancel',
              style: const TextStyle(color: TacticalTheme.slate400),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TacticalTheme.red500,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(boardPostsProvider.notifier)
                  .deletePost(widget.post.id);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isKo ? '게시글이 삭제되었습니다.' : 'Post deleted.',
                    ),
                  ),
                );
              }
            },
            child: Text(
              widget.isKo ? '삭제' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- 게시글/댓글 신고 다이얼로그 ---
  void _showReportDialog({required bool isPost, String? commentId}) {
    final reasons = widget.isKo
        ? ['스팸 / 홍보성 게시물', '부적절한 언어 및 욕설', '허위 정보 / 사기 의심', '기타 불쾌한 콘텐츠']
        : ['Spam / Promotional', 'Inappropriate language', 'False info / Scam', 'Other'];

    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: TacticalTheme.slate800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: TacticalTheme.slate700),
          ),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: TacticalTheme.amber500, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.isKo
                    ? (isPost ? '게시글 신고' : '댓글 신고')
                    : (isPost ? 'Report Post' : 'Report Comment'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isKo ? '신고 사유를 선택해주세요:' : 'Select report reason:',
                  style: const TextStyle(color: TacticalTheme.slate400, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ...reasons.map(
                  (r) => RadioListTile<String>(
                    title: Text(
                      r,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                    value: r,
                    groupValue: selectedReason,
                    dense: true,
                    activeColor: TacticalTheme.amber500,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedReason = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                widget.isKo ? '취소' : 'Cancel',
                style: const TextStyle(color: TacticalTheme.slate400),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TacticalTheme.amber500,
                foregroundColor: TacticalTheme.slate900,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                bool ok = false;
                if (isPost) {
                  ok = await ref
                      .read(boardPostsProvider.notifier)
                      .reportPost(postId: widget.post.id, reason: selectedReason);
                } else if (commentId != null) {
                  ok = await ref.read(boardPostsProvider.notifier).reportComment(
                        postId: widget.post.id,
                        commentId: commentId,
                        reason: selectedReason,
                      );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? (widget.isKo
                                ? '신고가 접수되었습니다. 관리자 검토 후 조치됩니다.'
                                : 'Report submitted. We will review it shortly.')
                            : (widget.isKo ? '신고 처리에 실패했습니다.' : 'Failed to submit report.'),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                widget.isKo ? '신고 제출' : 'Submit',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 댓글 수정 다이얼로그 ---
  void _showEditCommentDialog(BoardComment comment) {
    final ctrl = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TacticalTheme.slate800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: TacticalTheme.slate700),
        ),
        title: Text(
          widget.isKo ? '댓글 수정' : 'Edit Comment',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: widget.isKo ? '수정할 댓글을 입력하세요' : 'Enter updated comment',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              widget.isKo ? '취소' : 'Cancel',
              style: const TextStyle(color: TacticalTheme.slate400),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TacticalTheme.amber500,
              foregroundColor: TacticalTheme.slate900,
            ),
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop();
                final ok = await ref
                    .read(boardPostsProvider.notifier)
                    .updateComment(
                      postId: widget.post.id,
                      commentId: comment.id,
                      content: text,
                    );
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.isKo ? '댓글이 수정되었습니다.' : 'Comment updated.',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              widget.isKo ? '저장' : 'Save',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- 댓글 삭제 확인 다이얼로그 ---
  void _showDeleteCommentDialog(BoardComment comment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TacticalTheme.slate800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: TacticalTheme.slate700),
        ),
        title: Text(
          widget.isKo ? '댓글 삭제' : 'Delete Comment',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isKo
              ? '이 댓글을 삭제하시겠습니까?'
              : 'Are you sure you want to delete this comment?',
          style: const TextStyle(color: TacticalTheme.slate300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              widget.isKo ? '취소' : 'Cancel',
              style: const TextStyle(color: TacticalTheme.slate400),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TacticalTheme.red500,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(boardPostsProvider.notifier)
                  .deleteComment(
                    postId: widget.post.id,
                    commentId: comment.id,
                  );
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isKo ? '댓글이 삭제되었습니다.' : 'Comment deleted.',
                    ),
                  ),
                );
              }
            },
            child: Text(
              widget.isKo ? '삭제' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isKo = widget.isKo;
    final contentText = post.content(isKo);
    final isLongContent = contentText.length > 90 || contentText.contains('\n\n');

    final account = ref.watch(accountProvider);
    final currentDisplayId = account.serverDisplayId ?? account.guestId;

    // 본인 글 여부 판별
    final isMyPost = post.displayId == currentDisplayId ||
        (post.author.isNotEmpty &&
            post.author == (account.serverDisplayName ?? ''));

    return Card(
      color: TacticalTheme.slate800,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: TacticalTheme.slate700),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Author Row & More Options Menu (수정/삭제 or 신고)
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: TacticalTheme.slate700,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 17,
                    color: TacticalTheme.amber500,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.author,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMyPost) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: TacticalTheme.amber500.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isKo ? '내 글' : 'Me',
                                style: const TextStyle(
                                  color: TacticalTheme.amber500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        post.date,
                        style: const TextStyle(
                          color: TacticalTheme.slate500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Post More Options (내가 쓴 글: 수정/삭제, 남의 글: 신고)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: TacticalTheme.slate400,
                  ),
                  color: TacticalTheme.slate800,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: TacticalTheme.slate700),
                  ),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showEditPostDialog();
                    } else if (action == 'delete') {
                      _showDeletePostDialog();
                    } else if (action == 'report') {
                      _showReportDialog(isPost: true);
                    }
                  },
                  itemBuilder: (ctx) {
                    if (isMyPost) {
                      return [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined,
                                  size: 16, color: TacticalTheme.slate300),
                              const SizedBox(width: 8),
                              Text(
                                isKo ? '수정하기' : 'Edit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  size: 16, color: TacticalTheme.red500),
                              const SizedBox(width: 8),
                              Text(
                                isKo ? '삭제하기' : 'Delete',
                                style: const TextStyle(
                                  color: TacticalTheme.red500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      return [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              const Icon(Icons.flag_outlined,
                                  size: 16, color: TacticalTheme.amber500),
                              const SizedBox(width: 8),
                              Text(
                                isKo ? '신고하기' : 'Report',
                                style: const TextStyle(
                                  color: TacticalTheme.amber500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Post Content (부드러운 펼침)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                contentText,
                maxLines: _isExpanded ? null : 3,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TacticalTheme.slate300,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ),

            // 3. '더보기' / '접기'
            if (isLongContent) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded
                            ? (isKo ? '접기' : 'Show less')
                            : (isKo ? '...더 보기' : '...More'),
                        style: const TextStyle(
                          color: TacticalTheme.amber500,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: TacticalTheme.amber500,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: TacticalTheme.slate700, height: 1),
            const SizedBox(height: 8),

            // 4. Action Bar (좋아요 & 댓글 토글 버튼)
            Row(
              children: [
                // Like Button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    ref
                        .read(boardPostsProvider.notifier)
                        .toggleLike(post.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_alt_outlined,
                          size: 16,
                          color: post.isLiked
                              ? TacticalTheme.amber500
                              : TacticalTheme.slate400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            color: post.isLiked
                                ? TacticalTheme.amber500
                                : TacticalTheme.slate400,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Comments Toggle Button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    final willOpen = !_isCommentsOpen;
                    setState(() {
                      _isCommentsOpen = willOpen;
                    });
                    if (willOpen && !post.isCommentsLoaded) {
                      ref
                          .read(boardPostsProvider.notifier)
                          .loadComments(post.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isCommentsOpen
                          ? TacticalTheme.amber500.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCommentsOpen
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: _isCommentsOpen
                              ? TacticalTheme.amber500
                              : TacticalTheme.slate400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isKo
                              ? '댓글 ${post.commentCount}'
                              : 'Comments ${post.commentCount}',
                          style: TextStyle(
                            color: _isCommentsOpen
                                ? TacticalTheme.amber500
                                : TacticalTheme.slate400,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isCommentsOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _isCommentsOpen
                              ? TacticalTheme.amber500
                              : TacticalTheme.slate400,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 5. Comments Section (스르륵 인라인 펼침)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isCommentsOpen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Divider(color: TacticalTheme.slate700, height: 1),
                        const SizedBox(height: 12),

                        // Comment List
                        if (post.comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              isKo
                                  ? '아직 댓글이 없습니다. 첫 댓글을 남겨보세요!'
                                  : 'No comments yet. Be the first to reply!',
                              style: const TextStyle(
                                color: TacticalTheme.slate500,
                                fontSize: 12.5,
                              ),
                            ),
                          )
                        else
                          ...post.comments.map(
                            (c) {
                              final isMyComment =
                                  c.displayId == currentDisplayId ||
                                      (c.author.isNotEmpty &&
                                          c.author ==
                                              (account.serverDisplayName ?? ''));

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
                                decoration: BoxDecoration(
                                  color: TacticalTheme.slate900,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: TacticalTheme.slate700,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.author,
                                          style: const TextStyle(
                                            color: TacticalTheme.amber500,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isMyComment) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            isKo ? '(나)' : '(me)',
                                            style: const TextStyle(
                                              color: TacticalTheme.slate500,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Text(
                                          c.date,
                                          style: const TextStyle(
                                            color: TacticalTheme.slate500,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                        const Spacer(),

                                        // Comment More Options (수정/삭제 or 신고)
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_horiz_rounded,
                                            size: 16,
                                            color: TacticalTheme.slate500,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          color: TacticalTheme.slate800,
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            side: const BorderSide(
                                              color: TacticalTheme.slate700,
                                            ),
                                          ),
                                          onSelected: (action) {
                                            if (action == 'edit') {
                                              _showEditCommentDialog(c);
                                            } else if (action == 'delete') {
                                              _showDeleteCommentDialog(c);
                                            } else if (action == 'report') {
                                              _showReportDialog(
                                                isPost: false,
                                                commentId: c.id,
                                              );
                                            }
                                          },
                                          itemBuilder: (ctx) {
                                            if (isMyComment) {
                                              return [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  height: 32,
                                                  child: Text(
                                                    isKo ? '수정' : 'Edit',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  height: 32,
                                                  child: Text(
                                                    isKo ? '삭제' : 'Delete',
                                                    style: const TextStyle(
                                                      color:
                                                          TacticalTheme.red500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ];
                                            } else {
                                              return [
                                                PopupMenuItem(
                                                  value: 'report',
                                                  height: 32,
                                                  child: Text(
                                                    isKo ? '신고' : 'Report',
                                                    style: const TextStyle(
                                                      color:
                                                          TacticalTheme.amber500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ];
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.content,
                                      style: const TextStyle(
                                        color: TacticalTheme.slate300,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 8),

                        // Inline Comment Input Field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: isKo
                                      ? '댓글을 입력하세요...'
                                      : 'Write a comment...',
                                  hintStyle: const TextStyle(
                                    color: TacticalTheme.slate500,
                                    fontSize: 12.5,
                                  ),
                                  filled: true,
                                  fillColor: TacticalTheme.slate900,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: TacticalTheme.slate700,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: TacticalTheme.slate700,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: TacticalTheme.amber500,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _submitComment(),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: TacticalTheme.amber500,
                                foregroundColor: TacticalTheme.slate900,
                                minimumSize: const Size(36, 36),
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.send_rounded, size: 16),
                              onPressed: _submitComment,
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
