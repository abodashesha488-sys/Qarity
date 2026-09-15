import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/contact_links.dart';
import '../../models/lost_item_model.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/lost_item_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/qurity_app_bar.dart';

String _fmtDate(DateTime? d) => d == null
    ? ''
    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// شاشة المفقودات — قائمة إعلانات الأشياء المفقودة/الموجودة في القرية.
class LostItemsScreen extends StatefulWidget {
  const LostItemsScreen({super.key});

  @override
  State<LostItemsScreen> createState() => _LostItemsScreenState();
}

class _LostItemsScreenState extends State<LostItemsScreen> {
  final LostItemService _service = LostItemService();
  late final Stream<List<LostItem>> _stream = _service.watchApproved();
  final TextEditingController _search = TextEditingController();
  String _filter = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
        () => setState(() => _query = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<LostItem> _apply(List<LostItem> all) => all.where((i) {
        if (_filter == 'lost') return i.isLostType && !i.isResolved;
        if (_filter == 'found') return !i.isLostType && !i.isResolved;
        if (_filter == 'resolved') return i.isResolved;
        return true;
      }).where((i) {
        if (_query.isEmpty) return true;
        return [i.title, i.description, i.location, i.userName]
            .join(' ')
            .toLowerCase()
            .contains(_query);
      }).toList();

  Future<void> _openForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('سجّل الدخول أولاً لنشر إعلان', error: true);
      return;
    }
    final identity = await UserService().resolveAuthor();
    if (!mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _LostFormSheet(userId: user.uid, userName: identity.name),
    );
    if (ok == true) {
      _snack('تم إرسال الإعلان — يظهر للقرية بعد موافقة الإدارة');
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : kLostItemsColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _chip(String value, String label, IconData icon) {
    final selected = _filter == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      avatar: Icon(icon,
          size: 16,
          color: selected ? Colors.white : kLostItemsColor),
      label: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : null)),
      selectedColor: kLostItemsColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(title: 'المفقودات', color: kLostItemsColor),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lost_items_fab',
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('أضف إعلاناً',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: kLostItemsColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: kLostItemsColor.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'ابحث: غرض، مكان، صاحب الإعلان…',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: kLostItemsColor, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'مسح',
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: _search.clear,
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: kLostItemsColor.withValues(alpha: 0.4))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: kLostItemsColor.withValues(alpha: 0.4))),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('', 'الكل', Icons.apps_rounded),
                      const SizedBox(width: 8),
                      _chip('lost', 'مفقود', Icons.help_rounded),
                      const SizedBox(width: 8),
                      _chip('found', 'تم العثور عليه', Icons.search_rounded),
                      const SizedBox(width: 8),
                      _chip('resolved', 'تم التسليم', Icons.verified_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LostItem>>(
              stream: _stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: kLostItemsColor));
                }
                final items = _apply(snap.data!);
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wrong_location_rounded,
                            size: 54,
                            color: kLostItemsColor.withValues(alpha: 0.4)),
                        const SizedBox(height: 10),
                        Text(
                          _query.isNotEmpty || _filter.isNotEmpty
                              ? 'لا توجد نتائج مطابقة'
                              : 'لا توجد إعلانات مفقودات بعد\nكن أول من ينشر إعلاناً',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _LostItemCard(item: items[i])
                      .animate(delay: ((i % 8) * 35).ms)
                      .fadeIn(duration: 300.ms),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LostItemCard extends StatelessWidget {
  const _LostItemCard({required this.item});
  final LostItem item;

  Color get _typeColor =>
      item.isResolved ? Colors.blueGrey : (item.isLostType ? const Color(0xFFC62828) : const Color(0xFF00897B));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmed = item.isResolved;
    return Opacity(
      opacity: dimmed ? 0.65 : 1,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: _typeColor.withValues(alpha: dimmed ? 0.25 : 0.45),
              width: dimmed ? 1 : 1.2),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.lostItemDetail,
              arguments: item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _thumb(theme),
                          )
                        : _thumb(theme),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: _typeColor,
                                borderRadius: BorderRadius.circular(7)),
                            child: Text(
                                dimmed
                                    ? 'تم التسليم ✓'
                                    : (item.isLostType
                                        ? 'مفقود'
                                        : 'تم العثور عليه'),
                                style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4)),
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        children: [
                          if (item.location.isNotEmpty)
                            _meta(Icons.place_rounded, item.location,
                                _typeColor),
                          if (item.date != null)
                            _meta(Icons.event_rounded, _fmtDate(item.date),
                                _typeColor),
                          if (item.userName.isNotEmpty)
                            _meta(Icons.person_rounded, item.userName,
                                _typeColor),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumb(ThemeData theme) => ColoredBox(
        color: _typeColor.withValues(alpha: 0.12),
        child: Icon(
            item.isLostType
                ? Icons.help_outline_rounded
                : Icons.search_rounded,
            color: _typeColor,
            size: 26),
      );

  Widget _meta(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Builder(builder: (context) => Text(text,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      );
}

/// تفاصيل إعلان مفقود — اتصال / واتساب / مشاركة / تسليم (لصاحب الإعلان).
class LostItemDetailScreen extends StatefulWidget {
  const LostItemDetailScreen({super.key});

  @override
  State<LostItemDetailScreen> createState() => _LostItemDetailScreenState();
}

class _LostItemDetailScreenState extends State<LostItemDetailScreen> {
  final LostItemService _service = LostItemService();
  LostItem? _item;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _item ??= ModalRoute.of(context)!.settings.arguments as LostItem?;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleResolved() async {
    final item = _item;
    if (item == null) return;
    setState(() => _busy = true);
    try {
      await _service.setResolved(item.id, !item.isResolved);
      if (mounted) {
        setState(() {
          _item = item.copyWith(isResolved: !item.isResolved);
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تعذّر التحديث: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _item;
    if (item == null) {
      return const Scaffold(
        appBar: QurityAppBar(title: 'المفقودات', color: kLostItemsColor),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final typeColor = item.isResolved
        ? Colors.blueGrey
        : (item.isLostType
            ? const Color(0xFFC62828)
            : const Color(0xFF00897B));
    String? myUid;
    try {
      myUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      myUid = null;
    }
    final isOwner = myUid != null && myUid == item.userId;

    return Scaffold(
      appBar: QurityAppBar(
        title: item.title,
        color: kLostItemsColor,
        actions: [
          IconButton(
            tooltip: 'مشاركة الإعلان',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareService.shareText(
              title:
                  '${item.isLostType ? '🔎 مفقود' : '📦 تم العثور عليه'}: ${item.title}',
              body: [
                if (item.location.isNotEmpty) 'المكان: ${item.location}',
                if (item.date != null) 'التاريخ: ${_fmtDate(item.date)}',
                if (item.description.isNotEmpty) item.description,
                if (item.phone.isNotEmpty) 'تواصل: ${item.phone}',
                '— من قرية أبوديشيشة',
              ].join('\n'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: typeColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(
                      item.isLostType
                          ? Icons.help_rounded
                          : Icons.search_rounded,
                      color: Colors.white,
                      size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 3),
                      Text(
                          item.isResolved
                              ? 'تم التسليم — هذا الإعلان مغلق ✓'
                              : (item.isLostType
                                  ? 'إعلان عن غرض مفقود'
                                  : 'غرض تم العثور عليه'),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: typeColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (item.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                      height: 230,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: kLostItemsColor))),
                  errorWidget: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          const SizedBox(height: 14),
          if (item.description.isNotEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(item.description,
                    style: const TextStyle(
                        fontSize: 13.5, height: 1.7,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          const SizedBox(height: 10),
          _infoRow(Icons.place_rounded, 'المكان', item.location),
          _infoRow(Icons.event_rounded, 'التاريخ', _fmtDate(item.date)),
          _infoRow(Icons.person_rounded, 'أضافه الإعلان', item.userName),
          _infoRow(Icons.phone_rounded, 'هاتف التواصل', item.phone),
          const SizedBox(height: 16),
          if (item.phone.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _launch('tel://${item.phone}'),
                    style: FilledButton.styleFrom(
                        backgroundColor: kLostItemsColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('اتصال',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: item.phone.isEmpty
                    ? null
                    : () {
                        final u = egyptianWhatsAppUrl(item.phone);
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
          if (isOwner) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _toggleResolved,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    item.isResolved ? Colors.blueGrey : const Color(0xFF00897B),
                side: BorderSide(
                    color: item.isResolved
                        ? Colors.blueGrey
                        : const Color(0xFF00897B),
                    width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(item.isResolved
                      ? Icons.restart_alt_rounded
                      : Icons.verified_rounded,
                      size: 18),
              label: Text(
                  item.isResolved
                      ? 'إعادة فتح الإعلان'
                      : 'تم التسليم — إغلاق الإعلان',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: kLostItemsColor),
          const SizedBox(width: 9),
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

/// نموذج إضافة إعلان (bottom sheet) — نوع + عنوان + وصف + مكان + تاريخ + هاتف + صورة.
class _LostFormSheet extends StatefulWidget {
  const _LostFormSheet({required this.userId, required this.userName});
  final String userId;
  final String userName;

  @override
  State<_LostFormSheet> createState() => _LostFormSheetState();
}

class _LostFormSheetState extends State<_LostFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _type = 'lost';
  DateTime? _date;
  String _imageUrl = '';
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1280, imageQuality: 82);
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
    } catch (e) {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await LostItemService().create(LostItem(
        title: _title.text.trim(),
        type: _type,
        description: _description.text.trim(),
        location: _location.text.trim(),
        date: _date,
        phone: _phone.text.trim(),
        imageUrl: _imageUrl,
        userId: widget.userId,
        userName: widget.userName,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في الإرسال: $e'),
            backgroundColor: Colors.red));
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
              const Text('إعلان جديد في المفقودات',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _typeButton('مفقود', 'lost',
                        const Color(0xFFC62828), Icons.help_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeButton('وجدت غرضاً', 'found',
                        const Color(0xFF00897B), Icons.search_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: _dec('اسم الغرض (مفتاح، هاتف، حقيبة…) *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: _dec('وصف تفصيلي (لون، علامات مميزة، مكان محتمل…)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _location,
                decoration: _dec('مكان الفقد / العثور (تقريبي)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: _dec('التاريخ'),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 18, color: kLostItemsColor),
                            const SizedBox(width: 7),
                            Text(_date == null
                                ? 'التاريخ (اختياري)'
                                : _fmtDate(_date)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _uploading ? null : _pickImage,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                            color: kLostItemsColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    kLostItemsColor.withValues(alpha: 0.4))),
                        child: Center(
                          child: _uploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: kLostItemsColor))
                              : _imageUrl.isNotEmpty
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_rounded,
                                            size: 18,
                                            color: Color(0xFF00897B)),
                                        SizedBox(width: 6),
                                        Text('الصورة مرفقة ✓',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11.5,
                                                color: Color(0xFF00897B))),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_rounded,
                                            size: 18,
                                            color: kLostItemsColor),
                                        SizedBox(width: 6),
                                        Text('صورة (اختياري)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11.5,
                                                color: kLostItemsColor)),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec('هاتف التواصل (واتساب/اتصال)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving || _uploading ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: kLostItemsColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('إرسال للمراجعة',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label, String value, Color color, IconData icon) {
    final selected = _type == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? color
                  : color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: selected ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
