import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/product_interaction_service.dart';
import '../../widgets/common_appbar_actions.dart';
import 'cart.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  MarketProduct? _product;
  bool _loading = true;
  final TextEditingController _commentController = TextEditingController();
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final ProductInteractionService _interactionService = ProductInteractionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MarketService _marketService = MarketService();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MarketProduct) {
      setState(() {
        _product = args;
        _loading = false;
      });
    } else if (args is String) {
      final product = await _marketService.getProductById(args);
      setState(() {
        _product = product;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_product == null) return const Scaffold(body: Center(child: Text('المنتج غير موجود')));

    return Scaffold(
      appBar: AppBar(title: Text(_product!.name), actions: CommonAppBarActions.actions(context)),
      body: ListView(children: [
        if (_product!.imageUrls.isNotEmpty) ...[
          Stack(alignment: Alignment.bottomCenter, children: [
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _product!.imageUrls.length,
                itemBuilder: (context, index) => CachedNetworkImage(
                  imageUrl: _product!.imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                onPageChanged: (index) => setState(() => _currentPage = index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _product!.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? AppColors.primary : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ] else if (_product!.imageUrl.isNotEmpty) ...[
          CachedNetworkImage(imageUrl: _product!.imageUrl, height: 280, fit: BoxFit.cover, width: double.infinity),
        ],
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(_product!.name, style: Theme.of(context).textTheme.headlineMedium)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(_product!.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary))),
          ]),
          const SizedBox(height: 8),
          Text('${_product!.price.toStringAsFixed(0)} ج.م', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [const Icon(Icons.star, color: Colors.amber, size: 18), const SizedBox(width: 4), Text('4.5 (120 مشتريات', style: Theme.of(context).textTheme.bodyMedium)]),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.store, size: 18), const SizedBox(width: 8), Text(_product!.sellerName, style: Theme.of(context).textTheme.bodyMedium)]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.phone, size: 16), const SizedBox(width: 8), Text(_product!.sellerPhone, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]))]),
          const SizedBox(height: 12),
          Text(_product!.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الكمية', style: Theme.of(context).textTheme.titleMedium), Row(children: [IconButton(icon: const Icon(Icons.remove), onPressed: () { if (_quantity > 1) setState(() => _quantity--); }), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('$_quantity', style: Theme.of(context).textTheme.titleMedium)), IconButton(icon: const Icon(Icons.add), onPressed: () { setState(() => _quantity++); })])]))),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [StreamBuilder<DocumentSnapshot>(stream: _auth.currentUser != null ? FirebaseFirestore.instance.collection('market_products').doc(_product!.id).snapshots() : null, builder: (context, snapshot) { final likedBy = snapshot.hasData ? List<String>.from((snapshot.data?.data() as Map<String, dynamic>?)?['likedBy'] as List<dynamic>? ?? []) : []; final isLiked = likedBy.contains(_auth.currentUser?.uid); return TextButton.icon(onPressed: _auth.currentUser != null ? _toggleLike : null, icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red), label: Text('${_product!.likes + (isLiked ? 1 : 0)}')); }), TextButton.icon(onPressed: _shareProduct, icon: const Icon(Icons.share), label: const Text('مشاركة')), Text('${_product!.reviewCount} تقييم', style: Theme.of(context).textTheme.bodyMedium)])),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('التعليقات', style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 8),
          SizedBox(height: 200, child: StreamBuilder<List<Map<String, dynamic>>>(stream: _interactionService.getCommentsStream(_product!.id), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); final comments = snapshot.data ?? []; if (comments.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد تعليقات', style: TextStyle(color: Colors.grey))); return ListView.builder(itemCount: comments.length, itemBuilder: (context, index) => ListTile(title: Text(comments[index]['userName'] as String, style: TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(comments[index]['text'] as String))); })),
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: TextField(controller: _commentController, decoration: InputDecoration(hintText: 'أضف تعليق...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))), IconButton(icon: const Icon(Icons.send), onPressed: _addComment)])),
        ])),
      ]),
      bottomNavigationBar: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -4))]), child: Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.marketCart), child: Text('السلة (${Cart.instance.totalItems})'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _addToCart, child: const Text('أضف إلى السلة')))])),
    );
  }

  void _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _interactionService.toggleLike(productId: _product!.id, userId: user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الإعجاب: $e')));
    }
  }

  void _shareProduct() async {
    final text = '${_product!.name}\n${_product!.description}\n${_product!.price} ج.م';
    await launchUrl(Uri.parse('https://t.me/share/url?url=$text'));
  }

  void _addComment() {
    if (_commentController.text.isEmpty || _auth.currentUser == null) return;
    _interactionService.addComment(productId: _product!.id, userName: _auth.currentUser!.displayName ?? 'زائر', text: _commentController.text);
    _commentController.clear();
  }

  void _addToCart() {
    if (_product == null) return;
    for (var i = 0; i < _quantity; i++) {
      Cart.instance.add(_product!);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة إلى السلة')));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}