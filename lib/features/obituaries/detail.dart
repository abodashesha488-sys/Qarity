import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../services/engagement_service.dart';
import '../../services/obituary_service.dart';
import '../../services/share_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_appbar_actions.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الوفاة'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          if (_obituary != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'مشاركة',
              onPressed: () => _shareObituary(_obituary!),
            ),
          ...CommonAppBarActions.actions(context),
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
        child: _ObituaryDetailContent(obituary: obituary, onShare: _shareObituary),
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
          child: _ObituaryDetailContent(obituary: loaded, onShare: _shareObituary),
        );
      },
    );
  }
}

class _ObituaryDetailContent extends StatelessWidget {
  const _ObituaryDetailContent({
    required this.obituary,
    required this.onShare,
  });

  final Obituary obituary;
  final Future<void> Function(Obituary) onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroImage(imageUrl: obituary.imageUrl),
        const SizedBox(height: 20),
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
            if (obituary.age.isNotEmpty)
              _MetaChip(
                icon: Icons.cake_rounded,
                label: 'العمر: ${obituary.age} سنة',
                color: theme.colorScheme.primary,
              ),
            if (obituary.dateOfDeath.isNotEmpty)
              _MetaChip(
                icon: Icons.calendar_today_rounded,
                label: 'الوفاة: ${obituary.dateOfDeath}',
                color: theme.colorScheme.error,
              ),
            if (obituary.funeralDate.isNotEmpty)
              _MetaChip(
                icon: Icons.event_rounded,
                label: 'الدفن: ${obituary.funeralDate}',
                color: theme.colorScheme.tertiary,
              ),
          ],
        ),
        if (obituary.funeralLocation.isNotEmpty ||
            obituary.condolenceLocation.isNotEmpty ||
            obituary.mosque.isNotEmpty) ...[
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أماكن الدفن والعزاء',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (obituary.funeralLocation.isNotEmpty)
                  _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'مكان الصلاة',
                      value: obituary.funeralLocation),
                if (obituary.mosque.isNotEmpty)
                  _InfoRow(
                      icon: Icons.mosque_rounded,
                      label: 'المسجد',
                      value: obituary.mosque),
                if (obituary.condolenceLocation.isNotEmpty)
                  _InfoRow(
                      icon: Icons.home_rounded,
                      label: 'مكان العزاء',
                      value: obituary.condolenceLocation),
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
        if (obituary.relatives.isNotEmpty) ...[
          const SizedBox(height: 16),
          _RelativesSection(relatives: obituary.relatives),
        ],
        const SizedBox(height: 24),
        _CondolenceSection(
            obituaryId: obituary.id, obituaryName: obituary.name),
      ],
    );
  }
}

class _RelativesSection extends StatelessWidget {
  const _RelativesSection({required this.relatives});

  final List<Relative> relatives;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <RelativeType, List<Relative>>{};
    for (final r in relatives) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('أقارب المتوفى',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          ...RelativeType.values.map((type) {
            final list = grouped[type] ?? [];
            if (list.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(type.icon, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(type.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        list.map((r) => _RelativeChip(relative: r)).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RelativeChip extends StatelessWidget {
  const _RelativeChip({required this.relative});

  final Relative relative;

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
          Icon(relative.type.icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(relative.name,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
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
    final theme = Theme.of(context);
    final url = imageUrl;

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(Icons.person_rounded,
            size: 72, color: theme.colorScheme.onSurfaceVariant),
      ),
    );

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: url == null || url.isEmpty
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, _) => fallback,
                errorWidget: (context, _, __) => fallback,
              ),
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
  final EngagementService _engagement = EngagementService();
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('اكتب رسالة التعزية'), backgroundColor: Colors.orange));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _engagement.addCondolence(
        obituaryId: widget.obituaryId,
        userId: user.uid,
        userName:
            user.displayName ?? user.email?.split('@').first ?? 'مستخدم',
        message: message,
      );
      if (!mounted) return;
      _messageController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تقديم التعزية'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذر الإرسال: $e'), backgroundColor: Colors.red));
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            return SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openDialog,
                icon: const Icon(Icons.volunteer_activism_rounded),
                label: Text(
                    count > 0 ? 'تقديم التعازي ($count)' : 'تقديم التعازي',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1);
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
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('التعازي',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ...list.take(5).map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.userName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(c.message, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      ],
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