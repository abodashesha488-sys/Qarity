import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../widgets/common_appbar_actions.dart';

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
      appBar: AppBar(
        title: Text('$name - المراجعات'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
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
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      child: Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      r['userName'] ?? 'مستخدم',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
              Text(r['comment'] as String, style: theme.textTheme.bodyMedium),
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
