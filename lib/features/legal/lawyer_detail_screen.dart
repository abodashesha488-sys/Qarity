import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/contact_links.dart';
import '../../core/utils/relative_time.dart';
import '../../models/legal_models.dart';
import '../../routes/app_routes.dart';
import '../../services/legal_service.dart';
import '../../services/share_service.dart';
import '../../widgets/full_fit_image.dart';
import '../../widgets/qurity_app_bar.dart';
import 'legal_advisor_screen.dart';

/// صفحة تفاصيل المحامي — صورته كاملة بلا اقتصاص، تخصصاته، مكتبه ومواعيده،
/// وأزرار تواصل، وتحكم لصاحب التسجيل (تعديل/حذف) إلى جانب ما تملكه الإدارة.
class LawyerDetailScreen extends StatefulWidget {
  const LawyerDetailScreen({super.key, this.service});

  /// قابل للحقن لاختبار الشاشة بلا Firebase (نمط المشروع).
  final LawyerService? service;

  @override
  State<LawyerDetailScreen> createState() => _LawyerDetailScreenState();
}

class _LawyerDetailScreenState extends State<LawyerDetailScreen> {
  late final LawyerService _service = widget.service ?? LawyerService();
  Lawyer? _lawyer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lawyer ??= ModalRoute.of(context)?.settings.arguments as Lawyer?;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _edit(Lawyer lawyer) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => LawyerFormSheet(service: _service, existing: lawyer)),
    );
    if (ok != true || !mounted) return;
    final fresh = await _safeGet(lawyer.id);
    if (!mounted) return;
    setState(() => _lawyer = fresh ?? lawyer);
    _snack('تم حفظ التعديلات');
  }

  Future<void> _confirmDelete(Lawyer lawyer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التسجيل'),
        content:
            Text('سيُحذف تسجيل «${lawyer.name}» من سجل المحامين نهائيًا.'),
        actions: [
          TextButton(
            key: const Key('lawyer-detail-delete-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const Key('lawyer-detail-delete-confirm'),
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
      if (mounted) Navigator.pop(context);
      _snack('تم حذف تسجيل «${lawyer.name}»');
    } catch (_) {
      _snack('تعذّر الحذف — تحقّق من الصلاحيات ثم أعد المحاولة.', error: true);
    }
  }

  Future<Lawyer?> _safeGet(String id) async {
    try {
      return await _service.getById(id);
    } catch (_) {
      return null;
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
    final lawyer = _lawyer;
    if (lawyer == null) {
      return Scaffold(
        appBar: const QurityAppBar(title: 'تفاصيل المحامي'),
        body: Center(
          child: Text('انتهت صلاحية هذا الرابط — افتح المحامي من سجل المحامين.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      uid = null;
    }
    final isOwner = uid != null &&
        uid.isNotEmpty &&
        uid == lawyer.submittedBy;

    return Scaffold(
      appBar: QurityAppBar(
        title: lawyer.name,
        actions: [
          IconButton(
            key: const Key('lawyer-detail-share'),
            tooltip: 'مشاركة بيانات المحامي',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareService.shareText(
              title: '⚖️ ${lawyer.name}',
              body: [
                if (lawyer.specializationsLine.isNotEmpty)
                  'التخصص: ${lawyer.specializationsLine}',
                if (lawyer.office.isNotEmpty) 'المكتب: ${lawyer.office}',
                if (lawyer.workingHours.isNotEmpty)
                  'مواعيد العمل: ${lawyer.workingHours}',
                if (lawyer.bio.isNotEmpty) lawyer.bio,
                if (lawyer.phone.isNotEmpty) 'تواصل: ${lawyer.phone}',
                '— من سجل المحامين في تطبيق قرية أبوديشيشة',
              ].join('\n'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _identityCard(theme, lawyer),
          if (lawyer.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              theme,
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(theme, Icons.person_outline_rounded, 'نبذة'),
                    const SizedBox(height: 8),
                    Text(lawyer.bio,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.75,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _card(
            theme,
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle(theme, Icons.info_outline_rounded, 'بيانات التسجيل'),
                  const SizedBox(height: 6),
                  _infoRow(theme, Icons.work_outline_rounded, 'التخصص',
                      lawyer.specializationsLine),
                  _infoRow(theme, Icons.location_city_rounded, 'المكتب',
                      lawyer.office),
                  _infoRow(theme, Icons.schedule_rounded, 'مواعيد العمل',
                      lawyer.workingHours),
                  _infoRow(theme, Icons.phone_rounded, 'الهاتف', lawyer.phone),
                  _infoRow(theme, Icons.person_rounded, 'مقدّم التسجيل',
                      lawyer.submittedByName),
                  _infoRow(theme, Icons.history_rounded, 'أُضيف',
                      relativeTimeLabelAr(lawyer.createdAt)),
                ],
              ),
            ),
          ),
          if (lawyer.phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('lawyer-detail-call'),
                    onPressed: () => _launch('tel://${lawyer.phone}'),
                    style: FilledButton.styleFrom(
                        backgroundColor: kLegalAdvisorColor,
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
                    key: const Key('lawyer-detail-whatsapp'),
                    onPressed: () {
                      final u = egyptianWhatsAppUrl(lawyer.phone);
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
          ],
          if (isOwner) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('lawyer-detail-edit'),
              onPressed: () => _edit(lawyer),
              style: OutlinedButton.styleFrom(
                foregroundColor: kLegalAdvisorColor,
                side: const BorderSide(color: kLegalAdvisorColor, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('تعديل تسجيلي',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('lawyer-detail-delete'),
              onPressed: () => _confirmDelete(lawyer),
              style: OutlinedButton.styleFrom(
                foregroundColor: kLegalDeleteRed,
                side: const BorderSide(color: kLegalDeleteRed, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('حذف تسجيلي',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('lawyer-detail-ask'),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.legalAdvisor),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              side: BorderSide(
                  color: theme.colorScheme.outlineVariant, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: const Text('اطرح استشارتك في «مستشار القرية»',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 10),
          _notice(theme),
        ],
      ),
    );
  }

  /// بطاقة الهوية: الصورة كاملة (أو حرف الاسم) ثم الاسم ورقائق التخصص.
  Widget _identityCard(ThemeData theme, Lawyer lawyer) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kLegalAdvisorColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: kLegalAdvisorColor.withValues(alpha: 0.32)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FullFitImage(
                imageUrl: lawyer.photoUrl,
                width: 92,
                radius: 0,
                fallback: _avatar(theme, lawyer.name),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lawyer.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 17)),
                  if (lawyer.office.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(lawyer.office,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  if (lawyer.specializations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in lawyer.specializations) _specChip(s),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _specChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: kLegalAdvisorColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: kLegalAdvisorColor)),
      );

  Widget _avatar(ThemeData theme, String name) => Container(
        width: 92,
        height: 92,
        color: kLegalAdvisorColor.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Text(
          name.isEmpty ? '⚖️' : name.characters.first,
          style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: kLegalAdvisorColor),
        ),
      );

  /// تنبيه إرشادي ثابت: محتوى السجل توعوي لا وكالة ولا ترخيص.
  Widget _notice(ThemeData theme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kLegalDeleteRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kLegalDeleteRed.withValues(alpha: 0.3)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 18, color: kLegalDeleteRed),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'بيانات هذا السجل يقدّمها صاحبه، والتطبيق لا يتحقق من قيده '
                'النقابي. تواصل مع المحامي مباشرة وتأكد من أوراقه قبل أي تكليف.',
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: kLegalDeleteRed),
              ),
            ),
          ],
        ),
      );

  Widget _card(ThemeData theme, Widget child) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: child,
      );

  Widget _cardTitle(ThemeData theme, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: kLegalAdvisorColor),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      );

  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: kLegalAdvisorColor),
          const SizedBox(width: 8),
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
