import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tactical_theme.dart';
import '../../providers/survival_providers.dart';
import 'community_board_screen.dart';

class BoardPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const BoardPostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<BoardPostDetailScreen> createState() =>
      _BoardPostDetailScreenState();
}

class _BoardPostDetailScreenState extends ConsumerState<BoardPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitComment(BoardPost post) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final account = ref.read(accountProvider);
    final authorName = account.serverDisplayName ??
        (account.isGoogleLinked && account.linkedEmail != null
            ? account.linkedEmail!.split('@').first
            : account.guestId);

    ref.read(boardPostsProvider.notifier).addComment(
          postId: post.id,
          author: authorName,
          content: text,
        );

    _commentController.clear();
    FocusScope.of(context).unfocus();

    // 스크롤 맨 아래 댓글로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKo = ref.watch(localeProvider).languageCode == 'ko';
    final allPosts = ref.watch(boardPostsProvider);
    final postIndex = allPosts.indexWhere((p) => p.id == widget.postId);

    if (postIndex == -1) {
      return Scaffold(
        backgroundColor: TacticalTheme.slate900,
        appBar: AppBar(
          title: Text(isKo ? '게시글 상세' : 'Post Detail'),
        ),
        body: Center(
          child: Text(
            isKo ? '게시글을 찾을 수 없습니다.' : 'Post not found.',
            style: const TextStyle(color: TacticalTheme.slate400),
          ),
        ),
      );
    }

    final post = allPosts[postIndex];

    return Scaffold(
      backgroundColor: TacticalTheme.slate900,
      appBar: AppBar(
        backgroundColor: TacticalTheme.slate900,
        title: Text(
          isKo ? '자유게시판' : 'Free Board',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Main Post Content + Comments List
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Post Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: TacticalTheme.slate800,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TacticalTheme.slate700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content Body
                      SelectableText(
                        post.content(isKo),
                        style: const TextStyle(
                          color: TacticalTheme.slate300,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Like & Comment Info Bar
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              ref
                                  .read(boardPostsProvider.notifier)
                                  .toggleLike(post.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: post.isLiked
                                    ? TacticalTheme.amber500.withOpacity(0.2)
                                    : TacticalTheme.slate900,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: post.isLiked
                                      ? TacticalTheme.amber500
                                      : TacticalTheme.slate700,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    post.isLiked
                                        ? Icons.thumb_up_rounded
                                        : Icons.thumb_up_outlined,
                                    size: 15,
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
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 16,
                                color: TacticalTheme.slate400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${post.comments.length}',
                                style: const TextStyle(
                                  color: TacticalTheme.slate400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Comments Section Header
                Row(
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 18,
                      color: TacticalTheme.amber500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isKo
                          ? '댓글 ${post.comments.length}개'
                          : 'Comments (${post.comments.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Comments List
                if (post.comments.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Text(
                      isKo
                          ? '첫 번째 댓글을 작성해보세요!'
                          : 'Be the first to comment!',
                      style: const TextStyle(
                        color: TacticalTheme.slate500,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...post.comments.map(
                    (comment) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TacticalTheme.slate800,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TacticalTheme.slate700),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.author,
                                style: const TextStyle(
                                  color: TacticalTheme.amber500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment.date,
                                style: const TextStyle(
                                  color: TacticalTheme.slate500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            comment.content,
                            style: const TextStyle(
                              color: TacticalTheme.slate300,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Comment Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).viewInsets.bottom > 0
                  ? MediaQuery.of(context).viewInsets.bottom + 10
                  : MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: TacticalTheme.slate800,
              border: const Border(
                top: BorderSide(color: TacticalTheme.slate700),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isKo ? '댓글을 입력하세요...' : 'Write a comment...',
                      hintStyle: const TextStyle(
                        color: TacticalTheme.slate500,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: TacticalTheme.slate900,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: TacticalTheme.slate700),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: TacticalTheme.slate700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: TacticalTheme.amber500),
                      ),
                    ),
                    maxLines: 1,
                    onSubmitted: (_) => _submitComment(post),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: TacticalTheme.amber500,
                    foregroundColor: TacticalTheme.slate900,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: () => _submitComment(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
