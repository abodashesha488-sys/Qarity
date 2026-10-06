import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/utils/comment_style.dart';
import '../../services/review_service.dart';
import '../../widgets/qurity_app_bar.dart';

class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  String? _sellerId;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, String>) {
      _sellerId = args['name']?.isNotEmpty == true ? args['name'] : args['phone'];
      _loadReviews();
    }
    super.didChangeDependencies();
  }

  Future<void> _loadReviews() async {
    if (_sellerId == null) return;
    setState(() => _isLoading = true);
    final reviews = await _reviewService.getSellerReviews(_sellerId!);
    if (!mounted) return;
    setState(() {
      _reviews = reviews.map((r) => r.toJson()).toList();
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final name = args is Map<String, String> ? (args['name'] ?? 'البائع') : 'البائع';

    return Scaffold(
      appBar: QurityAppBar(title: '$name — المراجعات'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.colorScheme.primary,
        child: _isLoading
            ? ListView(children: const [SizedBox(height: 120), Center(child: CircularProgressIndicator(strokeWidth: 2))])
            : _reviews.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('لا توجد مراجعات بعد', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildReviewCard(theme, _reviews[index]),
                  ),
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme, Map<String, dynamic> r) {
    final rating = (r['rating'] as int?) ?? 0;
    final photo = (r['userPhotoUrl'] as String? ?? '').trim();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: CommentStyle.avatarRadius,
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      backgroundImage: photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                      child: photo.isEmpty
                          ? Icon(Icons.person, size: 20, color: theme.colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      r['userName'] ?? 'مستخدم',
                      style: CommentStyle.author(context),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  )),
                ),
              ],
            ),
            if ((r['comment'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                r['comment'] as String,
                style: CommentStyle.body(context),
              ),
            ],
            _buildDateRow(theme, r['createdAt']),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(ThemeData theme, dynamic timestamp) {
    String dateText = '';
    if (timestamp != null) {
      if (timestamp is Timestamp) {
        dateText = timestamp.toDate().toString().split(' ')[0];
      }
    }
    if (dateText.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(dateText, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
