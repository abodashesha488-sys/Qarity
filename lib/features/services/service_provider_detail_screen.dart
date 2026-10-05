import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/comment_style.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/launch_link.dart';
import '../../models/service_provider_model.dart';
import '../../services/service_provider_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/edu_kind_mark.dart';
import '../../widgets/full_fit_image.dart';
import '../../widgets/owner_actions.dart';
import '../medical/clinic_detail_screen.dart';
import 'service_directory_screen.dart';

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

  /// صاحب التعليق نفسه أو الأدمن/الأدمن المساعد فقط يحذف.
  String _currentUid = '';
  bool _canModerate = false;

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
    if (uid != null) {
      _currentUid = uid;
      _loadModerationRole(uid);
    }
    if (uid != null && _initial.id.isNotEmpty) {
      _service.getUserComment(_initial.id, uid).then((c) {
        if (mounted && c != null) {
          setState(() => _myRating = c.rating.toDouble());
        }
      }).catchError((_) {});
    }
  }

  /// الأدمن العام/الأدمن المساعد يحذفان أي تعليق — تُقرأ الرتبة من ملفه.
  Future<void> _loadModerationRole(String uid) async {
    try {
      final model = await UserService().getUser(uid);
      if (mounted) setState(() => _canModerate = model?.isAdmin ?? false);
    } catch (_) {
      // بلا Firebase (اختبارات واجهة) أو بلا شبكة: لا صلاحيات إشرافية.
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

  /// حذف تعليق بعد تأكيد — يعيد حساب تقييم السجل ذرّيًا داخل الخدمة.
  Future<void> _deleteComment(ServiceProviderComment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: Text(c.text.isEmpty
            ? 'هل أنت متأكد من حذف هذا التعليق؟'
            : 'هل أنت متأكد من حذف التعليق: "${c.text}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteComment(_initial.id, c.id, c.rating);
      _snack('تم حذف التعليق');
    } catch (_) {
      _snack('تعذّر حذف التعليق — تحقق من الصلاحيات', error: true);
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

  /// تعديل صاحب السجل: نفس ورقة الإضافة بـ`existing`، والحفظ يمرّ بـ`update`
  /// الذي يفرض العودة إلى المراجعة ولا يمسّ النسبة.
  Future<void> _openEdit(ServiceProvider provider) async {
    String authorName = '';
    try {
      authorName = (await UserService().resolveAuthor()).name;
    } catch (_) {
      // بلا جلسة (اختبارات) يبقى الاسم كما هو في السجل.
    }
    if (!mounted) return;
    final res = await showModalBottomSheet<ServiceProvider>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ProviderFormSheet(
        category: provider.category,
        userId: _currentUid,
        userName: authorName.isEmpty ? (provider.submittedByName ?? '') : authorName,
        existing: provider,
      ),
    );
    if (res == null) return;
    try {
      await _service.update(res);
      _snack('تم حفظ التعديلات — عاد السجل إلى المراجعة');
    } catch (e) {
      _snack('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال', error: true);
    }
  }

  Future<bool> _deleteRecord(ServiceProvider provider) async {
    try {
      await _service.delete(provider.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// صفا «تعديل/حذف» لصاحب السجل فقط — الإدارة تعدّل وتميّز من لوحة التحكم،
  /// لأن قواعد البند ٨ تجيز تعديل المالك لسجله وحده.
  Widget? _ownerActions(ServiceProvider provider) {
    final owner = provider.submittedBy ?? '';
    if (_currentUid.isEmpty || _currentUid != owner) return null;
    return OwnerActions(
      keyTag: 'provider-detail',
      ownerId: owner,
      currentUserId: _currentUid,
      itemName: provider.name,
      editLabel: 'تعديل السجل',
      deleteLabel: 'حذف السجل',
      onEdit: () => _openEdit(provider),
      onDelete: () => _deleteRecord(provider),
    );
  }

  /// بلا بوّابة `canLaunchUrl`: كانت ترجع false على أندرويد 11+ حين لا تُرى حزمة
  /// الطلب، فيصمت زر الاتصال؛ التجربة المباشرة هي الدليل والفشل يُبلَّغ.
  Future<void> _call(String phone) async {
    final error = await launchPhoneCall(phone);
    if (error != null) AppHelpers.showToast(error, isError: true);
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
        final ownerRow = _ownerActions(provider);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              MedDetailHeader(
                title: provider.name,
                accent: accent,
                accentDark: Color.alphaBlend(
                    Colors.black.withValues(alpha: 0.25), accent),
                // الهيدر هنا بلا بانر مصوَّر: صورة السجل تُرسم كاملة أسفلَه
                // (`_heroPhoto`)، فـ`MedDetailHeader` يقصّ بـ`cover` ولا يصلح
                // لسجلٍ صورته عمودية أو ممتدة.
                imageUrl: '',
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
              _heroPhoto(context, accent, imageUrl),
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
                      if (ownerRow != null) ...[
                        const SizedBox(height: 10),
                        ownerRow,
                      ],
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

  /// صورة السجل كاملة أسفل الهيدر: ارتفاعها من نسبتها الحقيقية فبلا اقتصاص
  /// (كان `MedDetailHeader` يقصّها بـ`cover` في شريط 210 ثابتًا).
  Widget _heroPhoto(BuildContext context, Color accent, String imageUrl) {
    if (imageUrl.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final available = MediaQuery.sizeOf(context).width - 44;
    final side = available < 320 ? available : 320.0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Center(
            child: FullFitImage(
              key: const Key('detail-hero-photo'),
              imageUrl: imageUrl,
              width: side,
              radius: 14,
              // الصور الممتدة (لافتات/لوحات) تُرى كاملة بشريط أقصر بدل إطار
              // مربّع يترك فراغًا كبيرًا فوقها وتحتها.
              maxRatio: side / 140,
              tint: Colors.transparent,
              fallback: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
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
                      style: const TextStyle(
                          fontSize: _kBody,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _kPhotoSide = 68;

  /// أحجام الخط المشتركة في الشاشة: النصوص القديمة كانت `bodySmall` على
  /// خلفية رمادية فتقرأ بصعوبة. المصدر واحد فلا يتفارق موضع مع آخر.
  static const double _kChipText = 13;
  static const double _kLabel = 13;
  static const double _kBody = 14.5;

  Widget _photo(ThemeData theme, ServiceProvider provider, Color accent) {
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
    // الارتفاع يُقاس من نسبة الصورة الحقيقية فتملأ إطارها كاملة بلا اقتصاص.
    return FullFitImage(
      imageUrl: provider.photoUrl ?? '',
      width: _kPhotoSide,
      radius: 14,
      fallback: fallback(),
    );
  }

  Widget _kindChip(ServiceProvider provider, Color accent) {
    return _pill(provider.providerKindLabel, accent,
        mark: provider.providerKind);
  }

  Widget _featuredChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF1C40F), Color(0xFFB8860B)]),
        borderRadius: BorderRadius.circular(10),
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
                  fontSize: _kChipText)),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: filled ? 1 : 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null) ...[
            EduKindMark(kind: mark, size: 14),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                    fontSize: _kChipText)),
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
              style: const TextStyle(
                  fontSize: _kLabel,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: _kBody,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          if (provider.description.length > 120)
            TextButton(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(_descExpanded ? 'أقل' : 'المزيد',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  /// بيانات التواصل: أسطر مدمجة + زر اتصال أخضر صغير.
  Widget _contactCard(ThemeData theme, ServiceProvider provider, Color accent) {
    final hasLines = provider.phone.isNotEmpty || provider.address.isNotEmpty;
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
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: _kBody,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
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
            // الكتابة بنفس حجم نص التعليق المعروض، واللون من الثيم حتى يبقى
            // مقروءًا في الوضع الداكن.
            style: const TextStyle(
                fontSize: _kBody, fontWeight: FontWeight.w600, height: 1.5),
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
                      style: TextStyle(
                          fontSize: _kBody,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant))
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
                                    fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _commentTile(ThemeData theme, ServiceProviderComment c, Color accent) {
    // صاحب التعليق يحذف تعليقه وحده، والأدمن/الأدمن المساعد يحذفان أي تعليق.
    final deletable = c.id.isNotEmpty &&
        (_canModerate || (_currentUid.isNotEmpty && c.userId == _currentUid));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: CommentStyle.avatarRadius,
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
                        child: Text(c.userName, style: CommentStyle.author)),
                    RatingBarIndicator(
                      rating: c.rating.toDouble(),
                      itemSize: 14,
                      unratedColor: Colors.grey.withValues(alpha: 0.25),
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star_rounded, color: Colors.amber),
                    ),
                    if (deletable)
                      IconButton(
                        key: ValueKey('comment-delete-${c.id}'),
                        tooltip: 'حذف التعليق',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.delete_outline_rounded,
                            color: theme.colorScheme.error),
                        onPressed: () => _deleteComment(c),
                      ),
                  ],
                ),
                if (c.text.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(c.text, style: CommentStyle.body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
