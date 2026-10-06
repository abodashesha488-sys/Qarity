import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/legal_reference_egypt.dart';
import '../../core/utils/relative_time.dart';
import '../../models/legal_models.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/legal_service.dart';
import '../../services/user_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/full_fit_image.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';

/// أحمر/برتقالي هذا القسم — مستقل عن أخضر «منشور» وعن تركوازي القسم.
const Color kLegalDeleteRed = Color(0xFFB71C1C);
const Color kLegalPendingOrange = Color(0xFFEF6C00);

/// حبر القسم: في الفاتح هو تركوازي القسم حرفيًا، وفي الداكن يُرفع سطوعه
/// محافظًا على درجته — فالأصل 2.28 على البطاقة الداكنة ولا يُقرأ.
Color legalInk(Brightness brightness) =>
    AppColors.inkOn(kLegalAdvisorColor, brightness);

/// شاشة «مستشار القرية»: سجل محامين + استشارات الأهالي + مرجع معلومات قانونية.
class LegalAdvisorScreen extends StatefulWidget {
  const LegalAdvisorScreen({super.key, this.lawyers, this.consultations});

  /// قابلان للحقن لاختبار الشاشة بلا Firebase (نمط المشروع).
  final LawyerService? lawyers;
  final LegalConsultationService? consultations;

  @override
  State<LegalAdvisorScreen> createState() => _LegalAdvisorScreenState();
}

class _LegalAdvisorScreenState extends State<LegalAdvisorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// زر «+» في الهيدر يتبع التبويب المفتوح؛ المرجع القانوني ثابت بلا إضافة.
  ({String tooltip, VoidCallback action})? _addForTab() {
    return switch (_tabs.index) {
      0 => (
          tooltip: 'سجّل نفسك محاميًا في الدليل',
          action: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => LawyerFormSheet(service: widget.lawyers)))
        ),
      1 => (
          tooltip: 'اطرح استشارتك القانونية',
          action: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ConsultationFormSheet(service: widget.consultations)))
        ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final add = _addForTab();
    return Scaffold(
      appBar: QurityAppBar(
        title: 'مستشار القرية',
        onAdd: add?.action,
        addTooltip: add?.tooltip ?? 'إضافة',
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => setState(() {}),
          dividerColor: Colors.transparent,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'المحامون'),
            Tab(text: 'الاستشارات'),
            Tab(text: 'معلومات قانونية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LawyersTab(service: widget.lawyers),
          _ConsultationsTab(service: widget.consultations),
          const _LegalReferenceTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════ تبويب المحامين ═══════════════════════════
class _LawyersTab extends StatefulWidget {
  const _LawyersTab({this.service});
  final LawyerService? service;

  @override
  State<_LawyersTab> createState() => _LawyersTabState();
}

class _LawyersTabState extends State<_LawyersTab> {
  late final LawyerService _service = widget.service ?? LawyerService();
  late final Stream<List<Lawyer>> _feed = _service.watchApproved();
  final TextEditingController _search = TextEditingController();

  String _spec = '';
  String _query = '';
  bool _mineOnly = false;
  String _myUid = '';
  Stream<List<Lawyer>>? _mineStream;

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

  List<Lawyer> _apply(List<Lawyer> all) => all.where((l) {
        if (_spec.isNotEmpty && !l.specializations.contains(_spec)) {
          return false;
        }
        if (_query.isEmpty) return true;
        return [
          l.name,
          l.specializationsLine,
          l.office,
          l.bio,
          l.workingHours,
        ].join(' ').toLowerCase().contains(_query);
      }).toList();

  void _toggleMine() => setState(() {
        _mineOnly = !_mineOnly;
        if (_mineOnly && _myUid.isNotEmpty) {
          _mineStream ??= _service.watchMine(_myUid);
        }
      });

  Future<void> _confirmDelete(Lawyer lawyer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التسجيل'),
        content:
            Text('سيُحذف تسجيل «${lawyer.name}» من سجل المحامين نهائيًا.'),
        actions: [
          TextButton(
            key: const Key('lawyer-delete-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const Key('lawyer-delete-confirm'),
            style: FilledButton.styleFrom(backgroundColor: kLegalDeleteRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(lawyer.id);
      _snack('تم حذف تسجيل «${lawyer.name}»');
    } catch (_) {
      _snack('تعذّر الحذف — تحقّق من الصلاحيات ثم أعد المحاولة.', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? kLegalDeleteRed : kLegalAdvisorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _chip(String value, String label) {
    final selected = _spec == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _spec = value),
        label: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : null)),
        selectedColor: kLegalAdvisorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          color: kLegalAdvisorColor.withValues(alpha: 0.06),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            children: [
              TextField(
                key: const Key('lawyer-search'),
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'ابحث: اسم المحامي، تخصصه، مكتبه…',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: legalInk(theme.brightness), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: 'مسح',
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: _search.clear,
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('', 'كل التخصصات'),
                    for (final s in kLegalSpecializations) _chip(s, s),
                    ChoiceChip(
                      key: const Key('lawyer-mine-toggle'),
                      selected: _mineOnly,
                      onSelected: (_) => _toggleMine(),
                      avatar: Icon(
                          _myUid.isEmpty
                              ? Icons.lock_outline_rounded
                              : Icons.person_rounded,
                          size: 16),
                      label: const Text('تسجيلي',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      selectedColor: kLegalAdvisorColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Lawyer>>(
            stream: _mineOnly ? _mineStream : _feed,
            builder: (context, snap) {
              if (_mineOnly && _myUid.isEmpty) {
                return _empty(theme, Icons.lock_outline_rounded,
                    'سجّل الدخول لترى تسجيلك في السجل');
              }
              if (!snap.hasData) {
                return Center(
                    child: CircularProgressIndicator(
                        color: legalInk(Theme.of(context).brightness)));
              }
              final items = _apply(snap.data!);
              if (items.isEmpty) {
                return _empty(
                    theme,
                    Icons.gavel_rounded,
                    _mineOnly
                        ? 'لم تسجّل نفسك بعد\nاضغط «+» في الأعلى للتسجيل'
                        : (_query.isNotEmpty || _spec.isNotEmpty
                            ? 'لا يوجد محامون مطابقون'
                            : 'السجل بانتظار أول تسجيل معتمد'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final lawyer = items[i];
                  return LawyerCard(
                    lawyer: lawyer,
                    showStatus: _mineOnly,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.lawyerDetail,
                        arguments: lawyer),
                    onEdit: _mineOnly
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LawyerFormSheet(
                                    service: _service, existing: lawyer)))
                        : null,
                    onDelete:
                        _mineOnly ? () => _confirmDelete(lawyer) : null,
                  ).animate(delay: ((i % 8) * 35).ms).fadeIn(duration: 300.ms);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _empty(ThemeData theme, IconData icon, String text) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 54,
                color: legalInk(theme.brightness).withValues(alpha: 0.4)),
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

/// بطاقة محامٍ في السجل — صورة كاملة بلا اقتصاص ثم الاسم والتخصصات.
class LawyerCard extends StatelessWidget {
  const LawyerCard({
    super.key,
    required this.lawyer,
    required this.onTap,
    this.showStatus = false,
    this.onEdit,
    this.onDelete,
  });

  final Lawyer lawyer;
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
        side: BorderSide(color: kLegalAdvisorColor.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FullFitImage(
                    imageUrl: lawyer.photoUrl,
                    width: 92,
                    fallback: const _LawyerAvatar(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lawyer.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15.5)),
                        if (lawyer.office.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(lawyer.office,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                        if (lawyer.bio.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(lawyer.bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (lawyer.specializations.isNotEmpty) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in lawyer.specializations)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color:
                                kLegalAdvisorColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: kLegalAdvisorColor
                                    .withValues(alpha: 0.35))),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: legalInk(theme.brightness))),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 5,
                children: [
                  if (lawyer.phone.isNotEmpty)
                    _meta(theme, Icons.phone_rounded, lawyer.phone),
                  if (lawyer.workingHours.isNotEmpty)
                    _meta(theme, Icons.schedule_rounded, lawyer.workingHours),
                ],
              ),
              if (showStatus) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatusMark(approved: lawyer.isApproved),
                    const Spacer(),
                    if (onEdit != null)
                      IconButton(
                        key: Key('lawyer-edit-${lawyer.id}'),
                        tooltip: 'تعديل التسجيل',
                        icon: const Icon(Icons.edit_rounded, size: 19),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        key: Key('lawyer-delete-${lawyer.id}'),
                        tooltip: 'حذف التسجيل',
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 19, color: kLegalDeleteRed),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: legalInk(theme.brightness)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

class _LawyerAvatar extends StatelessWidget {
  const _LawyerAvatar();

  @override
  Widget build(BuildContext context) => Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
            color: kLegalAdvisorColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.gavel_rounded,
            size: 34,
            color: legalInk(Theme.of(context).brightness)
                .withValues(alpha: 0.65)),
      );
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.approved});
  final bool approved;

  @override
  Widget build(BuildContext context) {
    final color = approved ? const Color(0xFF2E7D32) : kLegalPendingOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(approved ? 'معتمد في السجل ✓' : 'بانتظار موافقة الإدارة',
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w900, color: color)),
    );
  }
}

// ═══════════════════════════ تبويب الاستشارات ═══════════════════════════
class _ConsultationsTab extends StatefulWidget {
  const _ConsultationsTab({this.service});
  final LegalConsultationService? service;

  @override
  State<_ConsultationsTab> createState() => _ConsultationsTabState();
}

class _ConsultationsTabState extends State<_ConsultationsTab> {
  late final LegalConsultationService _service =
      widget.service ?? LegalConsultationService();
  late final Stream<List<LegalConsultation>> _feed = _service.watchApproved();
  bool _mineOnly = false;
  String _myUid = '';
  Stream<List<LegalConsultation>>? _mineStream;

  @override
  void initState() {
    super.initState();
    try {
      _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      _myUid = '';
    }
  }

  void _toggleMine() => setState(() {
        _mineOnly = !_mineOnly;
        if (_mineOnly && _myUid.isNotEmpty) {
          _mineStream ??= _service.watchMine(_myUid);
        }
      });

  Future<void> _openEdit(LegalConsultation c) async {
    if (c.isApproved) {
      _snack('لا يمكن تعديل سؤال نُشر — احذفه وأعد طرحه إن لزم.', error: true);
      return;
    }
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => ConsultationFormSheet(service: _service, existing: c)));
    if (saved == true) _snack('تم حفظ التعديلات — عاد سؤالك للمراجعة');
  }

  Future<bool> _delete(LegalConsultation c) async {
    try {
      await _service.delete(c.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? kLegalDeleteRed : kLegalAdvisorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          color: kLegalAdvisorColor.withValues(alpha: 0.06),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'استشارات الأهالي — تُنشر بعد موافقة الإدارة، والرد يكتبه '
                  'مستشار القسم.',
                  style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                key: const Key('consult-mine-toggle'),
                selected: _mineOnly,
                onSelected: (_) => _toggleMine(),
                avatar: Icon(
                    _myUid.isEmpty ? Icons.lock_outline_rounded : Icons.person_rounded,
                    size: 16),
                label: const Text('استشاراتي',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                selectedColor: kLegalAdvisorColor,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<LegalConsultation>>(
            stream: _mineOnly ? _mineStream : _feed,
            builder: (context, snap) {
              if (_mineOnly && _myUid.isEmpty) {
                return _empty(theme, Icons.lock_outline_rounded,
                    'سجّل الدخول لمتابعة استشاراتك');
              }
              if (!snap.hasData) {
                return Center(
                    child: CircularProgressIndicator(
                        color: legalInk(Theme.of(context).brightness)));
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return _empty(
                    theme,
                    Icons.help_outline_rounded,
                    _mineOnly
                        ? 'لم تطرح استشارة بعد\nاضغط «+» في الأعلى'
                        : 'لا توجد استشارات منشورة بعد');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final c = items[i];
                  return ConsultationCard(
                    consultation: c,
                    showStatus: _mineOnly,
                    currentUserId: _mineOnly ? _myUid : '',
                    onEdit: () => _openEdit(c),
                    onDelete: () => _delete(c),
                  ).animate(delay: ((i % 8) * 35).ms).fadeIn(duration: 300.ms);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _empty(ThemeData theme, IconData icon, String text) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 54,
                color: legalInk(theme.brightness).withValues(alpha: 0.4)),
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

/// بطاقة استشارة: السؤال ثم الرد إن كُتب.
class ConsultationCard extends StatelessWidget {
  const ConsultationCard({
    super.key,
    required this.consultation,
    this.showStatus = false,
    this.currentUserId = '',
    this.onEdit,
    this.onDelete,
  });

  final LegalConsultation consultation;
  final bool showStatus;
  final String currentUserId;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = consultation;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: kLegalAdvisorColor.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: kLegalAdvisorColor,
                      borderRadius: BorderRadius.circular(7)),
                  child: Text(c.category,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
                const Spacer(),
                Text(relativeTimeLabelAr(c.createdAt),
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 9),
            Text(c.question,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 14, height: 1.5)),
            if (c.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(c.details,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.65,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (c.hasAnswer) ...[
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: kLegalAdvisorColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: kLegalAdvisorColor.withValues(alpha: 0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 14, color: legalInk(theme.brightness)),
                        const SizedBox(width: 5),
                        Text('رد المستشار',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: legalInk(theme.brightness))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(c.answer,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 9),
              Text('بانتظار رد المستشار',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (showStatus) ...[
              const SizedBox(height: 10),
              _StatusMark(approved: c.isApproved),
              const SizedBox(height: 10),
              OwnerActions(
                keyTag: 'consult-${c.id}',
                ownerId: c.userId,
                currentUserId: currentUserId,
                itemName: 'استشارتك',
                editLabel: 'تعديل السؤال',
                deleteLabel: 'حذف السؤال',
                onEdit: onEdit ?? () {},
                onDelete: onDelete ?? () async => false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ تبويب المعلومات القانونية ═══════════════════════
/// مرجع «حسب القانون المصري الحديث — نظم القضاء المصري»: بيانات ثابتة داخل
/// الحزمة، تعمل بلا اتصال، ولا تقرأ من Firestore إطلاقًا.
class _LegalReferenceTab extends StatelessWidget {
  const _LegalReferenceTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: kLegalDeleteRed.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: kLegalDeleteRed.withValues(alpha: 0.35))),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: kLegalDeleteRed, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(kLegalReferenceDisclaimer,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: kLegalDeleteRed,
                        height: 1.55)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('موضوعات المرجع',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: 10),
        for (final topic in kLegalReferenceTopics)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: kLegalAdvisorColor.withValues(alpha: 0.28)),
              ),
              child: ListTile(
                onTap: () => showLegalTopicSheet(context, topic),
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: kLegalAdvisorColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11)),
                  child: Icon(topic.icon,
                      size: 20, color: legalInk(theme.brightness)),
                ),
                title: Text(topic.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13.5)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(topic.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
                trailing: const Icon(Icons.chevron_left_rounded, size: 18),
              ),
            ),
          ),
      ],
    );
  }
}

/// ورقة موضوع قانوني — نقاط مفصّلة + تنبيه + زر «اطرح استشارتك» في نفس التصنيف.
Future<void> showLegalTopicSheet(BuildContext context, LegalTopic topic) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => LegalTopicSheet(topic: topic),
    );

class LegalTopicSheet extends StatelessWidget {
  const LegalTopicSheet({super.key, required this.topic});
  final LegalTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ListView(
          controller: controller,
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
            Row(
              children: [
                Icon(topic.icon, size: 22, color: legalInk(theme.brightness)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(topic.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(topic.summary,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.7, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            for (final point in topic.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: legalInk(theme.brightness),
                              shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(point,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.7,
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: kLegalAdvisorColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(kLegalReferenceDisclaimer,
                  style: TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                      color: legalInk(theme.brightness))),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('topic-ask-consultation'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConsultationFormSheet()));
                },
                style: FilledButton.styleFrom(
                    backgroundColor: kLegalAdvisorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('اطرح استشارتك في هذا الموضوع',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ نموذج تسجيل محامٍ ═══════════════════════════
class LawyerFormSheet extends StatefulWidget {
  const LawyerFormSheet({
    super.key,
    this.existing,
    this.service,
    this.uploader,
    this.bytesSource,
  });

  final Lawyer? existing;
  final LawyerService? service;

  /// اختياري لاختبار المحرّر المشترك بلا شبكة ولا معرض جهاز.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  @override
  State<LawyerFormSheet> createState() => _LawyerFormSheetState();
}

class _LawyerFormSheetState extends State<LawyerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final LawyerService _service = widget.service ?? LawyerService();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _office =
      TextEditingController(text: widget.existing?.office ?? '');
  late final TextEditingController _hours =
      TextEditingController(text: widget.existing?.workingHours ?? '');
  late final TextEditingController _bio =
      TextEditingController(text: widget.existing?.bio ?? '');

  late final List<String> _specs = [...?widget.existing?.specializations];
  late String _photo = widget.existing?.photoUrl ?? '';
  String _error = '';
  bool _uploading = false;
  bool _saving = false;
  String _uid = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    try {
      _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      _uid = '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _office.dispose();
    _hours.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_specs.isEmpty) {
      setState(() => _error = 'اختر تخصصًا واحدًا على الأقل.');
      return;
    }
    if (_uid.isEmpty && widget.existing == null) {
      setState(() => _error = 'سجّل الدخول أولاً لتسجيل نفسك في السجل.');
      return;
    }
    setState(() => _saving = true);
    if (_userName.isEmpty) {
      try {
        _userName = (await UserService().resolveAuthor()).name;
      } catch (_) {
        _userName = widget.existing?.submittedByName ?? '';
      }
    }
    final lawyer = Lawyer(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      specializations: [
        for (final s in kLegalSpecializations)
          if (_specs.contains(s)) s,
      ],
      office: _office.text.trim(),
      workingHours: _hours.text.trim(),
      bio: _bio.text.trim(),
      photoUrl: _photo,
      submittedBy: widget.existing?.submittedBy ?? _uid,
      submittedByName:
          widget.existing?.submittedByName.isNotEmpty ?? false
              ? widget.existing!.submittedByName
              : _userName,
      isApproved: widget.existing?.isApproved ?? false,
      createdAt: widget.existing?.createdAt,
    );
    try {
      if (widget.existing == null) {
        await _service.create(lawyer);
      } else {
        await _service.update(lawyer.id, lawyer);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'تعذّر الحفظ — تحقّق من الاتصال ومن صلاحياتك.';
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kLegalAdvisorColor,
        foregroundColor: Colors.white,
        title: Text(
            widget.existing == null ? 'تسجيل في سجل المحامين' : 'تعديل التسجيل',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _photo.isEmpty
                          ? const SizedBox(
                              width: 92,
                              height: 92,
                              child: _LawyerAvatar(),
                            )
                          : FullFitImage(
                              imageUrl: _photo,
                              width: 92,
                              fallback: const _LawyerAvatar(),
                            ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'صورة المحامي تظهر في السجل وفي صفحة التفاصيل — '
                        'أضفها أو غيّرها من المحرّر أدناه.',
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.6,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ImageListEditor(
                  label: 'صورة المحامي (اختياري)',
                  fieldKey: 'photoUrl',
                  single: true,
                  urls: _photo.isEmpty ? const <String>[] : <String>[_photo],
                  uploader: widget.uploader,
                  bytesSource: widget.bytesSource,
                  maxSide: 1280,
                  onBusyChanged: (busy) => setState(() => _uploading = busy),
                  onChanged: (urls) =>
                      setState(() => _photo = urls.isEmpty ? '' : urls.first),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('lawyer-field-name'),
                  controller: _name,
                  decoration: _dec('اسم المحامي (بالقيد النقابي) *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'الاسم مطلوب'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('lawyer-field-phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('هاتف التواصل / مكتب المحاماة *'),
                  validator: (v) => (v == null || v.trim().length < 8)
                      ? 'ضع رقمًا صحيحًا ليصل إليك الأهالي'
                      : null,
                ),
                const SizedBox(height: 12),
                Text('التخصصات (اختر ما تعمل به)',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in kLegalSpecializations)
                      FilterChip(
                        key: Key('lawyer-spec-$s'),
                        selected: _specs.contains(s),
                        onSelected: (on) => setState(() {
                          if (on) {
                            if (!_specs.contains(s)) _specs.add(s);
                          } else {
                            _specs.remove(s);
                          }
                        }),
                        label: Text(s,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 11.5)),
                        selectedColor:
                            kLegalAdvisorColor.withValues(alpha: 0.16),
                        checkmarkColor: legalInk(theme.brightness),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _office,
                  decoration: _dec('عنوان المكتب / المدينة'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _hours,
                  decoration: _dec('مواعيد العمل (مثال: السبت–الخميس 10ص–4م)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bio,
                  maxLines: 4,
                  decoration: _dec(
                      'نبذة مختصرة: سنوات الخبرة، نوع القضايا التي تتولاها، وأي '
                      'تفصيل يفيد الأهالي…'),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    key: const Key('lawyer-form-error'),
                    _error,
                    style: const TextStyle(
                        color: kLegalDeleteRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kLegalDeleteRed.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kLegalDeleteRed.withValues(alpha: 0.35))),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: kLegalDeleteRed, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'التسجيل يظهر في السجل بعد موافقة الإدارة، وهو قيْد '
                          'إرشادي لا يُعد وكالة ولا ترخيصًا بمزاولة المهنة.',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: kLegalDeleteRed,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('lawyer-save'),
                    onPressed: _saving || _uploading ? null : _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: kLegalAdvisorColor,
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
                            ? 'إرسال للتسجيل بعد المراجعة'
                            : 'حفظ التعديلات',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════ نموذج استشارة قانونية ═══════════════════════════
class ConsultationFormSheet extends StatefulWidget {
  const ConsultationFormSheet({super.key, this.existing, this.service});

  final LegalConsultation? existing;
  final LegalConsultationService? service;

  @override
  State<ConsultationFormSheet> createState() => _ConsultationFormSheetState();
}

class _ConsultationFormSheetState extends State<ConsultationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final LegalConsultationService _service =
      widget.service ?? LegalConsultationService();
  late final TextEditingController _question =
      TextEditingController(text: widget.existing?.question ?? '');
  late final TextEditingController _details =
      TextEditingController(text: widget.existing?.details ?? '');
  late String _category = widget.existing?.category ?? 'استشارات عامة';
  String _error = '';
  bool _saving = false;
  String _uid = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    try {
      _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      _uid = '';
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uid.isEmpty && widget.existing == null) {
      setState(() => _error = 'سجّل الدخول أولاً لطرح استشارتك.');
      return;
    }
    setState(() => _saving = true);
    if (_userName.isEmpty) {
      try {
        _userName = (await UserService().resolveAuthor()).name;
      } catch (_) {
        _userName = widget.existing?.userName ?? '';
      }
    }
    final c = LegalConsultation(
      id: widget.existing?.id ?? '',
      question: _question.text.trim(),
      details: _details.text.trim(),
      category: _category,
      userId: widget.existing?.userId ?? _uid,
      userName: widget.existing?.userName.isNotEmpty ?? false
          ? widget.existing!.userName
          : _userName,
      answer: widget.existing?.answer ?? '',
      isApproved: widget.existing?.isApproved ?? false,
      createdAt: widget.existing?.createdAt,
    );
    try {
      if (widget.existing == null) {
        await _service.create(c);
      } else {
        await _service.update(c.id, c);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'تعذّر الإرسال — تحقّق من الاتصال ومن صلاحياتك.';
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kLegalAdvisorColor,
        foregroundColor: Colors.white,
        title: Text(
            widget.existing == null ? 'استشارة قانونية جديدة' : 'تعديل الاستشارة',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التصنيف',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: const Key('consult-field-category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: _dec(''),
                  items: [
                    for (final s in kLegalSpecializations)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(
                      () => _category = v ?? 'استشارات عامة'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('consult-field-question'),
                  controller: _question,
                  maxLines: 2,
                  decoration: _dec('سؤالك في سطر واضح *'),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'اكتب سؤالك بوضوح (١٠ أحرف على الأقل)'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('consult-field-details'),
                  controller: _details,
                  maxLines: 6,
                  decoration: _dec(
                      'تفاصيل الحالة: ما حدث، التواريخ، الأوراق التي لديك، وما '
                      'الخطوة التي تحتار فيها…'),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    key: const Key('consult-form-error'),
                    _error,
                    style: const TextStyle(
                        color: kLegalDeleteRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kLegalDeleteRed.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kLegalDeleteRed.withValues(alpha: 0.35))),
                  child: const Row(
                    children: [
                      Icon(Icons.privacy_tip_rounded,
                          color: kLegalDeleteRed, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لا تكتب أسماءً أو أرقام قضايا أو بيانات شخصية؛ '
                          'الاستشارة تُراجَع ثم تُنشر للقرية مع الرد، ولا تُغني '
                          'عن محامٍ يطلع على أوراقك.',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: kLegalDeleteRed,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('consult-save'),
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: kLegalAdvisorColor,
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
      ),
    );
  }
}
