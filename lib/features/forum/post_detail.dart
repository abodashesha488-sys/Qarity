import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    post = ModalRoute.of(context)!.settings.arguments as ForumPost;
    _likes = post.likes;
    _isLiked = post.likedBy.contains(_currentUserId);
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
    return Scaffold(
      appBar: AppBar(title: Text(post.userName), actions: CommonAppBarActions.actions(context)),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [CircleAvatar(backgroundImage: post.userPhotoUrl.isNotEmpty ? NetworkImage(post.userPhotoUrl) : null, radius: 28, child: post.userPhotoUrl.isEmpty ? const Icon(Icons.person) : null), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(post.userName, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16)), Text(_formatDate(post.createdAt), style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12))])]),
          const SizedBox(height: 16),
          Text(post.content, style: GoogleFonts.cairo(fontSize: 16, height: 1.4)),
          const SizedBox(height: 12),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: post.imageUrl!, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          Row(children: [TextButton.icon(onPressed: _toggleLike, icon: Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, color: Colors.blue), label: Text('$_likes', style: GoogleFonts.cairo())), TextButton.icon(onPressed: null, icon: const Icon(Icons.chat_bubble), label: Text('${post.comments}', style: GoogleFonts.cairo())), Text('${post.views} مشاهدة', style: GoogleFonts.cairo(color: Colors.grey))]),
          const Divider(height: 1),
          Text('التعليقات', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(stream: _forumService.getCommentsStream(post.id), builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('خطأ');
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final comments = snapshot.data?.docs ?? [];
            if (comments.isEmpty) return const Text('لا توجد تعليقات', style: TextStyle(color: Colors.grey));
            return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: comments.length, itemBuilder: (context, index) => ListTile(title: Text(comments[index]['userName'] as String, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)), subtitle: Text(comments[index]['text'] as String, style: GoogleFonts.cairo())));
          }),
        ])),
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(controller: _commentController, decoration: InputDecoration(hintText: 'أضف تعليق...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.send), onPressed: _addComment)])),
      ]),
    );
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