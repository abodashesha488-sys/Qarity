import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/medical_models.dart';
import '../../services/medical_service.dart';
import '../../widgets/clinic_photo_tile.dart';
import '../../widgets/qurity_app_bar.dart';
import 'medical_home_screen.dart' show MedicalImageField;

/// شاشة إدارة المركز الطبي الخيري — لمدير المركز الطبي.
/// إضافة/تعديل/حذف عيادات المركز مع الأيام والساعات والأجور وصورة العيادة.
class MedicalCenterAdminScreen extends StatefulWidget {
  const MedicalCenterAdminScreen({super.key});

  @override
  State<MedicalCenterAdminScreen> createState() =>
      _MedicalCenterAdminScreenState();
}

class _MedicalCenterAdminScreenState extends State<MedicalCenterAdminScreen> {
  final MedicalCenterService _service = MedicalCenterService();
  static const _days = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة'
  ];

  @override
  void initState() {
    super.initState();
    _service.seedIfEmpty().catchError((_) {});
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _addOrEdit([MedicalCenterClinic? existing]) async {
    final res = await showModalBottomSheet<MedicalCenterClinic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ClinicEditForm(
        days: _days,
        existing: existing,
      ),
    );
    if (res == null || !mounted) return;
    try {
      if (existing == null) {
        await _service.addClinic(res);
        _snack('تمت إضافة العيادة');
      } else {
        await _service.updateClinic(existing.id, res.toMap());
        _snack('تم تحديث العيادة');
      }
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  Future<void> _delete(MedicalCenterClinic c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العيادة'),
        content: Text('هل تريد حذف "${c.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.deleteClinic(c.id);
        _snack('تم الحذف');
      } catch (e) {
        _snack('تعذّر الحذف: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
        title: 'إدارة المركز الطبي الخيري',
        onAdd: () => _addOrEdit(),
        addTooltip: 'إضافة عيادة',
      ),
      body: StreamBuilder<List<MedicalCenterClinic>>(
        stream: _service.getClinicsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text('لا توجد عيادات — أضف أول عيادة',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = list[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  leading: ClinicPhotoTile(imageUrl: c.imageUrl, side: 52),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                          '${c.specialty} • ${c.scheduleLabel}'
                          '${c.fees > 0 ? ' • ${c.fees.toStringAsFixed(0)} ج.م' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (!c.isApproved)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('⏳ بانتظار موافقة المدير العام',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange)),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!c.isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.visibility_off_rounded,
                              size: 16, color: Colors.grey),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _addOrEdit(c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded,
                            size: 20, color: Colors.red),
                        onPressed: () => _delete(c),
                      ),
                    ],
                  ),
                  onTap: () => _addOrEdit(c),
                ),
              ).animate().fadeIn(duration: 150.ms);
            },
          );
        },
      ),
    );
  }
}

extension on MedicalCenterClinic {
  Map<String, dynamic> toMap() => {
        'name': name,
        'specialty': specialty,
        'doctorName': doctorName,
        'description': description,
        'workingDays': workingDays,
        'workingHours': workingHours,
        'imageUrl': imageUrl,
        'fees': fees,
        'isActive': isActive,
      };
}

/// صيغة مواعيد العمل المحفوظة: «9 ص - 2 م» — نفس صيغة الوثائق القديمة،
/// فلا حاجة لهجرة أو حقل جديد.
String formatClinicHours(TimeOfDay start, TimeOfDay end) =>
    '${clinicHourLabel(start)} - ${clinicHourLabel(end)}';

/// توقيت عربي مستقل عن إعدادات اللغة: «9 ص»، «9:30 م»، «12 ص» لمنتصف الليل.
String clinicHourLabel(TimeOfDay t) {
  final suffix = t.hour < 12 ? 'ص' : 'م';
  var h12 = t.hour % 12;
  if (h12 == 0) h12 = 12;
  return t.minute == 0
      ? '$h12 $suffix'
      : '$h12:${t.minute.toString().padLeft(2, '0')} $suffix';
}

/// يقرأ «9 ص - 2 م» و«9:30 ص - 14:00» وغيرها؛ يعيد null إن لم يجد وقتين
/// صالحين — فيبقى النص المحفوظ كما هو بدل أن يُستبدل بتقدير خاطئ.
({TimeOfDay start, TimeOfDay end})? parseClinicHours(String text) {
  final found = <TimeOfDay>[];
  for (final m in RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(ص|م)?').allMatches(text)) {
    final h = int.tryParse(m.group(1) ?? '');
    final minute = int.tryParse(m.group(2) ?? '0') ?? 0;
    final period = m.group(3);
    if (h == null || h < 1 || h > 12 && period != null || h > 23) return null;
    if (minute > 59) return null;
    int hour = h;
    if (period == 'ص' && h == 12) hour = 0;
    if (period == 'م' && h != 12) hour = h + 12;
    found.add(TimeOfDay(hour: hour, minute: minute));
    if (found.length == 2) break;
  }
  if (found.length < 2) return null;
  return (start: found[0], end: found[1]);
}

/// النص الذي يُحفظ في `workingHours`: الوقتان المختاران معًا، أو النص المحفوظ
/// كما هو إن لم يلمس أحدٌ الاختيار. `null` = وقت واحد فقط (حالة مرفوضة).
String? resolveClinicHours(
    {TimeOfDay? start, TimeOfDay? end, String? existing}) {
  if ((start == null) != (end == null)) return null;
  if (start != null && end != null) return formatClinicHours(start, end);
  return existing ?? '';
}

/// نموذج إضافة/تعديل عيادة المركز الطبي الخيري.
class ClinicEditForm extends StatefulWidget {
  const ClinicEditForm({super.key, required this.days, this.existing});
  final List<String> days;
  final MedicalCenterClinic? existing;

  @override
  State<ClinicEditForm> createState() => _ClinicEditFormState();
}

class _ClinicEditFormState extends State<ClinicEditForm> {
  late final _nameC = TextEditingController(text: widget.existing?.name ?? '');
  late final _doctorC =
      TextEditingController(text: widget.existing?.doctorName ?? '');
  late final _feesC = TextEditingController(
      text: (widget.existing?.fees ?? 0) > 0
          ? (widget.existing!.fees).toStringAsFixed(0)
          : '');
  late final _descC =
      TextEditingController(text: widget.existing?.description ?? '');
  late String _specialty = widget.existing?.specialty ?? 'باطنة';
  late final Set<String> _days = {...?widget.existing?.workingDays};
  late bool _active = widget.existing?.isActive ?? true;

  late String _imageUrl = widget.existing?.imageUrl ?? '';
  String? _photoError;

  TimeOfDay? _open;
  TimeOfDay? _close;
  String? _hoursError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final parsed = parseClinicHours(widget.existing?.workingHours ?? '');
    _open = parsed?.start;
    _close = parsed?.end;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _doctorC.dispose();
    _feesC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _open : _close;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: isStart ? 'وقت بداية العمل' : 'وقت نهاية العمل',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _open = picked;
      } else {
        _close = picked;
      }
      _hoursError = null;
    });
  }

  Widget _timeRow(String key, String label, TimeOfDay? value) {
    final theme = Theme.of(context);
    return InkWell(
      key: Key(key),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pickTime(isStart: key.endsWith('start')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 18, color: Color(0xFF00897B)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? 'اختر الوقت' : clinicHourLabel(value),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: value == null
                        ? theme.colorScheme.onSurfaceVariant
                        : const Color(0xFF00897B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    widget.existing == null
                        ? 'إضافة عيادة'
                        : 'تعديل عيادة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18)),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _f(_nameC, 'اسم العيادة', Icons.medical_services_rounded),
                  if (_nameError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _nameError!,
                          key: const Key('clinic-name-error'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB71C1C)),
                        ),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: _specialty,
                    decoration: const InputDecoration(labelText: 'التخصص'),
                    items: kClinicSpecialties
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _specialty = v ?? _specialty),
                    menuMaxHeight: 360,
                  ),
                  const SizedBox(height: 12),
                  _f(_doctorC, 'اسم الطبيب', Icons.person_rounded),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('مواعيد العمل',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _timeRow('clinic-hours-start', 'من', _open)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _timeRow('clinic-hours-end', 'إلى', _close)),
                    ],
                  ),
                  if (_hoursError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_hoursError!,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB71C1C))),
                    ),
                  if (_open == null && _close == null &&
                      (widget.existing?.workingHours ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                          'المواعيد المحفوظة: ${widget.existing!.workingHours} — اختر الوقتين لتغييرها',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  const SizedBox(height: 12),
                  _f(_feesC, 'الأجر الرمزي (ج.م)', Icons.attach_money_rounded,
                      type: TextInputType.number),
                  const SizedBox(height: 12),
                  _f(_descC, 'نبذة', Icons.description_rounded, maxLines: 3),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('أيام العمل',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.days.map((d) {
                      final sel = _days.contains(d);
                      return FilterChip(
                        label: Text(d),
                        selected: sel,
                        selectedColor:
                            const Color(0xFF00897B).withValues(alpha: 0.2),
                        onSelected: (v) =>
                            setState(() => v ? _days.add(d) : _days.remove(d)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('صورة العيادة',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                  const SizedBox(height: 8),
                  ClinicPhotoPreviewTile(imageUrl: _imageUrl),
                  const SizedBox(height: 8),
                  MedicalImageField(
                    key: ValueKey('clinic-photo-field-$_imageUrl'),
                    maxImages: 1,
                    initial: _imageUrl.isEmpty ? const [] : [_imageUrl],
                    onError: (msg) => setState(() => _photoError = msg),
                    onChanged: (urls) => setState(() {
                      _imageUrl = urls.isEmpty ? '' : urls.first;
                      if (_imageUrl.isNotEmpty) _photoError = null;
                    }),
                  ),
                  if (_photoError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _photoError!,
                        key: const Key('clinic-photo-error'),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB71C1C)),
                      ),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ظاهرة للجمهور'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _save,
            child: const Text('حفظ',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_nameC.text.trim().isEmpty) {
      setState(() => _nameError = 'اكتب اسم العيادة أولاً');
      return;
    }
    final hours = resolveClinicHours(
        start: _open, end: _close, existing: widget.existing?.workingHours);
    if (hours == null) {
      setState(() => _hoursError = 'اختر وقت البداية ووقت النهاية معًا');
      return;
    }
    Navigator.pop(
      context,
      MedicalCenterClinic(
        id: widget.existing?.id ?? '',
        name: _nameC.text.trim(),
        specialty: _specialty,
        doctorName: _doctorC.text.trim(),
        description: _descC.text.trim(),
        workingDays: _days.toList(),
        workingHours: hours,
        imageUrl: _imageUrl,
        fees: double.tryParse(_feesC.text) ?? 0,
        isActive: _active,
        // الإضافة الجديدة تنتظر موافقة المدير العام؛ التعديل يحافظ على الحالة.
        isApproved: widget.existing?.isApproved ?? false,
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon,
      {TextInputType? type, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

/// معاينة صورة العيادة داخل النموذج (تُخفي نفسها بلا صورة).
class ClinicPhotoPreviewTile extends StatelessWidget {
  const ClinicPhotoPreviewTile({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ClinicPhotoTile(imageUrl: imageUrl, side: 96, radius: 16),
    );
  }
}
