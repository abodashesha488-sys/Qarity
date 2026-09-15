import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/village_content_models.dart';
import '../../services/admin_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/village_content_service.dart';
import '../../widgets/qurity_app_bar.dart';

/// هل المستخدم الحالي يسمح له بإدارة محتوى «تعرف على القرية»؟
Future<bool> canManageVillageContent() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return false;
    final v = await AdminService().isAdminUser(uid);
    return v;
  } catch (_) {
    return false;
  }
}

InputDecoration vdec(String hint, {String? label}) => InputDecoration(
      hintText: hint,
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: const Color(0x0F000000),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12)),
    );

/// اختيار صورة ورفعها على ImgBB — يعيد الرابط أو null.
Future<String?> pickAndUploadImage(BuildContext context,
    {String? current}) async {
  final picker = ImagePicker();
  try {
    final x = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1400, imageQuality: 86);
    if (x == null) return current;
    if (!context.mounted) return current;
    final dlg = showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: Card(
              child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('جارٍ رفع الصورة…'),
          ],
        ),
      ))),
    );
    unawaited(dlg);
    final bytes = await x.readAsBytes();
    final url = await ImageUploadService().uploadImage(bytes);
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    return url;
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    return current;
  }
}

/// قائمة إدارة عامة لعنصر من عناصر محتوى القرية.
/// النماذج تحفظ بياناتها بنفسها — هنا نتدفّق مع التحديث الفوري للقائمة.
Future<void> manageVillageContent<T>(
  BuildContext context, {
  required String title,
  required Color accent,
  required Stream<List<T>> stream,
  required String Function(T item) nameOf,
  String Function(T item)? subtitleOf,
  required Future<void> Function(String id) remove,
  required Widget Function(BuildContext ctx, T? editing) formBuilder,
}) async {
  Future<void> openForm([T? editing]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(child: formBuilder(ctx, editing)),
      ),
    );
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, scrollController) => StreamBuilder<List<T>>(
        stream: stream,
        builder: (context, snap) {
          final items = snap.data ?? const [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9)),
                      child: Icon(Icons.tune_rounded, color: accent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('إدارة — $title',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                    IconButton(
                      tooltip: 'إضافة جديد',
                      onPressed: () => openForm(),
                      icon: Icon(Icons.add_circle_rounded, color: accent),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('لا توجد عناصر بعد — أضف أول عنصر ＋',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                  color:
                                      accent.withValues(alpha: 0.35)),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(nameOf(item),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                              subtitle: (subtitleOf?.call(item) ?? '')
                                      .isNotEmpty
                                  ? Text(subtitleOf!(item),
                                      maxLines: 1,
                                      style: const TextStyle(fontSize: 11))
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'تعديل',
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 17, color: Color(0xFF1565C0)),
                                    onPressed: () => openForm(item),
                                  ),
                                  IconButton(
                                    tooltip: 'حذف',
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 17, color: Colors.red),
                                    onPressed: () async {
                                      final id = switch (item) {
                                        final HistoryEra e => e.id,
                                        final VillageFigure f => f.id,
                                        final VillageArchivePhoto p => p.id,
                                        final VillageInstitution n => n.id,
                                        _ => '',
                                      };
                                      if (id.isEmpty) return;
                                      await remove(id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// ═══════════════ أنموذج حقبة تاريخية ═══════════════
class HistoryEraForm extends StatefulWidget {
  const HistoryEraForm({super.key, this.editing});
  final HistoryEra? editing;

  @override
  State<HistoryEraForm> createState() => _HistoryEraFormState();
}

class _HistoryEraFormState extends State<HistoryEraForm> {
  late final _title =
      TextEditingController(text: widget.editing?.title ?? '');
  late final _years =
      TextEditingController(text: widget.editing?.years ?? '');
  late final _narrative =
      TextEditingController(text: widget.editing?.narrative ?? '');
  late final _order =
      TextEditingController(text: '${widget.editing?.sortOrder ?? 0}');
  late String _imageUrl = widget.editing?.imageUrl ?? '';
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _years.dispose();
    _narrative.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _narrative.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('العنوان والسرد مطلوبان'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    await VillageContentService().saveEra(HistoryEra(
      id: widget.editing?.id ?? '',
      title: _title.text.trim(),
      years: _years.text.trim(),
      narrative: _narrative.text.trim(),
      imageUrl: _imageUrl,
      sortOrder: int.tryParse(_order.text.trim()) ?? 0,
      createdAt: widget.editing?.createdAt,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حقبة تاريخية',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
              controller: _title,
              decoration: vdec('مثال: نشأة القرية', label: 'عنوان الحقبة *')),
          const SizedBox(height: 10),
          TextField(
              controller: _years,
              decoration: vdec('مثال: 1800م — 1900م', label: 'السنوات')),
          const SizedBox(height: 10),
          TextField(
              controller: _narrative,
              maxLines: 6,
              decoration: vdec('اكتب سرد الحقبة بالتفصيل…', label: 'السرد *')),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                  width: 90,
                  child: TextField(
                      controller: _order,
                      keyboardType: TextInputType.number,
                      decoration: vdec('0', label: 'الترتيب'))),
              const SizedBox(width: 12),
              Expanded(child: _imageTile()),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _saving || _uploading ? null : _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: QurityAppBar.headerColor,
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ الحقبة',
                      style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(height: 8),
        ],
      );

  Widget _imageTile() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _uploading
          ? null
          : () async {
              setState(() => _uploading = true);
              final url = await pickAndUploadImage(context, current: _imageUrl);
              if (mounted) {
                setState(() {
                  _imageUrl = url ?? '';
                  _uploading = false;
                });
              }
            },
      child: Container(
        height: 74,
        decoration: BoxDecoration(
            color: const Color(0x0A000000),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12)),
        clipBehavior: Clip.antiAlias,
        child: _uploading
            ? const Center(
                child:
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
            : _imageUrl.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 20, color: Colors.black38),
                      Text('صورة (اختياري)',
                          style: TextStyle(fontSize: 10, color: Colors.black38)),
                    ],
                  )
                : CachedNetworkImage(imageUrl: _imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}

// ═══════════════ أنموذج شخصية ═══════════════
class FigureForm extends StatefulWidget {
  const FigureForm({super.key, this.editing});
  final VillageFigure? editing;

  @override
  State<FigureForm> createState() => _FigureFormState();
}

class _FigureFormState extends State<FigureForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _era = TextEditingController(text: widget.editing?.era ?? '');
  late final _bio = TextEditingController(text: widget.editing?.bio ?? '');
  late final _order =
      TextEditingController(text: '${widget.editing?.sortOrder ?? 0}');
  late String _category =
      widget.editing?.category ?? FigureCategory.elders;
  late String _photoUrl = widget.editing?.photoUrl ?? '';
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _era.dispose();
    _bio.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('اسم الشخصية مطلوب'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    await VillageContentService().saveFigure(VillageFigure(
      id: widget.editing?.id ?? '',
      name: _name.text.trim(),
      category: _category,
      title: _title.text.trim(),
      era: _era.text.trim(),
      bio: _bio.text.trim(),
      photoUrl: _photoUrl,
      sortOrder: int.tryParse(_order.text.trim()) ?? 0,
      createdAt: widget.editing?.createdAt,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('شخصية من شخصيات القرية',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            borderRadius: BorderRadius.circular(16),
            decoration: vdec('', label: 'التصنيف'),
            items: [
              for (final c in FigureCategory.all)
                DropdownMenuItem(
                    value: c,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FigureCategory.icon(c),
                            size: 16, color: FigureCategory.color(c)),
                        const SizedBox(width: 7),
                        Text(FigureCategory.label(c)),
                      ],
                    )),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _name,
              decoration: vdec('الاسم الكامل *', label: 'الاسم')),
          const SizedBox(height: 10),
          TextField(
              controller: _title,
              decoration: vdec('مثال: عمدة القرية 1970 — 1982', label: 'المنصب/اللقب')),
          const SizedBox(height: 10),
          TextField(
              controller: _era,
              decoration: vdec('مثال: منتصف القرن العشرين', label: 'الحقبة')),
          const SizedBox(height: 10),
          TextField(
              controller: _bio,
              maxLines: 4,
              decoration: vdec('سيرة مختصرة…', label: 'السيرة')),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                  width: 90,
                  child: TextField(
                      controller: _order,
                      keyboardType: TextInputType.number,
                      decoration: vdec('0', label: 'الترتيب'))),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _uploading
                      ? null
                      : () async {
                          setState(() => _uploading = true);
                          final url = await pickAndUploadImage(context,
                              current: _photoUrl);
                          if (mounted) {
                            setState(() {
                              _photoUrl = url ?? '';
                              _uploading = false;
                            });
                          }
                        },
                  child: Container(
                    height: 74,
                    decoration: BoxDecoration(
                        color: const Color(0x0A000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12)),
                    clipBehavior: Clip.antiAlias,
                    child: _uploading
                        ? const Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)))
                        : _photoUrl.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.portrait_rounded,
                                      size: 20, color: Colors.black38),
                                  Text('الصورة',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black38)),
                                ],
                              )
                            : CachedNetworkImage(
                                imageUrl: _photoUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _saving || _uploading ? null : _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ الشخصية',
                      style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(height: 8),
        ],
      );
}

// ═══════════════ أنموذج صورة أرشيفية ═══════════════
class ArchivePhotoForm extends StatefulWidget {
  const ArchivePhotoForm({super.key, this.editing});
  final VillageArchivePhoto? editing;

  @override
  State<ArchivePhotoForm> createState() => _ArchivePhotoFormState();
}

class _ArchivePhotoFormState extends State<ArchivePhotoForm> {
  late final _title =
      TextEditingController(text: widget.editing?.title ?? '');
  late final _year = TextEditingController(text: widget.editing?.year ?? '');
  late final _description =
      TextEditingController(text: widget.editing?.description ?? '');
  late final _source =
      TextEditingController(text: widget.editing?.source ?? '');
  late String _imageUrl = widget.editing?.imageUrl ?? '';
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _year.dispose();
    _description.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عنوان الصورة مطلوب'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    await VillageContentService().saveArchivePhoto(VillageArchivePhoto(
      id: widget.editing?.id ?? '',
      title: _title.text.trim(),
      year: _year.text.trim(),
      description: _description.text.trim(),
      source: _source.text.trim(),
      imageUrl: _imageUrl,
      createdAt: widget.editing?.createdAt,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('صورة / وثيقة أرشيفية',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
              controller: _title,
              decoration: vdec('مثال: صورة للسوق القديم', label: 'العنوان *')),
          const SizedBox(height: 10),
          TextField(
              controller: _year,
              decoration: vdec('مثال: 1962م', label: 'السنة')),
          const SizedBox(height: 10),
          TextField(
              controller: _description,
              maxLines: 3,
              decoration: vdec('وصف ما في الصورة…', label: 'الوصف')),
          const SizedBox(height: 10),
          TextField(
              controller: _source,
              decoration: vdec('مثال: ألبوم عائلة …', label: 'مصدر الصورة')),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _uploading
                ? null
                : () async {
                    setState(() => _uploading = true);
                    final url =
                        await pickAndUploadImage(context, current: _imageUrl);
                    if (mounted) {
                      setState(() {
                        _imageUrl = url ?? '';
                        _uploading = false;
                      });
                    }
                  },
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0x0A000000),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12)),
              clipBehavior: Clip.antiAlias,
              child: _uploading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : _imageUrl.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 26, color: Colors.black38),
                            Text('اختر صورة الأرشيف',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.black38)),
                          ],
                        )
                      : CachedNetworkImage(
                          imageUrl: _imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _saving || _uploading ? null : _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ الصورة',
                      style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(height: 8),
        ],
      );
}

// ═══════════════ أنموذج منشأة ═══════════════
class InstitutionForm extends StatefulWidget {
  const InstitutionForm({super.key, this.editing});
  final VillageInstitution? editing;

  @override
  State<InstitutionForm> createState() => _InstitutionFormState();
}

class _InstitutionFormState extends State<InstitutionForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _description =
      TextEditingController(text: widget.editing?.description ?? '');
  late final _location =
      TextEditingController(text: widget.editing?.location ?? '');
  late final _phone =
      TextEditingController(text: widget.editing?.phone ?? '');
  late final _hours =
      TextEditingController(text: widget.editing?.workingHours ?? '');
  late final _order =
      TextEditingController(text: '${widget.editing?.sortOrder ?? 0}');
  late String _type = widget.editing?.type ?? InstitutionType.schools;
  late final List<String> _images = [...?widget.editing?.imageUrls];
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    _phone.dispose();
    _hours.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('اسم المنشأة مطلوب'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    await VillageContentService().saveInstitution(VillageInstitution(
      id: widget.editing?.id ?? '',
      name: _name.text.trim(),
      type: _type,
      description: _description.text.trim(),
      location: _location.text.trim(),
      phone: _phone.text.trim(),
      workingHours: _hours.text.trim(),
      imageUrls: _images,
      sortOrder: int.tryParse(_order.text.trim()) ?? 0,
      createdAt: widget.editing?.createdAt,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('منشأة من منشآت القرية',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            borderRadius: BorderRadius.circular(16),
            decoration: vdec('', label: 'نوع المنشأة'),
            items: [
              for (final t in InstitutionType.ordered)
                DropdownMenuItem(
                    value: t,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(InstitutionType.icon(t),
                            size: 16, color: InstitutionType.color(t)),
                        const SizedBox(width: 7),
                        Text(InstitutionType.label(t)),
                      ],
                    )),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _name,
              decoration: vdec('مثال: مدرسة أبوديشيشة الابتدائية', label: 'الاسم *')),
          const SizedBox(height: 10),
          TextField(
              controller: _description,
              maxLines: 3,
              decoration: vdec('نبذة عن المنشأة…', label: 'الوصف')),
          const SizedBox(height: 10),
          TextField(
              controller: _location,
              decoration: vdec('موقعها داخل القرية', label: 'الموقع')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: vdec('هاتف', label: 'تليفون'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _hours,
                      decoration: vdec('مثال: 8ص — 2ظ', label: 'المواعيد'))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: vdec('0', label: 'الترتيب داخل النوع')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final u in _images)
                Stack(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                            imageUrl: u, width: 70, height: 70, fit: BoxFit.cover)),
                    Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(u)),
                          child: const CircleAvatar(
                              radius: 9,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close,
                                  size: 11, color: Colors.white)),
                        )),
                  ],
                ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _uploading
                    ? null
                    : () async {
                        setState(() => _uploading = true);
                        final url = await pickAndUploadImage(context);
                        if (mounted && url != null && url.isNotEmpty) {
                          setState(() => _images.add(url));
                        }
                        if (mounted) setState(() => _uploading = false);
                      },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: const Color(0x0A000000),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12)),
                  child: _uploading
                      ? const Center(
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)))
                      : const Icon(Icons.add_photo_alternate_rounded,
                          size: 22, color: Colors.black38),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _saving || _uploading ? null : _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ المنشأة',
                      style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(height: 8),
        ],
      );
}
