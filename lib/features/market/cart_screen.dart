import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';
import 'cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> get _cartItems => Cart.instance.items;

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems => Cart.instance.totalItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السلة'),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _showClearDialog()),
        ],
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(_cartItems[index], index),
                  ),
                ),
                _buildCartSummary(),
              ],
            ),
      bottomNavigationBar: _cartItems.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _checkout,
                  child: Text('إنهاء الطلب ($totalItems منتج)', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('السلة فارغة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('أضف منتجات من السوق لبدأ التسوق', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('تصفح المنتجات')),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => Cart.instance.remove(item.product),
      background: Container(
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: item.product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: item.product.imageUrl, fit: BoxFit.cover)
                      : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.product.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${item.product.price.toStringAsFixed(0)} ج.م', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => Cart.instance.add(item.product),
                  ),
                  Text('${item.quantity}', style: Theme.of(context).textTheme.titleSmall),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () => Cart.instance.updateQuantity(item.product, item.quantity - 1),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${item.totalPrice.toStringAsFixed(0)} ج.م', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ).animate(delay: (index * 100).ms).fade(duration: 300.ms).slideX(begin: 0.1),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي المنتجات ($totalItems)', style: Theme.of(context).textTheme.bodyMedium),
              Text('${totalPrice.toStringAsFixed(0)} ج.م', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الشحن', style: Theme.of(context).textTheme.bodyMedium),
              Text('مجاني', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('$totalPrice ج.م', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح السلة'),
        content: const Text('هل أنت متأكد من مسح جميع المنتجات من السلة؟'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () { Cart.instance.clear(); Navigator.pop(context); }, child: const Text('مسح')),
        ],
      ),
    );
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;
    final orderService = OrderService();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final userService = UserService();
    final userModel = await userService.getUser(user?.uid ?? '');
    final buyerPhone = user?.phoneNumber ?? userModel?.phone ?? '';

    for (final item in _cartItems) {
      final sellerId = item.product.sellerId ?? '';
      if (sellerId.isEmpty) continue;

      final order = AppOrder(
        id: '',
        productId: item.product.id,
        productName: item.product.name,
        price: item.product.effectivePrice,
        quantity: item.quantity,
        buyerId: user?.uid ?? '',
        buyerName: user?.displayName ?? user?.email?.split('@').first ?? 'زائر',
        buyerPhone: buyerPhone,
        sellerId: sellerId,
        createdAt: DateTime.now(),
      );
      await orderService.createOrder(order);
    }

    Cart.instance.clear();
    if (mounted) {
      AppHelpers.showSnackBar(context, 'تم إرسال الطلبات بنجاح! شكراً لك', isSuccess: true);
    }
  }
}