import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _initSellerId();
  }

  Future<void> _initSellerId() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      setState(() => _sellerId = user.id);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث الحالة', style: GoogleFonts.cairo())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحديث: $e', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sellerId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات الواردة'), actions: CommonAppBarActions.actions(context)),
      body: StreamBuilder<List<AppOrder>>(
        stream: _orderService.getSellerOrdersStream(_sellerId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في التحميل', style: GoogleFonts.cairo()));
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(child: Text('لا توجد طلبات', style: GoogleFonts.cairo()));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildOrderCard(orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(AppOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        childrenPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: order.statusColor.withValues(alpha: 0.2),
          child: Icon(Icons.shopping_cart, color: order.statusColor),
        ),
        title: Text(order.productName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        subtitle: Text('من ${order.buyerName} • ${order.quantity} قطعة • ${order.price.toStringAsFixed(0)} ج.م', style: GoogleFonts.cairo(color: Colors.grey[600])),
        trailing: Chip(label: Text(order.statusLabel, style: GoogleFonts.cairo(color: order.statusColor, fontSize: 12))),
        children: [
          Row(children: [Text('العميل: ', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)), Text(order.buyerName)]),
          const SizedBox(height: 8),
          Row(children: [Text('هاتف العميل: ', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)), Text(order.buyerPhone)]),
          const SizedBox(height: 8),
          Row(children: [Text('الإجمالي: ', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)), Text('${order.price * order.quantity} ج.م', style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('تغيير الحالة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), _buildStatusDropdown(order)]),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(AppOrder order) {
    return DropdownButton<String>(
      value: order.status,
      items: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
      onChanged: (v) => v != null ? _updateStatus(order.id, v) : null,
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