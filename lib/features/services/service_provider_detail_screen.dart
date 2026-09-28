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
        if (mounted && c != null) setState(() => _myRating = c.rating.toDouble());
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
                        '✔ يقدّم دروساً خصوصية',
                      if (provider.description.isNotEmpty)
                        provider.description,
                      if (provider.address.isNotEmpty)
                        'العنوان: ${provider.address}',
                      if (provider.phone.isNotEmpty) 'هاتف: ${provider.phone}',
                    ].join('\n')),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _titleRow(theme, provider, accent),
                      if (provider.isEducational &&
                          provider.offersPrivateTutoring) ...[
                        const SizedBox(height: 12),
                        _privateTutoringBanner(theme),
                      ],
                      const SizedBox(height: 16),
                      MedSection(
                        title: provider.isEducational
                            ? 'بيانات التدريس'
                            : 'بيانات الخدمة',
                        accent: accent,
                        child: Column(
                          children: [
                            if (provider.isEducational) ...[
                              MedInfoRow(
                                  icon: Icons.badge_rounded,
                                  label: 'الصفة',
                                  value: provider.providerKindLabel,
                                  accent: accent),
                              if (provider.eduTypesLine.isNotEmpty)
                                MedInfoRow(
                                    icon: Icons.category_rounded,
                                    label: 'نوع التعليم',
                                    value: provider.eduTypesLine,
                                    accent: accent),
                              if (provider.stagesLine.isNotEmpty)
                                MedInfoRow(
                                    icon: Icons.school_rounded,
                                    label: 'المراحل',
                                    value: provider.stagesLine,
                                    accent: accent),
                              if (provider.subjectsLine.isNotEmpty ||
                                  provider.specialty.trim().isNotEmpty)
                                MedInfoRow(
                                    icon: Icons.menu_book_rounded,
                                    label: 'المواد',
                                    value: provider.subjectsLine.isNotEmpty
                                        ? provider.subjectsLine
                                        : provider.specialty.trim(),
                                    accent: accent),
                              if (provider.universityNote.trim().isNotEmpty)
                                MedInfoRow(
                                    icon: Icons.edit_note_rounded,
                                    label: 'التخصص الجامعي',
                                    value: provider.universityNote.trim(),
                                    accent: accent),
                              MedInfoRow(
                                  icon: Icons.cast_for_education_rounded,
                                  label: 'تدريس خاص',
                                  value: provider.offersPrivateTutoring
                                      ? 'يقدّم دروساً خصوصية'
                                      : 'غير متاح',
                                  accent: accent),
                            ] else if (provider.displaySpecialty.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.category_rounded,
                                  label: 'المجال',
                                  value: provider.displaySpecialty,
                                  accent: accent),
                            if (provider.phone.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.phone_rounded,
                                  label: 'الهاتف',
                                  value: provider.phone,
                                  accent: accent),
                            if (provider.address.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.location_on_rounded,
                                  label: 'العنوان',
                                  value: provider.address,
                                  accent: accent),
                            if (provider.submittedByName != null &&
                                provider.submittedByName!.isNotEmpty)
                              MedInfoRow(
                                  icon: Icons.person_rounded,
                                  label: 'أضافها',
                                  value: provider.submittedByName!,
                                  accent: accent),
                          ],
                        ),
                      ),
                      if (provider.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MedSection(
                          title: 'عن الخدمة',
                          accent: accent,
                          child: Text(provider.description,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(height: 1.6)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ratingSummary(theme, provider, accent),
                      const SizedBox(height: 16),
                      _myRatingCard(theme, accent),
                      const SizedBox(height: 16),
                      _commentsSection(theme, accent),
                      const SizedBox(height: 22),
                      if (provider.phone.isNotEmpty)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () => _call(provider.phone),
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('اتصال الآن',
                              style:
                                  TextStyle(fontWeight: FontWeight.w800)),
                        ),
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

  Widget _titleRow(
      ThemeData theme, ServiceProvider provider, Color accent) {
    return Row(
      children: [
        Expanded(
          child: Text(provider.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
        ),
        if (provider.isEducational)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    provider.isSchool
                        ? Icons.account_balance_rounded
                        : Icons.person_rounded,
                    size: 13,
                    color: accent),
                const SizedBox(width: 3),
                Text(provider.providerKindLabel,
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5)),
              ],
            ),
          ),
        if (provider.isFeatured)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors:
                  [Color(0xFFF1C40F), Color(0xFFB8860B)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 14),
                SizedBox(width: 3),
                Text('مميز',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  /// شريط «يقدّم دروساً خصوصية» أعلى بيانات المدرّس.
  Widget _privateTutoringBanner(ThemeData theme) {
    const teal = Color(0xFF00695C);
    return Container(
      key: const Key('edu-private-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cast_for_education_rounded, size: 19, color: teal),
          SizedBox(width: 9),
          Expanded(
            child: Text('يقدّم دروساً خصوصية',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13, color: teal)),
          ),
        ],
      ),
    );
  }

  Widget _ratingSummary(
      ThemeData theme, ServiceProvider provider, Color accent) {
    final avg = provider.ratingCount == 0
        ? 0.0
        : provider.rating;
    return MedSection(
      title: 'التقييم',
      accent: accent,
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(avg.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: accent)),
          RatingBarIndicator(
            rating: avg,
            itemSize: 22,
            unratedColor: Colors.grey.withValues(alpha: 0.3),
            itemBuilder: (_, __) =>
                const Icon(Icons.star_rounded, color: Colors.amber),
          ),
          Text('(${provider.ratingCount} تقييم)',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey)),
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
          Center(
            child: RatingBar.builder(
              initialRating: _myRating,
              minRating: 1,
              itemSize: 34,
              unratedColor: Colors.grey.withValues(alpha: 0.3),
              itemBuilder: (_, __) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (v) => setState(() => _myRating = v),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textC,
            maxLines: 3,
            maxLength: 240,
            decoration: const InputDecoration(
              hintText: 'أضف تعليقك (اختياري)...',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 13)),
            onPressed: _submitting ? null : _submitComment,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rate_review_rounded, size: 18),
            label: const Text('إرسال التقييم',
                style: TextStyle(fontWeight: FontWeight.w800)),
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
        return MedSection(
          title: 'تعليقات المستخدمين (${comments.length})',
          accent: accent,
          child: snap.connectionState == ConnectionState.waiting
              ? const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2))
              : comments.isEmpty
                  ? Text('لا توجد تعليقات بعد — كن أول المقيّمين.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey))
                  : Column(
                      children: comments
                          .map((c) => _commentTile(theme, c, accent))
                          .toList(),
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
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w900),
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
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    RatingBarIndicator(
                      rating: c.rating.toDouble(),
                      itemSize: 14,
                      unratedColor: Colors.grey.withValues(alpha: 0.25),
                      itemBuilder: (_, __) => const Icon(
                          Icons.star_rounded, color: Colors.amber),
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
