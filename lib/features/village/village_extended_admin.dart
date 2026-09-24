import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_content_admin.dart';

/// مكتبة نماذج إدارة محتوى «تعرف على القرية» الموسّع.
/// كل نموذج StatefulWidget يحفظ بنفسه عبر [VillageExtendedService]
/// ثم يغلق الـ bottom sheet — بنفس أسلوب HistoryEraForm في
/// `village_content_admin.dart`.

/// تقسيم نص مفصول بفواصل عربية/إنجليزية إلى قائمة.
List<String> _splitCsv(String s) => s
    .split(RegExp(r'[،,]'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// يبني قائمة الصور عند الحفظ: يحافظ على القائمة الأصلية إن لم تتغير
/// الصورة المعروضة، وإلا يستبدلها بالصورة الجديدة.
List<String> _keepImages(String url, List<String> original) {
  if (url.isEmpty) return original;
  if (original.contains(url)) return original;
  return <String>[url];
}

/// حقل رفع صورة موحّد: معاينة مصغّرة (إن وُجد رابط) + زر اختيار/تغيير.
class _ImageUploadField extends StatelessWidget {
  const _ImageUploadField({
    required this.url,
    required this.uploading,
    required this.onPick,
    this.label = 'صورة',
  });

  final String url;
  final bool uploading;
  final VoidCallback onPick;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (url.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                  imageUrl: url, width: 64, height: 64, fit: BoxFit.cover),
            ),
          ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: uploading ? null : onPick,
            icon: uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.image_rounded, size: 18),
            label: Text(url.isEmpty ? 'اختيار $label' : 'تغيير $label'),
          ),
        ),
      ],
    );
  }
}

// ═══════════════ نموذج عائلة (village_families) ═══════════════
class FamilyForm extends StatefulWidget {
  const FamilyForm({super.key, this.editing});

  final VillageFamily? editing;

  @override
  State<FamilyForm> createState() => _FamilyFormState();
}

class _FamilyFormState extends State<FamilyForm> {
  static const _color = Color(0xFF6F4E37);
  static const _categories = {
    'notable': 'عائلات معروفة',
    'scholarly': 'عائلات علمية/أكاديمية',
    'merchant': 'عائلات تجارية',
    'agricultural': 'عائلات زراعية',
    'other': 'أخرى',
  };

  final _name = TextEditingController();
  final _originHistory = TextEditingController();
  final _branches = TextEditingController();
  final _residenceArea = TextEditingController();
  final _historicalInfo = TextEditingController();
  final _description = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _category = 'notable';
  String _imageUrl = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _originHistory.text = e.originHistory;
      _branches.text = e.branches.join('، ');
      _residenceArea.text = e.residenceArea;
      _historicalInfo.text = e.historicalInfo;
      _description.text = e.description;
      _order.text = e.sortOrder.toString();
      if (_categories.containsKey(e.category)) _category = e.category;
      _imageUrl = e.imageUrls.isNotEmpty ? e.imageUrls.first : '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _originHistory.dispose();
    _branches.dispose();
    _residenceArea.dispose();
    _historicalInfo.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final url = await pickAndUploadImage(context, current: _imageUrl);
    if (!mounted) return;
    setState(() {
      _imageUrl = url ?? _imageUrl;
      _uploading = false;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final e = widget.editing;
    try {
      await VillageExtendedService().saveFamily(VillageFamily(
        id: e?.id ?? '',
        name: _name.text.trim(),
        category: _category,
        description: _description.text.trim(),
        originHistory: _originHistory.text.trim(),
        branches: _splitCsv(_branches.text),
        residenceArea: _residenceArea.text.trim(),
        historicalInfo: _historicalInfo.text.trim(),
        sources: e?.sources ?? const [],
        imageUrls: _keepImages(_imageUrl, e?.imageUrls ?? const []),
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة عائلة' : 'تعديل عائلة',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _name,
            decoration: vdec('اسم العائلة', label: 'اسم العائلة *')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: vdec('', label: 'التصنيف'),
          items: [
            for (final c in _categories.entries)
              DropdownMenuItem(value: c.key, child: Text(c.value)),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 10),
        TextField(
            controller: _originHistory,
            maxLines: 3,
            decoration:
                vdec('من أين جاءت العائلة وتاريخها', label: 'أصل العائلة')),
        const SizedBox(height: 10),
        TextField(
            controller: _branches,
            maxLines: 2,
            decoration:
                vdec('افصل بينها بفاصلة (،)', label: 'أبرز العائلات الفرعية')),
        const SizedBox(height: 10),
        TextField(
            controller: _residenceArea,
            decoration: vdec('مثال: وسط البلد', label: 'منطقة السكن')),
        const SizedBox(height: 10),
        TextField(
            controller: _historicalInfo,
            maxLines: 2,
            decoration:
                vdec('معلومات تاريخية إضافية', label: 'معلومات تاريخية')),
        const SizedBox(height: 10),
        TextField(
            controller: _description,
            maxLines: 3,
            decoration: vdec('وصف أو ملاحظات', label: 'ملاحظات')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 10),
        _ImageUploadField(
            url: _imageUrl, uploading: _uploading, onPick: _pickImage),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ العائلة',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════ نموذج شخصية بارزة (village_notable_people) ═══════════════
class NotablePersonForm extends StatefulWidget {
  const NotablePersonForm({super.key, this.editing});

  final VillageNotablePerson? editing;

  @override
  State<NotablePersonForm> createState() => _NotablePersonFormState();
}

class _NotablePersonFormState extends State<NotablePersonForm> {
  static const _color = Color(0xFF1565C0);
  static const _categories = {
    'scholar': 'علماء وأساتذة',
    'doctor': 'أطباء',
    'engineer': 'مهندسون',
    'teacher': 'معلمون',
    'athlete': 'رياضيون',
    'entrepreneur': 'رواد أعمال',
    'public': 'شخصيات عامة',
    'community': 'شخصيات مجتمعية',
    'other': 'أخرى',
  };

  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _achievements = TextEditingController();
  final _relationship = TextEditingController();
  String _category = 'other';
  String _photoUrl = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.fullName;
      _bio.text = e.biography;
      _achievements.text = e.achievements.join('، ');
      _relationship.text = e.relationshipToVillage;
      if (_categories.containsKey(e.category)) _category = e.category;
      _photoUrl = e.photoUrl;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _achievements.dispose();
    _relationship.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final url = await pickAndUploadImage(context, current: _photoUrl);
    if (!mounted) return;
    setState(() {
      _photoUrl = url ?? _photoUrl;
      _uploading = false;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final e = widget.editing;
    try {
      await VillageExtendedService().saveNotablePerson(VillageNotablePerson(
        id: e?.id ?? '',
        fullName: _name.text.trim(),
        photoUrl: _photoUrl,
        field: _categories[_category] ?? _category,
        biography: _bio.text.trim(),
        achievements: _splitCsv(_achievements.text),
        relationshipToVillage: _relationship.text.trim(),
        images: e?.images ?? const [],
        documents: e?.documents ?? const [],
        sources: e?.sources ?? const [],
        approvalStatus: e?.approvalStatus ?? 'approved',
        category: _category,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة شخصية بارزة' : 'تعديل شخصية',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _name,
            decoration: vdec('الاسم الكامل', label: 'الاسم *')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: vdec('', label: 'المجال'),
          items: [
            for (final c in _categories.entries)
              DropdownMenuItem(value: c.key, child: Text(c.value)),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 10),
        TextField(
            controller: _bio,
            maxLines: 4,
            decoration: vdec('نبذة عن الشخصية', label: 'الوصف / السيرة')),
        const SizedBox(height: 10),
        TextField(
            controller: _achievements,
            maxLines: 2,
            decoration: vdec('افصل بينها بفاصلة (،)', label: 'أبرز الإنجازات')),
        const SizedBox(height: 10),
        TextField(
            controller: _relationship,
            decoration:
                vdec('مثال: من أبناء القرية', label: 'العلاقة بالقرية')),
        const SizedBox(height: 10),
        _ImageUploadField(
            url: _photoUrl,
            uploading: _uploading,
            onPick: _pickImage,
            label: 'صورة شخصية'),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ الشخصية',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════ نموذج شخصية الذاكرة (village_memorial_people) ═══════════════
class MemorialPersonForm extends StatefulWidget {
  const MemorialPersonForm({super.key, this.editing});

  final VillageMemorialPerson? editing;

  @override
  State<MemorialPersonForm> createState() => _MemorialPersonFormState();
}

class _MemorialPersonFormState extends State<MemorialPersonForm> {
  static const _color = Color(0xFF5D4037);
  static const _categories = {
    'scholar': 'علماء وأساتذة',
    'doctor': 'أطباء',
    'engineer': 'مهندسون',
    'teacher': 'معلمون',
    'athlete': 'رياضيون',
    'entrepreneur': 'رواد أعمال',
    'public': 'شخصيات عامة',
    'community': 'شخصيات مجتمعية',
    'other': 'أخرى',
  };

  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _relationship = TextEditingController();
  final _causeOfDeath = TextEditingController();
  String _field = 'other';
  String _photoUrl = '';
  DateTime? _dateOfDeath;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.fullName;
      _bio.text = e.biography;
      _relationship.text = e.relationshipToVillage;
      _causeOfDeath.text = e.causeOfDeath;
      if (_categories.containsKey(e.field)) _field = e.field;
      _photoUrl = e.photoUrl;
      _dateOfDeath = e.dateOfDeath;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _relationship.dispose();
    _causeOfDeath.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final url = await pickAndUploadImage(context, current: _photoUrl);
    if (!mounted) return;
    setState(() {
      _photoUrl = url ?? _photoUrl;
      _uploading = false;
    });
  }

  Future<void> _pickDateOfDeath() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateOfDeath ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null && mounted) setState(() => _dateOfDeath = d);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final e = widget.editing;
    try {
      await VillageExtendedService().saveMemorialPerson(VillageMemorialPerson(
        id: e?.id ?? '',
        fullName: _name.text.trim(),
        photoUrl: _photoUrl,
        field: _field,
        biography: _bio.text.trim(),
        relationshipToVillage: _relationship.text.trim(),
        dateOfDeath: _dateOfDeath,
        causeOfDeath: _causeOfDeath.text.trim(),
        images: e?.images ?? const [],
        documents: e?.documents ?? const [],
        sources: e?.sources ?? const [],
        approvalStatus: e?.approvalStatus ?? 'approved',
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة شخصية للذاكرة' : 'تعديل شخصية',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _name,
            decoration: vdec('الاسم الكامل', label: 'الاسم *')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _field,
          decoration: vdec('', label: 'الدور / المجال'),
          items: [
            for (final c in _categories.entries)
              DropdownMenuItem(value: c.key, child: Text(c.value)),
          ],
          onChanged: (v) => setState(() => _field = v ?? _field),
        ),
        const SizedBox(height: 10),
        TextField(
            controller: _bio,
            maxLines: 4,
            decoration: vdec('أثره وسيرته', label: 'الأثر / السيرة')),
        const SizedBox(height: 10),
        TextField(
            controller: _relationship,
            decoration:
                vdec('مثال: من أبناء القرية', label: 'العلاقة بالقرية')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _dateOfDeath == null
                    ? 'تاريخ الوفاة: غير محدد'
                    : 'تاريخ الوفاة: ${_dateOfDeath!.day}/${_dateOfDeath!.month}/${_dateOfDeath!.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
                onPressed: _pickDateOfDeath,
                child: const Text('اختيار التاريخ')),
            if (_dateOfDeath != null)
              IconButton(
                  tooltip: 'مسح التاريخ',
                  onPressed: () => setState(() => _dateOfDeath = null),
                  icon: const Icon(Icons.clear_rounded, size: 18)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
            controller: _causeOfDeath,
            decoration: vdec('اختياري', label: 'سبب الوفاة')),
        const SizedBox(height: 10),
        _ImageUploadField(
            url: _photoUrl,
            uploading: _uploading,
            onPick: _pickImage,
            label: 'صورة شخصية'),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ الشخصية',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════ نموذج عنصر تراثي (village_heritage) ═══════════════
class HeritageForm extends StatefulWidget {
  const HeritageForm({super.key, this.editing});

  final VillageHeritage? editing;

  @override
  State<HeritageForm> createState() => _HeritageFormState();
}

class _HeritageFormState extends State<HeritageForm> {
  static const _color = Color(0xFF6A1B9A);
  static const _categories = {
    'customs': 'العادات والتقاليد',
    'food': 'الأكلات الشعبية',
    'proverbs': 'الأمثال والحكايات',
    'games': 'الألعاب القديمة',
    'weddings': 'الأفراح قديماً',
    'funerals': 'العزاء والمناسبات',
    'crafts': 'الحرف والمهن القديمة',
    'tools': 'أدوات الزراعة القديمة',
  };

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _period = TextEditingController();
  final _source = TextEditingController();
  final _contributor = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _category = 'customs';
  String _imageUrl = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _title.text = e.title;
      _description.text = e.description;
      _period.text = e.historicalPeriod;
      _source.text = e.source;
      _contributor.text = e.contributor;
      _order.text = e.sortOrder.toString();
      if (_categories.containsKey(e.category)) _category = e.category;
      _imageUrl = e.images.isNotEmpty ? e.images.first : '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _period.dispose();
    _source.dispose();
    _contributor.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final url = await pickAndUploadImage(context, current: _imageUrl);
    if (!mounted) return;
    setState(() {
      _imageUrl = url ?? _imageUrl;
      _uploading = false;
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final e = widget.editing;
    try {
      await VillageExtendedService().saveHeritage(VillageHeritage(
        id: e?.id ?? '',
        title: _title.text.trim(),
        category: _category,
        description: _description.text.trim(),
        images: _keepImages(_imageUrl, e?.images ?? const []),
        audioUrl: e?.audioUrl ?? '',
        videoUrl: e?.videoUrl ?? '',
        historicalPeriod: _period.text.trim(),
        source: _source.text.trim(),
        contributor: _contributor.text.trim(),
        approvalStatus: e?.approvalStatus ?? 'approved',
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة عنصر تراثي' : 'تعديل عنصر تراثي',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _title,
            decoration:
                vdec('مثال: أكلة شعبية، مثل، لعبة', label: 'العنوان *')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: vdec('', label: 'الفئة'),
          items: [
            for (final c in _categories.entries)
              DropdownMenuItem(value: c.key, child: Text(c.value)),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 10),
        TextField(
            controller: _description,
            maxLines: 4,
            decoration: vdec('وصف العنصر التراثي', label: 'الوصف')),
        const SizedBox(height: 10),
        TextField(
            controller: _period,
            decoration:
                vdec('مثال: بداية القرن العشرين', label: 'الفترة الزمنية')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: TextField(
                    controller: _source,
                    decoration: vdec('المصدر', label: 'المصدر'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _contributor,
                    decoration: vdec('المساهم', label: 'المساهم'))),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 10),
        _ImageUploadField(
            url: _imageUrl, uploading: _uploading, onPick: _pickImage),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ العنصر',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════ نموذج معلم (village_landmarks) ═══════════════
class LandmarkForm extends StatefulWidget {
  const LandmarkForm({super.key, this.editing});

  final VillageLandmark? editing;

  @override
  State<LandmarkForm> createState() => _LandmarkFormState();
}

class _LandmarkFormState extends State<LandmarkForm> {
  static const _color = Color(0xFF00897B);
  static const _categories = {
    'mosque': 'مساجد',
    'school': 'مدارس',
    'facility': 'مرافق',
    'historical': 'أماكن تاريخية',
    'agricultural': 'مناطق زراعية',
    'notable': 'أماكن مميزة',
  };

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _mapLocation = TextEditingController();
  final _historicalInfo = TextEditingController();
  final _story = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _category = 'notable';
  String _historicalImageUrl = '';
  String _currentImageUrl = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _description.text = e.description;
      _location.text = e.location;
      _mapLocation.text = e.mapLocation;
      _historicalInfo.text = e.historicalInfo;
      _story.text = e.story;
      _order.text = e.sortOrder.toString();
      if (_categories.containsKey(e.category)) _category = e.category;
      _historicalImageUrl =
          e.historicalImages.isNotEmpty ? e.historicalImages.first : '';
      _currentImageUrl =
          e.currentImages.isNotEmpty ? e.currentImages.first : '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    _mapLocation.dispose();
    _historicalInfo.dispose();
    _story.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool historical) async {
    setState(() => _uploading = true);
    final url = await pickAndUploadImage(context,
        current: historical ? _historicalImageUrl : _currentImageUrl);
    if (!mounted) return;
    setState(() {
      if (historical) {
        _historicalImageUrl = url ?? _historicalImageUrl;
      } else {
        _currentImageUrl = url ?? _currentImageUrl;
      }
      _uploading = false;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final e = widget.editing;
    try {
      await VillageExtendedService().saveLandmark(VillageLandmark(
        id: e?.id ?? '',
        name: _name.text.trim(),
        category: _category,
        description: _description.text.trim(),
        location: _location.text.trim(),
        historicalInfo: _historicalInfo.text.trim(),
        story: _story.text.trim(),
        historicalImages:
            _keepImages(_historicalImageUrl, e?.historicalImages ?? const []),
        currentImages:
            _keepImages(_currentImageUrl, e?.currentImages ?? const []),
        mapLocation: _mapLocation.text.trim(),
        relatedPeople: e?.relatedPeople ?? const [],
        relatedEvents: e?.relatedEvents ?? const [],
        sources: e?.sources ?? const [],
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة معلم' : 'تعديل المعلم',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _name,
            decoration: vdec('اسم المعلم/المكان', label: 'الاسم *')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: vdec('', label: 'التصنيف'),
          items: [
            for (final c in _categories.entries)
              DropdownMenuItem(value: c.key, child: Text(c.value)),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 10),
        TextField(
            controller: _description,
            maxLines: 3,
            decoration: vdec('وصف المكان', label: 'الوصف')),
        const SizedBox(height: 10),
        TextField(
            controller: _location,
            decoration: vdec('الموقع داخل القرية', label: 'الموقع')),
        const SizedBox(height: 10),
        TextField(
            controller: _mapLocation,
            decoration: vdec('رابط خرائط جوجل أو الإحداثيات',
                label: 'موقعه على الخريطة')),
        const SizedBox(height: 10),
        TextField(
            controller: _historicalInfo,
            maxLines: 3,
            decoration: vdec('معلومات تاريخية', label: 'المعلومات التاريخية')),
        const SizedBox(height: 10),
        TextField(
            controller: _story,
            maxLines: 3,
            decoration: vdec('حكاية المكان', label: 'الحكاية')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 10),
        const Text('صورة تاريخية', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        _ImageUploadField(
            url: _historicalImageUrl,
            uploading: _uploading,
            label: 'صورة تاريخية',
            onPick: () => _pickImage(true)),
        const SizedBox(height: 10),
        const Text('صورة حديثة', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        _ImageUploadField(
            url: _currentImageUrl,
            uploading: _uploading,
            label: 'صورة حديثة',
            onPick: () => _pickImage(false)),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════ نموذج «قبل وبعد» (village_before_after) ═══════════════
class BeforeAfterForm extends StatefulWidget {
  const BeforeAfterForm({super.key, this.editing});

  final VillageBeforeAfter? editing;

  @override
  State<BeforeAfterForm> createState() => _BeforeAfterFormState();
}

class _BeforeAfterFormState extends State<BeforeAfterForm> {
  static const _color = Color(0xFF00695C);

  final _location = TextEditingController();
  final _historicalDate = TextEditingController();
  final _currentDate = TextEditingController();
  final _description = TextEditingController();
  final _source = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _historicalImage = '';
  String _currentImage = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _location.text = e.location;
      _historicalDate.text = e.historicalDate;
      _currentDate.text = e.currentDate;
      _description.text = e.description;
      _source.text = e.source;
      _order.text = '${e.sortOrder}';
      _historicalImage = e.historicalImage;
      _currentImage = e.currentImage;
    }
  }

  @override
  void dispose() {
    _location.dispose();
    _historicalDate.dispose();
    _currentDate.dispose();
    _description.dispose();
    _source.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pick(bool historical) async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage(context,
          current: historical ? _historicalImage : _currentImage);
      if (!mounted || url == null) return;
      setState(() {
        if (historical) {
          _historicalImage = url;
        } else {
          _currentImage = url;
        }
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final e = widget.editing;
    setState(() => _saving = true);
    try {
      await VillageExtendedService().saveBeforeAfter(VillageBeforeAfter(
        id: e?.id ?? '',
        historicalImage: _historicalImage,
        currentImage: _currentImage,
        location: _location.text.trim(),
        historicalDate: _historicalDate.text.trim(),
        currentDate: _currentDate.text.trim(),
        description: _description.text.trim(),
        source: _source.text.trim(),
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة مقارنة قبل/بعد' : 'تعديل المقارنة',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        const Text('الصورة القديمة', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        _ImageUploadField(
            url: _historicalImage,
            uploading: _uploading,
            label: 'الصورة القديمة',
            onPick: () => _pick(true)),
        const SizedBox(height: 10),
        const Text('الصورة الحديثة', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        _ImageUploadField(
            url: _currentImage,
            uploading: _uploading,
            label: 'الصورة الحديثة',
            onPick: () => _pick(false)),
        const SizedBox(height: 10),
        TextField(
            controller: _location,
            decoration: vdec('مثال: شارع الترعة', label: 'الموقع')),
        const SizedBox(height: 10),
        TextField(
            controller: _historicalDate,
            decoration: vdec('مثال: 1965', label: 'تاريخ الصورة القديمة')),
        const SizedBox(height: 10),
        TextField(
            controller: _currentDate,
            decoration: vdec('مثال: 2025', label: 'تاريخ الصورة الحديثة')),
        const SizedBox(height: 10),
        TextField(
            controller: _description,
            maxLines: 3,
            decoration: vdec('ما الذي تغيّر في هذا المكان؟', label: 'الوصف')),
        const SizedBox(height: 10),
        TextField(
            controller: _source,
            decoration: vdec('اسم المصوّر أو مصدر الصورة', label: 'المصدر')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════ نموذج تاريخ الزراعة (village_agriculture_history) ═══════
class AgricultureHistoryForm extends StatefulWidget {
  const AgricultureHistoryForm({super.key, this.editing});

  final VillageAgricultureHistory? editing;

  @override
  State<AgricultureHistoryForm> createState() => _AgricultureHistoryFormState();
}

class _AgricultureHistoryFormState extends State<AgricultureHistoryForm> {
  static const _color = Color(0xFF2E7D32);

  final _crop = TextEditingController();
  final _area = TextEditingController();
  final _traditional = TextEditingController();
  final _tools = TextEditingController();
  final _story = TextEditingController();
  final _changes = TextEditingController();
  final _sources = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _imageUrl = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _crop.text = e.crop;
      _area.text = e.agriculturalArea;
      _traditional.text = e.traditionalFarming;
      _tools.text = e.historicalTools;
      _story.text = e.farmerStory;
      _changes.text = e.changesOverTime;
      _sources.text = e.sources.join('، ');
      _order.text = '${e.sortOrder}';
      _imageUrl = e.images.isNotEmpty ? e.images.first : '';
    }
  }

  @override
  void dispose() {
    _crop.dispose();
    _area.dispose();
    _traditional.dispose();
    _tools.dispose();
    _story.dispose();
    _changes.dispose();
    _sources.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage(context, current: _imageUrl);
      if (!mounted || url == null) return;
      setState(() => _imageUrl = url);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final e = widget.editing;
    setState(() => _saving = true);
    try {
      await VillageExtendedService()
          .saveAgricultureHistory(VillageAgricultureHistory(
        id: e?.id ?? '',
        crop: _crop.text.trim(),
        agriculturalArea: _area.text.trim(),
        traditionalFarming: _traditional.text.trim(),
        historicalTools: _tools.text.trim(),
        farmerStory: _story.text.trim(),
        changesOverTime: _changes.text.trim(),
        images: _keepImages(_imageUrl, e?.images ?? const []),
        sources: _splitCsv(_sources.text),
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة محصول' : 'تعديل المحصول',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _crop,
            decoration: vdec('مثال: القطن، القمح', label: 'المحصول *')),
        const SizedBox(height: 10),
        TextField(
            controller: _area,
            decoration: vdec('أين كان يُزرع؟', label: 'المساحة الزراعية')),
        const SizedBox(height: 10),
        TextField(
            controller: _traditional,
            maxLines: 3,
            decoration: vdec('الزراعة التقليدية', label: 'الزراعة التقليدية')),
        const SizedBox(height: 10),
        TextField(
            controller: _tools,
            maxLines: 2,
            decoration: vdec('الأدوات القديمة', label: 'الأدوات التاريخية')),
        const SizedBox(height: 10),
        TextField(
            controller: _story,
            maxLines: 3,
            decoration: vdec('حكاية مزارع من القرية', label: 'حكاية الفلاح')),
        const SizedBox(height: 10),
        TextField(
            controller: _changes,
            maxLines: 3,
            decoration: vdec('ما الذي تغيّر عبر الزمن؟', label: 'التغيّرات')),
        const SizedBox(height: 10),
        TextField(
            controller: _sources,
            decoration: vdec('افصل بينها بفاصلة (،)', label: 'المصادر')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 10),
        _ImageUploadField(url: _imageUrl, uploading: _uploading, onPick: _pick),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════ نموذج تاريخ التعليم (village_education_history) ═══════
class EducationHistoryForm extends StatefulWidget {
  const EducationHistoryForm({super.key, this.editing});

  final VillageEducationHistory? editing;

  @override
  State<EducationHistoryForm> createState() => _EducationHistoryFormState();
}

class _EducationHistoryFormState extends State<EducationHistoryForm> {
  static const _color = Color(0xFF1565C0);

  final _history = TextEditingController();
  final _oldSchools = TextEditingController();
  final _currentSchools = TextEditingController();
  final _formerTeachers = TextEditingController();
  final _figures = TextEditingController();
  final _photos = TextEditingController();
  final _memories = TextEditingController();
  final _sources = TextEditingController();
  final _order = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _history.text = e.historyOfEducation;
      _oldSchools.text = e.oldSchools.join('، ');
      _currentSchools.text = e.currentSchools.join('، ');
      _formerTeachers.text = e.formerTeachers.join('، ');
      _figures.text = e.educationalFigures.join('، ');
      _photos.text = e.historicalPhotos.join('، ');
      _memories.text = e.studentMemories.join('، ');
      _sources.text = e.sources.join('، ');
      _order.text = '${e.sortOrder}';
    }
  }

  @override
  void dispose() {
    _history.dispose();
    _oldSchools.dispose();
    _currentSchools.dispose();
    _formerTeachers.dispose();
    _figures.dispose();
    _photos.dispose();
    _memories.dispose();
    _sources.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final e = widget.editing;
    setState(() => _saving = true);
    try {
      await VillageExtendedService()
          .saveEducationHistory(VillageEducationHistory(
        id: e?.id ?? '',
        historyOfEducation: _history.text.trim(),
        oldSchools: _splitCsv(_oldSchools.text),
        currentSchools: _splitCsv(_currentSchools.text),
        formerTeachers: _splitCsv(_formerTeachers.text),
        educationalFigures: _splitCsv(_figures.text),
        historicalPhotos: _splitCsv(_photos.text),
        studentMemories: _splitCsv(_memories.text),
        sources: _splitCsv(_sources.text),
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة سجل تعليمي' : 'تعديل السجل',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _history,
            maxLines: 4,
            decoration:
                vdec('كيف بدأ التعليم في القرية؟', label: 'تاريخ التعليم *')),
        const SizedBox(height: 10),
        TextField(
            controller: _oldSchools,
            maxLines: 2,
            decoration: vdec('افصل بفاصلة (،)', label: 'المدارس القديمة')),
        const SizedBox(height: 10),
        TextField(
            controller: _currentSchools,
            maxLines: 2,
            decoration: vdec('افصل بفاصلة (،)', label: 'المدارس الحالية')),
        const SizedBox(height: 10),
        TextField(
            controller: _formerTeachers,
            maxLines: 2,
            decoration: vdec('افصل بفاصلة (،)', label: 'المعلمون السابقون')),
        const SizedBox(height: 10),
        TextField(
            controller: _figures,
            maxLines: 2,
            decoration: vdec('افصل بفاصلة (،)', label: 'شخصيات تعليمية بارزة')),
        const SizedBox(height: 10),
        TextField(
            controller: _photos,
            maxLines: 2,
            decoration: vdec('افصل بفاصلة (،)', label: 'صور تاريخية (روابط)')),
        const SizedBox(height: 10),
        TextField(
            controller: _memories,
            maxLines: 3,
            decoration: vdec('افصل بفاصلة (،)', label: 'ذكريات الطلاب')),
        const SizedBox(height: 10),
        TextField(
            controller: _sources,
            decoration: vdec('افصل بفاصلة (،)', label: 'المصادر')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══ نموذج الخط الزمني للتطوير (village_development_timeline) ═══
class DevelopmentTimelineForm extends StatefulWidget {
  const DevelopmentTimelineForm({super.key, this.editing});

  final VillageDevelopmentTimeline? editing;

  @override
  State<DevelopmentTimelineForm> createState() =>
      _DevelopmentTimelineFormState();
}

class _DevelopmentTimelineFormState extends State<DevelopmentTimelineForm> {
  static const _color = Color(0xFF0277BD);

  final _date = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _project = TextEditingController();
  final _source = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _beforeImage = '';
  String _afterImage = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _date.text = e.date;
      _title.text = e.title;
      _description.text = e.description;
      _project.text = e.relatedProject;
      _source.text = e.source;
      _order.text = '${e.sortOrder}';
      _beforeImage = e.beforeImage;
      _afterImage = e.afterImage;
    }
  }

  @override
  void dispose() {
    _date.dispose();
    _title.dispose();
    _description.dispose();
    _project.dispose();
    _source.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pick(bool before) async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage(context,
          current: before ? _beforeImage : _afterImage);
      if (!mounted || url == null) return;
      setState(() {
        if (before) {
          _beforeImage = url;
        } else {
          _afterImage = url;
        }
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final e = widget.editing;
    setState(() => _saving = true);
    try {
      await VillageExtendedService()
          .saveDevelopmentTimeline(VillageDevelopmentTimeline(
        id: e?.id ?? '',
        date: _date.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        beforeImage: _beforeImage,
        afterImage: _afterImage,
        relatedProject: _project.text.trim(),
        source: _source.text.trim(),
        approvalStatus: e?.approvalStatus ?? 'approved',
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة محطة تطوير' : 'تعديل المحطة',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _date,
            decoration: vdec('مثال: 1998', label: 'التاريخ *')),
        const SizedBox(height: 10),
        TextField(
            controller: _title,
            decoration: vdec('مثال: إدخال الكهرباء', label: 'العنوان *')),
        const SizedBox(height: 10),
        TextField(
            controller: _description,
            maxLines: 3,
            decoration: vdec('تفاصيل المشروع وأثره', label: 'الوصف')),
        const SizedBox(height: 10),
        TextField(
            controller: _project,
            decoration: vdec('اسم المشروع', label: 'المشروع المرتبط')),
        const SizedBox(height: 10),
        TextField(
            controller: _source,
            decoration: vdec('مصدر المعلومة', label: 'المصدر')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 10),
        const Text('صورة ما قبل', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        _ImageUploadField(
            url: _beforeImage,
            uploading: _uploading,
            label: 'صورة ما قبل',
            onPick: () => _pick(true)),
        const SizedBox(height: 10),
        const Text('صورة ما بعد', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        _ImageUploadField(
            url: _afterImage,
            uploading: _uploading,
            label: 'صورة ما بعد',
            onPick: () => _pick(false)),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════ نموذج إنجاز (village_achievements) ═══════════════
class AchievementForm extends StatefulWidget {
  const AchievementForm({super.key, this.editing});

  final VillageAchievement? editing;

  @override
  State<AchievementForm> createState() => _AchievementFormState();
}

class _AchievementFormState extends State<AchievementForm> {
  static const _color = Color(0xFFB8860B);

  final _date = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _people = TextEditingController();
  final _source = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _image = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _date.text = e.date;
      _title.text = e.title;
      _description.text = e.description;
      _people.text = e.relatedPeople.join('، ');
      _source.text = e.source;
      _order.text = '${e.sortOrder}';
      _image = e.image;
    }
  }

  @override
  void dispose() {
    _date.dispose();
    _title.dispose();
    _description.dispose();
    _people.dispose();
    _source.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage(context, current: _image);
      if (!mounted || url == null) return;
      setState(() => _image = url);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final e = widget.editing;
    setState(() => _saving = true);
    try {
      await VillageExtendedService().saveAchievement(VillageAchievement(
        id: e?.id ?? '',
        date: _date.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        image: _image,
        relatedPeople: _splitCsv(_people.text),
        source: _source.text.trim(),
        approvalStatus: e?.approvalStatus ?? 'approved',
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.editing == null ? 'إضافة إنجاز' : 'تعديل الإنجاز',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
            controller: _title,
            decoration: vdec('عنوان الإنجاز', label: 'العنوان *')),
        const SizedBox(height: 10),
        TextField(
            controller: _date,
            decoration: vdec('مثال: 2015', label: 'التاريخ')),
        const SizedBox(height: 10),
        TextField(
            controller: _description,
            maxLines: 4,
            decoration: vdec('وصف الإنجاز وأثره', label: 'الوصف')),
        const SizedBox(height: 10),
        TextField(
            controller: _people,
            maxLines: 2,
            decoration: vdec('افصل بفاصلة (،)', label: 'أصحاب الإنجاز')),
        const SizedBox(height: 10),
        TextField(
            controller: _source,
            decoration: vdec('مصدر المعلومة', label: 'المصدر')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 10),
        _ImageUploadField(url: _image, uploading: _uploading, onPick: _pick),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════ نموذج عنصر أرشيف (village_archive_items) ═══════
/// يقبل التمرير بأيٍّ من [item] أو [editing]، وكذلك [fixedCategory] لقفل الفئة.
class ArchiveItemForm extends StatefulWidget {
  const ArchiveItemForm({
    super.key,
    this.item,
    this.editing,
    this.fixedCategory = '',
    this.category,
  });

  final VillageArchiveItem? item;
  final VillageArchiveItem? editing;
  final String fixedCategory;
  final VillageArchiveItem? category;

  @override
  State<ArchiveItemForm> createState() => _ArchiveItemFormState();
}

class _ArchiveItemFormState extends State<ArchiveItemForm> {
  static const _color = Color(0xFF6A1B9A);

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _year = TextEditingController();
  final _period = TextEditingController();
  final _location = TextEditingController();
  final _people = TextEditingController();
  final _contributor = TextEditingController();
  final _source = TextEditingController();
  final _documentUrl = TextEditingController();
  final _videoUrl = TextEditingController();
  final _audioUrl = TextEditingController();
  final _order = TextEditingController(text: '0');
  String _category = ArchiveItemCategory.photos;
  String _imageUrl = '';
  bool _saving = false;
  bool _uploading = false;

  VillageArchiveItem? get _src =>
      widget.item ?? widget.editing ?? widget.category;

  @override
  void initState() {
    super.initState();
    if (widget.fixedCategory.isNotEmpty) _category = widget.fixedCategory;
    final e = _src;
    if (e != null) {
      _category = e.category;
      _title.text = e.title;
      _description.text = e.description;
      _year.text = e.year;
      _period.text = e.period;
      _location.text = e.location;
      _people.text = e.people;
      _contributor.text = e.contributor;
      _source.text = e.source;
      _documentUrl.text = e.documentUrl;
      _videoUrl.text = e.videoUrl;
      _audioUrl.text = e.audioUrl;
      _order.text = '${e.sortOrder}';
      _imageUrl = e.imageUrl;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _year.dispose();
    _period.dispose();
    _location.dispose();
    _people.dispose();
    _contributor.dispose();
    _source.dispose();
    _documentUrl.dispose();
    _videoUrl.dispose();
    _audioUrl.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage(context, current: _imageUrl);
      if (!mounted || url == null) return;
      setState(() => _imageUrl = url);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final e = _src;
    setState(() => _saving = true);
    try {
      await VillageExtendedService().saveArchiveItem(VillageArchiveItem(
        id: e?.id ?? '',
        category: _category,
        title: _title.text.trim(),
        description: _description.text.trim(),
        imageUrl: _imageUrl,
        documentUrl: _documentUrl.text.trim(),
        videoUrl: _videoUrl.text.trim(),
        audioUrl: _audioUrl.text.trim(),
        year: _year.text.trim(),
        source: _source.text.trim(),
        contributor: _contributor.text.trim(),
        location: _location.text.trim(),
        people: _people.text.trim(),
        period: _period.text.trim(),
        approvalStatus: e?.approvalStatus ?? 'approved',
        sortOrder: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: e?.createdAt,
      ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catLabel = ArchiveItemCategory.label(_category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_src == null ? 'إضافة عنصر أرشيف' : 'تعديل عنصر الأرشيف',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (widget.fixedCategory.isEmpty)
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: vdec('', label: 'الفئة'),
            items: [
              for (final c in ArchiveItemCategory.all)
                DropdownMenuItem(
                    value: c, child: Text(ArchiveItemCategory.label(c))),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          )
        else
          Chip(
            avatar: Icon(ArchiveItemCategory.icon(_category),
                size: 16, color: ArchiveItemCategory.color(_category)),
            label: Text(catLabel),
          ),
        const SizedBox(height: 10),
        TextField(
            controller: _title,
            decoration: vdec('عنوان المادة', label: 'العنوان *')),
        const SizedBox(height: 10),
        TextField(
            controller: _description,
            maxLines: 4,
            decoration: vdec('وصف المادة أو نص الحكاية', label: 'الوصف')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                  controller: _year,
                  decoration: vdec('مثال: 1972', label: 'السنة')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                  controller: _period,
                  decoration: vdec('مثال: الستينات', label: 'الفترة')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
            controller: _location,
            decoration: vdec('مكان الحدث أو الصورة', label: 'الموقع')),
        const SizedBox(height: 10),
        TextField(
            controller: _people,
            decoration: vdec('افصل بفاصلة (،)', label: 'الأشخاص المذكورون')),
        const SizedBox(height: 10),
        TextField(
            controller: _contributor,
            decoration: vdec('من قدّم المادة؟', label: 'المساهم / الراوي')),
        const SizedBox(height: 10),
        TextField(
            controller: _source,
            decoration: vdec('مصدر المادة', label: 'المصدر')),
        const SizedBox(height: 10),
        _ImageUploadField(url: _imageUrl, uploading: _uploading, onPick: _pick),
        const SizedBox(height: 10),
        TextField(
            controller: _documentUrl,
            decoration: vdec('رابط PDF إن وُجد', label: 'رابط وثيقة')),
        const SizedBox(height: 10),
        TextField(
            controller: _videoUrl,
            decoration:
                vdec('رابط YouTube/Drive إن وُجد', label: 'رابط فيديو')),
        const SizedBox(height: 10),
        TextField(
            controller: _audioUrl,
            decoration:
                vdec('رابط التسجيل الصوتي إن وُجد', label: 'رابط تسجيل صوتي')),
        const SizedBox(height: 10),
        TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: vdec('0', label: 'الترتيب')),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _saving || _uploading ? null : _save,
                style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(height: 8),
      ],
    );
  }
}
