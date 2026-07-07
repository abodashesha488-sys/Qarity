import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ForumPostDetailScreen extends StatefulWidget {
  const ForumPostDetailScreen({super.key});

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  late ForumPost post;
  int _likes = 0;
  bool _isLiked = false;
  final TextEditingController _commentController = TextEditingController();
  final ForumService _forumService = ForumService();
  String _currentUserId = '';
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = FirebaseAuth.instance;
    final userService = UserService();
    final user = auth.currentUser;
    if (user != null) {
      final userModel = await userService.getUser(user.uid);
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = userModel?.name ?? user.displayName ?? 'مستخدم';
      });
    }
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ForumPost) {
      post = args;
    }
    _isLiked = _currentUserId.isNotEmpty && post.likedBy.contains(_currentUserId);
    super.didChangeDependencies();
  }

  void _toggleLike() {
    if (_currentUserId.isEmpty) return;
    setState(() {
      _isLiked = !_isLiked;
      _likes = _isLiked ? _likes + 1 : _likes - 1;
    });
    _forumService.toggleLike(post.id, _currentUserId);
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty && _currentUserId.isNotEmpty) {
      _forumService.addComment(post.id, _currentUserName, _commentController.text);
      _commentController.clear();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              backgroundImage: post.userPhotoUrl.isNotEmpty ? NetworkImage(post.userPhotoUrl) : null,
                              child: post.userPhotoUrl.isEmpty ? Icon(Icons.person_rounded, color: theme.colorScheme.primary) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.userName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(AppHelpers.formatRelativeDate(post.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(post.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(imageUrl: post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatChip(context, Icons.visibility_rounded, '${post.views} مشاهدة', theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 12),
                            _buildStatChip(context, Icons.comment_rounded, '${post.comments} تعليق', theme.colorScheme.onSurfaceVariant),
                            const Spacer(),
                            InkWell(
                              onTap: _toggleLike,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isLiked ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined, color: _isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant, size: 18),
                                    const SizedBox(width: 6),
                                    Text('$_likes', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: _isLiked ? Colors.red : theme.colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Text('التعليقات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: _forumService.getCommentsStream(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text('خطأ', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error));
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    final comments = snapshot.data?.docs ?? [];
                    if (comments.isEmpty) return Center(child: Text('لا توجد تعليقات بعد', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)));
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5), radius: 18, child: Icon(Icons.person_rounded, size: 16, color: theme.colorScheme.primary)),
                            title: Text(comment['userName'] as String? ?? 'زائر', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                            subtitle: Text(comment['text'] as String? ?? '', style: theme.textTheme.bodySmall),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'أضف تعليق...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                  style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}