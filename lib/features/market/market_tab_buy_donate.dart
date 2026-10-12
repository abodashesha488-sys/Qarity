part of 'market_tabs_screen.dart';

// ─── هوية التبويبين اللونية ───
const Color _buyAccent = Color(0xFF1565C0);
const Color _donateAccent = Color(0xFFEF6C00);

// نفس الدرجة العنبرية لكن محققة التباين: الأرضية والتظليل يبقيان على
// `_donateAccent`، وأما الكتابة والأيقونات فوق البياض فـ`#EF6C00` يعطيها
// 3.08 فقط فلا تُقرأ، وهذه 5.04.
const Color _donateInk = Color(0xFFB45309);

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
          // كل نداء هنا يمرّر أرضية ثابتة داكنة، و`onPrimary` في الداكن داكن
          // مثلها فلا يُقرأ فوقها، فيُثبَّت البياض.
          style: FilledButton.styleFrom(
              backgroundColor: color, foregroundColor: Colors.white),
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

  /// نسبة كل صورة تُقاس مرة واحدة عبر المحرّك المشترك للعرض، فيأخذ الشريط
  /// ارتفاع الصورة نفسها بدل قصّها في إطار ثابت.
  @override
  void initState() {
    super.initState();
    _measureAll();
  }

  void _measureAll() {
    for (final url in widget.urls) {
      FullFitImage.measure(url, onResult: (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant _MarketGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls != widget.urls) _measureAll();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 360.0;
      final current = widget.urls[_page.clamp(0, widget.urls.length - 1)];
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: FullFitImage.heightFor(current, width),
          width: double.infinity,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pager,
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => FullFitImage(
                  imageUrl: widget.urls[i],
                  width: width,
                  radius: 0,
                  fallback: ColoredBox(
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
    });
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

  // الستريم والكاش يُبنى مرة واحدة في الحالة لا في build: مع cacheFirst=false
  // كانت أول لقطة waiting بلا بيانات فتسقط في فرع الكاش (offline_stream_builder
  // :51)، وكان الكاش يُقرأ من Future جديد كل بناء فلا يُملأ إلا من الستريم الذي
  // لفظته تلك اللقطة — حلقة تُبقي «لا توجد طلبات مخزنة» إلى الأبد.
  Stream<List<BuyRequest>>? _stream;
  Future<List<Map<String, dynamic>>?>? _cacheFuture;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _stream = _service.getOpenRequestsStream();
    _cacheFuture = CacheService.getBuyRequests();
  }

  @override
  Widget build(BuildContext context) {
    final uid = BuyRequestService.viewerUid();
    return OfflineStreamBuilder<List<BuyRequest>>(
      stream: _stream!,
      cacheFirst: false,
      progressBuilder: (_) =>
          const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, _) => _TabLoadError(
        icon: Icons.request_quote_rounded,
        message: 'تعذّر تحميل السلع المطلوبة — تحقّق من الاتصال.',
        onRetry: () => setState(_attach),
      ),
      onlineBuilder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return RefreshIndicator(
            color: _buyAccent,
            onRefresh: () async {
              await _service.getOpenRequests(forceRefresh: true);
              if (mounted) setState(_attach);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _TabEmpty(
                  icon: Icons.request_quote_rounded,
                  message:
                      'لا توجد سلع مطلوبة حالياً\nأضف طلبك من زر «أضف سلعة مطلوبة»',
                ),
              ],
            ),
          );
        }
        return _buildBuyRequestsList(uid, items);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: _cacheFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = BuyRequestService.visibleToViewer(
              (snapshot.data ?? [])
                  .map((j) => BuyRequest.fromJson(j, 'cache'))
                  .toList(),
              uid);
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
    return RefreshIndicator(
      color: _buyAccent,
      onRefresh: () async {
        await _service.getOpenRequests(forceRefresh: true);
        if (mounted) setState(_attach);
      },
      child: ListView.separated(
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
                color: mine
                    ? _buyAccent.withValues(alpha: 0.6)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: mine ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => _openMarketPage(
                context,
                _BuyRequestDetailPage(request: r, service: _service),
              ),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── رأس الكرت: الناشر والرتبة والوقت وشارة الحالة ───
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _buyAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.person_rounded,
                                color: _buyAccent, size: 19),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RoleNameText(
                                name: r.userName,
                                role: r.userRole,
                                sellerType: r.userSellerType,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                iconSize: 12,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 11,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  Text(
                                    _agoLabel(r.createdAt),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _StatusChip(
                          label: mine
                              ? (r.isApproved
                                  ? 'طلبك • ${r.statusLabel}'
                                  : 'طلبك • بانتظار موافقة الإدارة')
                              : r.statusLabel,
                          color: r.isOpen ? _buyAccent : Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ─── عنوان السلعة المطلوبة ───
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _buyAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.search_rounded,
                              size: 15, color: _buyAccent),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ─── التفاصيل (إن وجدت) ───
                    if (r.details.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        r.details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],

                    // ─── صور السلعة المصغرة (إن وجدت) ───
                    if (r.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 90,
                          width: double.infinity,
                          child: r.imageUrls.length == 1
                              ? _net(r.imageUrls.first, theme)
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: r.imageUrls.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 6),
                                  itemBuilder: (ctx, idx) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 120,
                                      height: 90,
                                      child: _net(r.imageUrls[idx], theme),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],

                    // ─── بادج الميزانية ───
                    if (r.budget.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFFB300)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payments_rounded,
                                size: 13, color: Color(0xFFE65100)),
                            const SizedBox(width: 4),
                            Text(
                              'الميزانية المتوقعة: ${r.budget}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.7),
                    const SizedBox(height: 8),

                    // ─── شريط التفاعل: اتصال - واتساب - تعليقات - مشاركة ───
                    Row(
                      children: [
                        if (r.contactPhone.isNotEmpty) ...[
                          _ContactPillButton(
                            icon: Icons.phone_rounded,
                            label: 'اتصال',
                            color: _buyAccent,
                            onTap: () =>
                                _makePhoneCall(context, r.contactPhone),
                          ),
                          const SizedBox(width: 6),
                          _ContactPillButton(
                            icon: Icons.chat_rounded,
                            label: 'واتساب',
                            color: const Color(0xFF128C7E),
                            onTap: () =>
                                _openWhatsApp(context, r.contactPhone),
                          ),
                          const SizedBox(width: 6),
                        ],
                        StreamBuilder<List<BuyRequestComment>>(
                          stream: _service.getCommentsStream(r.id),
                          builder: (context, commentSnap) {
                            final count =
                                commentSnap.data?.length ?? r.commentsCount;
                            return _CommentPillButton(
                              count: count,
                              onTap: () => _openMarketPage(
                                context,
                                _BuyRequestDetailPage(
                                  request: r,
                                  service: _service,
                                  focusComment: true,
                                ),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          tooltip: 'مشاركة',
                          icon: const Icon(Icons.share_outlined,
                              color: Colors.black54),
                          onPressed: () => ShareService.shareText(
                            title: '🔍 مطلوب: ${r.title}',
                            body: [
                              if (r.details.isNotEmpty) r.details,
                              if (r.budget.isNotEmpty)
                                'الميزانية: ${r.budget}',
                              if (r.contactPhone.isNotEmpty)
                                'للتواصل: ${r.contactPhone}',
                              '— من سوق قرية أبوديشيشة',
                            ].join('\n'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: Colors.black38),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ).animate(delay: (i * 40).ms).fadeIn();
        },
      ),
    );
  }
}

/// زر تواصل مصغر داخل كرت الطلب
class _ContactPillButton extends StatelessWidget {
  const _ContactPillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر عداد التعليقات داخل كرت الطلب
class _CommentPillButton extends StatelessWidget {
  const _CommentPillButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blueGrey.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 13, color: Colors.blueGrey),
              const SizedBox(width: 4),
              Text(
                count > 0 ? '$count تعليق' : 'تعليق',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _makePhoneCall(BuildContext context, String phone) async {
  final clean = phone.trim();
  if (clean.isEmpty) return;
  final error = await launchPhoneCall(clean);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

Future<void> _openWhatsApp(BuildContext context, String phone) async {
  final clean = phone.trim();
  if (clean.isEmpty) return;
  final waUrl = egyptianWhatsAppUrl(clean);
  if (waUrl == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الهاتف غير صالح للمراسلة عبر واتساب.')));
    }
    return;
  }
  final error = await launchWhatsAppUrl(waUrl);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

/// تفاصيل سلعة مطلوبة — تواصل مباشر، تعليقات وعروض، وإغلاق/حذف لصاحب الطلب.
class _BuyRequestDetailPage extends StatefulWidget {
  const _BuyRequestDetailPage({
    required this.request,
    required this.service,
    this.focusComment = false,
  });

  final BuyRequest request;
  final BuyRequestService service;
  final bool focusComment;

  @override
  State<_BuyRequestDetailPage> createState() => _BuyRequestDetailPageState();
}

class _BuyRequestDetailPageState extends State<_BuyRequestDetailPage> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isSending = false;
  bool _isAdmin = false;
  UserModel? _currentUserModel;

  @override
  void initState() {
    super.initState();
    _loadUser();
    if (widget.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _commentFocus.requestFocus();
      });
    }
  }

  Future<void> _loadUser() async {
    final uid = BuyRequestService.viewerUid();
    if (uid != null) {
      final user = await UserService().getCurrentUser();
      final admin = await AdminService().isAdminUser(uid);
      if (mounted) {
        setState(() {
          _currentUserModel = user;
          _isAdmin = admin;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final uid = BuyRequestService.viewerUid();
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول للتعليق على الطلب')),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final name = _currentUserModel?.name.isNotEmpty == true
          ? _currentUserModel!.name
          : (FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم');
      final photo = _currentUserModel?.photoUrl ??
          FirebaseAuth.instance.currentUser?.photoURL ??
          '';

      await widget.service.addComment(
        requestId: widget.request.id,
        text: text,
        userId: uid,
        userName: name,
        userPhotoUrl: photo,
        userRole: _currentUserModel?.role,
        userSellerType: _currentUserModel?.sellerType?.name,
      );
      _commentCtrl.clear();
      _commentFocus.unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة تعليقك بنجاح'),
            backgroundColor: _buyAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر إرسال التعليق: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final ok = await _marketConfirm(
      context,
      title: 'حذف التعليق؟',
      body: 'هل أنت متأكد من حذف هذا التعليق نهائيًا؟',
      okLabel: 'حذف',
      color: AppColors.error,
    );
    if (ok == true) {
      try {
        await widget.service.deleteComment(widget.request.id, commentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف التعليق')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذّر حذف التعليق: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.request;
    final uid = BuyRequestService.viewerUid();
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
                if (r.contactPhone.isNotEmpty) 'هاتف التواصل: ${r.contactPhone}',
                '— من سوق قرية أبوديشيشة',
              ].join('\n'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
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
                        Text('طلب بدون صور',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _buyAccent)),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),

                // ─── عنوان الطلب والشارة ───
                Row(
                  children: [
                    Expanded(
                      child: Text(r.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 19)),
                    ),
                    _StatusChip(
                      label: mine && !r.isApproved
                          ? 'بانتظار موافقة الإدارة'
                          : r.statusLabel,
                      color: r.isOpen ? _buyAccent : Colors.teal,
                    ),
                  ],
                ),

                // ─── ميزانية الطلب المميزة ───
                if (r.budget.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFB300)
                              .withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE082),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.payments_rounded,
                              size: 18, color: Color(0xFFE65100)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الميزانية المحددة',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8D6E63))),
                              Text(r.budget,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFE65100))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ─── بطاقة تفاصيل الطلب وبيانات الناشر ───
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.details.isNotEmpty)
                          _DetailRow(
                              icon: Icons.notes_rounded,
                              label: 'التفاصيل',
                              value: r.details),
                        _DetailRow(
                            icon: Icons.person_rounded,
                            label: 'مقدم الطلب',
                            value: r.userName),
                        _DetailRow(
                            icon: Icons.schedule_rounded,
                            label: 'تاريخ النشر',
                            value: _agoLabel(r.createdAt),
                            color: Colors.black45),
                        if (r.contactPhone.isNotEmpty)
                          _DetailRow(
                              icon: Icons.phone_rounded,
                              label: 'هاتف التواصل',
                              value: r.contactPhone,
                              color: _buyAccent),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── قسم التواصل المباشر ───
                if (r.contactPhone.isNotEmpty) ...[
                  const Text('التواصل مع صاحب الطلب',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _makePhoneCall(context, r.contactPhone),
                          style: FilledButton.styleFrom(
                              backgroundColor: _buyAccent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13)),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('اتصال هاتفي',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _openWhatsApp(context, r.contactPhone),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF128C7E),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13)),
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('واتساب',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (!mine) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _buyAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _buyAccent.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: _buyAccent, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'لم يحدد صاحب الطلب رقم هاتف. يمكنك التواصل معه وعرض سلعتك مباشرة عبر قسم التعليقات بالأسفل.',
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: _buyAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── خيارات صاحب الطلب ───
                if (mine) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await _marketConfirm(context,
                          title: 'تمت تلبية الطلب؟',
                          body:
                              'سيُغلق الطلب ويختفي من قائمة «مطلوب» — إن حصلت على ما تريد فمبروك، ويمكنك إضافة طلب جديد لاحقًا.',
                          okLabel: 'نعم، تمت التلبية',
                          color: _buyAccent);
                      if (ok == true) {
                        await widget.service.close(r.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('🎉 تمت تلبية الطلب وأُغلق',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: _buyAccent));
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: _buyAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.check_circle_rounded, size: 19),
                    label: const Text('تمت التلبية — إغلاق الطلب',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await _marketConfirm(context,
                          title: 'حذف الطلب نهائيًا؟',
                          body: 'سيُحذف الطلب ولن يظهر لأحد بعد الآن.',
                          okLabel: 'حذف',
                          color: AppColors.error);
                      if (ok == true) {
                        await widget.service.delete(r.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حذف الطلب')));
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkOn(
                            AppColors.error, theme.brightness)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    label: const Text('حذف الطلب نهائيًا',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 12),
                ],

                const Divider(height: 24, thickness: 1),

                // ─── قسم التعليقات والعروض المتاحة ───
                StreamBuilder<List<BuyRequestComment>>(
                  stream: widget.service.getCommentsStream(r.id),
                  builder: (context, snapshot) {
                    final comments = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.forum_rounded,
                                size: 19, color: _buyAccent),
                            const SizedBox(width: 8),
                            Text(
                              'التعليقات والمقترحات (${comments.length})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (comments.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 32, color: Colors.black26),
                                  SizedBox(height: 8),
                                  Text(
                                    'لا توجد تعليقات أو عروض بعد.\nهل لديك ما يطلبه صاحب المنشور؟ اكتب له أدناه!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.5,
                                        color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final c = comments[idx];
                              final canDelete =
                                  (uid != null && c.userId == uid) ||
                                      _isAdmin;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: _buyAccent
                                              .withValues(alpha: 0.1),
                                          backgroundImage: c
                                                  .userPhotoUrl.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  c.userPhotoUrl)
                                              : null,
                                          child: c.userPhotoUrl.isEmpty
                                              ? const Icon(
                                                  Icons.person_rounded,
                                                  size: 16,
                                                  color: _buyAccent)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              RoleNameText(
                                                name: c.userName,
                                                role: c.userRole,
                                                sellerType: c.userSellerType,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    fontSize: 12.5),
                                                iconSize: 12,
                                              ),
                                              Text(
                                                _agoLabel(c.createdAt),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (canDelete)
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 17,
                                                color: Colors.redAccent),
                                            tooltip: 'حذف التعليق',
                                            onPressed: () =>
                                                _deleteComment(c.id),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 36),
                                      child: Text(
                                        c.text,
                                        style: const TextStyle(
                                            fontSize: 13, height: 1.45),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // ─── شريط كتابة التعليق في الأسفل ───
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      focusNode: _commentFocus,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقاً أو اعرض سلعتك...',
                        hintStyle: const TextStyle(fontSize: 12.5),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: _buyAccent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _submitComment,
                    style: IconButton.styleFrom(
                        backgroundColor: _buyAccent,
                        foregroundColor: Colors.white),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
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

  // نفس سبب «مطلوب»: الستريم والكاش يُبنى مرة واحدة، والخطأ يُعلَن لا يُستبدل
  // بكاش فارغ، وأول لقطة waiting تعرض نحلة صادقة لا «لا توجد تبرعات مخزنة».
  Stream<List<Donation>>? _stream;
  Future<List<Map<String, dynamic>>?>? _cacheFuture;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _stream = _service.getAvailableDonationsStream();
    _cacheFuture = CacheService.getDonations();
  }

  @override
  Widget build(BuildContext context) {
    final uid = DonationService.viewerUid();
    return OfflineStreamBuilder<List<Donation>>(
      stream: _stream!,
      cacheFirst: false,
      progressBuilder: (_) =>
          const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, _) => _TabLoadError(
        icon: Icons.volunteer_activism_rounded,
        message: 'تعذّر تحميل التبرعات — تحقّق من الاتصال.',
        onRetry: () => setState(_attach),
      ),
      onlineBuilder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return RefreshIndicator(
            color: _donateAccent,
            onRefresh: () async {
              await _service.getAvailableDonations(forceRefresh: true);
              if (mounted) setState(_attach);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _TabEmpty(
                  icon: Icons.volunteer_activism_rounded,
                  message:
                      'لا توجد تبرعات معروضة حالياً\nأضف تبرعك من زر «أضف تبرعاً»',
                ),
              ],
            ),
          );
        }
        return _buildDonationsList(uid, items);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: _cacheFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = DonationService.visibleToViewer(
              (snapshot.data ?? [])
                  .map((j) => Donation.fromJson(j, 'cache'))
                  .toList(),
              uid);
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
    return RefreshIndicator(
      color: _donateAccent,
      onRefresh: () async {
        await _service.getAvailableDonations(forceRefresh: true);
        if (mounted) setState(_attach);
      },
      child: ListView.separated(
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
              child: IntrinsicHeight(
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
                                    ? (d.isApproved
                                        ? 'تبرعك • ${d.statusLabel}'
                                        : 'تبرعك • بانتظار موافقة الإدارة')
                                    : d.statusLabel,
                                color: _donateInk),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.category_rounded,
                                size: 12, color: _donateInk),
                            const SizedBox(width: 4),
                            Text(d.category,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _donateInk)),
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
                            const Icon(Icons.keyboard_arrow_down_rounded,
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
          ),
        ).animate(delay: (i * 40).ms).fadeIn();
      },
    ),
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

  /// بلا بوّابة `canLaunchUrl`: الفحص القبلي كان يرجع false على أندرويد 11+ للحزم
  /// غير المصرّح برؤيتها فيصمت الزر رغم أن الفتح نفسه كان سينجح.
  Future<void> _launch(String url) async {
    final error = await launchContactUrl(url,
        unavailable: 'لا يمكن فتح هذا الرابط على هذا الجهاز.',
        failed: 'تعذّر الفتح — تحقّق من الاتصال ثم أعد المحاولة.');
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String? get _waLink => egyptianWhatsAppUrl(widget.donation.contactPhone);

  Future<void> _markHandedOver() async {
    final ok = await _marketConfirm(context,
        title: 'تم تسليم التبرع؟',
        body: 'سيُغلق الإعلان ويختفي من قائمة التبرعات — جزاك الله خيراً على خيرك.',
        okLabel: 'نعم، تم التسليم',
        color: _donateInk);
    if (ok != true) return;
    setState(() => _busy = true);
    await widget.service.markDonated(widget.donation.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🤲 تم تسليم التبرع وأُغلق الإعلان',
              style: TextStyle(color: Colors.white)),
          backgroundColor: _donateInk));
    }
  }

  Future<void> _delete() async {
    final ok = await _marketConfirm(context,
        title: 'حذف التبرع نهائيًا؟',
        body: 'سيُحذف الإعلان ولن يظهر لأحد بعد الآن.',
        okLabel: 'حذف',
        color: AppColors.error);
    if (ok != true) return;
    setState(() => _busy = true);
    await widget.service.delete(widget.donation.id);
    if (mounted) {
      Navigator.pop(context);
      // الحذف ليس خطأً، فالكلمة تأخذ أرضية الثيم المحايدة وحبرها المرافق بدل
      // درجة `blueGrey` الخارجة عن اللوحة.
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حذف الإعلان')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.donation;
    final uid = DonationService.viewerUid();
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
              _StatusChip(
                  label: mine && !d.isApproved
                      ? 'بانتظار موافقة الإدارة'
                      : d.statusLabel,
                  color: _donateInk),
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
                      color: _donateInk),
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
                        color: _donateInk),
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
                        backgroundColor: _donateInk,
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
                  backgroundColor: _donateInk,
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
                  backgroundColor: _donateInk,
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
              style: TextButton.styleFrom(
                  foregroundColor:
                      AppColors.inkOn(AppColors.error, theme.brightness)),
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
                    size: 17, color: _donateInk),
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

class _TabLoadError extends StatelessWidget {
  const _TabLoadError({
    required this.icon,
    required this.message,
    required this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
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
