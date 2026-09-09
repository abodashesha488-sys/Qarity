import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../services/engagement_service.dart';
import '../../services/occasion_service.dart';
import '../../services/share_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_appbar_actions.dart';

class OccasionDetailScreen extends StatefulWidget {
  const OccasionDetailScreen({super.key});

  @override
  State<OccasionDetailScreen> createState() => _OccasionDetailScreenState();
}

class _OccasionDetailScreenState extends State<OccasionDetailScreen> {
  final OccasionService _service = OccasionService();

  bool _argumentsResolved = false;
  Occasion? _occasion;
  String? _occasionId;
  Future<Occasion?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsResolved) return;
    _argumentsResolved = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Occasion) {
      _occasion = args;
      _occasionId = args.id.isEmpty ? null : args.id;
    } else if (args is String && args.trim().isNotEmpty) {
      _occasionId = args.trim();
      _future = _service.getOccasionById(_occasionId!);
    }
  }

  Future<void> _refresh() async {
    final id = _occasionId;
    if (id == null) return;
    final future = _service.getOccasionById(id);
    if (!mounted) return;
    setState(() => _future = future);
    try {
      final occasion = await future;
      if (!mounted || occasion == null) return;
      setState(() => _occasion = occasion);
    } catch (_) {
      // Handled by the future builder error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المناسبة'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          if (_occasion != null)
            IconButton(
              tooltip: 'مشاركة الدعوة',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => ShareService.shareOccasionAsImage(context, _occasion!),
            ),
          ...CommonAppBarActions.actions(context),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final occasion = _occasion;
    if (occasion != null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: _OccasionDetailContent(occasion: occasion),
      );
    }

    final future = _future;
    if (future == null) {
      return const _CenteredStateView(
        child: EmptyContentState(
          icon: Icons.card_giftcard_rounded,
          message: 'لا توجد بيانات لعرضها',
        ),
      );
    }

    return FutureBuilder<Occasion?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CenteredStateView(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _CenteredStateView(
            child: _ErrorStateView(message: 'تعذر تحميل التفاصيل', onRetry: _refresh),
          );
        }
        final loaded = snapshot.data;
        if (loaded == null) {
          return const _CenteredStateView(
            child: EmptyContentState(
              icon: Icons.card_giftcard_rounded,
              message: 'لم يتم العثور على هذه المناسبة',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: _OccasionDetailContent(occasion: loaded),
        );
      },
    );
  }
}

class _OccasionDetailContent extends StatelessWidget {
  const _OccasionDetailContent({required this.occasion});

  final Occasion occasion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final organizer = occasion.organizer;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroImage(imageUrl: occasion.imageUrl, fallbackIcon: Icons.celebration_rounded),
        const SizedBox(height: 20),
        Text(
          occasion.title,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _CountdownBanner(occasion: occasion),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (occasion.date.isNotEmpty)
              _MetaChip(
                icon: Icons.calendar_today_rounded,
                label: occasion.date,
                color: theme.colorScheme.primary,
              ),
            _AttendeesCountChip(occasionId: occasion.id),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل المناسبة',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (occasion.date.isNotEmpty)
                _InfoRow(icon: Icons.calendar_today_rounded, label: 'التاريخ', value: occasion.date),
              if (occasion.location.isNotEmpty)
                _InfoRow(icon: Icons.location_on_rounded, label: 'المكان', value: occasion.location),
              if (organizer != null && organizer.isNotEmpty)
                _InfoRow(icon: Icons.person_rounded, label: 'المنظم', value: organizer),
            ],
          ),
        ),
        if (occasion.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الوصف',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  occasion.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _AttendanceSection(occasionId: occasion.id, occasionTitle: occasion.title),
      ],
    );
  }
}

class _AttendanceSection extends StatefulWidget {
  const _AttendanceSection({required this.occasionId, required this.occasionTitle});

  final String occasionId;
  final String occasionTitle;

  @override
  State<_AttendanceSection> createState() => _AttendanceSectionState();
}

class _AttendanceSectionState extends State<_AttendanceSection> {
  final EngagementService _engagement = EngagementService();

  Future<void> _toggle(bool attending) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً'), backgroundColor: Colors.red),
      );
      return;
    }
    final name = user.displayName ?? user.email?.split('@').first ?? 'مستخدم';
    try {
      if (attending) {
        await _engagement.cancelAttendance(occasionId: widget.occasionId, userId: user.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء المشاركة'), backgroundColor: Colors.orange),
        );
      } else {
        await _engagement.attendOccasion(
          occasionId: widget.occasionId,
          userId: user.uid,
          userName: name,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل مشاركتك'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التنفيذ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد المشاركة'),
        content: Text('هل تود المشاركة في "${widget.occasionTitle}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toggle(false);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    return StreamBuilder<int>(
      stream: _engagement.attendeesCount(widget.occasionId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return StreamBuilder<bool>(
          stream: userId.isNotEmpty
              ? _engagement.isAttending(widget.occasionId, userId)
              : Stream.value(false),
          builder: (context, attSnap) {
            final attending = attSnap.data ?? false;
            return DetailActionButton(
              icon: attending ? Icons.check_circle_rounded : Icons.event_available_rounded,
              label: attending ? 'إلغاء المشاركة ($count)' : 'المشاركة بالحفل ($count)',
              onPressed: attending ? () => _toggle(true) : _confirm,
            );
          },
        );
      },
    );
  }
}

class _AttendeesCountChip extends StatelessWidget {
  const _AttendeesCountChip({required this.occasionId});

  final String occasionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<int>(
      stream: EngagementService().attendeesCount(occasionId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _MetaChip(
          icon: Icons.groups_rounded,
          label: '$count مشارك',
          color: theme.colorScheme.secondary,
        );
      },
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.occasion});

  final Occasion occasion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = occasion.date;
    final date = raw.isEmpty ? null : DateTime.tryParse(raw.replaceAll('/', '-'));
    if (date == null) return const SizedBox.shrink();
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _banner(theme, 'انتهت هذه المناسبة', Colors.grey),
      );
    }
    final days = diff.inDays;
    final label = days == 0
        ? 'المناسبة اليوم 🎉'
        : days == 1
            ? 'غداً بإذن الله • يوم واحد'
            : 'بعد $days يوم من الآن';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _banner(theme, label, theme.colorScheme.primary),
    );
  }

  Widget _banner(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.fallbackIcon, this.imageUrl});

  final String? imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl;

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(fallbackIcon, size: 72, color: theme.colorScheme.primary),
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
                placeholder: (context, url) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => fallback,
              ),
            ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});

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
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

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
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Keeps loading/empty/error states scrollable so pull-to-refresh keeps working.
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
          child: Icon(Icons.wifi_off_rounded, size: 44, color: theme.colorScheme.error),
        ),
        const SizedBox(height: 20),
        Text(message, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'تحقق من اتصالك بالإنترنت ثم أعد المحاولة',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
