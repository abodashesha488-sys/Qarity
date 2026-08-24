import 'package:flutter/material.dart';

import '../../models/data_models.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();
  String? _sellerId;
  late Stream<List<AppOrder>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _initSellerId();
  }

  Future<void> _initSellerId() async {
    final user = await _userService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _sellerId = user.id;
        _ordersStream = _orderService.getSellerOrdersStream(_sellerId!);
      });
    }
  }

  Future<void> _refresh() async {
    if (_sellerId == null) return;
    setState(() {
      _ordersStream = _orderService.getSellerOrdersStream(_sellerId!);
    });
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الحالة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحديث: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_sellerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('الطلبات الواردة'),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: theme.colorScheme.surface,
          actions: CommonAppBarActions.actions(context),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات الواردة'),
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
        child: StreamBuilder<List<AppOrder>>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 56, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('تعذر تحميل الطلبات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
                    ],
                  ),
                ),
              );
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('لا توجد طلبات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildOrderCard(orders[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(AppOrder order) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          childrenPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: order.statusColor.withValues(alpha: 0.2),
            child: Icon(Icons.shopping_cart, color: order.statusColor),
          ),
          title: Text(order.productName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          subtitle: Text('من ${order.buyerName} • ${order.quantity} قطعة • ${order.price.toStringAsFixed(0)} ج.م', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          trailing: Chip(
            label: Text(order.statusLabel, style: theme.textTheme.labelSmall?.copyWith(color: order.statusColor, fontWeight: FontWeight.w800)),
            backgroundColor: order.statusColor.withValues(alpha: 0.12),
            side: BorderSide(color: order.statusColor.withValues(alpha: 0.3)),
            padding: EdgeInsets.zero,
          ),
          children: [
            Row(children: [Text('العميل: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), Expanded(child: Text(order.buyerName, style: theme.textTheme.bodyMedium))]),
            const SizedBox(height: 8),
            Row(children: [Text('هاتف العميل: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), Expanded(child: Text(order.buyerPhone, style: theme.textTheme.bodyMedium))]),
            const SizedBox(height: 8),
            Row(children: [Text('الإجمالي: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), Text('${order.price * order.quantity} ج.م', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('تغيير الحالة', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)), _buildStatusDropdown(order)]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(AppOrder order) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: DropdownButton<String>(
        value: order.status,
        underline: const SizedBox.shrink(),
        items: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
        onChanged: (v) => v != null ? _updateStatus(order.id, v) : null,
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'processing': return 'قيد المعالجة';
      case 'shipped': return 'تم الشحن';
      case 'delivered': return 'تم التسليم';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}
