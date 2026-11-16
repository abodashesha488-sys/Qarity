import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/contact_links.dart';
import '../core/utils/launch_link.dart';
import '../models/etsawaqli_model.dart';
import '../services/etsawaqli_service.dart';
import '../services/user_service.dart';
import 'commercial_receipt_dialog.dart';

/// نافذة خدمة «إتسوقلي» للمستخدم: اختيار السوق الأسبوعي، السلع، الأصناف الخاصة، وفاتورة كاشير السوبر ماركت
/// (مستوحى من معايير Instacart & Nana & Breadfast العالمية المخصصة للريف المصري)
class EtsawaqliMarketSheet extends StatefulWidget {
  const EtsawaqliMarketSheet({super.key});

  @override
  State<EtsawaqliMarketSheet> createState() => _EtsawaqliMarketSheetState();
}

class _EtsawaqliMarketSheetState extends State<EtsawaqliMarketSheet>
    with SingleTickerProviderStateMixin {
  final EtsawaqliService _service = EtsawaqliService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final TabController _tabController;
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _userName = '';
  String _userPhone = '';
  bool _isSubmitting = false;

  EtsawaqliMarket? _selectedMarket;
  String _selectedCategory = 'الكل';
  final Map<String, double> _cartQuantities = {}; // productId -> quantity
  final Map<String, String> _cartNotes = {}; // productId -> notes
  final Map<String, String> _cartPreferences = {}; // productId -> preference
  final List<EtsawaqliCartItem> _customItems =
      []; // أصناف خاصة غير موجودة بالقائمة

  static const List<String> _freshnessChips = [
    'جامد للسلطة',
    'مستوي للأكل فوراً',
    'حجم متوسط',
    'طازة بلدي',
  ];

  final List<String> _categories = [
    'الكل',
    'خضروات',
    'فواكه',
    'دواجن',
    'لحوم',
    'أسماك',
    'ألبان وجبن',
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
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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

  List<EtsawaqliCartItem> _buildCartItems(
      List<EtsawaqliProductItem> allProducts) {
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
          preference: _cartPreferences[p.id] ?? '',
        ));
      }
    }
    list.addAll(_customItems);
    return list;
  }

  Future<void> _submitMarketOrder(List<EtsawaqliProductItem> allProducts,
      {bool isRecurringWeekly = false}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى تسجيل الدخول أولاً لإتمام الاشتراك',
                style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final cartItems = _buildCartItems(allProducts);
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار صنف واحد على الأقل للتسوق',
                style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    final market = _selectedMarket ?? EtsawaqliService.defaultMarkets.first;
    final subtotal = _calculateItemsSubtotal(allProducts);

    setState(() => _isSubmitting = true);
    try {
      await _service.createOrder(
        userId: uid,
        userName: _userName.isNotEmpty ? _userName : 'أحد أهالي القرية',
        userPhone: _userPhone,
        marketId: market.id,
        marketName: market.name,
        marketDay: market.dayOfWeek,
        items: cartItems,
        itemsSubtotal: subtotal,
        serviceFee: market.serviceFee,
        deliveryFee: market.deliveryFee,
        deliveryAddress: _addressCtrl.text.trim().isEmpty
            ? 'داخل القرية'
            : _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        isRecurringWeekly: isRecurringWeekly,
      );

      setState(() {
        _cartQuantities.clear();
        _cartNotes.clear();
        _cartPreferences.clear();
        _customItems.clear();
        _isSubmitting = false;
        _tabController.animateTo(1);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text(
                'تم تسجيل اشتراكك بفاتورة كاشير معتمدة! ستتسوق المندوبة لك يوم السوق ✅',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('حدث خطأ أثناء تسجيل الاشتراك: $e',
                  style: const TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }

  void _showAddCustomItemDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'كيلو');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_task_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('إضافة صنف خاص غير موجود بالقائمة',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم الصنف أو الطلب *',
                  hintText: 'مثال: نعناع أخضر، بهارات كذا، ملوخية مخروطة...',
                  labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'الكمية *',
                        labelStyle:
                            TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الوحدة',
                        hintText: 'كيلو / ربطة / حبة',
                        labelStyle:
                            TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'أي تفضيل أو مواصفات خاصة للصنف',
                  labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A)),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
              final unit =
                  unitCtrl.text.trim().isEmpty ? 'قطعة' : unitCtrl.text.trim();

              if (name.isEmpty) return;

              setState(() {
                _customItems.add(EtsawaqliCartItem(
                  productId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  productName: name,
                  category: 'أصناف خاصة',
                  unit: unit,
                  quantity: qty,
                  unitPrice: 0.0, // سيتم حسابها بسعر السوق الفعلي
                  userNotes: notesCtrl.text.trim(),
                  isCustom: true,
                ));
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF16A34A),
                  content: Text('تمت إضافة "$name" إلى سلة تسوقك بنجاح ✅',
                      style: const TextStyle(fontFamily: 'Cairo')),
                ),
              );
            },
            child: const Text('إضافة للسلة',
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = _auth.currentUser?.uid ?? '';

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
          // مقبض النافذة
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

          // ترويسة خدمة إتسوقلي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_basket_rounded,
                      color: Color(0xFF16A34A), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خدمة إتسوقلي (تسوق أسواق القرية) 🧺',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Cairo'),
                      ),
                      Text(
                        'مندوبة التطبيق تتسوق لكِ من سوق الجمعة والأسواق المجاورة',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'Cairo'),
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

          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            tabs: const [
              Tab(
                  icon: Icon(Icons.add_shopping_cart_rounded, size: 18),
                  text: 'التسوق وقائمة السلع'),
              Tab(
                  icon: Icon(Icons.receipt_rounded, size: 18),
                  text: 'سجل فواتيري واشتراكاتي'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShoppingView(theme),
                _buildMyInvoicesList(theme, uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── تبويب 1: اختيار السوق وقائمة السلع وفاتورة الكاشير ─────────────────────────
  Widget _buildShoppingView(ThemeData theme) {
    return StreamBuilder<List<EtsawaqliMarket>>(
      stream: _service.watchActiveMarkets(),
      builder: (context, marketsSnap) {
        final markets = marketsSnap.data ?? EtsawaqliService.defaultMarkets;
        _selectedMarket ??= markets.first;

        return StreamBuilder<List<EtsawaqliProductItem>>(
          stream: _service.watchProducts(),
          builder: (context, productsSnap) {
            final allProducts =
                productsSnap.data ?? EtsawaqliService.defaultProducts;
            final filteredProducts = _selectedCategory == 'الكل'
                ? allProducts
                : allProducts
                    .where((p) => p.category == _selectedCategory)
                    .toList();

            final cartCount =
                _cartQuantities.values.where((q) => q > 0).length +
                    _customItems.length;
            final subtotal = _calculateItemsSubtotal(allProducts);

            return Column(
              children: [
                // 1. اختيار السوق المستهدف من القائمة المنسدلة
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              const Color(0xFF16A34A).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<EtsawaqliMarket>(
                              value: _selectedMarket,
                              isExpanded: true,
                              items: markets.map((m) {
                                return DropdownMenuItem<EtsawaqliMarket>(
                                  value: m,
                                  child: Text(
                                    '${m.name} (${m.dayOfWeek})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                        fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newMarket) {
                                if (newMarket != null) {
                                  setState(() => _selectedMarket = newMarket);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. زر إضافة صنف خاص وفلاتر التصنيفات الأفقية
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF16A34A), width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _showAddCustomItemDialog,
                        icon: const Icon(Icons.add,
                            size: 15, color: Color(0xFF16A34A)),
                        label: const Text(
                          '+ صنف خاص',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, i) {
                              final cat = _categories[i];
                              final isSel = cat == _selectedCategory;
                              return ChoiceChip(
                                label: Text(cat,
                                    style: const TextStyle(
                                        fontFamily: 'Cairo', fontSize: 11)),
                                selected: isSel,
                                selectedColor: const Color(0xFF16A34A)
                                    .withValues(alpha: 0.2),
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = cat),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 10),

                // 3. عرض الأصناف الخاصة إذا أضاف المستخدم أي صنف
                if (_customItems.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded,
                                  size: 16, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text(
                                'أصنافك الخاصة المضافة (${_customItems.length}):',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _customItems.map((ci) {
                              return Chip(
                                padding: EdgeInsets.zero,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                label: Text(
                                  '${ci.productName} (${ci.quantity.toStringAsFixed(0)} ${ci.unit})',
                                  style: const TextStyle(
                                      fontSize: 10.5, fontFamily: 'Cairo'),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () {
                                  setState(() => _customItems.remove(ci));
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // 4. قائمة السلع مع أزرار الزيادة والنقصان وتفضيلات الجودة
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, idx) {
                      final p = filteredProducts[idx];
                      final qty = _cartQuantities[p.id] ?? 0.0;
                      final selectedPref = _cartPreferences[p.id] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: qty > 0
                                ? const Color(0xFF16A34A)
                                : Colors.grey.withValues(alpha: 0.2),
                            width: qty > 0 ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              fontFamily: 'Cairo'),
                                        ),
                                        Text(
                                          '${p.estimatedPrice.toStringAsFixed(0)} ج / ${p.unit}',
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF16A34A),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                            size: 22),
                                        onPressed: qty > 0
                                            ? () {
                                                setState(() {
                                                  if (qty <= 1.0) {
                                                    _cartQuantities
                                                        .remove(p.id);
                                                    _cartPreferences
                                                        .remove(p.id);
                                                  } else {
                                                    _cartQuantities[p.id] =
                                                        qty - 1.0;
                                                  }
                                                });
                                              }
                                            : null,
                                      ),
                                      Text(
                                        qty > 0
                                            ? '${qty.toStringAsFixed(0)} ${p.unit}'
                                            : '0',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            fontFamily: 'Cairo'),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFF16A34A),
                                            size: 22),
                                        onPressed: () {
                                          setState(() {
                                            _cartQuantities[p.id] = qty + 1.0;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // تفضيلات النضج والنوع عند اختيار السلعة
                              if (qty > 0) ...[
                                const Divider(height: 10),
                                Row(
                                  children: [
                                    const Text('تفضيلك: ',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontFamily: 'Cairo')),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: _freshnessChips.map((chip) {
                                            final isChipSel =
                                                selectedPref == chip;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4),
                                              child: ChoiceChip(
                                                label: Text(chip,
                                                    style: const TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 9.5)),
                                                selected: isChipSel,
                                                onSelected: (sel) {
                                                  setState(() {
                                                    _cartPreferences[p.id] =
                                                        sel ? chip : '';
                                                  });
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 5. الشريط السفلي لعرض الفاتورة وإتمام الاشتراك
                if (cartCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$cartCount أصناف مختارة • ${subtotal.toStringAsFixed(0)} ج',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: 'Cairo'),
                              ),
                              Text(
                                '+ رسوم خدمة وتوصيل (${(_selectedMarket?.serviceFee ?? 25).toStringAsFixed(0)} + ${(_selectedMarket?.deliveryFee ?? 15).toStringAsFixed(0)} ج)',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () =>
                              _openCashierReceiptDialog(context, allProducts),
                          icon:
                              const Icon(Icons.receipt_long_rounded, size: 18),
                          label: const Text('معاينة فاتورة الكاشير 🧾',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
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

  // ───────────────────────── نافذة فاتورة كاشير السوبر ماركت ─────────────────────────
  void _openCashierReceiptDialog(
      BuildContext context, List<EtsawaqliProductItem> allProducts) {
    final cartItems = _buildCartItems(allProducts);
    final market = _selectedMarket ?? EtsawaqliService.defaultMarkets.first;
    final subtotal = _calculateItemsSubtotal(allProducts);
    final total = subtotal + market.serviceFee + market.deliveryFee;
    bool isRecurringWeekly = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // شارة رأس الفاتورة
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_rounded,
                            size: 36, color: Color(0xFF16A34A)),
                        const SizedBox(height: 4),
                        const Text(
                          'سوق أبودشيشة والقرى المجاورة',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Cairo',
                              color: Colors.black87),
                        ),
                        Text(
                          'فاتورة كاشير تسوق أسبوعية • ${market.name}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontFamily: 'Cairo'),
                        ),
                        const Text(
                          '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                          style:
                              TextStyle(color: Colors.grey, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),

                  // جدول الأصناف
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('السلعة',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                    color: Colors.black87))),
                        Expanded(
                            child: Text('الكمية',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                    color: Colors.black87))),
                        Expanded(
                            child: Text('السعر',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                    color: Colors.black87))),
                        Expanded(
                            child: Text('الإجمالي',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'Cairo',
                                    color: Colors.black87))),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.black26),

                  for (final item in cartItems)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontFamily: 'Cairo',
                                        color: Colors.black87)),
                                if (item.preference.isNotEmpty)
                                  Text('تفضيل: ${item.preference}',
                                      style: const TextStyle(
                                          fontSize: 9.5,
                                          color: Color(0xFF16A34A),
                                          fontFamily: 'Cairo')),
                              ],
                            ),
                          ),
                          Expanded(
                              child: Text(
                                  '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'Cairo',
                                      color: Colors.black87))),
                          Expanded(
                              child: Text(
                                  item.isCustom
                                      ? 'حسب السوق'
                                      : '${item.unitPrice.toStringAsFixed(0)} ج',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'Cairo',
                                      color: Colors.black87))),
                          Expanded(
                              child: Text(
                                  item.isCustom
                                      ? 'حسب الفاتورة'
                                      : '${item.totalPrice.toStringAsFixed(0)} ج',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                      color: Colors.black87))),
                        ],
                      ),
                    ),

                  const Text(
                    '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                    style: TextStyle(color: Colors.grey, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),

                  // ملخص الحساب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('مجموع السلع التقديري:',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: Colors.black87)),
                      Text('${subtotal.toStringAsFixed(0)} ج',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('رسوم خدمة تسوق المندوبة:',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: Colors.black87)),
                      Text('${market.serviceFee.toStringAsFixed(0)} ج',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أجرة التوصيل لباب بيتك:',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: Colors.black87)),
                      Text('${market.deliveryFee.toStringAsFixed(0)} ج',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: Colors.black87)),
                    ],
                  ),
                  const Divider(color: Colors.black45, thickness: 1.2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي الكلي للفاتورة:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              color: Colors.black)),
                      Text('${total.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                              fontFamily: 'Cairo')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // اشتراك دوري أسبوعي
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تفعيل الاشتراك الأسبوعي الدوري 🔄',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo')),
                    subtitle: const Text(
                        'تكرار هذا الطلب تلقائياً كل أسبوع في نفس يوم السوق',
                        style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey,
                            fontFamily: 'Cairo')),
                    value: isRecurringWeekly,
                    activeThumbColor: const Color(0xFF16A34A),
                    onChanged: (val) {
                      setModalState(() => isRecurringWeekly = val);
                    },
                  ),
                  const SizedBox(height: 8),

                  // نص الملاحظة الإلزامية بالخط الواضح
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      EtsawaqliOrder.marketNoticeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF92400E),
                        fontFamily: 'Cairo',
                        height: 1.45,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // حقل العنوان
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان أو مكان التوصيل بالقرية *',
                      labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _submitMarketOrder(allProducts,
                                isRecurringWeekly: isRecurringWeekly);
                          },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('تأكيد الاشتراك واعتماد الفاتورة 🚀',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── تبويب 2: سجل فواتيري واشتراكاتي ─────────────────────────
  Widget _buildMyInvoicesList(ThemeData theme, String uid) {
    if (uid.isEmpty) {
      return const Center(
          child: Text('يرجى تسجيل الدخول أولاً لعرض فواتيرك',
              style: TextStyle(fontFamily: 'Cairo')));
    }

    return StreamBuilder<List<EtsawaqliOrder>>(
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
                const Icon(Icons.shopping_basket_outlined,
                    size: 54, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('ليس لديك أي فواتير تسوق سابقة في إتسوقلي',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('تسوق الآن من السوق الأسبوعي 🧺',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildInvoiceCard(theme, orders[i]),
        );
      },
    );
  }

  Widget _buildInvoiceCard(ThemeData theme, EtsawaqliOrder order) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: order.status == 'completed'
              ? const Color(0xFF16A34A)
              : const Color(0xFF16A34A).withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.invoiceNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Cairo'),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusArabic,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                        fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'السوق: ${order.marketName} (${order.marketDay})',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'Cairo'),
                ),
                if (order.isRecurringWeekly) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('اشتراك دوري 🔄',
                        style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo')),
                  ),
                ],
              ],
            ),
            const Divider(height: 16),

            // أصناف الفاتورة
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '• ${item.productName} (${item.quantity.toStringAsFixed(0)} ${item.unit})',
                        style:
                            const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                    Text(
                        item.isCustom
                            ? 'حسب الفاتورة'
                            : '${item.totalPrice.toStringAsFixed(0)} ج',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo')),
                  ],
                ),
              ),

            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي الفاتورة بالتوصيل:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} ج',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16A34A),
                      fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // كود الاستلام للمندوبة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_rounded,
                      color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('كود استلام الطلب من المندوبة:',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF92400E),
                                fontFamily: 'Cairo')),
                        Text(
                          order.claimCode,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // تفاصيل المندوبة المكلفة إن وجدت
            if (order.shopperPhone.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'المندوبة: ${order.shopperName.isNotEmpty ? order.shopperName : "مندوبة التسوق"}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  fontFamily: 'Cairo')),
                          Text(order.shopperPhone,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'اتصال هاتفي',
                      icon: const Icon(Icons.phone_in_talk,
                          color: Color(0xFF16A34A), size: 18),
                      onPressed: () => launchPhoneCall(order.shopperPhone),
                    ),
                    IconButton(
                      tooltip: 'واتساب',
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF16A34A), size: 18),
                      onPressed: () {
                        final waUrl = egyptianWhatsAppUrl(order.shopperPhone);
                        if (waUrl != null) launchWhatsAppUrl(waUrl);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => CommercialReceiptDialog.showEtsawaqliReceipt(
                context,
                order: order,
              ),
              icon: const Icon(Icons.print_rounded,
                  size: 16, color: Color(0xFF16A34A)),
              label: const Text(
                'طباعة ومشاركة فاتورة الكاشير 🖨️',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
