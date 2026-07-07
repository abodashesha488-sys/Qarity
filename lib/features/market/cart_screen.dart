import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';
import 'cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get totalPrice {
    return Cart.instance.items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems => Cart.instance.distinctItemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          if (Cart.instance.items.isNotEmpty)
            IconButton(onPressed: _showClearDialog, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          final items = Cart.instance.items;
          if (items.isEmpty) return _buildEmptyCart();
          return Column(
            children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildCartItem(items[index], index),
              )),
              _buildCartSummary(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text('السلة فارغة', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('أضف منتجات من السوق لبدأ التسوق', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.marketProducts),
              icon: const Icon(Icons.store_rounded),
              label: const Text('تصفح المنتجات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => Cart.instance.remove(item.product),
      background: Container(
        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Hero(tag: 'cart_${item.product.id}', child: _buildProductImage(item, theme)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.product.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${item.product.effectivePrice.toStringAsFixed(0)} ج.م', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _buildQuantityControl(item, theme),
              const SizedBox(width: 12),
              Text('${item.totalPrice.toStringAsFixed(0)} ج.م', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 80).ms).fade(duration: 300.ms).slideX(begin: 0.05);
  }

  Widget _buildProductImage(CartItem item, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 66,
        height: 66,
        child: item.product.imageUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: item.product.imageUrl, fit: BoxFit.cover)
            : ColoredBox(color: theme.colorScheme.surfaceContainerHighest, child: Icon(Icons.image_outlined, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item, ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: () => Cart.instance.updateQuantity(item.product, item.quantity - 1), icon: const Icon(Icons.remove_rounded, size: 18), padding: const EdgeInsets.symmetric(horizontal: 6)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text('${item.quantity}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          IconButton(onPressed: () => Cart.instance.add(item.product), icon: const Icon(Icons.add_rounded, size: 18), padding: const EdgeInsets.symmetric(horizontal: 6)),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي المنتجات ($totalItems)', style: theme.textTheme.bodyMedium),
              Text('${totalPrice.toStringAsFixed(0)} ج.م', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الشحن', style: theme.textTheme.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withValues(alpha: 0.25))),
                child: Text('مجاني', style: theme.textTheme.labelSmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text('${totalPrice.toStringAsFixed(0)} ج.م', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('إنهاء الطلب (${Cart.instance.distinctItemCount} منتج)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearDialog() {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 32),
      title: Text('مسح السلة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      content: Text('هل أنت متأكد من مسح جميع المنتجات من السلة؟', style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () { Cart.instance.clear(); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
          child: const Text('مسح'),
        ),
      ],
    );
  }

  void _showClearDialog() {
    showDialog(context: context, builder: (context) => _buildClearDialog());
  }

  void _checkout() async {
    final items = Cart.instance.items;
    if (items.isEmpty) return;
    final orderService = OrderService();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final userService = UserService();
    final userModel = await userService.getUser(user?.uid ?? '');
    final buyerName = userModel?.name ?? user?.displayName ?? user?.email?.split('@').first ?? 'زائر';
    final buyerPhone = userModel?.phone ?? user?.phoneNumber ?? '';

    for (final item in items) {
      final sellerId = item.product.sellerId ?? '';
      if (sellerId.isEmpty) continue;

      final order = AppOrder(
        id: '',
        productId: item.product.id,
        productName: item.product.name,
        price: item.product.effectivePrice,
        quantity: item.quantity,
        buyerId: user?.uid ?? '',
        buyerName: buyerName,
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