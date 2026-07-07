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

  void _loadReviews() async {
    if (_sellerId == null) return;
    final reviews = await _reviewService.getSellerReviews(_sellerId!);
    setState(() {
      _reviews = reviews.map((r) => r.toJson()).toList();
      _isLoading = false;
    });
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
    );
  }
}
