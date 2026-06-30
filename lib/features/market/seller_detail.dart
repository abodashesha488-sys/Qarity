import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/review_service.dart';
import '../../widgets/common_appbar_actions.dart';

class SellerDetailScreen extends StatefulWidget {
  const SellerDetailScreen({super.key});

  @override
  State<SellerDetailScreen> createState() => _SellerDetailScreenState();
}

class _SellerDetailScreenState extends State<SellerDetailScreen> {
  final ReviewService _reviewService = ReviewService();
  double _avgRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSellerData());
  }

  Future<void> _loadSellerData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final seller = args is Map<String, String> ? args : {'name': 'بائع محلي', 'phone': ''};
    final sellerKey = seller['phone']?.isNotEmpty == true ? seller['phone']! : seller['name']!;

    final avg = await _reviewService.getSellerAverageRating(sellerKey);
    final count = await _reviewService.getReviewCount(sellerKey);

    if (!mounted) return;
    setState(() {
      _avgRating = avg;
      _reviewCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final seller = args is Map<String, String>
        ? args
        : {'name': 'بائع محلي', 'phone': ''};
    final name = seller['name'] ?? 'بائع محلي';
    final phone = seller['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: CommonAppBarActions.actions(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(name.isNotEmpty ? name[0] : 'ب'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          if (_reviewCount > 0) ...[
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < _avgRating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_avgRating • $_reviewCount مراجعات',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'معرض البائع',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/market/seller/gallery',
                      arguments: {'name': name},
                    );
                  },
                  icon: const Icon(Icons.photo_library),
                ),
                IconButton(
                  tooltip: 'مراجعات البائع',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/market/seller/reviews',
                      arguments: {'name': name, 'phone': phone},
                    );
                  },
                  icon: const Icon(Icons.reviews),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: phone);
                try {
                  await launchUrl(uri);
                } catch (_) {}
              },
              icon: const Icon(Icons.call),
              label: const Text('اتصال'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri(scheme: 'sms', path: phone);
                try {
                  await launchUrl(uri);
                } catch (_) {}
              },
              icon: const Icon(Icons.message),
              label: const Text('إرسال رسالة'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('تم نسخ الرقم')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('نسخ الرقم'),
            ),
          ],
        ),
      ),
    );
  }
}