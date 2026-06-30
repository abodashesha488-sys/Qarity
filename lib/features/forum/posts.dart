import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../main.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ForumPostsScreen extends StatefulWidget {
  const ForumPostsScreen({super.key});

  @override
  State<ForumPostsScreen> createState() => _ForumPostsScreenState();
}

class _ForumPostsScreenState extends State<ForumPostsScreen> {
  final ForumService _forumService = ForumService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'الكل';
  String _searchQuery = '';
  String _currentUserId = '';
  String _currentUserName = '';

  static const List<String> _filters = ['الكل', 'الأحدث', 'الأكثر إعجاباً'];

  @override
  void initState() {
    super.initState();
    _initUser();
    _initNotifications();
  }

  Future<void> _initUser() async {
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

  void _initNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'like') {
        final content = message.data['title'] as String? ?? 'منشور جديد';
        final ctx = navigatorKey.currentContext;
        if (ctx != null && mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('إعجاب جديد على منشور: $content')));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنتدى المجتمعي'), actions: CommonAppBarActions.actions(context)),
      floatingActionButton: FloatingActionButton.extended(icon: const Icon(Icons.add_rounded), label: const Text('موضوع جديد'), onPressed: () => Navigator.pushNamed(context, AppRoutes.forumCreatePost)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: 'ابحث في المواضيع...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest))),
        const SizedBox(height: 8),
        SizedBox(height: 44, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filters.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, index) => ChoiceChip(label: Text(_filters[index]), selected: _selectedFilter == _filters[index], onSelected: (_) => setState(() => _selectedFilter = _filters[index]), selectedColor: Theme.of(context).colorScheme.primary))),
        const SizedBox(height: 8),
        Expanded(child: StreamBuilder<List<ForumPost>>(stream: _forumService.getPostsStream(), builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error, color: Colors.grey), SizedBox(height: 8), Text('خطأ في التحميل')]));
          var posts = snapshot.data ?? [];
          if (_searchQuery.isNotEmpty) posts = posts.where((p) => p.userName.contains(_searchQuery) || p.content.contains(_searchQuery)).toList();
          if (posts.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.forum_rounded, size: 80, color: Colors.grey[300]), const SizedBox(height: 16), const Text('لا توجد مواضيع بعد', style: TextStyle(color: Colors.grey)), Text('كن أول من يبدأ موضوعاً', style: TextStyle(color: Colors.grey[600]))]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: posts.length, itemBuilder: (context, index) => _buildPostCard(context, posts[index]));
        })),
      ]),
    );
  }

  Widget _buildPostCard(BuildContext context, ForumPost post) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.forumPostDetail, arguments: post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(backgroundImage: post.userPhotoUrl.isNotEmpty ? NetworkImage(post.userPhotoUrl) : null, radius: 24, child: post.userPhotoUrl.isEmpty ? const Icon(Icons.person) : null),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(post.userName, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)), Text(_formatDate(post.createdAt), style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11))])),
              ]),
              const SizedBox(height: 12),
              Text(post.content, style: GoogleFonts.cairo(fontSize: 15, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: post.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  IconButton(onPressed: () => _toggleLike(post), icon: Icon(_isPostLiked(post) ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: Colors.blue), padding: EdgeInsets.zero),
                  Text('${post.likes}', style: GoogleFonts.cairo()),
                  const SizedBox(width: 4),
                  IconButton(onPressed: () => _showComments(context, post), icon: const Icon(Icons.chat_bubble, color: Colors.grey), padding: EdgeInsets.zero),
                  Text('${post.comments}', style: GoogleFonts.cairo(color: Colors.grey)),
                ]),
                Row(children: [Text('${post.views} مشاهدة', style: GoogleFonts.cairo(color: Colors.grey)), const Icon(Icons.bookmark_border, size: 18)]),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPostLiked(ForumPost post) {
    return _currentUserId.isNotEmpty && post.likedBy.contains(_currentUserId);
  }

  Future<void> _toggleLike(ForumPost post) async {
    if (_currentUserId.isEmpty) return;
    try {
      final wasLiked = post.likedBy.contains(_currentUserId);
      await _forumService.toggleLike(post.id, _currentUserId);
      setState(() {
        final updatedLikedby = List<String>.from(post.likedBy);
        if (wasLiked) {
          updatedLikedby.remove(_currentUserId);
        } else {
          updatedLikedby.add(_currentUserId);
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإعجاب: $e')));
    }
  }

  void _showComments(BuildContext context, ForumPost post) {
    showModalBottomSheet(context: context, builder: (context) => CommentsSheet(post: post, forumService: _forumService, currentUserName: _currentUserName));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return '${diff.inHours} ساعة';
    if (diff.inDays < 7) return '${diff.inDays} يوم';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CommentsSheet extends StatefulWidget {
  final ForumPost post;
  final ForumService forumService;
  final String currentUserName;

  const CommentsSheet({super.key, required this.post, required this.forumService, required this.currentUserName});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [Positioned(bottom: 0, left: 0, right: 0, child: Container(color: Theme.of(context).scaffoldBackgroundColor, padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: _buildCommentsContent()))]);
  }

  Widget _buildCommentsContent() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.all(16), child: Text(widget.post.content, style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
      const Divider(height: 1),
      SizedBox(
        height: 300,
        child: StreamBuilder<QuerySnapshot>(stream: widget.forumService.getCommentsStream(widget.post.id), builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final comments = snapshot.data?.docs ?? [];
          if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات'));
          return ListView.builder(itemCount: comments.length, itemBuilder: (context, index) {
            final c = comments[index];
            return ListTile(title: Text(c['userName'] as String? ?? 'مستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.w500)), subtitle: Text(c['text'] as String? ?? '', style: GoogleFonts.cairo()));
          });
        }),
      ),
      Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _commentController, decoration: InputDecoration(hintText: 'أضف تعليق...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))), IconButton(icon: const Icon(Icons.send), onPressed: _addComment)])),
    ]);
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      await widget.forumService.addComment(widget.post.id, widget.currentUserName, _commentController.text);
      _commentController.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }
}