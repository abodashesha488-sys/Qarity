part of 'admin_dashboard.dart';

/// صفحة «الإعلانات الدعائية» — إدارة البرومبثينات المنبثقة لكل الشاشات.
class _PromosPage extends StatefulWidget {
  const _PromosPage({required this.currentUid});
  final String? currentUid;

  @override
  State<_PromosPage> createState() => _PromosPageState();
}

class _PromosPageState extends State<_PromosPage> {
  final PromoService _service = PromoService();
  late final Stream<List<Promo>> _stream = _service.watchAll();

  Future<void> _openForm([Promo? promo]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _PromoFormSheet(promo: promo, adminUid: widget.currentUid),
    );
    if (saved == true) _snack(promo == null ? 'تم نشر الإعلان' : 'تم تحديث الإعلان');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: QurityAppBar.headerColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _delete(Promo promo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('هل تريد حذف «${promo.title}» نهائيًا؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(promo.id);
    } catch (_) {
      _snack('تعذّر الحذف — تحقق من الصلاحيات');
    }
  }

  Future<void> _toggleActive(Promo promo, bool value) async {
    try {
      await _service.setActive(promo, value);
    } catch (_) {
      _snack('تعذّر التبديل');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_promos_fab',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('إضافة إعلان',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: QurityAppBar.headerColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Promo>>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final promos = snap.data!;
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_rounded,
                      size: 56,
                      color: QurityAppBar.headerColor.withValues(alpha: 0.35)),
                  const SizedBox(height: 10),
                  Text(
                    'لا توجد إعلانات بعد\nأنشئ إعلاناً اختيارياً وخصّص شاشته ومدته',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
            itemCount: promos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _PromoCard(
              promo: promos[i],
              onEdit: () => _openForm(promos[i]),
              onDelete: () => _delete(promos[i]),
              onToggle: (v) => _toggleActive(promos[i], v),
            ),
          );
        },
      ),
    );
  }
}

class _PromoStatus {
  const _PromoStatus(this.label, this.color);
  final String label;
  final Color color;
}

_PromoStatus _promoStatus(Promo p) {
  final now = DateTime.now();
  if (!p.isActive) return const _PromoStatus('متوقف', Colors.blueGrey);
  if (now.isBefore(p.startsAt)) {
    return const _PromoStatus('مجدول', Color(0xFF1565C0));
  }
  if (!now.isBefore(p.endsAt)) {
    return const _PromoStatus('منتهي', Color(0xFF6F4E37));
  }
  return const _PromoStatus('مباشر الآن', Color(0xFF00897B));
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.promo,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });
  final Promo promo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  String _d(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String get _linkSummary => switch (promo.linkType) {
        'none' => 'بدون رابط',
        'app' => 'داخل التطبيق: ${kPromoInternalLinks
            .firstWhere((l) => l.encoded == promo.linkValue,
                orElse: () => const PromoInternalLink('؟', ''))
            .label}',
        _ => '${kPromoExternalKinds
                .firstWhere((k) => k.key == promo.linkType,
                    orElse: () => kPromoExternalKinds.first)
                .label}: ${promo.linkValue}',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _promoStatus(promo);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: status.color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: CachedNetworkImage(
                      imageUrl: promo.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                              child: Icon(Icons.image_rounded,
                                  size: 22, color: Colors.black26))),
                      errorWidget: (_, __, ___) =>
                          const ColoredBox(
                              color: Colors.black12,
                              child: Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      size: 22))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(promo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14.5)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _miniChip(status.label, status.color, solid: true),
                          _miniChip(promoPlacementLabel(promo.placement),
                              QurityAppBar.headerColor),
                          _miniChip(
                              promo.showOnce
                                  ? 'مرة واحدة'
                                  : 'كل زيارة',
                              const Color(0xFF1565C0)),
                          if (promo.playSound)
                            _miniChip('🔊 صوت', Colors.black38),
                          if (promo.vibrate)
                            _miniChip('📳 اهتزاز', Colors.black38),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: promo.isActive,
                  activeThumbColor: const Color(0xFF00897B),
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                      'من ${_d(promo.startsAt)} إلى ${_d(promo.endsAt)} — $_linkSummary',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
                IconButton(
                  tooltip: 'تعديل',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded,
                      size: 18, color: Color(0xFF1565C0)),
                ),
                IconButton(
                  tooltip: 'حذف',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String text, Color color, {bool solid = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: solid ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: solid ? null : Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: solid ? Colors.white : color)),
      );
}

/// نموذج إنشاء/تعديل إعلان دعائي.
class _PromoFormSheet extends StatefulWidget {
  const _PromoFormSheet({this.promo, this.adminUid});
  final Promo? promo;
  final String? adminUid;

  @override
  State<_PromoFormSheet> createState() => _PromoFormSheetState();
}

class _PromoFormSheetState extends State<_PromoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _linkValue;
  final ImagePicker _picker = ImagePicker();

  String _imageUrl = '';
  String _placement = 'home';
  String _linkType = 'none';
  bool _showOnce = true;
  bool _playSound = false;
  bool _vibrate = false;
  DateTime? _start;
  DateTime? _end;
  bool _uploading = false;
  bool _saving = false;

  Promo? get _editing => widget.promo;
  bool get _isEdit => _editing != null;

  @override
  void initState() {
    super.initState();
    final p = _editing;
    _title = TextEditingController(text: p?.title ?? '');
    _linkValue = TextEditingController(text: p?.linkValue ?? '');
    _imageUrl = p?.imageUrl ?? '';
    _placement = p?.placement ?? 'home';
    _linkType = p?.linkType ?? 'none';
    _showOnce = p?.showOnce ?? true;
    _playSound = p?.playSound ?? false;
    _vibrate = p?.vibrate ?? false;
    _start = p?.startsAt ?? DateTime.now();
    _end = p?.endsAt ??
        DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _title.dispose();
    _linkValue.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1400, imageQuality: 86);
      if (x == null) return;
      setState(() => _uploading = true);
      final bytes = await x.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _uploading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_start ?? now)
          : (_end ?? now.add(const Duration(days: 7))),
      firstDate: isStart
          ? now.subtract(const Duration(days: 365))
          : (_start ?? now),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end != null && !_end!.isAfter(_start!)) {
          _end = _start!.add(const Duration(days: 1));
        }
      } else {
        _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  String? get _linkValidationError {
    final v = _linkValue.text.trim();
    if (_linkType == 'none') return null;
    if (_linkType == 'app') {
      return v.isEmpty ? 'اختر شاشة الهدف' : null;
    }
    if (v.isEmpty) return 'أدخل قيمة الرابط';
    final url = buildExternalUrl(_linkType, v);
    if (url == null || !url.startsWith('http')) {
      return 'صيغة غير صحيحة لهذا النوع';
    }
    return null;
  }

  Promo _draft() {
    return Promo(
      id: _editing?.id ?? '',
      title: _title.text.trim(),
      imageUrl: _imageUrl,
      placement: _placement,
      linkType: _linkType,
      linkValue: _linkValue.text.trim(),
      showOnce: _showOnce,
      startsAt: _start ?? DateTime.now(),
      endsAt: _end ?? DateTime.now().add(const Duration(days: 1)),
      isActive: _editing?.isActive ?? true,
      playSound: _playSound,
      vibrate: _vibrate,
      version: _editing?.version ?? 1,
      createdBy: _editing?.createdBy ?? widget.adminUid ?? '',
      createdAt: _editing?.createdAt,
    );
  }

  Future<void> _preview() async {
    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ارفق صورة الإعلان أولًا')));
      return;
    }
    await showPromoPreview(context, _draft());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الصورة المطلوبة للإعلان')));
      return;
    }
    if (!_end!.isAfter(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نهاية المدة يجب أن بعد بدايتها')));
      return;
    }
    setState(() => _saving = true);
    try {
      final svc = PromoService();
      if (_isEdit) {
        await svc.update(_draft());
      } else {
        await svc.create(_draft());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  InputDecoration _dec(String hint, {String? label}) => InputDecoration(
        hintText: hint,
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  Widget _dateTile(String title, DateTime? d, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: QurityAppBar.headerColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: QurityAppBar.headerColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 16, color: QurityAppBar.headerColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black54)),
                      Text(
                          d == null
                              ? 'حدّد'
                              : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              Text(_isEdit ? 'تعديل إعلان دعائي' : 'إعلان دعائي جديد',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: _dec('اسم داخلي للتمييز — لن يظهر للمستخدم',
                    label: 'اسم الإعلان *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'اسم الإعلان مطلوب'
                    : null,
              ),
              const SizedBox(height: 12),
              // الصورة
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: QurityAppBar.headerColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            QurityAppBar.headerColor.withValues(alpha: 0.4)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _uploading
                      ? const Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2.6))
                      : _imageUrl.isEmpty
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 30,
                                    color: QurityAppBar.headerColor),
                                SizedBox(height: 6),
                                Text('اضغط لاختيار صورة الإعلان',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: QurityAppBar.headerColor)),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                    imageUrl: _imageUrl,
                                    fit: BoxFit.contain),
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: IconButton(
                                    tooltip: 'إزالة الصورة',
                                    style: IconButton.styleFrom(
                                        backgroundColor: Colors.white70),
                                    onPressed: () =>
                                        setState(() => _imageUrl = ''),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 12),
              // مكان الظهور
              DropdownButtonFormField<String>(
                initialValue: _placement,
                borderRadius: BorderRadius.circular(16),
                decoration: _dec('', label: 'مكان الظهور *'),
                items: [
                  for (final group in {
                    for (final p in kPromoPlacements) p.group
                  })
                    DropdownMenuItem<String>(
                      enabled: false,
                      value: 'h_$group',
                      child: Text('— $group —',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary)),
                    ),
                  for (final p in kPromoPlacements)
                    DropdownMenuItem(value: p.key, child: Text(p.label)),
                ],
                onChanged: (v) => setState(
                    () => _placement = (v == null || v.startsWith('h_')) ? _placement : v),
              ),
              const SizedBox(height: 12),
              // الرابط
              DropdownButtonFormField<String>(
                initialValue: _linkType,
                borderRadius: BorderRadius.circular(16),
                decoration: _dec('', label: 'رابط عند الضغط على الصورة'),
                items: [
                  const DropdownMenuItem(
                      value: 'none', child: Text('بدون رابط')),
                  const DropdownMenuItem(
                      value: 'app', child: Text('داخل التطبيق')),
                  ...kPromoExternalKinds.map(
                    (k) => DropdownMenuItem(
                        value: k.key,
                        child: Text('${k.label} (رابط خارجي)')),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _linkType = v ?? 'none';
                  _linkValue.clear();
                }),
              ),
              if (_linkType == 'app') ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _linkValue.text.isEmpty
                      ? null
                      : _linkValue.text,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 380,
                  decoration: _dec('', label: 'شاشة الهدف *'),
                  items: [
                    for (final l in kPromoInternalLinks)
                      DropdownMenuItem(
                          value: l.encoded, child: Text(l.label)),
                  ],
                  onChanged: (v) => setState(() {
                    _linkValue.text = v ?? '';
                  }),
                ),
              ] else if (_linkType != 'none') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _linkValue,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _dec(
                    kPromoExternalKinds
                        .firstWhere((k) => k.key == _linkType,
                            orElse: () => kPromoExternalKinds.first)
                        .hint,
                    label: 'قيمة الرابط *',
                  ),
                  validator: (_) => _linkValidationError,
                ),
              ],
              const SizedBox(height: 12),
              // المدة (إلزامية)
              Row(
                children: [
                  _dateTile('بداية العرض', _start, () => _pickDate(true)),
                  const SizedBox(width: 10),
                  _dateTile('نهاية العرض', _end, () => _pickDate(false)),
                ],
              ),
              const SizedBox(height: 12),
              // التكرار
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: true,
                      icon: Icon(Icons.looks_one_rounded, size: 16),
                      label: Text('مرة واحدة لكل مستخدم',
                          style: TextStyle(fontSize: 11))),
                  ButtonSegment(
                      value: false,
                      icon: Icon(Icons.refresh_rounded, size: 16),
                      label: Text('كل زيارة', style: TextStyle(fontSize: 11))),
                ],
                selected: {_showOnce},
                onSelectionChanged: (s) =>
                    setState(() => _showOnce = s.first),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _playSound,
                onChanged: (v) => setState(() => _playSound = v),
                title: const Text('🔊 تشغيل صوت تنبيه عند الظهور',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _vibrate,
                onChanged: (v) => setState(() => _vibrate = v),
                title: const Text('📳 اهتزاز الجهاز عند الظهور',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploading ? null : _preview,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: QurityAppBar.headerColor,
                          side: const BorderSide(
                              color: QurityAppBar.headerColor, width: 1.4),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('معاينة حية',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _saving || _uploading ? null : _save,
                      style: FilledButton.styleFrom(
                          backgroundColor: QurityAppBar.headerColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(_isEdit ? 'حفظ التعديلات' : 'نشر الإعلان',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
