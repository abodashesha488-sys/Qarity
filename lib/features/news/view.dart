import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/data_models.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';

class NewsViewScreen extends StatefulWidget {
  const NewsViewScreen({super.key});

  @override
  State<NewsViewScreen> createState() => _NewsViewScreenState();
}

class _NewsViewScreenState extends State<NewsViewScreen> {
  late NewsItem news;
  int _likes = 0;
  bool _isLiked = false;
  final TextEditingController _commentController = TextEditingController();
  final NewsService _newsService = NewsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void didChangeDependencies() {
    news = ModalRoute.of(context)!.settings.arguments as NewsItem;
    _likes = news.likes;
    super.didChangeDependencies();
  }

  void _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _newsService.likeNews(news.id, userId: user.uid);
    setState(() {
      _isLiked = !_isLiked;
      _likes = _isLiked ? _likes + 1 : _likes - 1;
    });
  }

  void _addComment() {
    if (_commentController.text.isEmpty) return;
    _newsService.addComment(news.id, _auth.currentUser?.displayName ?? 'زائر', _commentController.text);
    _commentController.clear();
  }

  void _shareNews() async {
    final text = '${news.title}\n${news.subtitle}';
    await launchUrl(Uri.parse('https://t.me/share/url?url=$text'));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(news.title), actions: CommonAppBarActions.actions(context)),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (news.imageUrls.isNotEmpty)
            Stack(alignment: Alignment.bottomCenter, children: [
              SizedBox(height: 220, child: PageView.builder(itemBuilder: (context, i) => CachedNetworkImage(imageUrl: news.imageUrls[i], fit: BoxFit.cover, width: double.infinity), itemCount: news.imageUrls.length)),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(news.imageUrls.length, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)))))
            ])
          else if (news.imageUrl.isNotEmpty)
            CachedNetworkImage(imageUrl: news.imageUrl, height: 220, fit: BoxFit.cover, width: double.infinity),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(news.category, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 12),
            Text(news.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 10),
            Text(news.subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            Row(children: [
              Text('بواسطة: ${news.authorName ?? 'محرر النظام'}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              const Spacer(),
              StreamBuilder<DocumentSnapshot>(
                stream: _auth.currentUser != null ? FirebaseFirestore.instance.collection('news').doc(news.id).snapshots() : null,
                builder: (context, snapshot) {
                  final likedBy = snapshot.hasData ? List<String>.from((snapshot.data?.data() as Map<String, dynamic>?)?['likedBy'] as List<dynamic>? ?? []) : [];
                  final isLiked = likedBy.contains(_auth.currentUser?.uid);
                  return TextButton.icon(onPressed: _auth.currentUser != null ? _toggleLike : null, icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red), label: Text('${news.likes + (isLiked ? 1 : 0)}'));
                },
              ),
              TextButton.icon(onPressed: _shareNews, icon: const Icon(Icons.share), label: const Text('مشاركة')),
              Text('${news.views} مشاهدة', style: const TextStyle(color: AppColors.textTertiary)),
            ]),
            const SizedBox(height: 8),
            Text(news.date, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ])),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const Padding(padding: EdgeInsets.all(16), child: Text('التعليقات', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(stream: _newsService.getCommentsStream(news.id), builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final comments = snapshot.data?.docs ?? [];
              if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات', style: TextStyle(color: Colors.grey)));
              return ListView.builder(itemCount: comments.length, itemBuilder: (context, index) => ListTile(title: Text(comments[index]['userName'] as String, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(comments[index]['text'] as String)));
            }),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Expanded(child: TextField(controller: _commentController, decoration: InputDecoration(hintText: 'أضف تعليق...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))))),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
          ])),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}