import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/relative_time.dart';
import '../../models/village_ad_model.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/user_service.dart';
import '../../services/village_ad_service.dart';
import '../../widgets/ad_photo_frame.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة «إعلانات القرية» — إعلانات تجارية وخدمية وإنشائية لأهل القرية.
/// المعتمد منها فقط يظهر للقرية، وصاحب الإعلان يرى معلّقه ويعدّله ويحذفه.
class VillageAdsScreen extends StatefulWidget {
  const VillageAdsScreen({super.key, this.service});

  /// قابل للحقن لاختبار الشاشة بلا Firebase (نمط المشروع).
  final VillageAdService? service;

  @override
  State<VillageAdsScreen> createState() => _VillageAdsScreenState();
}

class _VillageAdsScreenState extends State<VillageAdsScreen> {
  late final VillageAdService _service =
      widget.service ?? VillageAdService();
  late final Stream<List<VillageAd>> _feed = _service.watchApproved();
  final TextEditingController _search = TextEditingController();

  String _kind = '';
  String _query = '';
  bool _mineOnly = false;
  String _myUid = '';
  Stream<List<VillageAd>>? _mineStream;

  @override
  void initState() {
    super.initState();
    _search.addListener(
        () => setState(() => _query = _search.text.trim().toLowerCase()));
    try {
      _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      _myUid = '';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VillageAd> _apply(List<VillageAd> all) => all.where((ad) {
        if (_kind.isNotEmpty && ad.kind != _kind) return false;
        if (_query.isEmpty) return true;
        return [
          ad.title,
          ad.businessName,
          ad.description,
          ad.location,
          ad.kind,
        ].join(' ').toLowerCase().contains(_query);
      }).toList();

  void _toggleMine() {
    setState(() {
      _mineOnly = !_mineOnly;
      if (_mineOnly && _myUid.isNotEmpty) {
        _mineStream ??= _service.watchMine(_myUid);
      }
    });
  }

  Future<void> _openForm([VillageAd? existing]) async {
    String uid = _myUid;
    var name = '';
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? uid;
      name = (await UserService().resolveAuthor()).name;
    } catch (_) {
      // لا جلسة (اختبارات/متصفح بلا تسجيل): النموذج يظل يعمل بحقل الاسم.
    }
    if (existing == null && uid.isEmpty) {
      _snack('سجّل الدخول أولاً لنشر إعلان', error: true);
      return;
    }
    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => VillageAdFormSheet(
        userId: existing?.userId ?? uid,
        userName: name,
        existing: existing,
      ),
    );
    if (result == true && mounted) {
      _snack(existing == null
          ? 'تم إرسال الإعلان — يظهر للقرية بعد موافقة الإدارة'
          : 'تم حفظ التعديلات');
    }
  }

  Future<void> _confirmDelete(VillageAd ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('سيُحذف «${ad.title}» نهائيًا ولن يظهر لأحد.'),
        actions: [
          TextButton(
            key: const Key('ad-delete-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const Key('ad-delete-confirm'),
            style: FilledButton.styleFrom(backgroundColor: kAdsDeleteRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(ad.id);
      _snack('تم حذف «${ad.title}»');
    } catch (_) {
      _snack('تعذّر الحذف — تحقّق من الصلاحيات ثم أعد المحاولة.', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? kAdsDeleteRed : kVillageAdsColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _kindChip(String value, String label, IconData icon) {
    final selected = _kind == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _kind = value),
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : null),
      label: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : null)),
      selectedColor: kVillageAdsColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
        title: 'إعلانات القرية',
        onAdd: () => _openForm(),
        addTooltip: 'أضف إعلاناً',
      ),
      body: Column(
        children: [
          Container(
            color: kVillageAdsColor.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              children: [
                TextField(
                  key: const Key('ads-search'),
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'ابحث: نشاط، وصف، مكان…',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: kVillageAdsColor, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'مسح',
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: _search.clear,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _kindChip('', 'الكل', Icons.apps_rounded),
                      const SizedBox(width: 8),
                      for (final kind in kVillageAdKinds) ...[
                        _kindChip(kind, kind, villageAdKindIcon(kind)),
                        const SizedBox(width: 8),
                      ],
                      ChoiceChip(
                        key: const Key('ads-mine-toggle'),
                        selected: _mineOnly,
                        onSelected: (_) => _toggleMine(),
                        avatar: Icon(
                            _myUid.isEmpty
                                ? Icons.lock_outline_rounded
                                : Icons.person_rounded,
                            size: 16),
                        label: const Text('إعلاناتي',
                            style:
                                TextStyle(fontWeight: FontWeight.w800)),
                        selectedColor: kVillageAdsColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<VillageAd>>(
              stream: _mineOnly ? _mineStream : _feed,
              builder: (context, snap) {
                if (_mineOnly && _myUid.isEmpty) {
                  return _empty(
                      theme, Icons.lock_outline_rounded, 'سجّل الدخول لترى إعلاناتك');
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kVillageAdsColor));
                }
                final items = _apply(snap.data!);
                if (items.isEmpty) {
                  return _empty(
                      theme,
                      Icons.campaign_rounded,
                      _mineOnly
                          ? 'لم تنشر أي إعلان بعد\nاضغط «+» في الأعلى'
                          : (_query.isNotEmpty || _kind.isNotEmpty
                              ? 'لا توجد إعلانات مطابقة'
                              : 'لا توجد إعلانات بعد\nكن أول من ينشر إعلاناً'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final ad = items[i];
                    return VillageAdCard(
                      ad: ad,
                      showStatus: _mineOnly,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.villageAdDetail,
                          arguments: ad),
                      onEdit: _mineOnly ? () => _openForm(ad) : null,
                      onDelete: _mineOnly ? () => _confirmDelete(ad) : null,
                    ).animate(delay: ((i % 8) * 35).ms).fadeIn(duration: 300.ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(ThemeData theme, IconData icon, String text) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 54, color: kVillageAdsColor.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}

/// بطاقة إعلان واحدة — مساحة صورة معلومة الارتفاع يملؤها الرسم، ثم العنوان
/// والوصف، فتتساوى البطاقات ولو اختلفت مقاسات صور أصحاب الإعلانات.
class VillageAdCard extends StatelessWidget {
  const VillageAdCard({
    super.key,
    required this.ad,
    required this.onTap,
    this.showStatus = false,
    this.onEdit,
    this.onDelete,
  });

  final VillageAd ad;
  final VoidCallback onTap;
  final bool showStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: kVillageAdsColor.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdPhotoFrame(
              imageUrl: ad.imageUrl,
              height: kVillageAdCardImageHeight,
              accent: kVillageAdsColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _KindMark(kind: ad.kind),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(ad.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16.5)),
                      ),
                    ],
                  ),
                  if (ad.businessName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(ad.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: kVillageAdsColor)),
                  ],
                  if (ad.description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(ad.description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 12,
                    runSpacing: 5,
                    children: [
                      if (ad.location.isNotEmpty)
                        _Meta(icon: Icons.place_rounded, text: ad.location),
                      if (ad.phone.isNotEmpty)
                        _Meta(icon: Icons.phone_rounded, text: ad.phone),
                      _Meta(
                          icon: Icons.schedule_rounded,
                          text: relativeTimeLabelAr(ad.createdAt)),
                    ],
                  ),
                  if (showStatus) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatusMark(approved: ad.isApproved),
                        const Spacer(),
                        if (onEdit != null)
                          IconButton(
                            key: Key('ad-edit-${ad.id}'),
                            tooltip: 'تعديل الإعلان',
                            icon: const Icon(Icons.edit_rounded, size: 19),
                            onPressed: onEdit,
                          ),
                        if (onDelete != null)
                          IconButton(
                            key: Key('ad-delete-${ad.id}'),
                            tooltip: 'حذف الإعلان',
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 19, color: kAdsDeleteRed),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة نوع الإعلان (تجارية / خدمية / إنشائية).
class _KindMark extends StatelessWidget {
  const _KindMark({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: kVillageAdsColor,
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(villageAdKindIcon(kind), size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(kind,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
      );
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.approved});
  final bool approved;

  @override
  Widget build(BuildContext context) {
    final color = approved ? const Color(0xFF2E7D32) : kAdsPendingOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(approved ? 'منشور للقرية ✓' : 'بانتظار موافقة الإدارة',
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w900, color: color)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kVillageAdsColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      );
}

/// نموذج إضافة/تعديل إعلان — النوع + العنوان + اسم النشاط + الوصف + المكان +
/// الهاتف + حتى ثلاث صور. الرفع يفشل بصوت عالٍ: لا تضيع صورة بصمت.
class VillageAdFormSheet extends StatefulWidget {
  const VillageAdFormSheet({
    super.key,
    required this.userId,
    this.userName = '',
    this.existing,
    this.service,
    this.uploader,
    this.bytesSource,
  });

  final String userId;
  final String userName;
  final VillageAd? existing;
  final VillageAdService? service;

  /// اختياري لاختبار المحرّر المشترك بلا شبكة ولا معرض جهاز.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  @override
  State<VillageAdFormSheet> createState() => _VillageAdFormSheetState();
}

class _VillageAdFormSheetState extends State<VillageAdFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _business =
      TextEditingController(text: widget.existing?.businessName ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _location =
      TextEditingController(text: widget.existing?.location ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final VillageAdService _service =
      widget.service ?? VillageAdService();

  late String _kind = widget.existing?.kind ?? 'تجارية';
  late final List<String> _images = [...?widget.existing?.imageUrls];
  String _uploadError = '';
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _business.dispose();
    _description.dispose();
    _location.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final base = VillageAd(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      kind: _kind,
      businessName: _business.text.trim(),
      description: _description.text.trim(),
      phone: _phone.text.trim(),
      location: _location.text.trim(),
      imageUrls: List.unmodifiable(_images),
      userId: widget.userId,
      userName: widget.existing?.userName ?? widget.userName,
      isApproved: widget.existing?.isApproved ?? false,
      createdAt: widget.existing?.createdAt,
    );
    try {
      final existing = widget.existing;
      if (existing == null) {
        await _service.create(base);
      } else {
        await _service.update(existing.id, base);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadError = 'تعذّر الحفظ — تحقّق من الاتصال ومن صلاحياتك.';
        });
      }
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
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
              Text(
                  widget.existing == null
                      ? 'إعلان جديد للقرية'
                      : 'تعديل الإعلان',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final kind in kVillageAdKinds) ...[
                    Expanded(
                      child: _kindButton(kind, villageAdKindIcon(kind)),
                    ),
                    if (kind != kVillageAdKinds.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('ad-field-title'),
                controller: _title,
                decoration: _dec('عنوان الإعلان (مفتاح، أو «محل…») *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _business,
                decoration: _dec('اسم النشاط أو المحل (اختياري)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('ad-field-description'),
                controller: _description,
                maxLines: 5,
                decoration: _dec(
                    'تفاصيل الإعلان: ما تقدّم، الخامات، الأسعار أو «حسب '
                    'المقاس»، مواعيد العمل، منطقة الخدمة…'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _location,
                decoration: _dec('المكان / عنوان الورشة أو المحل'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('ad-field-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec('هاتف التواصل (اتصال/واتساب) *'),
                validator: (v) => (v == null || v.trim().length < 8)
                    ? 'ضع رقم تواصل صحيحًا ليصل إليك الأهالي'
                    : null,
              ),
              const SizedBox(height: 12),
              ImageListEditor(
                label: 'صور الإعلان (حتى $kVillageAdMaxImages)',
                fieldKey: 'imageUrls',
                urls: _images,
                maxImages: kVillageAdMaxImages,
                uploader: widget.uploader,
                bytesSource: widget.bytesSource,
                maxSide: 1280,
                onBusyChanged: (busy) => setState(() => _uploading = busy),
                onChanged: (urls) =>
                    setState(() => _images..clear()..addAll(urls)),
              ),
              if (_uploadError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  key: const Key('ad-upload-error'),
                  _uploadError,
                  style: const TextStyle(
                      color: kAdsDeleteRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),
              _notice(theme),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('ad-save'),
                  onPressed: _saving || _uploading ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: kVillageAdsColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                      widget.existing == null
                          ? 'إرسال للنشر بعد المراجعة'
                          : 'حفظ التعديلات',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notice(ThemeData theme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kAdsDeleteRed.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAdsDeleteRed.withValues(alpha: 0.35))),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kAdsDeleteRed, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'يظهر الإعلان للقرية بعد موافقة الإدارة، ولا يُقبل إعلان مخالف '
                'أو مكرر. يمكنك تعديله أو حذفه في أي وقت من «إعلاناتي».',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: kAdsDeleteRed,
                    height: 1.5),
              ),
            ),
          ],
        ),
      );

  Widget _kindButton(String kind, IconData icon) {
    final selected = _kind == kind;
    return InkWell(
      key: Key('ad-kind-$kind'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _kind = kind),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kVillageAdsColor : kVillageAdsColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? kVillageAdsColor
                  : kVillageAdsColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : kVillageAdsColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(kind,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: selected ? Colors.white : kVillageAdsColor)),
            ),
          ],
        ),
      ),
    );
  }
}

/// أحمر الإعلانات المخالفة/الحذف — مستقل عن أخضر «منشور».
const Color kAdsDeleteRed = Color(0xFFB71C1C);
const Color kAdsPendingOrange = Color(0xFFEF6C00);
