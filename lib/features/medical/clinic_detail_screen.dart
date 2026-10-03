import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/medical_models.dart';
import '../../services/medical_service.dart';
import '../../services/share_service.dart';
import '../../widgets/common_appbar_actions.dart';
import '../../widgets/header_action_buttons.dart';
import '../../widgets/image_gallery_wrap.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import 'medical_home_screen.dart';

/// صف معلومة (أيقونة + عنوان + قيمة) — مشترك بين شاشات التفاصيل الطبية.
class MedInfoRow extends StatelessWidget {
  const MedInfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      this.accent = const Color(0xFF00897B)});
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة قسم بعنوان — مشتركة.
class MedSection extends StatelessWidget {
  const MedSection(
      {super.key,
      required this.title,
      required this.accent,
      required this.child});
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// رأس متدرج/صورة مشترك لشاشات التفاصيل.
class MedDetailHeader extends StatelessWidget {
  const MedDetailHeader({
    super.key,
    required this.title,
    required this.accent,
    required this.accentDark,
    required this.imageUrl,
    required this.icon,
    this.onShare,
    this.onAdd,
    this.addTooltip = 'إضافة',
  });
  final String title;
  final Color accent;
  final Color accentDark;
  final String imageUrl;
  final IconData icon;
  final VoidCallback? onShare;

  /// إجراء إضافة الشاشة — يظهر كزر «+» الأخضر في الهيدر (لا في شاشات لا إضافة لها).
  final VoidCallback? onAdd;
  final String addTooltip;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: QurityAppBar.headerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 10,
          title: Row(
            children: [
              const HeaderHomeButton(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          actions: [
            if (onShare != null)
              IconButton(
                  tooltip: 'مشاركة',
                  icon: const Icon(Icons.share_rounded),
                  onPressed: onShare),
            if (onAdd != null)
              HeaderAddButton(onPressed: onAdd!, tooltip: addTooltip),
            const NotificationBellButton(),
          ],
        ),
        if (imageUrl.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      _gradientFallback(context)),
            ),
          ),
      ],
    );
  }

  Widget _gradientFallback(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accentDark, accent])),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Icon(icon, size: 72, color: Colors.white.withValues(alpha: 0.55)),
          ),
        ),
      );
}

/// شاشة تفاصيل عيادة القرية — عرض احترافي كامل مع الاتصال والمشاركة،
/// و«عدّل/احذف» لصاحب العيادة وحده على بياناته (البند ٨).
class VillageClinicDetailScreen extends StatefulWidget {
  const VillageClinicDetailScreen({super.key});

  @override
  State<VillageClinicDetailScreen> createState() =>
      _VillageClinicDetailScreenState();
}

class _VillageClinicDetailScreenState extends State<VillageClinicDetailScreen> {
  static const _teal = Color(0xFF00897B);
  static const _tealDark = Color(0xFF00695C);

  /// نسخة محفوظة بعد حفظ التعديل — الشاشة تعرض بالوسائط لا بتدفّق، فلو لم
  /// تُستبدل لظلّت تعرض البيانات القديمة حتى يغلقها المستخدم ويعيد فتحها.
  VillageClinic? _saved;

  /// مبني عند أول استخدام فقط: بلا جلسة اختبار لا يمس Firestore.
  late final VillageClinicService _service = VillageClinicService();

  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openEdit(VillageClinic clinic) async {
    final res = await showModalBottomSheet<VillageClinic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VillageClinicFormSheet(
        userName: clinic.submittedByName ?? '',
        userId: _currentUid,
        existing: clinic,
      ),
    );
    if (res == null || !mounted) return;
    try {
      await _service.update(res);
      if (!mounted) return;
      setState(() => _saved = res);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ التعديلات — عادت العيادة للمراجعة')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال')));
    }
  }

  Future<bool> _deleteRecord(VillageClinic clinic) async {
    try {
      await _service.delete(clinic.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget? _ownerActions(VillageClinic clinic) {
    final owner = clinic.submittedBy ?? '';
    if (_currentUid.isEmpty || _currentUid != owner) return null;
    return OwnerActions(
      keyTag: 'clinic-detail',
      ownerId: owner,
      currentUserId: _currentUid,
      itemName: clinic.name,
      editLabel: 'تعديل العيادة',
      deleteLabel: 'حذف العيادة',
      onEdit: () => _openEdit(clinic),
      onDelete: () => _deleteRecord(clinic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = _saved ??
        ModalRoute.of(context)!.settings.arguments as VillageClinic? ??
            const VillageClinic(id: '', name: '');
    final ownerRow = _ownerActions(clinic);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: clinic.name,
            accent: _teal,
            accentDark: _tealDark,
            imageUrl: clinic.imageUrl,
            icon: Icons.add_business_rounded,
            onShare: () => ShareService.shareText(
                title: '🏥 ${clinic.name}',
                body: [
                  if (clinic.specialty.isNotEmpty)
                    'التخصص: ${clinic.specialty}',
                  if (clinic.ownerName.isNotEmpty)
                    'الطبيب: ${clinic.ownerName}',
                  if (clinic.workingHours.isNotEmpty)
                    'المواعيد: ${clinic.workingHours}',
                  if (clinic.address.isNotEmpty) 'العنوان: ${clinic.address}',
                  if (clinic.phone.isNotEmpty) 'هاتف: ${clinic.phone}',
                ].join('\n')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(clinic.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900)),
                      ),
                      if (clinic.specialty.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _teal.withValues(alpha: 0.3))),
                          child: Text(clinic.specialty,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _teal)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MedSection(
                    title: 'بيانات العيادة',
                    accent: _teal,
                    child: Column(
                      children: [
                        if (clinic.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'الطبيب المسؤول',
                              value: clinic.ownerName),
                        if (clinic.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'هاتف العيادة',
                              value: clinic.phone),
                        if (clinic.workingHours.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'مواعيد العمل',
                              value: clinic.workingHours),
                        if (clinic.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: clinic.address),
                      ],
                    ),
                  ),
                  if (clinic.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن العيادة',
                      accent: _teal,
                      child: Text(clinic.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (clinic.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور العيادة',
                      accent: _teal,
                      child: ImageGalleryWrap(urls: clinic.imageUrls, tileWidth: 180),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (clinic.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: clinic.phone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالعيادة',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  if (ownerRow != null) ...[
                    const SizedBox(height: 12),
                    ownerRow,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة تفاصيل صيدلية القرية — مع «عدّل/احذف» لصاحب الصيدلية وحده (البند ٨).
class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({super.key});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  static const _green = Color(0xFF6F4E37);
  static const _greenDark = Color(0xFF6F4E37);

  Pharmacy? _saved;
  late final PharmacyService _service = PharmacyService();

  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openEdit(Pharmacy pharmacy) async {
    final res = await showModalBottomSheet<Pharmacy>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PharmacyFormSheet(
        userName: pharmacy.submittedByName ?? '',
        userId: _currentUid,
        existing: pharmacy,
      ),
    );
    if (res == null || !mounted) return;
    try {
      await _service.update(res);
      if (!mounted) return;
      setState(() => _saved = res);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ التعديلات — عادت الصيدلية للمراجعة')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال')));
    }
  }

  Future<bool> _deleteRecord(Pharmacy pharmacy) async {
    try {
      await _service.delete(pharmacy.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget? _ownerActions(Pharmacy pharmacy) {
    final owner = pharmacy.submittedBy ?? '';
    if (_currentUid.isEmpty || _currentUid != owner) return null;
    return OwnerActions(
      keyTag: 'pharmacy-detail',
      ownerId: owner,
      currentUserId: _currentUid,
      itemName: pharmacy.name,
      editLabel: 'تعديل الصيدلية',
      deleteLabel: 'حذف الصيدلية',
      onEdit: () => _openEdit(pharmacy),
      onDelete: () => _deleteRecord(pharmacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pharmacy = _saved ??
        ModalRoute.of(context)!.settings.arguments as Pharmacy? ??
            const Pharmacy(id: '', name: '');
    final ownerRow = _ownerActions(pharmacy);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: pharmacy.name,
            accent: _green,
            accentDark: _greenDark,
            imageUrl: pharmacy.imageUrl,
            icon: Icons.local_pharmacy_rounded,
            onShare: () => ShareService.shareText(
                title: '💊 ${pharmacy.name}',
                body: [
                  if (pharmacy.ownerName.isNotEmpty)
                    'المسؤول: ${pharmacy.ownerName}',
                  pharmacy.is24Hours
                      ? 'تعمل على مدار ٢٤ ساعة'
                      : (pharmacy.workingHours.isNotEmpty
                          ? 'المواعيد: ${pharmacy.workingHours}'
                          : ''),
                  if (pharmacy.address.isNotEmpty)
                    'العنوان: ${pharmacy.address}',
                  if (pharmacy.phone.isNotEmpty) 'هاتف: ${pharmacy.phone}',
                ].where((e) => e.isNotEmpty).join('\n')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(pharmacy.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900)),
                      ),
                      if (pharmacy.is24Hours)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _green.withValues(alpha: 0.3))),
                          child: const Text('٢٤ ساعة',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _green)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MedSection(
                    title: 'بيانات الصيدلية',
                    accent: _green,
                    child: Column(
                      children: [
                        if (pharmacy.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'الصيدلي المسؤول',
                              value: pharmacy.ownerName,
                              accent: _green),
                        if (pharmacy.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'الهاتف',
                              value: pharmacy.phone,
                              accent: _green),
                        if (pharmacy.workingHours.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'مواعيد العمل',
                              value: pharmacy.workingHours,
                              accent: _green),
                        if (pharmacy.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: pharmacy.address,
                              accent: _green),
                      ],
                    ),
                  ),
                  if (pharmacy.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن الصيدلية',
                      accent: _green,
                      child: Text(pharmacy.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (pharmacy.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور الصيدلية',
                      accent: _green,
                      child: ImageGalleryWrap(urls: pharmacy.imageUrls, tileWidth: 180),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (pharmacy.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: pharmacy.phone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالصيدلية',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  if (ownerRow != null) ...[
                    const SizedBox(height: 12),
                    ownerRow,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة تفاصيل معمل التحاليل — مع «عدّل/احذف» لصاحب المعمل وحده (البند ٨).
class MedicalLabDetailScreen extends StatefulWidget {
  const MedicalLabDetailScreen({super.key});

  @override
  State<MedicalLabDetailScreen> createState() => _MedicalLabDetailScreenState();
}

class _MedicalLabDetailScreenState extends State<MedicalLabDetailScreen> {
  static const _purple = Color(0xFF6A1B9A);
  static const _purpleDark = Color(0xFF4A148C);

  MedicalLab? _saved;
  late final MedicalLabService _service = MedicalLabService();

  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openEdit(MedicalLab lab) async {
    final res = await showModalBottomSheet<MedicalLab>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LabFormSheet(
        userName: lab.submittedByName ?? '',
        userId: _currentUid,
        existing: lab,
      ),
    );
    if (res == null || !mounted) return;
    try {
      await _service.update(res);
      if (!mounted) return;
      setState(() => _saved = res);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ التعديلات — عاد المعمل للمراجعة')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال')));
    }
  }

  Future<bool> _deleteRecord(MedicalLab lab) async {
    try {
      await _service.delete(lab.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget? _ownerActions(MedicalLab lab) {
    final owner = lab.submittedBy ?? '';
    if (_currentUid.isEmpty || _currentUid != owner) return null;
    return OwnerActions(
      keyTag: 'lab-detail',
      ownerId: owner,
      currentUserId: _currentUid,
      itemName: lab.name,
      editLabel: 'تعديل المعمل',
      deleteLabel: 'حذف المعمل',
      onEdit: () => _openEdit(lab),
      onDelete: () => _deleteRecord(lab),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lab = _saved ??
        ModalRoute.of(context)?.settings.arguments as MedicalLab? ??
            const MedicalLab(id: '', name: '');
    final ownerRow = _ownerActions(lab);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: lab.name,
            accent: _purple,
            accentDark: _purpleDark,
            imageUrl: lab.imageUrl,
            icon: Icons.science_rounded,
            onShare: () => ShareService.shareText(
                title: '🧪 ${lab.name}',
                body: [
                  if (lab.category.isNotEmpty)
                    'نوع التحاليل: ${lab.category}',
                  if (lab.homeCollection) '✅ يتوفر سحب عينة بالمنزل',
                  if (lab.ownerName.isNotEmpty)
                    'المسؤول: ${lab.ownerName}',
                  if (lab.workingHours.isNotEmpty)
                    'المواعيد: ${lab.workingHours}',
                  if (lab.address.isNotEmpty) 'العنوان: ${lab.address}',
                  if (lab.phone.isNotEmpty) 'هاتف: ${lab.phone}',
                ].join('\n')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(lab.name,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      if (lab.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _purple.withValues(alpha: 0.3))),
                          child: Text(lab.category,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _purple)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MedSection(
                    title: 'بيانات المعمل',
                    accent: _purple,
                    child: Column(
                      children: [
                        if (lab.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'مدير المعمل',
                              value: lab.ownerName,
                              accent: _purple),
                        if (lab.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'الهاتف',
                              value: lab.phone,
                              accent: _purple),
                        if (lab.workingHours.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'مواعيد العمل',
                              value: lab.workingHours,
                              accent: _purple),
                        if (lab.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: lab.address,
                              accent: _purple),
                        MedInfoRow(
                            icon: Icons.home_work_rounded,
                            label: 'سحب العينات بالمنزل',
                            value: lab.homeCollection
                                ? 'متوفر — اتصل للترتيب'
                                : 'غير متوفر',
                            accent: _purple),
                      ],
                    ),
                  ),
                  if (lab.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن المعمل وتحاليله',
                      accent: _purple,
                      child: Text(lab.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (lab.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور المعمل',
                      accent: _purple,
                      child: ImageGalleryWrap(urls: lab.imageUrls, tileWidth: 180),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (lab.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _purple,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: lab.phone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالمعمل',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  if (ownerRow != null) ...[
                    const SizedBox(height: 12),
                    ownerRow,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
