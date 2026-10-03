import 'package:flutter/material.dart';

import '../../services/market_service.dart';
import '../../widgets/image_gallery_wrap.dart';
import '../../widgets/qurity_app_bar.dart';

class SellerGalleryScreen extends StatefulWidget {
  const SellerGalleryScreen({super.key});

  @override
  State<SellerGalleryScreen> createState() => _SellerGalleryScreenState();
}

class _SellerGalleryScreenState extends State<SellerGalleryScreen> {
  final MarketService _marketService = MarketService();
  List<String> _images = [];
  bool _isLoading = true;
  String _sellerId = '';

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    final seller = args is Map<String, String> ? args : <String, String>{};
    _sellerId = seller['sellerId'] ?? '';
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    if (_sellerId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final products = await _marketService.getProductsBySeller(_sellerId);
    final images = <String>[];
    for (final p in products) {
      images.addAll(p.imageUrls);
      if (p.imageUrl.isNotEmpty) images.add(p.imageUrl);
    }
    if (!mounted) return;
    setState(() {
      _images = images;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadGallery();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final seller = args is Map<String, String> ? args : <String, String>{};
    final name = seller['name'] ?? 'بائع محلي';

    return Scaffold(
      appBar: QurityAppBar(title: '$name — معرض الصور'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.colorScheme.primary,
        child: _isLoading
            ? ListView(children: const [SizedBox(height: 120), Center(child: CircularProgressIndicator(strokeWidth: 2))])
            : _images.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('لا توجد صور للعرض', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final tile = (constraints.maxWidth - 24 - 12) / 2;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: ImageGalleryWrap(
                          urls: _images,
                          tileWidth: tile,
                          radius: 16,
                          spacing: 12,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
