import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/data_models.dart';
import '../../models/market_extra_models.dart';
import '../../routes/app_routes.dart';
import '../../services/buy_request_service.dart';
import '../../services/cache_service.dart';
import '../../services/donation_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/shop_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';
import '../../widgets/offline_stream_builder.dart';

part 'market_tab_market.dart';
part 'market_tab_shops.dart';
part 'market_tab_buy_donate.dart';

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
      setState(() => _sellerType = u?.sellerType ?? SellerType.regular);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Text('سوق القرية',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: CommonAppBarActions.actions(context),
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
      floatingActionButton: _buildFab(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MarketTab(),
          _ShopsTab(),
          _BuyRequestsTab(),
          _DonationsTab(),
        ],
      ),
    );
  }

  Widget _buildFab() {
    final theme = Theme.of(context);
    final idx = _tabController.index;
    final configs = <(String, IconData, VoidCallback)>[
      (
        'إضافة منتج',
        Icons.add_rounded,
        () => Navigator.pushNamed(context, AppRoutes.marketAdd)
      ),
      ('إنشاء محل', Icons.storefront_rounded, _createShop),
      ('طلب سلعة', Icons.request_quote_rounded, _createBuyRequest),
      ('تبرّع بسلعة', Icons.volunteer_activism_rounded, _createDonation),
    ];
    final c = configs[idx];
    return FloatingActionButton.extended(
      heroTag: 'market_tab_fab_$idx',
      onPressed: c.$3,
      icon: Icon(c.$2),
      label: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
    );
  }

  Future<String?> _requireUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('سجّل الدخول أولاً');
      return null;
    }
    return user.uid;
  }

  String _userName() {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email ?? 'مستخدم';
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
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final waC = TextEditingController();
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
              const Expanded(child: Text('إنشاء محل')),
              _sellerBadge(ctx),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImageField(
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
                    controller: nameC,
                    decoration: const InputDecoration(
                        labelText: 'اسم المحل',
                        prefixIcon: Icon(Icons.store_rounded))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: _shopCats
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSt(() => category = v ?? category),
                  decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      prefixIcon: Icon(Icons.category_rounded)),
                  menuMaxHeight: 360,
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: descC,
                    decoration: const InputDecoration(
                        labelText: 'نبذة',
                        prefixIcon: Icon(Icons.description_rounded)),
                    maxLines: 3),
                const SizedBox(height: 12),
                TextField(
                    controller: waC,
                    decoration: const InputDecoration(
                        labelText: 'واتساب للتواصل',
                        prefixIcon: Icon(Icons.chat_rounded)),
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
                child: const Text('إنشاء')),
          ],
        ),
      ),
    );
    if (ok == true && nameC.text.trim().isNotEmpty) {
      try {
        await _shopService.createShop(Shop(
          id: '',
          ownerUid: uid,
          ownerName: _userName(),
          name: nameC.text.trim(),
          category: category,
          description: descC.text.trim(),
          logoUrl: images.isNotEmpty ? images.first : null,
          imageUrls: List.from(images),
          whatsapp: waC.text.trim(),
        ));
        _snack('تم إنشاء المحل، وسيظهر بعد موافقة الإدارة');
      } catch (e) {
        _snack('خطأ: $e');
      }
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
                _ImageField(
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
                _ImageField(
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
        ));
        _snack('جزاك الله خيراً، تم نشر التبرع');
      } catch (e) {
        _snack('خطأ: $e');
      }
    }
  }
}

// ═══════════════════ Reusable multi-image uploader (seller-type limit) ═══════════════════
class _ImageField extends StatefulWidget {
  final int maxImages;
  final ValueChanged<List<String>> onChanged;
  const _ImageField({required this.maxImages, required this.onChanged});

  @override
  State<_ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends State<_ImageField> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _urls = [];
  bool _uploading = false;

  bool get _atMax => _urls.length >= widget.maxImages;

  Future<void> _add() async {
    if (_atMax) return;
    setState(() => _uploading = true);
    try {
      final file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      setState(() => _urls.add(url));
      widget.onChanged(List.of(_urls));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _remove(int i) {
    setState(() => _urls.removeAt(i));
    widget.onChanged(List.of(_urls));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('الصور (${_urls.length}/${widget.maxImages})',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(_urls.length, (i) => _thumb(theme, i)),
            if (!_atMax)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _uploading ? null : _add,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: _uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.add_a_photo_rounded,
                            color: theme.colorScheme.primary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _thumb(ThemeData theme, int i) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: _urls[i],
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 72,
              height: 72,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (_, __, ___) => Container(
              width: 72,
              height: 72,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_rounded),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _remove(i),
            child: Container(
              decoration: BoxDecoration(
                  color: theme.colorScheme.error, shape: BoxShape.circle),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
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

