import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
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
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final seller = args is Map<String, String>
        ? args
        : {'name': 'بائع محلي', 'phone': ''};
    final name = seller['name'] ?? 'بائع محلي';
    final phone = seller['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        child: Text(
                          name.isNotEmpty ? name[0] : 'ب',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(phone, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                            if (_reviewCount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_avgRating',
                                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '($_reviewCount مراجعة)',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.photo_library_rounded,
                          label: 'المعرض',
                          color: theme.colorScheme.primary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.marketSellerGallery,
                            arguments: {'name': name},
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.reviews_rounded,
                          label: 'المراجعات',
                          color: theme.colorScheme.secondary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.marketSellerReviews,
                            arguments: {'name': name, 'phone': phone},
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
              Expanded(
                child: _buildContactButton(
                  context,
                  icon: Icons.call_rounded,
                  label: 'اتصال',
                  color: Colors.green,
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: phone);
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  context,
                  icon: Icons.message_rounded,
                  label: 'رسالة',
                  color: Colors.blue,
                  onTap: () async {
                    final uri = Uri(scheme: 'sms', path: phone);
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactButton(
            context,
            icon: Icons.copy_rounded,
            label: 'نسخ الرقم',
            color: theme.colorScheme.primaryContainer,
            textColor: theme.colorScheme.primary,
            onTap: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم نسخ الرقم'),
                  backgroundColor: theme.colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, {required IconData icon, required String label, required Color color, Color? textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor ?? color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor ?? color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}