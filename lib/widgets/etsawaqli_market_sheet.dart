import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/contact_links.dart';
import '../core/utils/launch_link.dart';
import '../core/utils/phone_validator.dart';
import '../models/etsawaqli_model.dart';
import '../services/etsawaqli_service.dart';
import '../services/user_service.dart';
import 'commercial_receipt_dialog.dart';
import 'order_progress_stepper.dart';

/// 🧺 نافذة خدمة «إتسوقلي» للمستخدم
///
/// مصممة ببساطة وسلاسة لتناسب كافة ثقافات ومستويات المستخدمين:
/// 1. الشاشة الرئيسية: نبذة تعريفية راقية وشرح للخدمة + زر "قائمة المشتريات" + زر "سجل العمليات".
/// 2. قائمة المشتريات: اختيار السوق والأصناف والكميات مع إمكانية إضافة أصناف خاصة تعامل كالبنود الأصلية، وبيانات التوصيل.
/// 3. سجل العمليات: كروت عمليات ملخصة (حالة العملية - تاريخ العملية - رقم العملية - مبلغ العملية) مع فتح التفاصيل بدون كود تسليم.
class EtsawaqliMarketSheet extends StatefulWidget {
  const EtsawaqliMarketSheet({
    super.key,
    this.initialView = 0,
    this.service,
    this.userService,
    this.currentUserId,
    this.initialExpandIntro = false,
  });

  /// 0: شاشة التفاصيل والنبذة التعريفية (الافتراضية)
  /// 1: قائمة المشتريات واختيار السلع
  /// 2: سجل العمليات (كروت العمليات الموجزة)
  final int initialView;

  /// خدمة إتسوقلي (تسمح بالحقن للاختبارات)
  final EtsawaqliService? service;

  /// خدمة المستخدم (تسمح بالحقن للاختبارات)
  final UserService? userService;

  /// معرف المستخدم الحالي (تسمح بالحقن للاختبارات)
  final String? currentUserId;

  /// حالة فتح كارت النبذة التعريفية افتراضياً (افتراضياً مطوي لتوفير المساحة)
  final bool initialExpandIntro;

  @override
  State<EtsawaqliMarketSheet> createState() => _EtsawaqliMarketSheetState();
}

class _EtsawaqliMarketSheetState extends State<EtsawaqliMarketSheet> {
  late final EtsawaqliService _service;

  late int _currentView; // 0: نبذة وأزرار رئيسية, 1: قائمة المشتريات, 2: سجل العمليات
  late bool _isIntroExpanded;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // إدخال صنف خاص ليس بالقوائم
  final TextEditingController _customItemNameCtrl = TextEditingController();
  double _customItemQty = 1.0;
  String _customItemUnit = 'كيلو';

  bool _isSubmitting = false;

  EtsawaqliMarket? _selectedMarket;
  String _selectedCategory = 'الكل';
  final Map<String, double> _cartQuantities = {}; // productId -> quantity
  final Map<String, String> _cartNotes = {}; // productId -> notes
  final List<EtsawaqliCartItem> _customItems = []; // أصناف خاصة غير مقيدة بالقائمة الافتراضية

  final List<String> _categories = [
    'الكل',
    'خضروات',
    'فواكه',
    'دواجن',
    'لحوم',
    'أسماك',
    'ألبان وجبن',
  ];

  final List<String> _units = ['كيلو', 'نصف كيلو', 'ربطة', 'قفص / كرتونة', 'حبة / رأس'];

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
    _service = widget.service ?? EtsawaqliService();
    _currentView = widget.initialView;
    _isIntroExpanded = widget.initialExpandIntro;
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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _customItemNameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$d/$m/$y • $h:$min $period';
  }

  double _calculateItemsSubtotal(List<EtsawaqliProductItem> allProducts) {
    double sum = 0.0;
    for (final p in allProducts) {
      final q = _cartQuantities[p.id] ?? 0.0;
      if (q > 0) {
        sum += q * p.estimatedPrice;
      }
    }
    for (final c in _customItems) {
      sum += c.totalPrice;
    }
    return sum;
  }

  List<EtsawaqliCartItem> _buildCartItems(List<EtsawaqliProductItem> allProducts) {
    final list = <EtsawaqliCartItem>[];
    for (final p in allProducts) {
      final q = _cartQuantities[p.id] ?? 0.0;
      if (q > 0) {
        list.add(EtsawaqliCartItem(
          productId: p.id,
          productName: p.name,
          category: p.category,
          unit: p.unit,
          quantity: q,
          unitPrice: p.estimatedPrice,
          userNotes: _cartNotes[p.id] ?? '',
        ));
      }
    }
    list.addAll(_customItems);
    return list;
  }

  void _addCustomItemDirectly() {
    final name = _customItemNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة اسم الصنف المراد إضافته', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final newItem = EtsawaqliCartItem(
      productId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      productName: name,
      category: 'أصناف خاصة',
      unit: _customItemUnit,
      quantity: _customItemQty,
      unitPrice: 0.0, // يُحسب بسعر السوق الفعلي
      isCustom: true,
    );

    setState(() {
      _customItems.add(newItem);
      _customItemNameCtrl.clear();
      _customItemQty = 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        content: Text('تمت إضافة "$name" إلى قائمة مشترياتك بنجاح ✅', style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  void _reorderPrevious(EtsawaqliOrder order) {
    setState(() {
      for (final item in order.items) {
        if (item.isCustom) {
          final exists = _customItems.any((c) => c.productName == item.productName);
          if (!exists) {
            _customItems.add(item);
          }
        } else {
          _cartQuantities[item.productId] = item.quantity;
        }
      }
      if (order.deliveryAddress.isNotEmpty) {
        _addressCtrl.text = order.deliveryAddress;
      }
      _currentView = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16A34A),
        content: Text(
          'تم نسخ أصناف الشروة إلى سلة المشتريات بنجاح 🧺',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Future<void> _submitMarketOrder(List<EtsawaqliProductItem> allProducts) async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً لإرسال طلب التسوق', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final cartItems = _buildCartItems(allProducts);
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار أو إضافة صنف واحد على الأقل في قائمة المشتريات', style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم صاحب الطلب', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || !PhoneValidator.isValidEgyptianPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'يرجى إدخال رقم محمول مصري صحيح (11 رقماً يبدأ بـ 010 أو 011 أو 012 أو 015)',
                style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان أو مكان التوصيل بالقرية', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final market = _selectedMarket ?? EtsawaqliService.defaultMarkets.first;
    final subtotal = _calculateItemsSubtotal(allProducts);

    setState(() => _isSubmitting = true);
    try {
      await _service.createOrder(
        userId: uid,
        userName: name,
        userPhone: PhoneValidator.normalize(phone) ?? phone,
        marketId: market.id,
        marketName: market.name,
        marketDay: market.dayOfWeek,
        items: cartItems,
        itemsSubtotal: subtotal,
        serviceFee: market.serviceFee,
        deliveryFee: market.deliveryFee,
        deliveryAddress: address,
        notes: _notesCtrl.text.trim(),
      );

      _cartQuantities.clear();
      _cartNotes.clear();
      _customItems.clear();
      _notesCtrl.clear();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _currentView = 2; // الانتقال مباشرة لسجل العمليات
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text(
              'تم تسجيل طلب تسوقك بنجاح! ستتسوق المندوبة وتوصل لك يوم السوق حتى باب بيتك 🧺',
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
            content: Text('حدث خطأ أثناء تسجيل الطلب: $e', style: const TextStyle(fontFamily: 'Cairo')),
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
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // مقبض النافذة العلوي
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
        return _buildShoppingListView(theme);
      case 2:
        return _buildOrdersHistoryView(theme, uid);
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
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خدمة إتسوقلي (تسوق أسواق القرية) 🧺',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        ),
                    ),
                    Text(
                      'تسوق سوق الجمعة والأسواق المجاورة حتى باب منزلك',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
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
                // كارت النبذة التعريفية والشرح المنسق والحديث (قابل للطي لتوفير المساحة)
                Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF14532D),
                                const Color(0xFF0F172A),
                              ]
                            : [
                                const Color(0xFFF0FDF4),
                                const Color(0xFFDCFCE7),
                              ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha: isDark ? 0.4 : 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: isDark ? 0.2 : 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() => _isIntroExpanded = !_isIntroExpanded),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // الرأس الدائم مع زر التبديل القابل للطي
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shopping_basket_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'خدمة إتسوقلي — تسوق أسواق القرية والمراكز',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      Text(
                                        'خزين بيتك الأسبوعي بسعر السوق وتوصيل موفّر لباب بيتك',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF16A34A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // كبسولة إشارة الفتح والطي
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isIntroExpanded ? 'طي' : 'تفاصيل',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        _isIntroExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: const Color(0xFF16A34A),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // المحتوى القابل للطي
                            AnimatedCrossFade(
                              firstChild: const SizedBox(width: double.infinity, height: 0),
                              secondChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Divider(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 10),

                                  // الفقرة التعريفية المنسقة
                                  Text(
                                    'خدمتك المخصصة لتسوق الخضار والفواكه واللحوم والأسماك والدواجن والتموين الطازج من سوق الجمعة بأبودشيشة وأسواق المراكز المجاورة (بلقاس، المعصرة، الستاموني...). نوفر عليك عناء وتعب ومصاريف المشوار، مع انتقاء أجود البضائع الطازجة وتوصيلها حتى باب منزلك في مواعيد الأسواق أو فوراً، والدفع عند المعاينة والاستلام.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.5,
                                      color: isDark ? Colors.grey.shade300 : const Color(0xFF14532D),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // رقائق المزايا
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildLandingPill(
                                        icon: Icons.eco_rounded,
                                        title: 'أسعار السوق الحقيقية',
                                        subtitle: 'شراء بأسعار وتخفيضات السوق',
                                        color: const Color(0xFF16A34A),
                                        isDark: isDark,
                                      ),
                                      _buildLandingPill(
                                        icon: Icons.verified_rounded,
                                        title: 'تنقية وجودة ممتازة',
                                        subtitle: 'اختيار طازج ونضج يناسبك',
                                        color: const Color(0xFF2563EB),
                                        isDark: isDark,
                                      ),
                                      _buildLandingPill(
                                        icon: Icons.local_shipping_rounded,
                                        title: 'توصيل لباب بيتك',
                                        subtitle: 'استلام مريح دون تعب المشوار',
                                        color: const Color(0xFFD97706),
                                        isDark: isDark,
                                      ),
                                      _buildLandingPill(
                                        icon: Icons.payments_rounded,
                                        title: 'دفع عند الاستلام',
                                        subtitle: 'معاينة البضاعة والدفع كاش',
                                        color: const Color(0xFF7C3AED),
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              crossFadeState: _isIntroExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 280),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // 1. زر قائمة المشتريات
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                        'قائمة المشتريات 🧺',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. زر سجل العمليات
                StreamBuilder<List<EtsawaqliOrder>>(
                  stream: uid.isNotEmpty ? _service.watchMyOrders(uid) : const Stream.empty(),
                  builder: (context, snap) {
                    final ordersCount = snap.data?.length ?? 0;
                    final activeCount = snap.data?.where((o) => o.status == 'shopping' || o.status == 'delivering' || o.status == 'pending').length ?? 0;

                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                                ? 'سجل العمليات ($activeCount جاري 🧺)'
                                : (ordersCount > 0 ? 'سجل العمليات ($ordersCount)' : 'سجل العمليات 📜'),
                            style: const TextStyle(
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

  // ───────────────────────── 2. شاشة قائمة المشتريات واختيار السلع ─────────────────────────
  Widget _buildShoppingListView(ThemeData theme) {
    return StreamBuilder<List<EtsawaqliMarket>>(
      stream: _service.watchActiveMarkets(),
      builder: (context, marketsSnap) {
        final markets = marketsSnap.data ?? EtsawaqliService.defaultMarkets;
        _selectedMarket ??= markets.first;

        return StreamBuilder<List<EtsawaqliProductItem>>(
          stream: _service.watchProducts(),
          builder: (context, productsSnap) {
            final allProducts = productsSnap.data ?? EtsawaqliService.defaultProducts;
            var filteredProducts = _selectedCategory == 'الكل'
                ? allProducts
                : allProducts.where((p) => p.category == _selectedCategory).toList();
            if (_searchQuery.isNotEmpty) {
              filteredProducts = filteredProducts.where((p) {
                final matchName = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchCat = p.category.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchName || matchCat;
              }).toList();
            }

            final cartCount = _cartQuantities.values.where((q) => q > 0).length + _customItems.length;
            final subtotal = _calculateItemsSubtotal(allProducts);

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
                          'قائمة المشتريات 🧺',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (cartCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$cartCount صنف بالسلة',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
                    children: [
                      // 0. شريط ضمان الشفافية والثقة
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 18, color: Color(0xFF16A34A)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'أسعار السوق الفعلية يوم الشراء · انتقاء يدوي طازج · الدفع عند الاستلام',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 1. اختيار السوق المستهدف
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            const Text(
                              'سوق التسوق:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedMarket?.id ?? markets.first.id,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF16A34A)),
                                  items: markets.map((m) {
                                    return DropdownMenuItem<String>(
                                      value: m.id,
                                      child: Text(
                                        '${m.name} (${m.dayOfWeek})',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    if (id == null) return;
                                    setState(() {
                                      _selectedMarket = markets.firstWhere((m) => m.id == id);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 2. كارت إضافة صنف خاص ليس بالقوائم (يعامل تماماً كالبنود الأصلية)
                      _buildAddCustomItemCard(theme),

                      const SizedBox(height: 12),

                      // 3. شريط البحث السريع عن السلع
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (q) => setState(() => _searchQuery = q.trim()),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن سلعة (طماطم، خيار، لحم، فراخ، سمك...)...',
                          hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF16A34A)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 4. شريط تصفية التصنيفات
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: FilterChip(
                                label: Text(cat, style: const TextStyle(fontSize: 11)),
                                selected: isSel,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: const Color(0xFF16A34A).withValues(alpha: 0.18),
                                checkmarkColor: const Color(0xFF16A34A),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 5. الأصناف الخاصة المضافة (إن وُجدت) معروضة تماماً كالبنود
                      if (_customItems.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.stars_rounded, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text(
                              'أصنافي الخاصة المضافة (تعامل كبنود التطبيق):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ..._customItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final customItem = entry.value;
                          return _buildCustomCartItemTile(theme, customItem, idx);
                        }),
                        const SizedBox(height: 10),
                      ],

                      // 6. قائمة السلع والبنود
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'سلع السوق المقترحة:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              'نتائج البحث: ${filteredProducts.length}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (filteredProducts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'لم يتم العثور على سلع تطابق "$_searchQuery" — يمكنك إضافتها مباشرة كصنف خاص بالأعلى ☝️'
                                : 'لا توجد سلع مسجلة في هذا التصنيف حالياً',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            return _buildProductItemTile(theme, filteredProducts[i]);
                          },
                        ),

                      const SizedBox(height: 18),

                      // 6. سلة المشتريات وملخص الفاتورة
                      if (cartCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'إجمالي السلع التقديري ($cartCount صنف):',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  Text(
                                    subtotal > 0 ? '${subtotal.toStringAsFixed(0)} ج' : 'حسب سعر السوق الفعلي',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'رسوم التسوق: ${_selectedMarket?.serviceFee.toStringAsFixed(0) ?? '25'} ج • التوصيل: ${_selectedMarket?.deliveryFee.toStringAsFixed(0) ?? '15'} ج',
                                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 7. بيانات التوصيل الأساسية
                      const Text(
                        'بيانات التوصيل:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم صاحب الطلب *',
                          labelStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف للتواصل *',
                          labelStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'عنوان أو مكان التوصيل بالقرية *',
                          hintText: 'مثال: بجوار المسجد، منزل فلان...',
                          labelStyle: const TextStyle(fontSize: 12.5),
                          hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesCtrl,
                        decoration: InputDecoration(
                          labelText: 'أي ملاحظات خاصة أو تفضيل للجودة (اختياري)',
                          hintText: 'مثال: الطماطم جامدة للسلطة، الموز مستوي...',
                          labelStyle: const TextStyle(fontSize: 12),
                          hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // زر تأكيد وإرسال الطلب
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubmitting ? null : () => _submitMarketOrder(allProducts),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text(
                          'تأكيد وإرسال طلب التسوق 🧺',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // كارت إضافة صنف ليس بالقوائم
  Widget _buildAddCustomItemCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_task_rounded, size: 18, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text(
                'إضافة صنف خاص ليس بالقوائم (يُعامل كبنود التطبيق):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _customItemNameCtrl,
                  decoration: InputDecoration(
                    hintText: 'اسم الصنف (مثال: نعناع، ملوخية، ليمون...)',
                    hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // اختيار الوحدة
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _customItemUnit,
                    items: _units.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(u, style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                    onChanged: (u) {
                      if (u != null) setState(() => _customItemUnit = u);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('الكمية:', style: TextStyle(fontSize: 11.5)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                onPressed: () {
                  if (_customItemQty > 0.5) {
                    setState(() => _customItemQty -= 0.5);
                  }
                },
              ),
              Text(
                _customItemQty.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF16A34A), size: 22),
                onPressed: () => setState(() => _customItemQty += 0.5),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _addCustomItemDirectly,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'إضافة للقائمة ➕',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // عرض الصنف المخصص كبند تماماً مثل بنود التطبيق
  Widget _buildCustomCartItemTile(ThemeData theme, EtsawaqliCartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                Text(
                  'صنف خاص • ${item.quantity} ${item.unit} (سعر السوق الفعلي)',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                onPressed: () {
                  if (item.quantity > 0.5) {
                    setState(() {
                      _customItems[index] = EtsawaqliCartItem(
                        productId: item.productId,
                        productName: item.productName,
                        category: item.category,
                        unit: item.unit,
                        quantity: item.quantity - 0.5,
                        unitPrice: item.unitPrice,
                        isCustom: true,
                      );
                    });
                  } else {
                    setState(() => _customItems.removeAt(index));
                  }
                },
              ),
              Text(
                item.quantity.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF16A34A)),
                onPressed: () {
                  setState(() {
                    _customItems[index] = EtsawaqliCartItem(
                      productId: item.productId,
                      productName: item.productName,
                      category: item.category,
                      unit: item.unit,
                      quantity: item.quantity + 0.5,
                      unitPrice: item.unitPrice,
                      isCustom: true,
                    );
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => setState(() => _customItems.removeAt(index)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // عرض صنف عادي من القائمة
  Widget _buildProductItemTile(ThemeData theme, EtsawaqliProductItem product) {
    final qty = _cartQuantities[product.id] ?? 0.0;
    final isSelected = qty > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF16A34A).withValues(alpha: 0.06) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF16A34A) : Colors.grey.withValues(alpha: 0.25),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF16A34A), size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                Text(
                  'تقريباً ${product.estimatedPrice.toStringAsFixed(0)} ج / ${product.unit}',
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (qty > 0) ...[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      if (qty <= 0.5) {
                        _cartQuantities.remove(product.id);
                      } else {
                        _cartQuantities[product.id] = qty - 0.5;
                      }
                    });
                  },
                ),
                Text(
                  qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF16A34A), size: 24),
                onPressed: () {
                  setState(() {
                    _cartQuantities[product.id] = qty + (product.unit == 'حبة / رأس' ? 1.0 : 0.5);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── 3. شاشة سجل العمليات (منسقة مثل إشتريلي) ─────────────────────────
  Widget _buildOrdersHistoryView(ThemeData theme, String uid) {
    if (uid.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('يرجى تسجيل الدخول أولاً لعرض سجل العمليات', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => setState(() => _currentView = 0),
              child: const Text('رجوع للرئيسية', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ترويسة سجل العمليات مع زر رجوع وزر تسوق جديد
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
                  'سجل العمليات 📜',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _currentView = 1),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'تسوق جديد',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
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
          child: StreamBuilder<List<EtsawaqliOrder>>(
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
                        const Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'ليس لديك أي عمليات تسوق سابقة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'اختر الأصناف والسلع التي ترغب بها ومندوبة القرية ستتسوق لك يوم السوق.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () => setState(() => _currentView = 1),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text('ابدأ أول تسوق الآن 🧺', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // قائمة كروت العمليات الملخصة
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
  Widget _buildOrderSummaryCard(ThemeData theme, EtsawaqliOrder order) {
    final isCompleted = order.status == 'completed';
    final isCancelled = order.status == 'cancelled';
    final isInProgress = order.status == 'shopping' || order.status == 'delivering';

    final Color statusColor = isCompleted
        ? const Color(0xFF16A34A)
        : (isCancelled
            ? Colors.red
            : (isInProgress ? const Color(0xFF2563EB) : const Color(0xFFD97706)));

    final String statusLabel = isCompleted
        ? 'تم التسليم بنجاح ✅'
        : (isCancelled
            ? 'ملغي ❌'
            : (order.status == 'delivering'
                ? 'في الطريق للتوصيل 🚚'
                : (order.status == 'shopping' ? 'جاري التسوق بالسوق 🧺' : 'بانتظار موعد السوق ⏳')));

    final String priceText = order.totalAmount > 0
        ? '${order.totalAmount.toStringAsFixed(0)} ج'
        : 'حسب فاتورة الكاشير 🧾';

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
                        order.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
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
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(order.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 15, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: order.totalAmount > 0 ? const Color(0xFF16A34A) : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // 3. ملخص الأصناف وتلميح النقر
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.marketName} • ${order.items.length} صنف',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.replay_rounded, size: 13, color: Color(0xFF16A34A)),
                              SizedBox(width: 3),
                              Text(
                                'إعادة الشروة 🔄',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF16A34A)),
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

  // ───────────────────────── 4. شيت تفاصيل العملية بالكامل (بدون كود التسليم) ─────────────────────────
  void _showOrderDetailSheet(BuildContext context, ThemeData theme, EtsawaqliOrder order) {
    final isCancelled = order.status == 'cancelled';
    final isInProgress = order.status == 'shopping' || order.status == 'delivering' || order.status == 'pending';

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تفاصيل العملية (${order.invoiceNumber})',
                        style: const TextStyle(
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
                      // مؤشر تتبع المراحل
                      if (!isCancelled) ...[
                        _buildOrderStepper(order),
                        const SizedBox(height: 16),
                      ],

                      // كارت السوق وموعده
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${order.marketName} • يوم ${order.marketDay}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // قائمة الأصناف المشتراة
                      const Text(
                        'الأصناف والسلع المطلوبة:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            for (final item in order.items)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '• ${item.productName} (${item.quantity} ${item.unit})',
                                        style: const TextStyle(fontSize: 11.5),
                                      ),
                                    ),
                                    Text(
                                      item.totalPrice > 0 ? '${item.totalPrice.toStringAsFixed(0)} ج' : 'سعر السوق',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // بيانات المندوبة إن وجدت
                      if (order.shopperPhone.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF16A34A),
                                child: Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'المندوبة: ${order.shopperName.isNotEmpty ? order.shopperName : 'مندوبة القرية'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                    ),
                                    Text(order.shopperPhone, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'اتصال هاتفي',
                                icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF16A34A), size: 20),
                                onPressed: () => launchPhoneCall(order.shopperPhone),
                              ),
                              IconButton(
                                tooltip: 'واتساب',
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 20),
                                onPressed: () {
                                  final waUrl = egyptianWhatsAppUrl(order.shopperPhone);
                                  if (waUrl != null) launchWhatsAppUrl(waUrl);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // الحساب المالي
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('إجمالي السلع التقديري:', style: TextStyle(fontSize: 11.5)),
                                Text('${order.itemsSubtotal.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('رسوم التسوق:', style: TextStyle(fontSize: 11.5)),
                                Text('${order.serviceFee.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('مصاريف التوصيل:', style: TextStyle(fontSize: 11.5)),
                                Text('${order.deliveryFee.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي المستحق عند الاستلام:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                Text(
                                  '${order.totalAmount.toStringAsFixed(0)} ج',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // زر إعادة طلب نفس الشروة بنقرة واحدة
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reorderPrevious(order);
                        },
                        icon: const Icon(Icons.replay_rounded, size: 19),
                        label: const Text(
                          'إعادة طلب نفس الشروة 🔄',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // زر طباعة ومشاركة فاتورة كاشير الطلب
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => CommercialReceiptDialog.showEtsawaqliReceipt(
                          context,
                          order: order,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF16A34A)),
                        label: const Text(
                          'طباعة ومشاركة فاتورة الكاشير 🖨️',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),

                      if (isInProgress) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('إلغاء الطلب', style: TextStyle(fontSize: 11.5)),
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

  Widget _buildOrderStepper(EtsawaqliOrder order) {
    var step = 1;
    if (order.status == 'shopping') step = 2;
    if (order.status == 'delivering') step = 3;
    if (order.status == 'completed') step = 4;

    return OrderProgressStepper(
      nodeRadius: 11,
      dividerWidth: 16,
      fontSize: 9,
      steps: [
        const OrderProgressStep(label: 'استلام الطلب 📝', isDone: true),
        OrderProgressStep(label: 'جاري التسوق 🧺', isDone: step >= 2),
        OrderProgressStep(label: 'في الطريق 🚚', isDone: step >= 3),
        OrderProgressStep(label: 'تم التسليم ✅', isDone: step >= 4),
      ],
    );
  }

  Future<void> _confirmCancelOrder(EtsawaqliOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء طلب التسوق', style: TextStyle(fontFamily: 'Cairo')),
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
}
