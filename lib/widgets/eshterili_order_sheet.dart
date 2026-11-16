import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../core/utils/contact_links.dart';
import '../core/utils/launch_link.dart';
import '../features/village/village_content_admin.dart';
import '../models/eshterili_model.dart';
import '../services/eshterili_service.dart';
import '../services/user_service.dart';
import 'commercial_receipt_dialog.dart';

/// نافذة خدمة «إشتريلي» للمستخدم: تسجيل طلب شراء جديد ومتابعة الطلبات الجارية وأكواد التسليم
/// (مستوحى من معايير تطبيقات التوصيل العالمية السريعة بدون انتظار تسعير)
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

  String? _uploadedImageUrl;
  String _userName = '';
  String _userPhone = '';
  bool _isSubmitting = false;

  static const List<String> _quickStoreChips = [
    'صيدليات القرية',
    'سوبرماركت وبقالة',
    'محلات بلقاس',
    'المعصرة',
    'مكتبة وأدوات',
    'جزارة ولحوم',
    'خضار وفواكه',
    'قطع غيار',
  ];

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
    if (items.isEmpty && (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة الأصناف المطلوبة أو إرفاق صورة الروشتة/الطلبات', style: TextStyle(fontFamily: 'Cairo'))),
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
        itemsDescription: items.isNotEmpty ? items : 'طلب شراء مرفق بالصورة 📸',
        estimatedBudget: budget,
        storeOrArea: _storeCtrl.text.trim().isEmpty ? 'حسب الأنسب للمندوب' : _storeCtrl.text.trim(),
        deliveryAddress: _addressCtrl.text.trim().isEmpty ? 'داخل القرية' : _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        imageUrl: _uploadedImageUrl ?? '',
        imageUrls: _uploadedImageUrl != null ? [_uploadedImageUrl!] : const [],
      );

      _itemsCtrl.clear();
      _budgetCtrl.clear();
      _storeCtrl.clear();
      _addressCtrl.clear();
      _notesCtrl.clear();
      _uploadedImageUrl = null;

      setState(() {
        _isSubmitting = false;
        _tabController.animateTo(1); // الانتقال لتبويب طلباتي
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('تم إرسال طلبك للمندوب بنجاح! جاري التجهيز والتوصيل والحساب عند الاستلام 🛵', style: TextStyle(fontFamily: 'Cairo')),
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
                        'اشتري أي حاجة من أي مكان والدفع عند الاستلام',
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
                Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'توصيل فوري بدون انتظار تسعير: ينطلق المندوب لشراء طلبك مباشرة والدفع والاستلام حسب فاتورة المحل الفعلية.',
                    style: TextStyle(fontSize: 11.5, fontFamily: 'Cairo', height: 1.4, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // تفاصيل المشتريات
          TextField(
            controller: _itemsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'قائمة المشتريات والطلبات المطلوبة بالتفصيل *',
              hintText: 'مثال: علبة دواء كذا من الصيدلية، ومستلزمات من البقالة، وكيلو موز...',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          // إرفاق صورة أو روشتة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    const Text(
                      'إرفاق صورة للطلب (روشتة دواء / قائمة ورقية / صورة صنف):',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final url = await pickAndUploadImage(context, current: _uploadedImageUrl);
                        if (url != null && mounted) {
                          setState(() => _uploadedImageUrl = url);
                        }
                      },
                      icon: Icon(_uploadedImageUrl != null ? Icons.change_circle : Icons.upload_file, size: 16),
                      label: Text(
                        _uploadedImageUrl != null ? 'تغيير الصورة' : 'رفع صورة',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (_uploadedImageUrl != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppImageCache.image(
                          url: _uploadedImageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'تم إرفاق الصورة بنجاح وستُسلّم للمندوب مع الطلب ✅',
                          style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'حذف الصورة',
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => setState(() => _uploadedImageUrl = null),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // مكان الشراء المفضل واختيار سريع
          const Text(
            'مكان أو محل الشراء (اختر جهة سريعة أو اكتب المحل):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickStoreChips.map((chip) {
              final isSelected = _storeCtrl.text.trim() == chip;
              return ChoiceChip(
                label: Text(chip, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10.5)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _storeCtrl.text = selected ? chip : '';
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _storeCtrl,
            decoration: const InputDecoration(
              labelText: 'محل الشراء المحدد (أو حسب الأنسب للمندوب)',
              hintText: 'مثال: صيدلية كذا / محل فلان / بلقاس...',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
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

          // الميزانية المتوقعة
          TextField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'الميزانية التقديرية المتوقعة (اختياري)',
              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              suffixText: 'ج.م',
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
              'انطلق بالمندوب لشراء طلبي الآن 🛵',
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
    final isCompleted = order.status == EshteriliStatus.completed;
    final isCancelled = order.status == EshteriliStatus.cancelled;
    final isInProgress = order.status == EshteriliStatus.inProgress;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? const Color(0xFF16A34A)
              : (isCancelled
                  ? Colors.red.withValues(alpha: 0.4)
                  : const Color(0xFF2563EB)),
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
                        : (isCancelled ? Colors.red.withValues(alpha: 0.15) : const Color(0xFF2563EB).withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted
                        ? 'تم التسليم بنجاح ✅'
                        : (isCancelled ? 'ملغي' : 'جاري الشراء والتوصيل 🛵'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? const Color(0xFF16A34A)
                          : (isCancelled ? Colors.red : const Color(0xFF2563EB)),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // مؤشر التتبع المباشر (Order Tracker Stepper)
            if (!isCancelled) ...[
              _buildLiveOrderStepper(theme, order),
              const SizedBox(height: 12),
            ],

            // تفاصيل الطلب
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppImageCache.image(
                      url: order.imageUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.itemsDescription,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      if (order.storeOrArea.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'المكان: ${order.storeOrArea}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                        ),
                      ],
                      if (order.deliveryAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'التوصيل إلى: ${order.deliveryAddress}',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontFamily: 'Cairo'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // فاتورة المحل الورقية المرفقة من المندوب
            if (order.receiptImageUrl.isNotEmpty) ...[
              InkWell(
                onTap: () => _showReceiptPreviewDialog(context, order.receiptImageUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AppImageCache.image(
                          url: order.receiptImageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فاتورة المحل الأصلية المرفقة من المندوب 🧾',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo', color: Color(0xFF1D4ED8)),
                            ),
                            Text(
                              'انقر لمعاينة صورة فاتورة المشتريات ومطابقة الأسعار',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.zoom_in_rounded, size: 22, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // كود الاستلام السري
            if (!isCancelled) ...[
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
            ],

            // تفاصيل المندوب المكلف وإمكانية الاتصال المباشر به
            if (order.assignedAgentPhone.isNotEmpty && !isCompleted && !isCancelled) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المندوب المكلف: ${order.assignedAgentName.isNotEmpty ? order.assignedAgentName : 'مندوب القرية'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo'),
                          ),
                          Text(order.assignedAgentPhone, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'اتصال هاتفي بالمندوب',
                      icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF16A34A), size: 20),
                      onPressed: () => launchPhoneCall(order.assignedAgentPhone),
                    ),
                    IconButton(
                      tooltip: 'مراسلة واتساب',
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 20),
                      onPressed: () {
                        final waUrl = egyptianWhatsAppUrl(order.assignedAgentPhone);
                        if (waUrl != null) launchWhatsAppUrl(waUrl);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // الفاتورة والتسعير إن وجد
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
                        const Text('قيمة المشتريات الفعلية:', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                        Text('${order.itemCost.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('أجرة التوصيل:', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                        Text('${(order.deliveryFee + order.serviceFee).toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    const Divider(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي عند الاستلام:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} ج',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'الحساب والدفع عند الاستلام نقداً حسب فاتورة المحل الفعلية + أجرة التوصيل 🧾',
                        style: TextStyle(fontSize: 10.5, color: Colors.blue, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // زر طباعة ومشاركة الفاتورة
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

            if (isInProgress) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('إلغاء الطلب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  onPressed: () => _confirmCancelOrder(order),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveOrderStepper(ThemeData theme, EshteriliOrder order) {
    final step = order.status == EshteriliStatus.completed ? 3 : 2;

    return Row(
      children: [
        _buildStepNode(1, 'استلام الطلب 📝', true),
        _buildStepDivider(step >= 2),
        _buildStepNode(2, 'جاري الشراء والتوصيل 🛵', step >= 2),
        _buildStepDivider(step >= 3),
        _buildStepNode(3, 'تم التسليم ✅', step >= 3),
      ],
    );
  }

  Widget _buildStepNode(int index, String label, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isDone ? const Color(0xFF16A34A) : Colors.grey.shade300,
            child: Icon(
              isDone ? Icons.check : Icons.circle,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? const Color(0xFF16A34A) : Colors.grey,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isDone) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isDone ? const Color(0xFF16A34A) : Colors.grey.shade300,
    );
  }

  Future<void> _confirmCancelOrder(EshteriliOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء طلب الشراء', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _service.cancelOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الطلب بنجاح', style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }

  void _showReceiptPreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('فاتورة المحل الأصلية 🧾', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: InteractiveViewer(
                child: AppImageCache.image(
                  url: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
