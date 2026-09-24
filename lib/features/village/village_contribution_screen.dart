import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/village_content_models.dart';
import '../../routes/app_routes.dart';
import '../../services/remote_push_service.dart';
import '../../services/user_service.dart';
import '../../services/village_extended_service.dart';
import '../../widgets/qurity_app_bar.dart';
import 'village_content_admin.dart';

const Color kContributionColor = Color(0xFFEF6C00);

/// لون شاشة مراجعة المساهمات (تستخدمه أيضاً بطاقة الإدارة في مركز القرية).
const Color kVillageContribColor = Color(0xFF00838F);

/// أنواع مساهمات الأهالي في أرشيف القرية (المفتاح المخزَّن في Firestore).
/// مصدر واحد للتسمية/الأيقونة/اللون يستخدمه نموذج الإرسال وشاشة المراجعة.
class ContributionType {
  const ContributionType({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  static const photo = ContributionType(
      key: 'photo',
      label: 'صورة قديمة',
      icon: Icons.photo_library_outlined,
      color: Color(0xFF6A1B9A));
  static const document = ContributionType(
      key: 'document',
      label: 'وثيقة',
      icon: Icons.description_outlined,
      color: Color(0xFF1565C0));
  static const video = ContributionType(
      key: 'video',
      label: 'فيديو',
      icon: Icons.videocam_outlined,
      color: Color(0xFFB71C1C));
  static const audio = ContributionType(
      key: 'audio',
      label: 'تسجيل صوتي / حكاية',
      icon: Icons.mic_none_rounded,
      color: Color(0xFFAD1457));
  static const info = ContributionType(
      key: 'info',
      label: 'معلومة تاريخية',
      icon: Icons.menu_book_outlined,
      color: Color(0xFF5D4037));

  static const List<ContributionType> all = [
    photo,
    document,
    video,
    audio,
    info,
  ];

  static ContributionType of(String key) => all.firstWhere(
        (t) => t.key == key,
        orElse: () => info,
      );
}

/// «ساهم في ذاكرة القرية» — نموذج تقديم المواد للأرشيف الرقمي
/// (صور / وثائق / فيديوهات / تسجيلات صوتية / معلومات تاريخية).
/// كل المساهمات تُحفظ بحالة pending وتراجعها الإدارة قبل النشر.
class VillageContributionScreen extends StatefulWidget {
  const VillageContributionScreen({super.key});

  @override
  State<VillageContributionScreen> createState() =>
      _VillageContributionScreenState();
}

class _VillageContributionScreenState extends State<VillageContributionScreen> {
  final VillageExtendedService _service = VillageExtendedService();
  final _formKey = GlobalKey<FormState>();

  String _type = 'photo';
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _documentUrl = TextEditingController();
  final _videoUrl = TextEditingController();
  final _audioUrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _documentUrl.dispose();
    _videoUrl.dispose();
    _audioUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('سجّل الدخول أولاً لإرسال مساهمة'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final author = await UserService().resolveAuthor();
      await _service.saveContribution(VillageContribution(
        userId: user.uid,
        userName: author.name,
        type: _type,
        title: _title.text.trim(),
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        documentUrl: _documentUrl.text.trim(),
        videoUrl: _videoUrl.text.trim(),
        audioUrl: _audioUrl.text.trim(),
        createdAt: DateTime.now(),
      ));
      unawaited(RemotePushService.notifyAdmins('village_contributions'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم إرسال مساهمتك للمراجعة — شكراً لك!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signedIn = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'ساهم في ذاكرة القرية', color: kContributionColor),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    kContributionColor,
                    kContributionColor.withValues(alpha: 0.8)
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text('ساهم في حفظ ذاكرة أبودشيشة',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                      'لديك صورة قديمة؟ وثيقة؟ قصة سمعتها من أجدادك؟ أو معلومة عن تاريخ القرية؟ ساهم بها في أرشيف القرية.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            if (!signedIn) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('تسجيل الدخول مطلوب',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle:
                      const Text('سجّل الدخول بحسابك لتتمكن من إرسال مساهمة'),
                  trailing: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    child: const Text('تسجيل الدخول'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // اختيار نوع المساهمة
            Text('نوع المساهمة',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ContributionType.all
                  .map((type) => ChoiceChip(
                        avatar: Icon(type.icon,
                            size: 17,
                            color:
                                _type == type.key ? Colors.white : type.color),
                        label: Text(type.label),
                        selected: _type == type.key,
                        onSelected: signedIn
                            ? (_) => setState(() => _type = type.key)
                            : null,
                        selectedColor: type.color,
                        labelStyle: TextStyle(
                            color: _type == type.key
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // الحقول
            TextFormField(
              enabled: signedIn,
              controller: _title,
              decoration: vdec('عنوان المساهمة *', label: 'العنوان'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              enabled: signedIn,
              controller: _description,
              maxLines: 4,
              decoration: vdec(
                  _type == 'info'
                      ? 'اكتب المعلومة التاريخية هنا *'
                      : 'الوصف / القصة / التفاصيل (اختياري)',
                  label: _type == 'info' ? 'المعلومة' : 'الوصف'),
              validator: _type == 'info'
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? 'اكتب المعلومة أولاً'
                      : null
                  : null,
            ),
            const SizedBox(height: 16),

            // حقول حسب النوع
            if (_type == 'photo') ...[
              TextFormField(
                  enabled: signedIn,
                  controller: _imageUrl,
                  decoration: vdec('رابط الصورة', label: 'رابط الصورة *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'ارفع الصورة أو أدخل رابطها'
                      : null),
              if (signedIn) ...[
                const SizedBox(height: 8),
                Row(children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('رفع صورة من الهاتف'),
                    onPressed: () async {
                      final url = await pickAndUploadImage(context,
                          current: _imageUrl.text.trim());
                      if (!mounted || url == null || url.isEmpty) return;
                      setState(() => _imageUrl.text = url);
                    },
                  ),
                ]),
              ],
              if (_imageUrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: _imageUrl.text.trim(),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
            ] else if (_type == 'document') ...[
              TextFormField(
                  enabled: signedIn,
                  controller: _documentUrl,
                  decoration: vdec('رابط الوثيقة (PDF/صورة ممسوحة)',
                      label: 'رابط الوثيقة *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'رابط الوثيقة مطلوب'
                      : null),
            ] else if (_type == 'video') ...[
              TextFormField(
                  enabled: signedIn,
                  controller: _videoUrl,
                  decoration: vdec('رابط الفيديو (YouTube/Drive)',
                      label: 'رابط الفيديو *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'رابط الفيديو مطلوب'
                      : null),
            ] else if (_type == 'audio') ...[
              TextFormField(
                  enabled: signedIn,
                  controller: _audioUrl,
                  decoration: vdec('رابط التسجيل الصوتي',
                      label: 'رابط التسجيل الصوتي *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'رابط التسجيل مطلوب'
                      : null),
            ] else ...[
              TextFormField(
                  enabled: signedIn,
                  controller: _imageUrl,
                  decoration:
                      vdec('رابط صورة داعمة (اختياري)', label: 'رابط صورة')),
            ],

            const SizedBox(height: 24),

            // زر الإرسال
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_submitting || !signedIn) ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting
                    ? 'جاري الإرسال...'
                    : 'إرسال المساهمة للمراجعة'),
                style: FilledButton.styleFrom(
                    backgroundColor: kContributionColor,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
                'جميع المساهمات تخضع للمراجعة من قبل الإدارة قبل النشر، وتُنسب لصاحبها.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
