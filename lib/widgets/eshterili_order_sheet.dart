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

/// 🛵 نافذة خدمة «إشتريلي» للمستخدم
///
/// مصممة ببساطة وسلاسة لتناسب كافة ثقافات ومستويات المستخدمين:
/// 1. الشاشة الرئيسية: نبذة تعريفية منسقة وشرح للخدمة + زر "طلب شراء جديد" + زر "متابعة طلباتي".
/// 2. شاشة إدخال الطلب: نموذج مبسط يقتصر على البنود والكمية، الاسم ورقم الهاتف والعنوان فقط.
/// 3. شاشة متابعة الطلبات: كروت عمليات موجزة تعرض (حالة العملية - تاريخ العملية - رقم العملية - مبلغ العملية)
///    وعند النقر على الكارت تُفتح التفاصيل الكاملة والفاتورة وكود الاستلام.
class EshteriliOrderSheet extends StatefulWidget {
  const EshteriliOrderSheet({
    super.key,
    this.initialView = 0,
    this.service,
    this.userService,
    this.currentUserId,
  });

  /// 0: شاشة التفاصيل والنبذة التعريفية (الافتراضية)
  /// 1: استمارة طلب شراء جديد المبسطة
  /// 2: متابعة طلباتي (قائمة كروت العمليات)
  final int initialView;

  /// خدمة إشتريلي (تسمح بالحقن للاختبارات)
  final EshteriliService? service;

  /// خدمة المستخدم (تسمح بالحقن للاختبارات)
  final UserService? userService;

  /// معرّف المستخدم الحالي (تسمح بالحقن للاختبارات)
  final String? currentUserId;

  @override
  State<EshteriliOrderSheet> createState() => _EshteriliOrderSheetState();
}

class _EshteriliOrderSheetState extends State<EshteriliOrderSheet> {
  late final EshteriliService _service;

  late int _currentView; // 0: نبذة وأزرار رئيسية, 1: طلب جديد مبسط, 2: متابعة طلباتي
  final TextEditingController _itemsCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  String? _uploadedImageUrl;
  bool _isSubmitting = false;

  String get _currentUid {
    if (widget.currentUserId != null && widget.currentUserId!.isNotEmpty) {
      return widget.currentUserId!;
    }
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? EshteriliService();
    _currentView = widget.initialView;
    _initUserData();
  }

  Future<void> _initUserData() async {
    try {
      final userSvc = widget.userService ?? UserService();
      final user = await userSvc.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          if (_nameCtrl.text.isEmpty) _nameCtrl.text = user.name;
          if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = user.phone ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _itemsCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h =
        (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$d/$m/$y • $h:$min $period';
  }

  void _reorderPrevious(EshteriliOrder order) {
    setState(() {
      _itemsCtrl.text = order.itemsDescription;
      if (order.deliveryAddress.isNotEmpty) {
        _addressCtrl.text = order.deliveryAddress;
      }
      _currentView = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF2563EB),
        content: Text(
          'تم نسخ طلبك السابق إلى استمارة الشراء بنجاح 📝',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً لإرسال الطلب',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final items = _itemsCtrl.text.trim();
    if (items.isEmpty &&
        (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'يرجى كتابة الطلبات المطلوبة أو إرفاق صورة الروشتة/الورقة',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم صاحب الطلب',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم الهاتف للتواصل',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة عنوان أو مكان التوصيل بالقرية',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.createOrder(
        userId: uid,
        userName: name,
        userPhone: phone,
        itemsDescription: items.isNotEmpty ? items : 'طلب شراء مرفق بالصورة 📸',
        estimatedBudget: 0.0,
        storeOrArea: 'حسب الأنسب للمندوب',
        deliveryAddress: address,
        imageUrl: _uploadedImageUrl ?? '',
        imageUrls: _uploadedImageUrl != null ? [_uploadedImageUrl!] : const [],
      );

      _itemsCtrl.clear();
      _uploadedImageUrl = null;

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _currentView = 2; // الانتقال مباشرة لشاشة متابعة طلباتي
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text(
              'تم إرسال طلبك للمندوب بنجاح! جاري التجهيز والتوصيل والحساب عند الاستلام 🛵',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال الطلب: $e',
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = _currentUid;

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
          // مقبض السحب العلوي
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // المحتوى التفاعلي حسب الشاشة الحالية
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentViewContent(theme, uid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentViewContent(ThemeData theme, String uid) {
    switch (_currentView) {
      case 1:
        return _buildNewOrderView(theme);
      case 2:
        return _buildMyOrdersView(theme, uid);
      case 0:
      default:
        return _buildLandingView(theme, uid);
    }
  }

  // ───────────────────────── 1. الشاشة الافتتاحية: نبذة وشرح + زران ─────────────────────────
  Widget _buildLandingView(ThemeData theme, String uid) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ترويسة الشاشة
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خدمة إشتريلي (مندوب القرية) 🛵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'اطلب أي حاجة من أي مكان والدفع عند الاستلام',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
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

        const Divider(height: 1),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // كارت النبذة التعريفية والشرح المنسق والحديث
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E3A8A),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              const Color(0xFFEFF6FF),
                              const Color(0xFFDBEAFE),
                            ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(
                      color: const Color(0xFF2563EB)
                          .withValues(alpha: isDark ? 0.4 : 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB)
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delivery_dining_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مندوب قرية أبودشيشة للشراء والتوصيل',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                  ),
                                ),
                                Text(
                                  'خدمتك الخاصة لشراء وتوصيل كافة الاحتياجات',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'خدمة مجتمعية مخصصة لأهالي قرية أبودشيشة لشراء أي مستلزمات أو طلبات من داخل القرية أو من الصيدليات والمحلات والأسواق بالقرى والمراكز المجاورة (بلقاس، المعصرة، الستاموني...). ينطلق المندوب لشرائها فوراً وتوصيلها حتى باب منزلك مع إرفاق فاتورة المحل الورقية الأصلية، والدفع كاش عند المعاينة والاستلام حسب سعر البائع الفعلي دون أي زيادة.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          height: 1.55,
                          color: isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF1E3A8A),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // رقائق المزايا
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildLandingPill(
                            icon: Icons.bolt_rounded,
                            title: 'توصيل فوري',
                            subtitle: 'بدون انتظار تسعير',
                            color: const Color(0xFF2563EB),
                            isDark: isDark,
                          ),
                          _buildLandingPill(
                            icon: Icons.receipt_long_rounded,
                            title: 'فاتورة المحل الأصلية',
                            subtitle: 'مطابقة الأسعار الفعلية',
                            color: const Color(0xFF16A34A),
                            isDark: isDark,
                          ),
                          _buildLandingPill(
                            icon: Icons.home_rounded,
                            title: 'لباب منزلك',
                            subtitle: 'معاينة ودفع عند الاستلام',
                            color: const Color(0xFFD97706),
                            isDark: isDark,
                          ),
                          _buildLandingPill(
                            icon: Icons.vpn_key_rounded,
                            title: 'كود تسليم آمن',
                            subtitle: 'حماية وأمان لطلبك',
                            color: const Color(0xFF7C3AED),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 1. زر طلب شراء جديد
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => setState(() => _currentView = 1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'طلب شراء جديد ➕',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. زر متابعة طلباتي
                StreamBuilder<List<EshteriliOrder>>(
                  stream: uid.isNotEmpty
                      ? _service.watchMyOrders(uid)
                      : const Stream.empty(),
                  builder: (context, snap) {
                    final ordersCount = snap.data?.length ?? 0;
                    final activeCount = snap.data
                            ?.where(
                                (o) => o.status == EshteriliStatus.inProgress)
                            .length ??
                        0;

                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(
                            color: Color(0xFF2563EB), width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => setState(() => _currentView = 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            activeCount > 0
                                ? 'متابعة طلباتي ($activeCount جاري 🛵)'
                                : (ordersCount > 0
                                    ? 'متابعة طلباتي ($ordersCount)'
                                    : 'متابعة طلباتي 📦'),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandingPill({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── 2. استمارة طلب شراء جديد المبسطة ─────────────────────────
  Widget _buildNewOrderView(ThemeData theme) {
    return Column(
      children: [
        // ترويسة الشاشة مع زر رجوع
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'رجوع للرئيسية',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => setState(() => _currentView = 0),
              ),
              const Expanded(
                child: Text(
                  'طلب شراء جديد 📝',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // رسالة توجيهية بسيطة ومريحة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          color: Color(0xFF2563EB), size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'اكتب ما تحتاجه ببساطة كما تطلب من صديقك، ومندوبنا سينطلق لشرائه وتوصيله لباب بيتك مع فاتورة المحل 🛵',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 1. حقل البنود المطلوبة والكمية
                TextField(
                  controller: _itemsCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'قائمة الطلبات والكميات المطلوبة *',
                    hintText:
                        'مثال: 2 كيلو طماطم، علبة دواء بنادول أزرق، 3 زجاجات عصير، كيس مسحوق غسيل...',
                    labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                    hintStyle: const TextStyle(
                        fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 8),

                // زر بسيط وإضافي لتصوير ورقة أو روشتة
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final url = await pickAndUploadImage(context,
                        current: _uploadedImageUrl);
                    if (url != null && mounted) {
                      setState(() => _uploadedImageUrl = url);
                    }
                  },
                  icon: Icon(
                    _uploadedImageUrl != null
                        ? Icons.check_circle_rounded
                        : Icons.camera_alt_outlined,
                    size: 18,
                    color: _uploadedImageUrl != null
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2563EB),
                  ),
                  label: Text(
                    _uploadedImageUrl != null
                        ? 'تم إرفاق صورة الطلب / الروشتة (تغيير الصورة)'
                        : '📸 أو صوّر ورقة الطلبات / الروشتة (اختياري)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _uploadedImageUrl != null
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),

                if (_uploadedImageUrl != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppImageCache.image(
                          url: _uploadedImageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'الصورة مرفقة ومجهزة لتسليمها للمندوب ✅',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'حذف الصورة',
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () =>
                            setState(() => _uploadedImageUrl = null),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // 2. حقل الاسم (مملوء تلقائياً وقابل للتعديل)
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم صاحب الطلب *',
                    labelStyle:
                        const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. حقل رقم التليفون (مملوء تلقائياً وقابل للتعديل)
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف للتواصل *',
                    labelStyle:
                        const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. حقل عنوان ومكان التوصيل
                TextField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'عنوان أو مكان التوصيل بالقرية *',
                    hintText:
                        'مثال: بجوار المسجد الكبير، منزل فلان، شارع كذا...',
                    labelStyle:
                        const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    hintStyle: const TextStyle(
                        fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 20),

                // زر تأكيد وإرسال الطلب
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _submitOrder,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text(
                    'إرسال الطلب للمندوب الآن 🛵',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── 3. شاشة متابعة طلباتي (كروت العمليات الموجزة) ─────────────────────────
  Widget _buildMyOrdersView(ThemeData theme, String uid) {
    if (uid.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('يرجى تسجيل الدخول أولاً لمتابعة طلباتك',
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => setState(() => _currentView = 0),
              child: const Text('رجوع للرئيسية',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ترويسة شاشة متابعة طلباتي مع زر رجوع وزر طلب جديد
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'رجوع للرئيسية',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => setState(() => _currentView = 0),
              ),
              const Expanded(
                child: Text(
                  'متابعة طلباتي 📦',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _currentView = 1),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'طلب جديد',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: StreamBuilder<List<EshteriliOrder>>(
            stream: _service.watchMyOrders(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 54, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'ليس لديك أي طلبات سابقة في إشتريلي',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'اطلب أي مشتريات وسيقوم مندوب القرية بتلبيتها فوراً.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => setState(() => _currentView = 1),
                          icon: const Icon(Icons.add_shopping_cart_rounded,
                              size: 18),
                          label: const Text('أرسل أول طلب الآن 🛵',
                              style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // قائمة كروت العمليات الموجزة
              return ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildOrderSummaryCard(theme, orders[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// كارت العملية الموجز والمرتب:
  /// يحتوي فقط على: (حالة العملية - تاريخ العملية - رقم العملية - مبلغ العملية)
  Widget _buildOrderSummaryCard(ThemeData theme, EshteriliOrder order) {
    final isCompleted = order.status == EshteriliStatus.completed;
    final isCancelled = order.status == EshteriliStatus.cancelled;
    final isInProgress = order.status == EshteriliStatus.inProgress;

    final Color statusColor = isCompleted
        ? const Color(0xFF16A34A)
        : (isCancelled ? Colors.red : const Color(0xFF2563EB));

    final String statusLabel = isCompleted
        ? 'تم التسليم بنجاح ✅'
        : (isCancelled ? 'ملغي ❌' : 'جاري الشراء والتوصيل 🛵');

    final String priceText = order.totalAmount > 0
        ? '${order.totalAmount.toStringAsFixed(0)} ج'
        : 'حسب فاتورة المحل 🧾';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      elevation: isInProgress ? 2 : 1,
      child: InkWell(
        onTap: () => _showOrderDetailSheet(context, theme, order),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: isInProgress ? 0.6 : 0.3),
              width: isInProgress ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. رقم العملية وحالة العملية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tag_rounded, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 2. تاريخ العملية ومبلغ العملية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(order.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          size: 15, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        priceText,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: order.totalAmount > 0
                              ? const Color(0xFF16A34A)
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // 3. تلميح النقر للتفاصيل
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.itemsDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _reorderPrevious(order),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.replay_rounded, size: 13, color: Color(0xFF2563EB)),
                              SizedBox(width: 3),
                              Text(
                                'إعادة الطلب 🔄',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        children: [
                          Text(
                            'تفاصيل العملية 👈',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded,
                              size: 16, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── 4. شيت تفاصيل العملية بالكامل ─────────────────────────
  void _showOrderDetailSheet(
      BuildContext context, ThemeData theme, EshteriliOrder order) {
    final isCompleted = order.status == EshteriliStatus.completed;
    final isCancelled = order.status == EshteriliStatus.cancelled;
    final isInProgress = order.status == EshteriliStatus.inProgress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تفاصيل العملية (${order.orderNumber})',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // مؤشر التتبع المباشر
                      if (!isCancelled) ...[
                        _buildLiveOrderStepper(order),
                        const SizedBox(height: 16),
                      ],

                      // كارت تفاصيل البنود والكميات
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 6),
                                Text(
                                  'الطلبات والكميات المطلوبة:',
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              order.itemsDescription,
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                            if (order.deliveryAddress.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'التوصيل إلى: ${order.deliveryAddress}',
                                      style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // الصورة المرفوعة من العميل إن وجدت
                      if (order.imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showImageZoomDialog(context,
                              order.imageUrl, 'صورة الطلب / الروشتة 📸'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppImageCache.image(
                                    url: order.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'معاينة صورة الطلب أو الروشتة المرفقة 📸',
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.zoom_in_rounded,
                                    size: 20, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // فاتورة المحل الأصلية المرفقة من المندوب
                      if (order.receiptImageUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showImageZoomDialog(context,
                              order.receiptImageUrl, 'فاتورة المحل الأصلية 🧾'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppImageCache.image(
                                    url: order.receiptImageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'فاتورة المحل الورقية الأصلية 🧾',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      Text(
                                        'انقر لمعاينة صورة فاتورة المشتريات ومطابقة الأسعار',
                                        style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 10,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.zoom_in_rounded,
                                    size: 22, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // كود الاستلام السري
                      if (!isCancelled) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFD97706)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.vpn_key_rounded,
                                  color: Color(0xFFD97706), size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'كود استلامك للمندوب عند التوصيل:',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF92400E),
                                          fontFamily: 'Cairo'),
                                    ),
                                    Text(
                                      order.claimCode,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCompleted)
                                const Chip(
                                  label: Text('مُستلم ✅',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontFamily: 'Cairo')),
                                  backgroundColor: Color(0xFFDCFCE7),
                                ),
                            ],
                          ),
                        ),
                      ],

                      // بيانات المندوب إن وُجد
                      if (order.assignedAgentPhone.isNotEmpty &&
                          !isCompleted &&
                          !isCancelled) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF16A34A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF16A34A)
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF16A34A),
                                child: Icon(Icons.delivery_dining_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'المندوب: ${order.assignedAgentName.isNotEmpty ? order.assignedAgentName : 'مندوب القرية'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          fontFamily: 'Cairo'),
                                    ),
                                    Text(order.assignedAgentPhone,
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'اتصال هاتفي',
                                icon: const Icon(Icons.phone_in_talk_rounded,
                                    color: Color(0xFF16A34A), size: 20),
                                onPressed: () =>
                                    launchPhoneCall(order.assignedAgentPhone),
                              ),
                              IconButton(
                                tooltip: 'واتساب',
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 20),
                                onPressed: () {
                                  final waUrl = egyptianWhatsAppUrl(
                                      order.assignedAgentPhone);
                                  if (waUrl != null) launchWhatsAppUrl(waUrl);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // الحساب المالي
                      const SizedBox(height: 12),
                      if (order.isPriced) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('قيمة المشتريات الفعلية:',
                                      style: TextStyle(
                                          fontSize: 11.5, fontFamily: 'Cairo')),
                                  Text('${order.itemCost.toStringAsFixed(0)} ج',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo')),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('أجرة التوصيل:',
                                      style: TextStyle(
                                          fontSize: 11.5, fontFamily: 'Cairo')),
                                  Text(
                                      '${(order.deliveryFee + order.serviceFee).toStringAsFixed(0)} ج',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo')),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الإجمالي عند الاستلام:',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo')),
                                  Text(
                                    '${order.totalAmount.toStringAsFixed(0)} ج',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF16A34A),
                                        fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'الدفع كاش عند الاستلام والمعاينة حسب فاتورة المحل الورقية + رسوم التوصيل 🧾',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // زر إعادة طلب نفس الاحتياجات بنقرة واحدة
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reorderPrevious(order);
                        },
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: const Text(
                          'إعادة طلب نفس الاحتياجات بنقرة واحدة 🔄',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // زر محادثة واتساب المباشرة
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final phone = order.assignedAgentPhone.isNotEmpty
                              ? order.assignedAgentPhone
                              : '01061730076';
                          final text =
                              'السلام عليكم، بخصوص طلبي في خدمة إشتريلي رقم (${order.orderNumber})...';
                          final wa = egyptianWhatsAppUrl(phone);
                          if (wa != null) {
                            launchWhatsAppUrl(
                                '$wa?text=${Uri.encodeComponent(text)}');
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                        label: Text(
                          order.assignedAgentPhone.isNotEmpty
                              ? 'محادثة المندوب (${order.assignedAgentName.isNotEmpty ? order.assignedAgentName : 'مندوب القرية'}) واتساب 💬'
                              : 'تواصل واتساب مع إدارة التوصيل 💬',
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // زر طباعة ومشاركة الفاتورة
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () =>
                            CommercialReceiptDialog.showEshteriliReceipt(
                          context,
                          order: order,
                        ),
                        icon: const Icon(Icons.print_rounded,
                            size: 18, color: Color(0xFF2563EB)),
                        label: const Text(
                          'طباعة ومشاركة فاتورة الطلب 🖨️',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      if (isInProgress) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('إلغاء الطلب',
                                style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 11.5)),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _confirmCancelOrder(order);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveOrderStepper(EshteriliOrder order) {
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
            backgroundColor:
                isDone ? const Color(0xFF16A34A) : Colors.grey.shade300,
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
        title: const Text('إلغاء طلب الشراء',
            style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الإلغاء',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _service.cancelOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إلغاء الطلب بنجاح',
                  style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }

  void _showImageZoomDialog(
      BuildContext context, String imageUrl, String title) {
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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
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
