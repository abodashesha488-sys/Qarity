import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  void _loadReviews() async {
    if (_sellerId == null) return;
    final reviews = await _reviewService.getSellerReviews(_sellerId!);
    setState(() {
      _reviews = reviews.map((r) => r.toJson()).toList();
      _isLoading = false;
    });
  }

  void _showAddReviewDialog() {
    final commentController = TextEditingController();
    int ratingValue = 5;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أضف مراجعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'ملاحظاتك'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < ratingValue ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => ratingValue = i + 1),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty || _sellerId == null) {
                Navigator.pop(context);
                return;
              }
              final user = _auth.currentUser;
              await _reviewService.addReview(
                sellerId: _sellerId!,
                rating: ratingValue,
                comment: commentController.text.trim(),
                userId: user?.uid ?? '',
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' - مراجعات'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text('لا توجد مراجعات بعد'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = _reviews[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r['userName'] ?? 'مستخدم',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < (r['rating'] as int) ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(r['comment'] ?? ''),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final timestamp = r['createdAt'];
                                String dateText = '';
                                if (timestamp != null) {
                                  if (timestamp is Timestamp) {
                                    dateText = timestamp.toDate().toString().split(' ')[0];
                                  }
                                }
                                if (dateText.isNotEmpty) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      dateText,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _auth.currentUser != null ? _showAddReviewDialog : null,
        icon: const Icon(Icons.rate_review),
        label: const Text('أضف مراجعة'),
      ),
    );
  }
}
