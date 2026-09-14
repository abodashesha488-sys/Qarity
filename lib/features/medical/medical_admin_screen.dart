import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/medical_models.dart';
import '../../services/medical_service.dart';

/// شاشة إدارة المركز الطبي الخيري — لمدير المركز الطبي.
/// إضافة/تعديل/حذف عيادات المركز مع الأيام والساعات والأجور.
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
      builder: (_) => _ClinicEditForm(
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
      await _service.deleteClinic(c.id);
      _snack('تم الحذف');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('إدارة المركز الطبي الخيري'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة عيادة'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(0xFF00897B).withValues(alpha: 0.12),
                    child: const Icon(Icons.medical_services_rounded,
                        color: Color(0xFF00897B)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                   subtitle: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
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
        'fees': fees,
        'isActive': isActive,
      };
}

class _ClinicEditForm extends StatefulWidget {
  const _ClinicEditForm({required this.days, this.existing});
  final List<String> days;
  final MedicalCenterClinic? existing;

  @override
  State<_ClinicEditForm> createState() => _ClinicEditFormState();
}

class _ClinicEditFormState extends State<_ClinicEditForm> {
  late final _nameC = TextEditingController(text: widget.existing?.name ?? '');
  late final _doctorC =
      TextEditingController(text: widget.existing?.doctorName ?? '');
  late final _hoursC =
      TextEditingController(text: widget.existing?.workingHours ?? '');
  late final _feesC = TextEditingController(
      text: (widget.existing?.fees ?? 0) > 0
          ? (widget.existing!.fees).toStringAsFixed(0)
          : '');
  late final _descC =
      TextEditingController(text: widget.existing?.description ?? '');
  late String _specialty = widget.existing?.specialty ?? 'باطنة';
  late final Set<String> _days = {...?widget.existing?.workingDays};
  late bool _active = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    _nameC.dispose();
    _doctorC.dispose();
    _hoursC.dispose();
    _feesC.dispose();
    _descC.dispose();
    super.dispose();
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
              Text(widget.existing == null ? 'إضافة عيادة' : 'تعديل عيادة',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
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
                  const SizedBox(height: 12),
                  _f(_hoursC, 'مواعيد العمل (مثال: 9 ص - 2 م)',
                      Icons.access_time_rounded),
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
            onPressed: () {
              if (_nameC.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                MedicalCenterClinic(
                  id: widget.existing?.id ?? '',
                  name: _nameC.text.trim(),
                  specialty: _specialty,
                  doctorName: _doctorC.text.trim(),
                  description: _descC.text.trim(),
                  workingDays: _days.toList(),
                  workingHours: _hoursC.text.trim(),
                  fees: double.tryParse(_feesC.text) ?? 0,
                  isActive: _active,
                  // الإضافة الجديدة تنتظر موافقة المدير العام؛ التعديل يحافظ على الحالة.
                  isApproved: widget.existing?.isApproved ?? false,
                ),
              );
            },
            child: const Text('حفظ',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
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
