part of 'market_tabs_screen.dart';

// ─── هوية التبويبين اللونية ───
const Color _buyAccent = Color(0xFF1565C0);
const Color _donateAccent = Color(0xFFEF6C00);

String _agoLabel(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
  if (diff.inDays < 30) return 'منذ ${diff.inDays ~/ 7} أسبوع';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

Future<void> _openMarketPage(BuildContext context, Widget page) async {
  await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page));
}

Future<bool?> _marketConfirm(BuildContext context,
    {required String title, required String body, required String okLabel, required Color color}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Text(body, style: const TextStyle(height: 1.6)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okLabel,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

/// معرض صور بسيط مع عدّاد — للطلبات والتبرعات.
class _MarketGallery extends StatefulWidget {
  const _MarketGallery({required this.urls, required this.accent});
  final List<String> urls;
  final Color accent;

  @override
  State<_MarketGallery> createState() => _MarketGalleryState();
}

class _MarketGalleryState extends State<_MarketGallery> {
  final PageController _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pager,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(
                  color: widget.accent.withValues(alpha: 0.08),
                  child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          size: 40, color: Colors.black26)),
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${_page + 1} / ${widget.urls.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// صف بيانات موحد داخل شاشة التفاصيل.
class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value, this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 9),
          SizedBox(
              width: 92,
              child: Text('$label:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.5))),
        ],
      ),
    );
  }
}

// ═══════════════════ Tab 3: سلع مطلوبة ═══════════════════
class _BuyRequestsTab extends StatefulWidget {
  const _BuyRequestsTab();

  @override
  State<_BuyRequestsTab> createState() => _BuyRequestsTabState();
}

class _BuyRequestsTabState extends State<_BuyRequestsTab> {
  final BuyRequestService _service = BuyRequestService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return OfflineStreamBuilder<List<BuyRequest>>(
      stream: _service.getOpenRequestsStream(),
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _TabEmpty(
            icon: Icons.request_quote_rounded,
            message:
                'لا توجد سلع مطلوبة حالياً\nأضف طلبك من زر «أضف سلعة مطلوبة»',
          );
        }
        return _buildBuyRequestsList(uid, items);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getBuyRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items =
              (snapshot.data ?? []).map((j) => BuyRequest.fromJson(j, 'cache')).toList();
          if (items.isEmpty) {
            return const _TabEmpty(
                icon: Icons.request_quote_rounded, message: 'لا توجد طلبات مخزنة');
          }
          return _buildBuyRequestsList(uid, items);
        },
      ),
    );
  }

  Widget _buildBuyRequestsList(String? uid, List<BuyRequest> items) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = items[i];
        final mine = uid != null && r.userId == uid;
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: _buyAccent.withValues(alpha: mine ? 0.55 : 0.3),
                width: mine ? 1.4 : 1),
          ),
          child: InkWell(
            onTap: () => _openMarketPage(context,
                _BuyRequestDetailPage(request: r, service: _service)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 92,
                  child: r.imageUrl.isEmpty
                      ? ColoredBox(
                          color: _buyAccent.withValues(alpha: 0.09),
                          child: const Icon(Icons.request_quote_rounded,
                              color: _buyAccent, size: 30),
                        )
                      : _net(r.imageUrl, theme),
                ),
                const VerticalDivider(
                    width: 1, thickness: 1, color: Color(0x14000000)),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(11, 10, 8, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5)),
                            ),
                            const SizedBox(width: 6),
                            _StatusChip(
                                label: mine
                                    ? 'طلبك • ${r.statusLabel}'
                                    : r.statusLabel,
                                color: _buyAccent),
                          ],
                        ),
                        if (r.details.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(r.details,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                  height: 1.45)),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 13, color: Colors.black45),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: RoleNameText(
                                        name: r.userName,
                                        role: r.userRole,
                                        sellerType: r.userSellerType,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                        iconSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (r.budget.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius:
                                        BorderRadius.circular(7),
                                    border: Border.all(
                                        color: _donateAccent
                                            .withValues(alpha: 0.4))),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.payments_rounded,
                                        size: 11,
                                        color: Color(0xFFE65100)),
                                    const SizedBox(width: 3),
                                    Text(r.budget,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFFE65100))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Text(_agoLabel(r.createdAt),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme
                                        .onSurfaceVariant)),
                            const Spacer(),
                            const Icon(Icons.chevron_left_rounded,
                                size: 18, color: Colors.black38),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (i * 40).ms).fadeIn();
      },
    );
  }
}

/// تفاصيل سلعة مطلوبة — مشاركة للجميع، وإغلاق/حذف لصاحب الطلب.
class _BuyRequestDetailPage extends StatelessWidget {
  const _BuyRequestDetailPage(
      {required this.request, required this.service});
  final BuyRequest request;
  final BuyRequestService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = request;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final mine = uid != null && r.userId == uid;

    return Scaffold(
      appBar: QurityAppBar(
        title: 'تفاصيل الطلب',
        actions: [
          IconButton(
            tooltip: 'مشاركة الطلب',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareService.shareText(
                title: '🔍 مطلوب: ${r.title}',
                body: [
                  if (r.details.isNotEmpty) r.details,
                  if (r.budget.isNotEmpty) 'الميزانية: ${r.budget}',
                  '— من قرية أبوديشيشة',
                ].join('\n')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MarketGallery(urls: r.imageUrls, accent: _buyAccent),
          if (r.imageUrls.isEmpty)
            Container(
              height: 96,
              decoration: BoxDecoration(
                color: _buyAccent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _buyAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.request_quote_rounded,
                      color: _buyAccent, size: 30),
                  SizedBox(width: 10),
                  Text('طلب بلا صور',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _buyAccent)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(r.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 19)),
              ),
              _StatusChip(label: r.statusLabel, color: _buyAccent),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4))),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.details.isNotEmpty)
                    _DetailRow(
                        icon: Icons.notes_rounded,
                        label: 'التفاصيل',
                        value: r.details),
                  if (r.budget.isNotEmpty)
                    _DetailRow(
                        icon: Icons.payments_rounded,
                        label: 'الميزانية',
                        value: r.budget,
                        color: const Color(0xFFE65100)),
                  _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'مقدم الطلب',
                      value: r.userName),
                  _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'التاريخ',
                      value: _agoLabel(r.createdAt),
                      color: Colors.black45),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (mine) ...[
            FilledButton.icon(
              onPressed: () async {
                final ok = await _marketConfirm(context,
                    title: 'تمت تلبية الطلب؟',
                    body: 'سيُغلق الطلب ويختفي من قائمة «مطلوب» — إن حصلت على ما تريد فمبروك، ويمكنك إضافة طلب جديد لاحقًا.',
                    okLabel: 'نعم، تمت التلبية',
                    color: _buyAccent);
                if (ok == true) {
                  await service.close(r.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('🎉 تمت تلبية الطلب وأُغلق'),
                        backgroundColor: _buyAccent));
                  }
                }
              },
              style: FilledButton.styleFrom(
                  backgroundColor: _buyAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('تمت التلبية — إغلاق الطلب',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                final ok = await _marketConfirm(context,
                    title: 'حذف الطلب نهائيًا؟',
                    body: 'سيُحذف الطلب ولن يظهر لأحد بعد الآن.',
                    okLabel: 'حذف',
                    color: Colors.red.shade700);
                if (ok == true) {
                  await service.delete(r.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم حذف الطلب'),
                            backgroundColor: Colors.blueGrey));
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('حذف الطلب',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () => ShareService.shareText(
                  title: '🔍 مطلوب: ${r.title}',
                  body: [
                    if (r.details.isNotEmpty) r.details,
                    if (r.budget.isNotEmpty) 'الميزانية: ${r.budget}',
                    'تواصل مع ${r.userName} عبر التطبيق',
                  ].join('\n')),
              style: FilledButton.styleFrom(
                  backgroundColor: _buyAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              icon: const Icon(Icons.share_rounded, size: 19),
              label: const Text('شارِك الطلب — عندك ما يطلب؟',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════ Tab 4: تبرعات ═══════════════════
class _DonationsTab extends StatefulWidget {
  const _DonationsTab();

  @override
  State<_DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends State<_DonationsTab> {
  final DonationService _service = DonationService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return OfflineStreamBuilder<List<Donation>>(
      stream: _service.getAvailableDonationsStream(),
      onlineBuilder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _TabEmpty(
            icon: Icons.volunteer_activism_rounded,
            message:
                'لا توجد تبرعات معروضة حالياً\nأضف تبرعك من زر «أضف تبرعاً»',
          );
        }
        return _buildDonationsList(uid, items);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getDonations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snapshot.data ?? [])
              .map((j) => Donation.fromJson(j, 'cache'))
              .toList();
          if (items.isEmpty) {
            return const _TabEmpty(
                icon: Icons.volunteer_activism_rounded,
                message: 'لا توجد تبرعات مخزنة');
          }
          return _buildDonationsList(uid, items);
        },
      ),
    );
  }

  Widget _buildDonationsList(String? uid, List<Donation> items) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = items[i];
        final mine = uid != null && d.userId == uid;
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: _donateAccent.withValues(alpha: mine ? 0.55 : 0.3),
                width: mine ? 1.4 : 1),
          ),
          child: InkWell(
            onTap: () => _openMarketPage(context,
                _DonationDetailPage(donation: d, service: _service)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 92,
                  child: _net(d.imageUrl, theme),
                ),
                const VerticalDivider(
                    width: 1, thickness: 1, color: Color(0x14000000)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 8, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(d.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5)),
                            ),
                            const SizedBox(width: 6),
                            _StatusChip(
                                label: mine
                                    ? 'تبرعك • ${d.statusLabel}'
                                    : d.statusLabel,
                                color: _donateAccent),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.category_rounded,
                                size: 12, color: _donateAccent),
                            const SizedBox(width: 4),
                            Text(d.category,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _donateAccent)),
                            if (d.imageUrls.length > 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.collections_rounded,
                                  size: 12, color: Colors.black38),
                              const SizedBox(width: 2),
                              Text('${d.imageUrls.length}',
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                        if (d.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(d.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                  height: 1.45)),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.favorite_outline_rounded,
                                size: 13, color: Color(0xFFC62828)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: RoleNameText(
                                  name: d.userName,
                                  role: d.userRole,
                                  sellerType: d.userSellerType,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                  iconSize: 11),
                            ),
                            const SizedBox(width: 8),
                            Text(_agoLabel(d.createdAt),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme
                                        .onSurfaceVariant)),
                            const Spacer(),
                            const Icon(Icons.chevron_left_rounded,
                                size: 18, color: Colors.black38),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (i * 40).ms).fadeIn();
      },
    );
  }
}

/// تفاصيل تبرع — تواصل للمتبرَّع له، وإغلاق/حذف لصاحب التبرع.
class _DonationDetailPage extends StatefulWidget {
  const _DonationDetailPage({required this.donation, required this.service});
  final Donation donation;
  final DonationService service;

  @override
  State<_DonationDetailPage> createState() => _DonationDetailPageState();
}

class _DonationDetailPageState extends State<_DonationDetailPage> {
  bool _busy = false;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط على هذا الجهاز')));
    }
  }

  String? get _waLink => egyptianWhatsAppUrl(widget.donation.contactPhone);

  Future<void> _markHandedOver() async {
    final ok = await _marketConfirm(context,
        title: 'تم تسليم التبرع؟',
        body: 'سيُغلق الإعلان ويختفي من قائمة التبرعات — جزاك الله خيراً على خيرك.',
        okLabel: 'نعم، تم التسليم',
        color: _donateAccent);
    if (ok != true) return;
    setState(() => _busy = true);
    await widget.service.markDonated(widget.donation.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🤲 تم تسليم التبرع وأُغلق الإعلان'),
          backgroundColor: _donateAccent));
    }
  }

  Future<void> _delete() async {
    final ok = await _marketConfirm(context,
        title: 'حذف التبرع نهائيًا؟',
        body: 'سيُحذف الإعلان ولن يظهر لأحد بعد الآن.',
        okLabel: 'حذف',
        color: Colors.red.shade700);
    if (ok != true) return;
    setState(() => _busy = true);
    await widget.service.delete(widget.donation.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حذف الإعلان'),
              backgroundColor: Colors.blueGrey));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.donation;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final mine = uid != null && d.userId == uid;

    return Scaffold(
      appBar: QurityAppBar(
        title: 'تفاصيل التبرع',
        actions: [
          IconButton(
            tooltip: 'مشاركة التبرع',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareService.shareText(
                title: '🎁 تبرّع: ${d.title}',
                body: [
                  'تصنيف: ${d.category}',
                  if (d.description.isNotEmpty) d.description,
                  '— من قرية أبوديشيشة',
                ].join('\n')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MarketGallery(urls: d.imageUrls, accent: _donateAccent),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(d.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 19)),
              ),
              _StatusChip(label: d.statusLabel, color: _donateAccent),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4))),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                      icon: Icons.category_rounded,
                      label: 'التصنيف',
                      value: d.category,
                      color: _donateAccent),
                  if (d.description.isNotEmpty)
                    _DetailRow(
                        icon: Icons.notes_rounded,
                        label: 'الوصف',
                        value: d.description),
                  _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'المتبرّع',
                      value: d.userName),
                  _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'التاريخ',
                      value: _agoLabel(d.createdAt),
                      color: Colors.black45),
                  if (d.contactPhone.isNotEmpty)
                    _DetailRow(
                        icon: Icons.phone_rounded,
                        label: 'هاتف التواصل',
                        value: d.contactPhone,
                        color: _donateAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!mine && d.contactPhone.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _launch('tel://${d.contactPhone}'),
                    style: FilledButton.styleFrom(
                        backgroundColor: _donateAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('اتصال بالمتبرّع',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () {
                            final u = _waLink;
                            if (u != null) _launch(u);
                          },
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF128C7E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('واتساب',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          if (!mine && d.contactPhone.isEmpty)
            FilledButton.icon(
              onPressed: () => ShareService.shareText(
                  title: '🎁 تبرّع: ${d.title}',
                  body:
                      '${d.category}\nسجّل طلبك داخل التطبيق وسيتواصل معك ${d.userName}'),
              style: FilledButton.styleFrom(
                  backgroundColor: _donateAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('مشاركة الإعلان للتواصل',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          if (mine) ...[
            FilledButton.icon(
              onPressed: _busy ? null : _markHandedOver,
              style: FilledButton.styleFrom(
                  backgroundColor: _donateAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.volunteer_activism_rounded, size: 20),
              label: const Text('تم التسليم — إغلاق الإعلان',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: const Text('حذف الإعلان',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _donateAccent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _donateAccent.withValues(alpha: 0.3))),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 17, color: _donateAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mine
                        ? 'أنت صاحب هذا التبرع — عند تسليم السلعة أغلق الإعلان ليختفي من القائمة.'
                        : 'تواصل مباشرة مع صاحب التبرع — والتسليم يكون وجهاً لوجه داخل القرية.',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة حالة صغيرة موحّدة للتبويبين.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white)),
    );
  }
}

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
