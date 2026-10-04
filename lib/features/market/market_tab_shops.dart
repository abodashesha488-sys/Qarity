part of 'market_tabs_screen.dart';

// ═══════════════════ Tab 2: المحلات ═══════════════════

/// نموذج المحل المشترك — إنشاءً وتعديلًا. كان الحوار خاصًا بالشاشة الرئيسية
/// للتبويبات فلا يستطيع صاحب المحل تعديل بياناته من صفحة المحل نفسها.
/// يعيد true فقط عند نجاح الحفظ (والبنية كما هي عند الإلغاء أو الرفض).
Future<bool> showShopFormDialog(
  BuildContext context, {
  required ShopService service,
  required String uid,
  required String ownerName,
  required String ownerRole,
  required SellerType sellerType,
  Shop? existing,
}) async {
  final theme = Theme.of(context);
  final isEdit = existing != null;
  final nameC = TextEditingController(text: existing?.name ?? '');
  final descC = TextEditingController(text: existing?.description ?? '');
  final waC = TextEditingController(text: existing?.whatsapp ?? '');
  final categories = List<String>.from(_MarketTabsScreenState._shopCats);
  var category = existing?.category ?? 'عام';
  if (!categories.contains(category)) category = 'عام';
  final images = <String>[...(existing?.imageUrls ?? const <String>[])];
  final max = sellerType.maxImages;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Expanded(child: Text(isEdit ? 'تعديل المحل' : 'إنشاء محل')),
            Chip(
              label: Text('${sellerType.label} • حتى $max صورة',
                  style: const TextStyle(fontSize: 10)),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MarketImageField(
                  maxImages: max,
                  initialUrls: images,
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
                items: categories
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.4))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit
                            ? 'بعد الحفظ يعود المحل إلى لوحة المراجعة تلقائيًا، فلا يُعدَّل بياناته أحد بلا علم الإدارة، ثم يظهر لأهالي القرية بعد الموافقة.'
                            : 'بعد الإنشاء سيظهر محلك هنا مباشرة بوسم «بانتظار موافقة الإدارة»، ولن يراه بقية أهالي القرية إلا بعد موافقة الأدمن من لوحة التحكم. ستصلك رسالة فور الموافقة.',
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'حفظ التعديلات' : 'إنشاء')),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  if (nameC.text.trim().isEmpty) return false;
  try {
    if (isEdit) {
      await service.updateShop(Shop(
        id: existing.id,
        ownerUid: existing.ownerUid,
        ownerName: existing.ownerName,
        name: nameC.text.trim(),
        category: category,
        description: descC.text.trim(),
        logoUrl: images.isNotEmpty ? images.first : existing.logoUrl,
        coverUrl: existing.coverUrl,
        imageUrls: List<String>.from(images),
        whatsapp: waC.text.trim(),
        ownerRole: existing.ownerRole,
        ownerSellerType: existing.ownerSellerType,
        isActive: existing.isActive,
        isApproved: existing.isApproved,
        createdAt: existing.createdAt,
      ));
      return true;
    }
    await service.createShop(Shop(
      id: '',
      ownerUid: uid,
      ownerName: ownerName,
      name: nameC.text.trim(),
      category: category,
      description: descC.text.trim(),
      logoUrl: images.isNotEmpty ? images.first : null,
      imageUrls: List<String>.from(images),
      whatsapp: waC.text.trim(),
      ownerRole: ownerRole,
      ownerSellerType: sellerType.name,
    ));
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ: $e'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
    return false;
  }
}
/// تبويب المحلات — كرتان في كل سطر. عام وقابل للحقن ليُختبر على بيانات بلا
/// Firebase (نمط المشروع)، كما هو الحال في بطاقات الخدمات الطبية.
class ShopsTab extends StatelessWidget {
  const ShopsTab({super.key, this.service});

  final ShopService? service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = this.service ?? ShopService();
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // بلا جلسة (أو بلا Firebase في الاختبار) تبقى قائمة القرية العامة هي
      // المطلوب عرضها، فلا يُسقط شذوذٌ غير محاصر التبويب كله.
      uid = null;
    }
    return OfflineStreamBuilder<List<Shop>>(
      stream: service.getVisibleShopsStream(uid),
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) {
          return const _TabEmpty(
            icon: Icons.storefront_rounded,
            message: 'لا توجد محلات بعد — أنشئ محلك من زر «إنشاء محل»',
          );
        }
        return _buildShopsList(theme, shops);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getShops(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final shops = (snapshot.data ?? []).map((j) => Shop.fromJson(j, 'cache')).toList();
          if (shops.isEmpty) {
            return const _TabEmpty(icon: Icons.storefront_rounded, message: 'لا توجد محلات مخزنة');
          }
          return _buildShopsList(theme, shops);
        },
      ),
    );
  }

  Widget _buildShopsList(ThemeData theme, List<Shop> shops) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        // ارتفاع مطلق لا نسبة: البطاقة تُركّ صورة ثابتة ثم أسطر محدودة،
        // فالنسبة تُقصّ النص على الشاشات الأضيق.
        mainAxisExtent: 212,
      ),
      itemCount: shops.length,
      itemBuilder: (context, i) {
        final s = shops[i];
        return _ShopGridCard(
          shop: s,
          theme: theme,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => _ShopDetailScreen(shop: s))),
        ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.06);
      },
    );
  }
}

/// بطاقة محل في شبكة المحلات — صورتها تعلوها وشارة الانتظار فوقها، فالكرت
/// يبدو متناسقًا ولو اختلفت المحلات في المقاس والنص.
class _ShopGridCard extends StatelessWidget {
  const _ShopGridCard({
    required this.shop,
    required this.theme,
    required this.onTap,
  });

  final Shop shop;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = shop;
    final accent = RoleStyle.contentAccent(s.ownerRole, s.ownerSellerType);
    final radius = BorderRadius.circular(20);
    return Card(
      elevation: accent != null ? 2 : 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
            width: accent != null ? 1.5 : 1,
            color: accent?.withValues(alpha: 0.7) ??
                theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _net(s.imageUrl, theme),
                  if (!s.isApproved)
                    PositionedDirectional(
                      top: 6,
                      start: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(9)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_top_rounded,
                                size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text('بانتظار موافقة الإدارة',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // الجسم «المتبقّي» لا «مقدار ثابت»: الارتفاع المطلق للبطاقة قد
            // يقلّ عن مجموع الأسطر على العروض الضيّقة، فالتوسيع يضمن أن
            // النبذة هي من ينكمش (بسَطرين وellipsis) لا أن يفيض الكرت.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RoleNameText(
                        name: s.name,
                        role: s.ownerRole,
                        sellerType: s.ownerSellerType,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14),
                        iconSize: 13),
                    const SizedBox(height: 3),
                    Text(s.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800)),
                    if (s.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Flexible(
                        child: Text(s.description,
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.45,
                                color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopDetailScreen extends StatefulWidget {
  const _ShopDetailScreen({required this.shop});
  final Shop shop;

  @override
  State<_ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<_ShopDetailScreen> {
  final ShopService _shopService = ShopService();

  Shop get shop => widget.shop;

  String _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openEdit() async {
    final uid = _currentUid();
    if (uid.isEmpty) {
      _snack('سجّل الدخول أولاً');
      return;
    }
    SellerType sellerType;
    try {
      sellerType = SellerType.values.firstWhere((t) => t.name == shop.ownerSellerType);
    } catch (_) {
      sellerType = SellerType.regular;
    }
    final saved = await showShopFormDialog(
      context,
      service: _shopService,
      uid: uid,
      ownerName: shop.ownerName,
      ownerRole: shop.ownerRole ?? 'user',
      sellerType: sellerType,
      existing: shop,
    );
    // التعديل يُعيد المحل للمراجعة، فصفحة المحل لم يعد لها ما تعرضه.
    if (saved && mounted) Navigator.pop(context);
  }

  Future<bool> _delete() async {
    try {
      await _shopService.deleteShop(shop.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = _currentUid();
    final isOwner = currentUid.isNotEmpty && currentUid == shop.ownerUid;
    return Scaffold(
      appBar: QurityAppBar(
        title: shop.name,
        onAdd: isOwner
            ? () => Navigator.pushNamed(context, AppRoutes.marketAdd,
                arguments: <String, dynamic>{kShopIdArgKey: shop.id})
            : null,
        addTooltip: 'أضف منتجاً لمحلي',
        actions: [
          IconButton(
            tooltip: 'مشاركة المحل',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareService.shareText(
              title: '🏬 ${shop.name}',
              body: [
                'التصنيف: ${shop.category}',
                'يديره: ${shop.ownerName}',
                if (shop.description.isNotEmpty) shop.description,
                if (shop.whatsapp.isNotEmpty) 'واتساب: ${shop.whatsapp}',
              ].join('\n'),
            ),
          ),
          if (shop.whatsapp.isNotEmpty)
            IconButton(
              tooltip: 'تواصل واتساب',
              icon: const Icon(Icons.chat_rounded),
              onPressed: () async {
                final wa = egyptianWhatsAppUrl(shop.whatsapp);
                if (wa == null) return;
                final uri = Uri.parse(wa);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<List<MarketProduct>>(
        stream: MarketService()
            .getShopProductsStream(ownerUid: shop.ownerUid, shopId: shop.id),
        builder: (context, snapshot) {
          final products = (snapshot.data ?? [])
              .where((p) => p.isApproved && p.isInStock)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                    height: 150,
                    child: _net(shop.coverUrl ?? shop.imageUrl, theme)),
              ),
              const SizedBox(height: 16),
              Text(shop.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${shop.category} • يديره ${shop.ownerName}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              if (shop.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(shop.description, style: const TextStyle(height: 1.5)),
              ],
              if (shop.imageUrls.length > 1) ...[
                const SizedBox(height: 12),
                const Text('صور المحل',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  child: ImageGalleryWrap(
                      urls: shop.imageUrls, tileWidth: 110),
                ),
              ],
              const SizedBox(height: 20),
              Text('منتجات المحل (${products.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد منتجات في هذا المحل بعد'),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62),
                  itemCount: products.length,
                  itemBuilder: (context, i) =>
                      _MiniProductCard(product: products[i]),
                ),
              const SizedBox(height: 20),
              OwnerActions(
                keyTag: 'shop-detail',
                ownerId: shop.ownerUid,
                currentUserId: currentUid,
                itemName: shop.name,
                editLabel: 'تعديل المحل',
                deleteLabel: 'حذف المحل',
                onEdit: _openEdit,
                onDelete: _delete,
              ),
            ],
          );
        },
      ),
    );
  }
}

