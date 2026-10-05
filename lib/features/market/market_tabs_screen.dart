import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/product_categories.dart';
import '../../core/utils/contact_links.dart';
import '../../core/utils/launch_link.dart';
import '../../core/utils/role_style.dart';
import '../../models/data_models.dart';
import '../../models/market_extra_models.dart';
import '../../routes/app_routes.dart';
import '../../services/buy_request_service.dart';
import '../../services/cache_service.dart';
import '../../services/donation_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/share_service.dart';
import '../../services/shop_service.dart';
import '../../services/user_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/full_fit_image.dart';
import '../../widgets/image_gallery_wrap.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import 'add_product.dart';

part 'market_tab_buy_donate.dart';
part 'market_tab_market.dart';
part 'market_tab_shops.dart';

/// سوق القرية — أربع تبويبات مترابطة: السوق، المحلات، سلع مطلوبة، تبرعات.
class MarketTabsScreen extends StatefulWidget {
  const MarketTabsScreen({super.key});

  @override
  State<MarketTabsScreen> createState() => _MarketTabsScreenState();
}

class _MarketTabsScreenState extends State<MarketTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShopService _shopService = ShopService();
  final BuyRequestService _buyService = BuyRequestService();
  final DonationService _donationService = DonationService();
  final UserService _userService = UserService();
  SellerType _sellerType = SellerType.regular;
  String _userRole = 'user';
  UserModel? _profile;

  /// تصنيفات المحلات — تشمل المحلات التجارية والخدمية (ورش، مخازن، حرف يدوية…)
  static const List<String> _shopCats = [
    'عام',
    'سوبر ماركت',
    'خضار وفواكه',
    'لحوم وأسماك',
    'ألبان ومخبوزات',
    'حلويات ومخابز',
    'مشروبات وكافيهات',
    'مطاعم ووجبات',
    'ملابس وأحذية',
    'إلكترونيات وهواتف',
    'أثاث ومفروشات',
    'أدوات منزلية ومنظفات',
    'مستلزمات زراعة وأعلاف',
    'سوق المستعمل',
    'ورش صيانة',
    'كهرباء وسباكة',
    'نجارة وألمنيوم',
    'حدادة ولحام',
    'تكييف وتبريد',
    'سيارات وموتوسيكلات',
    'مخازن ومستودعات',
    'حرف يدوية',
    'خياطة وتفصيل',
    'أحذية وجلود',
    'صيدليات',
    'بقالات وميني ماركت',
    'خدمات أخرى',
  ];

  static const List<String> _donationCats = [
    'عام',
    'ملابس',
    'أثاث',
    'أجهزة',
    'أغذية',
    'أطفال',
    'كتب',
    'مستلزمات منزلية',
    'أخرى'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSellerType();
  }

  Future<void> _loadSellerType() async {
    final u = await _userService.getCurrentUser();
    if (mounted) {
      setState(() {
        _profile = u;
        _sellerType = u?.sellerType ?? SellerType.regular;
        _userRole = u?.role ?? 'user';
      });
    }
  }

  String _userName() {
    final pname = (_profile?.name ?? '').trim();
    if (pname.isNotEmpty) return pname;
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email ?? 'مستخدم';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (addLabel, addAction) = _addForTab();
    return Scaffold(
      appBar: QurityAppBar(
        title: 'سوق القرية',
        onAdd: addAction,
        addTooltip: addLabel,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          dividerColor: Colors.transparent,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'السوق'),
            Tab(text: 'المحلات'),
            Tab(text: 'مطلوب'),
            Tab(text: 'تبرعات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MarketTab(),
          ShopsTab(),
          _BuyRequestsTab(),
          _DonationsTab(),
        ],
      ),
    );
  }

  /// تسمية وإجراء زر «+» في الهيدر يتبعان التبويب المفتوح.
  (String, VoidCallback) _addForTab() {
    return switch (_tabController.index) {
      1 => ('إنشاء محل', _createShop),
      2 => ('طلب سلعة', _createBuyRequest),
      3 => ('تبرّع بسلعة', _createDonation),
      _ => (
          'إضافة منتج',
          () => Navigator.pushNamed(context, AppRoutes.marketAdd)
        ),
    };
  }

  Future<String?> _requireUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('سجّل الدخول أولاً');
      return null;
    }
    return user.uid;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _sellerBadge(BuildContext ctx) {
    final max = _sellerType.maxImages;
    return Chip(
      label: Text('${_sellerType.label} • حتى $max صورة',
          style: const TextStyle(fontSize: 10)),
      backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
    );
  }

  Future<void> _createShop() async {
    final uid = await _requireUser();
    if (uid == null || !mounted) return;
    final saved = await showShopFormDialog(
      context,
      service: _shopService,
      uid: uid,
      ownerName: _userName(),
      ownerRole: _userRole,
      sellerType: _sellerType,
    );
    if (!mounted) return;
    if (saved) {
      _snack('تم إنشاء المحل، وسيظهر بعد موافقة الإدارة');
    }
  }

  Future<void> _createBuyRequest() async {
    final uid = await _requireUser();
    if (uid == null || !mounted) return;
    final titleC = TextEditingController();
    final detailsC = TextEditingController();
    final budgetC = TextEditingController();
    final images = <String>[];
    final max = _sellerType.maxImages;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Expanded(child: Text('أضف سلعة مطلوبة')),
              _sellerBadge(ctx),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarketImageField(
                    maxImages: max,
                    onChanged: (l) {
                      setSt(() {
                        images
                          ..clear()
                          ..addAll(l);
                      });
                    }),
                const SizedBox(height: 12),
                TextField(
                    controller: titleC,
                    decoration: const InputDecoration(
                        labelText: 'ما الذي تبحث عنه؟',
                        prefixIcon: Icon(Icons.search_rounded))),
                const SizedBox(height: 12),
                TextField(
                    controller: detailsC,
                    decoration: const InputDecoration(
                        labelText: 'تفاصيل',
                        prefixIcon: Icon(Icons.description_rounded)),
                    maxLines: 3),
                const SizedBox(height: 12),
                TextField(
                    controller: budgetC,
                    decoration: const InputDecoration(
                        labelText: 'الميزانية (اختياري)',
                        prefixIcon: Icon(Icons.payments_rounded))),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نشر الطلب')),
          ],
        ),
      ),
    );
    if (ok == true && titleC.text.trim().isNotEmpty) {
      try {
        await _buyService.create(BuyRequest(
          id: '',
          userId: uid,
          userName: _userName(),
          title: titleC.text.trim(),
          details: detailsC.text.trim(),
          budget: budgetC.text.trim(),
          imageUrls: List.from(images),
          userRole: _userRole,
          userSellerType: _sellerType.name,
        ));
        _snack('تم نشر طلبك');
      } catch (e) {
        _snack('خطأ: $e');
      }
    }
  }

  Future<void> _createDonation() async {
    final uid = await _requireUser();
    if (uid == null || !mounted) return;
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final phoneC = TextEditingController();
    var category = 'عام';
    final images = <String>[];
    final max = _sellerType.maxImages;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Expanded(child: Text('تبرّع بسلعة')),
              _sellerBadge(ctx),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarketImageField(
                    maxImages: max,
                    onChanged: (l) {
                      setSt(() {
                        images
                          ..clear()
                          ..addAll(l);
                      });
                    }),
                const SizedBox(height: 12),
                TextField(
                    controller: titleC,
                    decoration: const InputDecoration(
                        labelText: 'اسم السلعة',
                        prefixIcon: Icon(Icons.card_giftcard_rounded))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: _donationCats
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSt(() => category = v ?? category),
                  decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      prefixIcon: Icon(Icons.category_rounded)),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: descC,
                    decoration: const InputDecoration(
                        labelText: 'الوصف',
                        prefixIcon: Icon(Icons.description_rounded)),
                    maxLines: 3),
                const SizedBox(height: 12),
                TextField(
                    controller: phoneC,
                    decoration: const InputDecoration(
                        labelText: 'هاتف التواصل',
                        prefixIcon: Icon(Icons.phone_rounded)),
                    keyboardType: TextInputType.phone),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نشر التبرع')),
          ],
        ),
      ),
    );
    if (ok == true && titleC.text.trim().isNotEmpty) {
      try {
        await _donationService.create(Donation(
          id: '',
          userId: uid,
          userName: _userName(),
          title: titleC.text.trim(),
          description: descC.text.trim(),
          category: category,
          contactPhone: phoneC.text.trim(),
          imageUrls: List.from(images),
          userRole: _userRole,
          userSellerType: _sellerType.name,
        ));
        _snack('جزاك الله خيراً، تم نشر التبرع');
      } catch (e) {
        _snack('خطأ: $e');
      }
    }
  }
}

// ═══════════════════ الصور: المحرّر المشترك لكل التطبيق ═══════════════════
/// غلاف رفيع حول `ImageListEditor`: يبقى حدّ الصور حسب نوع البائع
/// (`SellerType.maxImages`) وهو ما يمرّره كل نموذج، والمحرك نفسه — الرفع
/// والحذف والفشل المرئي — مشترك. كان لهذا الحقل رافعه الخاص الذي يبتلع خطأ
/// ImgBB في `catch (_)` فتُحفظ السلعة بلا صورة وبلا كلمة.
class MarketImageField extends StatefulWidget {
  final int maxImages;
  final ValueChanged<List<String>> onChanged;

  /// اختياري لاختبار المحرّر المشترك بلا معرض جهاز ولا شبكة.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  /// عند تعديل صاحب محله أو سلعته: صوره المحفوظة تدخل المحرّر جاهزة.
  final List<String> initialUrls;
  const MarketImageField(
      {super.key,
      required this.maxImages,
      required this.onChanged,
      this.initialUrls = const [],
      this.uploader,
      this.bytesSource});

  @override
  State<MarketImageField> createState() => _MarketImageFieldState();
}

class _MarketImageFieldState extends State<MarketImageField> {
  late final List<String> _urls = [...widget.initialUrls];

  @override
  Widget build(BuildContext context) => ImageListEditor(
        label: 'الصور',
        fieldKey: 'marketImages',
        urls: _urls,
        maxImages: widget.maxImages,
        maxSide: 1200,
        uploader: widget.uploader,
        bytesSource: widget.bytesSource,
        onChanged: (urls) {
          setState(() => _urls
            ..clear()
            ..addAll(urls));
          widget.onChanged(urls);
        },
      );
}

Widget _net(String url, ThemeData theme) {
  if (url.isEmpty) {
    return ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image_rounded,
            color: theme.colorScheme.onSurfaceVariant));
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (c, u) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
    errorWidget: (c, u, e) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_rounded,
            color: theme.colorScheme.onSurfaceVariant)),
  );
}

