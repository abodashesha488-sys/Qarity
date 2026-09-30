import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/service_provider_model.dart';
import '../../services/service_provider_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/edu_kind_mark.dart';
import '../medical/clinic_detail_screen.dart';

/// شاشة تفاصيل بيان في دليل الخدمات — عرض منسق + تقييم 5 نجوم + تعليقات.
class ServiceProviderDetailScreen extends StatefulWidget {
  const ServiceProviderDetailScreen({super.key, this.provider, this.service});

  final ServiceProvider? provider;
  final ServiceProviderService? service;

  @override
  State<ServiceProviderDetailScreen> createState() =>
      _ServiceProviderDetailScreenState();
}

class _ServiceProviderDetailScreenState
    extends State<ServiceProviderDetailScreen> {
  late final ServiceProviderService _service =
      widget.service ?? ServiceProviderService();
  final TextEditingController _textC = TextEditingController();

  ServiceProvider? _resolved;
  bool _bootstrapped = false;
  double _myRating = 0;
  bool _submitting = false;
  bool _descExpanded = false;
  bool _allComments = false;

  static const _fallbackProvider =
      ServiceProvider(id: '', category: 'technicians', name: 'خدمة');

  ServiceProvider get _initial => _resolved ?? _fallbackProvider;

  @override
  void dispose() {
    _textC.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    // قراءة المعطيات من الـroute هنا وليست في initState — السياق آمن الآن.
    _resolved = widget.provider ??
        (ModalRoute.of(context)?.settings.arguments as ServiceProvider?) ??
        _fallbackProvider;
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    if (uid != null && _initial.id.isNotEmpty) {
      _service.getUserComment(_initial.id, uid).then((c) {
        if (mounted && c != null) {
          setState(() => _myRating = c.rating.toDouble());
        }
      }).catchError((_) {});
    }
  }

  Future<void> _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('سجّل الدخول أولاً للتقييم', error: true);
      return;
    }
    if (_myRating < 1) {
      _snack('اختر عدد النجوم أولاً', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final identity = await UserService().resolveAuthor();
      await _service.addComment(ServiceProviderComment(
        id: '',
        providerId: _initial.id,
        userId: user.uid,
        userName: identity.name,
        photoUrl: identity.photo,
        rating: _myRating.round(),
        text: _textC.text.trim(),
      ));
      _textC.clear();
      _snack('شكراً لتقييمك وتعليقك');
    } catch (e) {
      _snack('خطأ: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : const Color(0xFF6F4E37),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<ServiceProvider?>(
      stream: _initial.id.isEmpty
          ? Stream<ServiceProvider?>.value(null)
          : _service.watchProvider(_initial.id),
      builder: (context, snap) {
        final provider = snap.data ?? _initial;
        final accent = provider.isFeatured
            ? const Color(0xFFB8860B)
            : ServiceCategory.color(provider.category);
        final imageUrl = provider.photoUrl ?? '';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              MedDetailHeader(
                title: provider.name,
                accent: accent,
                accentDark: Color.alphaBlend(
                    Colors.black.withValues(alpha: 0.25), accent),
                imageUrl: imageUrl,
                icon: ServiceCategory.icon(provider.category),
                onShare: () => ShareService.shareText(
                    title: provider.isEducational
                        ? '🎓 ${provider.name}'
                        : '🛠️ ${provider.name}',
                    body: [
                      if (provider.isEducational &&
                          provider.providerKindLabel.isNotEmpty)
                        'الصفة: ${provider.providerKindLabel}',
                      if (provider.displaySpecialty.isNotEmpty)
                        provider.isEducational
                            ? 'المواد: ${provider.displaySpecialty}'
                            : 'التخصص: ${provider.displaySpecialty}',
                      if (provider.isEducational &&
                          provider.stagesLine.isNotEmpty)
                        'المراحل: ${provider.stagesLine}',
                      if (provider.isEducational &&
                          provider.eduTypesLine.isNotEmpty)
                        'نوع التعليم: ${provider.eduTypesLine}',
                      if (provider.isEducational &&
                          provider.universityNote.trim().isNotEmpty)
                        'التخصص الجامعي: ${provider.universityNote.trim()}',
                      if (provider.isEducational &&
                          provider.offersPrivateTutoring)
                        'امكانية تدريس خاص ✓',
                      if (provider.description.isNotEmpty) provider.description,
                      if (provider.address.isNotEmpty)
                        'العنوان: ${provider.address}',
                      if (provider.phone.isNotEmpty) 'هاتف: ${provider.phone}',
                    ].join('\n')),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _identityCard(theme, provider, accent),
                      if (provider.isEducational) ...[
                        const SizedBox(height: 10),
                        _teachingCard(theme, provider, accent),
                      ],
                      if (provider.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _aboutCard(theme, provider, accent),
                      ],
                      const SizedBox(height: 10),
                      _contactCard(theme, provider, accent),
                      const SizedBox(height: 10),
                      _myRatingCard(theme, accent),
                      const SizedBox(height: 10),
                      _commentsSection(theme, accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _cardDeco(ThemeData theme, Color accent) => BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      );

  /// بطاقة مدمجة: الصورة والاسم والصفة والتقييم وشارات الوسوم في كتلة واحدة.
  Widget _identityCard(
      ThemeData theme, ServiceProvider provider, Color accent) {
    final avg = provider.ratingCount == 0 ? 0.0 : provider.rating;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(theme, accent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photo(theme, provider, accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900, height: 1.25)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (provider.isEducational) _kindChip(provider, accent),
                    if (provider.isFeatured) _featuredChip(),
                    if (provider.isEducational &&
                        provider.offersPrivateTutoring)
                      _pill('امكانية تدريس خاص ✓', kEduPrivateTagColor,
                          key: const Key('edu-private-banner'), filled: true),
                    _ratingPill(avg, provider.ratingCount, accent),
                  ],
                ),
                if (!provider.isEducational &&
                    provider.displaySpecialty.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(provider.displaySpecialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _kPhotoSide = 68;

  Widget _photo(ThemeData theme, ServiceProvider provider, Color accent) {
    final url = provider.photoUrl ?? '';
    // الصورة الافتراضية للسجل التعليمي = صورة الصفة (mal / femal) ملء الإطار،
    // وتُستعمل أيضًا حين يفسد رابط الصورة المرفوعة.
    Widget fallback() => provider.isEducational
        ? EduKindMark(
            kind: provider.providerKind, size: _kPhotoSide, radius: 14)
        : ColoredBox(
            color: accent.withValues(alpha: 0.12),
            child: Center(
                child: Icon(ServiceCategory.icon(provider.category),
                    size: 30, color: accent)),
          );
    final inner = url.isEmpty
        ? fallback()
        : CachedNetworkImage(
            imageUrl: url,
            memCacheWidth: (_kPhotoSide * 3).ceil(),
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                ColoredBox(color: accent.withValues(alpha: 0.12)),
            errorWidget: (_, __, ___) => fallback(),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: _kPhotoSide, height: _kPhotoSide, child: inner),
    );
  }

  Widget _kindChip(ServiceProvider provider, Color accent) {
    return _pill(provider.providerKindLabel, accent,
        mark: provider.providerKind);
  }

  Widget _featuredChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF1C40F), Color(0xFFB8860B)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 12),
          SizedBox(width: 3),
          Text('مميز',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _ratingPill(double avg, int count, Color accent) {
    return _pill(
        count == 0 ? 'بلا تقييم' : '${avg.toStringAsFixed(1)} ★ ($count)',
        accent,
        icon: Icons.star_rounded);
  }

  Widget _pill(String text, Color color,
      {Key? key, IconData? icon, String? mark, bool filled = false}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: filled ? 1 : 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null) ...[
            EduKindMark(kind: mark, size: 12),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  /// سطر واحد: تسمية صغيرة ثم وسوم القيم تلتفّ أسطرًا عند الضيق.
  Widget _factLine(
      ThemeData theme, String label, List<String> values, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$label:',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurfaceVariant)),
          for (final v in values) _pill(v, color),
        ],
      ),
    );
  }

  /// بيانات التدريس في كتلة واحدة مضغوطة بدل صفوف طويلة.
  Widget _teachingCard(
      ThemeData theme, ServiceProvider provider, Color accent) {
    final subjects = provider.subjects.isNotEmpty
        ? provider.subjects
        : (provider.specialty.trim().isEmpty
            ? const <String>[]
            : provider.specialty
                .split(RegExp(r'[،,]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList());
    final university = provider.universityNote.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
      decoration: _cardDeco(theme, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات التدريس',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(height: 8),
          if (provider.eduTypesLine.isNotEmpty)
            _factLine(theme, 'النوع', provider.eduTypes, accent),
          if (provider.stageChips.isNotEmpty)
            _factLine(theme, 'المراحل', provider.stageChips, accent),
          if (subjects.isNotEmpty) _factLine(theme, 'المواد', subjects, accent),
          if (university.isNotEmpty)
            _factLine(theme, 'جامعي', [university], accent),
        ],
      ),
    );
  }

  /// نبذة قابلة للطي حتى لا تغطي الشاشة على حساب بقية البيانات.
  Widget _aboutCard(ThemeData theme, ServiceProvider provider, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(theme, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('عن الخدمة',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(height: 6),
          Text(provider.description,
              maxLines: _descExpanded ? null : 3,
              overflow: _descExpanded ? null : TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.55)),
          if (provider.description.length > 120)
            TextButton(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(_descExpanded ? 'أقل' : 'المزيد',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  /// بيانات التواصل: أسطر مدمجة + زر اتصال أخضر صغير.
  Widget _contactCard(ThemeData theme, ServiceProvider provider, Color accent) {
    final by = provider.submittedByName ?? '';
    final hasLines = provider.phone.isNotEmpty ||
        provider.address.isNotEmpty ||
        by.isNotEmpty;
    if (!hasLines) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _cardDeco(theme, accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.address.isNotEmpty)
            _inlineLine(
                theme, Icons.location_on_rounded, provider.address, accent),
          if (by.isNotEmpty)
            _inlineLine(theme, Icons.person_rounded, 'أضافها: $by', accent),
          if (provider.phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                key: const Key('detail-call'),
                style: FilledButton.styleFrom(
                    backgroundColor: kCallButtonColor,
                    padding: const EdgeInsets.symmetric(horizontal: 18)),
                onPressed: () => _call(provider.phone),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text('اتصال الآن — ${provider.phone}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inlineLine(
      ThemeData theme, IconData icon, String value, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _myRatingCard(ThemeData theme, Color accent) {
    return MedSection(
      title: 'قيّم هذه الخدمة',
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RatingBar.builder(
              initialRating: _myRating,
              minRating: 1,
              itemSize: 28,
              unratedColor: Colors.grey.withValues(alpha: 0.3),
              itemBuilder: (_, __) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (v) => setState(() => _myRating = v),
            ),
          ),
          TextField(
            controller: _textC,
            maxLines: 2,
            maxLength: 240,
            style: theme.textTheme.bodySmall,
            decoration: const InputDecoration(
              hintText: 'أضف تعليقك (اختياري)...',
              counterText: '',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 42,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 18)),
              onPressed: _submitting ? null : _submitComment,
              icon: _submitting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.rate_review_rounded, size: 17),
              label: const Text('إرسال التقييم',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentsSection(ThemeData theme, Color accent) {
    return StreamBuilder<List<ServiceProviderComment>>(
      stream: _initial.id.isEmpty
          ? Stream<List<ServiceProviderComment>>.value(const [])
          : _service.getCommentsStream(_initial.id),
      builder: (context, snap) {
        final comments = snap.data ?? [];
        final visible = _allComments || comments.length <= 2
            ? comments
            : comments.take(2).toList();
        return MedSection(
          title: 'تعليقات المستخدمين (${comments.length})',
          accent: accent,
          child: snap.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : comments.isEmpty
                  ? Text('لا توجد تعليقات بعد — كن أول المقيّمين.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey))
                  : Column(
                      children: [
                        ...visible.map((c) => _commentTile(theme, c, accent)),
                        if (visible.length < comments.length)
                          TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            onPressed: () =>
                                setState(() => _allComments = true),
                            child: Text('عرض كل التعليقات (${comments.length})',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _commentTile(ThemeData theme, ServiceProviderComment c, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: accent.withValues(alpha: 0.12),
            foregroundImage: c.photoUrl != null && c.photoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(c.photoUrl!)
                : null,
            child: Text(
              c.photoUrl != null && c.photoUrl!.isNotEmpty
                  ? ''
                  : (c.userName.isNotEmpty ? c.userName.substring(0, 1) : '؟'),
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    RatingBarIndicator(
                      rating: c.rating.toDouble(),
                      itemSize: 14,
                      unratedColor: Colors.grey.withValues(alpha: 0.25),
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star_rounded, color: Colors.amber),
                    ),
                  ],
                ),
                if (c.text.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(c.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
