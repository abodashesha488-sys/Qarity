import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/eshterili_model.dart';
import '../services/eshterili_service.dart';
import '../services/user_service.dart';
import 'commercial_receipt_dialog.dart';

/// نافذة خدمة «إشتريلي» للمستخدم: تسجيل طلب شراء جديد ومتابعة الطلبات الجارية وأكواد التسليم
class EshteriliOrderSheet extends StatefulWidget {
  const EshteriliOrderSheet({super.key});

  @override
  State<EshteriliOrderSheet> createState() => _EshteriliOrderSheetState();
}

class _EshteriliOrderSheetState extends State<EshteriliOrderSheet> with SingleTickerProviderStateMixin {
  final EshteriliService _service = EshteriliService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final TabController _tabController;
  final TextEditingController _itemsCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController();
  final TextEditingController _storeCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _userName = '';
  String _userPhone = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initUserData();
  }

  Future<void> _initUserData() async {
    final user = await _userService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user.name;
        _userPhone = user.phone ?? '';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemsCtrl.dispose();
    _budgetCtrl.dispose();
    _storeCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً لإرسال الطلب', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final items = _itemsCtrl.text.trim();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة الأصناف والمشتريات المطلوبة', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final budget = double.tryParse(_budgetCtrl.text.trim()) ?? 0.0;
      await _service.createOrder(
        userId: uid,
        userName: _userName.isNotEmpty ? _userName : 'أحد أهالي القرية',
        userPhone: _userPhone,
        itemsDescription: items,
        estimatedBudget: budget,
        storeOrArea: _storeCtrl.text.trim().isEmpty ? 'حسب الأنسب للمندوب' : _storeCtrl.text.trim(),
        deliveryAddress: _addressCtrl.text.trim().isEmpty ? 'داخل القرية' : _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );

      _itemsCtrl.clear();
      _budgetCtrl.clear();
      _storeCtrl.clear();
      _addressCtrl.clear();
      _notesCtrl.clear();

      setState(() {
        _isSubmitting = false;
        _tabController.animateTo(1); // الانتقال لتبويب طلباتي
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('تم إرسال طلبك للمندوب بنجاح! سيتم تسعيره وإبلاغك فوراً ✅', style: TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب: $e', style: const TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = _auth.currentUser?.uid ?? '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // شريط السحب والمقبض
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ترويسة خدمة إشتريلي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خدمة إشتريلي (مندوبك بالقرية) 🛵',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                      ),
                      Text(
                        'شراء وتوصيل طلباتك من أي مكان لباب بيتك',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // التبويبات الداخلية: طلب جديد / طلباتي السابقة
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            tabs: const [
              Tab(icon: Icon(Icons.post_add_rounded, size: 18), text: 'طلب شراء جديد'),
              Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'متابعة طلباتي'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewOrderForm(theme),
                _buildMyOrdersList(theme, uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── تبويب 1: استمارة طلب شراء جديدة ─────────────────────────
  Widget _buildNewOrderForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اكتب أي طلبات أو مشتريات تحتاجها بالتفصيل وسيقوم المندوب بتسعيرها وتوصيلها لك.',
                    style: TextStyle(fontSize: 11.5, fontFamily: 'Cairo', height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // تفاصيل المشتريات
          TextField(
            controller: _itemsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'قائمة المشتريات والطلبات المطلوبة بالتفصيل *',
              hintText: 'مثال: علبة دواء كذا من صيدلية المركز، ومستلزمات مكتبية، وكيلو حلويات...',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),

          // الميزانية المتوقعة
          TextField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'الميزانية التقديرية المتوقعة (جنيه تقريباً)',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              suffixText: 'ج.م',
            ),
          ),
          const SizedBox(height: 12),

          // مكان الشراء المفضل
          TextField(
            controller: _storeCtrl,
            decoration: const InputDecoration(
              labelText: 'مكان أو محل الشراء المفضل (اختياري)',
              hintText: 'مثال: صيدلية كذا بالمركز / سوبر ماركت بالقرية / محل محدد...',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),

          // عنوان التوصيل
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              labelText: 'عنوان أو مكان التوصيل بالقرية *',
              hintText: 'مثال: بجوار المسجد الكبير، منزل فلان...',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),

          // ملاحظات إضافية
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'أي ملاحظات أو تعليمات خاصة للمندوب',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isSubmitting ? null : _submitOrder,
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: const Text(
              'إرسال الطلب للمندوب للتسعير والتنفيذ 🚀',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── تبويب 2: قائمة طلباتي ومتابعتها ─────────────────────────
  Widget _buildMyOrdersList(ThemeData theme, String uid) {
    if (uid.isEmpty) {
      return const Center(child: Text('يرجى تسجيل الدخول أولاً لمتابعة طلباتك', style: TextStyle(fontFamily: 'Cairo')));
    }

    return StreamBuilder<List<EshteriliOrder>>(
      stream: _service.watchMyOrders(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('ليس لديك أي طلبات سابقة في إشتريلي', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('أرسل أول طلب الآن 🛵', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildOrderCard(theme, orders[i]),
        );
      },
    );
  }

  Widget _buildOrderCard(ThemeData theme, EshteriliOrder order) {
    final isPriced = order.status == EshteriliStatus.pricedWaitingApproval;
    final isInProgress = order.status == EshteriliStatus.inProgress;
    final isCompleted = order.status == EshteriliStatus.completed;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPriced
              ? const Color(0xFFD97706)
              : (isInProgress ? const Color(0xFF2563EB) : (isCompleted ? const Color(0xFF16A34A) : Colors.grey.withValues(alpha: 0.3))),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ترويسة الكارت: رقم الفاتورة والحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Cairo'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                        : (isPriced ? const Color(0xFFD97706).withValues(alpha: 0.15) : const Color(0xFF2563EB).withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.labelArabic,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? const Color(0xFF16A34A)
                          : (isPriced ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // تفاصيل الطلب
            Text(
              order.itemsDescription,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            if (order.storeOrArea.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'المكان: ${order.storeOrArea}',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
              ),
            ],
            const SizedBox(height: 8),

            // الفاتورة والتسعير المحاسبي إن كان تم تسعيره
            if (order.isPriced) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('قيمة المشتريات:', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                        Text('${order.itemCost.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('رسوم الخدمة والعمولة:', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                        Text('${order.serviceFee.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('أجرة التوصيل:', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                        Text('${order.deliveryFee.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    const Divider(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي المطلوب:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} ج',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // كود الاستلام السري
            if (isInProgress || isPriced || isCompleted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('كود استلامك للمندوب عند التوصيل:', style: TextStyle(fontSize: 10, color: Color(0xFF92400E), fontFamily: 'Cairo')),
                          Text(
                            order.claimCode,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      const Chip(
                        label: Text('مُستلم ✅', style: TextStyle(fontSize: 10, color: Colors.green, fontFamily: 'Cairo')),
                        backgroundColor: Color(0xFFDCFCE7),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => CommercialReceiptDialog.showEshteriliReceipt(
                  context,
                  order: order,
                ),
                icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF2563EB)),
                label: const Text(
                  'طباعة ومشاركة فاتورة الطلب 🖨️',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // إجراءات العميل في حال انتظار موافقته على السعر
            if (isPriced) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                      onPressed: () => _service.approvePricedOrder(order.id),
                      child: const Text('موافق على السعر، ابدأ الشراء ✅', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _service.cancelOrder(order.id),
                    child: const Text('إلغاء الطلب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
