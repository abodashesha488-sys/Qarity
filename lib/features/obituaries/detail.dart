import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/comment_style.dart';
import '../../core/utils/obituary_card_assets.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../services/engagement_service.dart';
import '../../services/obituary_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/full_fit_image.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import 'add.dart';

class ObituaryDetailScreen extends StatefulWidget {
  const ObituaryDetailScreen({super.key});

  @override
  State<ObituaryDetailScreen> createState() => _ObituaryDetailScreenState();
}

class _ObituaryDetailScreenState extends State<ObituaryDetailScreen> {
  final ObituaryService _service = ObituaryService();

  bool _argumentsResolved = false;
  Obituary? _obituary;
  String? _obituaryId;
  Future<Obituary?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsResolved) return;
    _argumentsResolved = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Obituary) {
      _obituary = args;
      _obituaryId = args.id.isEmpty ? null : args.id;
    } else if (args is String && args.trim().isNotEmpty) {
      _obituaryId = args.trim();
      _future = _service.getObituaryById(_obituaryId!);
    }
  }

  Future<void> _refresh() async {
    final id = _obituaryId;
    if (id == null) return;
    final future = _service.getObituaryById(id);
    if (!mounted) return;
    setState(() => _future = future);
    try {
      final obituary = await future;
      if (!mounted || obituary == null) return;
      setState(() => _obituary = obituary);
    } catch (_) {}
  }

  Future<void> _shareObituary(Obituary obituary) async {
    await ShareService.shareObituaryAsImage(context, obituary);
  }

  String _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// تعديل صاحب نعوتته: نفس نموذج الإضافة بـ`existing`. النجاح يُغلق الصفحة لأن
  /// السجل عاد إلى المراجعة فلم يعد هنا ما يُعرض.
  Future<void> _openEdit(Obituary obituary) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => AddObituaryScreen(existing: obituary)));
    if (saved == true && mounted) Navigator.pop(context);
  }

  Future<bool> _delete(Obituary obituary) async {
    try {
      await _service.deleteObituary(obituary.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// صف «تعديل/حذف» لصاحب النعوة فقط — الإدارة تراجع من لوحة التحكم، لأن
  /// قواعد البند ٨ تسمح بتعديل المالك لسجله العائد إلى المراجعة وحده.
  Widget? _ownerActions(Obituary obituary) {
    final uid = _currentUid();
    final owner = obituary.submittedBy ?? '';
    if (uid.isEmpty || uid != owner) return null;
    return OwnerActions(
      keyTag: 'obituary-detail',
      ownerId: owner,
      currentUserId: uid,
      itemName: obituary.name,
      editLabel: 'تعديل النعوة',
      deleteLabel: 'حذف النعوة',
      onEdit: () => _openEdit(obituary),
      onDelete: () => _delete(obituary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(
        title: 'تفاصيل الوفاة',
        actions: [
          if (_obituary != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'مشاركة',
              onPressed: () => _shareObituary(_obituary!),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final obituary = _obituary;
    if (obituary != null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: _ObituaryDetailContent(
            obituary: obituary,
            onShare: _shareObituary,
            ownerActions: _ownerActions(obituary)),
      );
    }

    final future = _future;
    if (future == null) {
      return const _CenteredStateView(
        child: EmptyContentState(
          icon: Icons.grade_rounded,
          message: 'لا توجد بيانات لعرضها',
        ),
      );
    }

    return FutureBuilder<Obituary?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CenteredStateView(
              child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _CenteredStateView(
            child:
                _ErrorStateView(message: 'تعذر تحميل التفاصيل', onRetry: _refresh),
          );
        }
        final loaded = snapshot.data;
        if (loaded == null) {
          return const _CenteredStateView(
            child: EmptyContentState(
              icon: Icons.grade_rounded,
              message: 'لم يتم العثور على هذه التعزية',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: _ObituaryDetailContent(
              obituary: loaded,
              onShare: _shareObituary,
              ownerActions: _ownerActions(loaded)),
        );
      },
    );
  }
}

class _ObituaryDetailContent extends StatelessWidget {
  const _ObituaryDetailContent({
    required this.obituary,
    required this.onShare,
    this.ownerActions,
  });

  final Obituary obituary;
  final Future<void> Function(Obituary) onShare;

  /// صفا تعديل المالك وحذفه — تبنيهما الشاشة الأم بحسب الجلسة.
  final Widget? ownerActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroImage(imageUrl: obituary.imageUrl),
        const SizedBox(height: 20),
        Text(
          obituary.transitionPhrase,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                obituary.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'مشاركة',
              onPressed: () => onShare(obituary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // نوع المتوفى لا يُعرض في نتيجة الإدخال: قيمته نحوية وحدها
            // (تسميات المجموعات و«انتقل/انتقلت»)، والنموذج يسأل عنه هناك.
            if (obituary.dateOfDeath.isNotEmpty)
              _MetaChip(
                icon: Icons.calendar_today_rounded,
                label: 'الوفاة: ${obituary.dateOfDeath}',
                color: theme.colorScheme.error,
              ),
            if (obituary.funeralDate.isNotEmpty)
              _MetaChip(
                icon: Icons.event_rounded,
                label: 'صلاة الجنازة: ${obituary.funeralDate}',
                color: theme.colorScheme.tertiary,
              ),
            // السجلات القديمة فقط هي من يحمل عمرًا؛ النموذج الجديد لا يسأل عنه
            if (obituary.age.isNotEmpty)
              _MetaChip(
                icon: Icons.cake_rounded,
                label: 'العمر: ${obituary.age} سنة',
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
        if (obituary.funeralLocation.isNotEmpty ||
            obituary.funeralTime.isNotEmpty ||
            obituary.funeralPrayer.isNotEmpty ||
            obituary.burialLocation.isNotEmpty ||
            obituary.mosque.isNotEmpty ||
            obituary.condolenceLocation.isNotEmpty ||
            obituary.condolenceTime.isNotEmpty ||
            obituary.condolencePrayer.isNotEmpty) ...[
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مكان الصلاة والدفن والعزاء',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (obituary.funeralLocation.isNotEmpty)
                  _InfoRow(
                      icon: Icons.mosque_rounded,
                      label: 'مكان صلاة الجنازة',
                      value: obituary.funeralLocation),
                if (obituary.funeralTime.isNotEmpty ||
                    obituary.funeralPrayer.isNotEmpty)
                  _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'موعد صلاة الجنازة',
                      value: obituaryTimeWithPrayer(
                          obituary.funeralTime, obituary.funeralPrayer)),
                if (obituary.burialLocation.isNotEmpty)
                  _InfoRow(
                      icon: Icons.terrain_rounded,
                      label: 'مكان الدفن',
                      value: obituary.burialLocation),
                // السجلات القديمة كانت تسأل عن المسجد وحده، فلا مكان دفن لها
                if (obituary.burialLocation.isEmpty &&
                    obituary.mosque.isNotEmpty)
                  _InfoRow(
                      icon: Icons.mosque_rounded,
                      label: 'المسجد',
                      value: obituary.mosque),
                if (obituary.condolenceLocation.isNotEmpty)
                  _InfoRow(
                      icon: Icons.home_rounded,
                      label: 'مكان العزاء',
                      value: obituary.condolenceLocation),
                if (obituary.condolenceTime.isNotEmpty ||
                    obituary.condolencePrayer.isNotEmpty)
                  _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'موعد العزاء',
                      value: obituaryTimeWithPrayer(
                          obituary.condolenceTime,
                          obituary.condolencePrayer)),
              ],
            ),
          ),
        ],
        if (obituary.description != null &&
            obituary.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نبذة',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(obituary.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
              ],
            ),
          ),
        ],
        if (obituary.hasRelatives) ...[
          const SizedBox(height: 16),
          _RelativesSection(obituary: obituary),
        ],
        const SizedBox(height: 24),
        _CondolenceSection(
            obituaryId: obituary.id, obituaryName: obituary.name),
        if (ownerActions != null) ...[
          const SizedBox(height: 20),
          ownerActions!,
        ],
      ],
    );
  }
}

/// مجموعات القرابة بعناوينها المصروفة بحسب نوع المتوفى، بالمجموعات التي لها
/// أسماء فقط (بما فيها تسميات السجلات القديمة).
class _RelativesSection extends StatelessWidget {
  const _RelativesSection({required this.obituary});

  final Obituary obituary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = obituary.relativeSections;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    obituary.isFemale ? 'قريبات المتوفاة' : 'أقارب المتوفى',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(section.group.icon,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(section.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in section.names)
                        _RelativeChip(group: section.group, name: name),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RelativeChip extends StatelessWidget {
  const _RelativeChip({required this.group, required this.name});

  final RelativeType group;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(group.icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(name,
                style:
                    theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();

    // بلا صورة — أو عند فشل تحميل رابطها — تظهر صورة العزاء الافتراضية azaa 0
    final fallback = Image.asset(
      kObituaryDeceasedFallbackAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 1170,
      errorBuilder: (context, _, __) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.person_rounded,
            size: 72, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );

    // الصورة كاملة في مساحتها: الارتفاع يُقاس من نسبة الصورة الحقيقية
    // (FullFitImage) فلا تُقتطع أطراف وجه المتوفى ولا ذيل المشهد.
    return LayoutBuilder(
      builder: (context, constraints) => FullFitImage(
        imageUrl: url,
        width: constraints.maxWidth,
        radius: 20,
        minRatio: 0.6,
        maxRatio: 1.6,
        fallback: fallback,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text('$label: ',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Expanded(
              child: Text(value,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _CondolenceSection extends StatefulWidget {
  const _CondolenceSection(
      {required this.obituaryId, required this.obituaryName});

  final String obituaryId;
  final String obituaryName;

  @override
  State<_CondolenceSection> createState() => _CondolenceSectionState();
}

class _CondolenceSectionState extends State<_CondolenceSection> {
  static const int _kPreviewCount = 20;

  final EngagementService _engagement = EngagementService();
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;
  bool _showAll = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      // أرضيات الشريط لون ثابت في السمتين بينما حبره الافتراضي يُقرأ من
      // `onInverseSurface` وهو في الداكن داكن ⇒ الحبر يُثبَّت. والعنبري وحده
      // لا يُقرأ عليه البياض (2.16) فحبره الداكن الزمردي (5.99).
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('اكتب رسالة التعزية',
              style: TextStyle(color: AppColors.onWarning)),
          backgroundColor: AppColors.warning));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error));
      return;
    }
    setState(() => _submitting = true);
    try {
      final identity = await UserService().resolveAuthor();
      if (await _engagement.hasCondolenced(widget.obituaryId, user.uid)) {
        if (!mounted) return;
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('لقد قدّمت تعازيك بالفعل لهذا الفقيد — جزاك الله خيراً')));
        return;
      }
      await _engagement.addCondolence(
        obituaryId: widget.obituaryId,
        userId: user.uid,
        userName: identity.name,
        photoUrl: identity.photo,
        message: message,
      );
      if (!mounted) return;
      _messageController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('تم تقديم التعزية',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذر الإرسال: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تقديم التعازي'),
        content: TextField(
          controller: _messageController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'رسالتك إلى أهل المتوفى ${widget.obituaryName}',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<int>(
          stream: _engagement.condolencesCount(widget.obituaryId),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            final uid = FirebaseAuth.instance.currentUser?.uid;
            return StreamBuilder<bool>(
              stream: uid == null
                  ? Stream<bool>.value(false)
                  : _engagement.condoledenceStream(widget.obituaryId, uid),
              builder: (context, doneSnap) {
                final done = doneSnap.data ?? false;
                return SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: done ? null : _openDialog,
                    icon: Icon(done
                        ? Icons.check_circle_rounded
                        : Icons.volunteer_activism_rounded),
                    // بلا لون مخصص من الثيم: النص يرث foregroundColor (أبيض)
                    label: Text(
                      done
                          ? 'لقد قدّمت تعازيك'
                          : (count > 0 ? 'تقديم التعازي ($count)' : 'تقديم التعازي'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: done
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.primary,
                      foregroundColor: done
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1);
              },
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Condolence>>(
          stream: _engagement.condolences(widget.obituaryId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) return const SizedBox.shrink();
            // الأحدث أولًا في القائمة، والترقيم تسلسلي بتاريخ التقديم:
            // أول من عزّى هو «١» وأحدثهم يحمل رقم الإجمالي.
            final total = list.length;
            final visible = _showAll || total <= _kPreviewCount
                ? list
                : list.sublist(0, _kPreviewCount);
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('التعازي',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        key: const Key('condolence-total'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'الإجمالي: $total تعزية',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < visible.length; i++)
                    _CondolenceTile(number: total - i, condolence: visible[i]),
                  if (total > _kPreviewCount) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        key: const Key('condolence-toggle'),
                        onPressed: () => setState(() => _showAll = !_showAll),
                        child: Text(_showAll
                            ? 'إخفاء الباقي'
                            : 'عرض كل التعازي ($total)'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// تعزية واحدة مرقّمة بترتيب تقديمها مع تاريخها النسبي.
class _CondolenceTile extends StatelessWidget {
  const _CondolenceTile({required this.number, required this.condolence});

  final int number;
  final Condolence condolence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = condolence;
    final time = relativeTimeLabelAr(c.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: Key('condolence-number-$number'),
            constraints: const BoxConstraints(minWidth: 24),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$number',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: CommentStyle.avatarRadius,
            backgroundColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            backgroundImage:
                (c.photoUrl ?? '').isNotEmpty ? CachedNetworkImageProvider(c.photoUrl!) : null,
            child: (c.photoUrl ?? '').isEmpty
                ? Icon(Icons.person_rounded,
                    size: 20, color: theme.colorScheme.primary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.userName, style: CommentStyle.author(context))),
                    if (time.isNotEmpty)
                      Text(time,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(c.message, style: CommentStyle.body(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredStateView extends StatelessWidget {
  const _CenteredStateView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    );
  }
}

class _ErrorStateView extends StatelessWidget {
  const _ErrorStateView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.wifi_off_rounded,
              size: 44, color: theme.colorScheme.error),
        ),
        const SizedBox(height: 20),
        Text(message,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'تحقق من اتصالك بالإنترنت ثم أعد المحاولة',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }
}