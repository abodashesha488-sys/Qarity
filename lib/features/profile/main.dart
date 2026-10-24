import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/role_style.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/theme_service.dart';
import '../../services/user_service.dart';
import '../../widgets/gender_selector.dart';
import '../../widgets/qurity_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();
  final MarketService _marketService = MarketService();
  final ThemeService _themeService = ThemeService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserModel? _user;
  Uint8List? _profileBytes;
  String? _uploadedImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSeller = false;
  String? _loadError;
  Map<String, dynamic>? _pendingUpgradeRequest;

  // stream منتجاتي مثبت لكل مستخدم — إنشاؤه داخل build كان يعيد الاشتراك
  // (وفوترة قراءة كاملة) عند كل إعادة بناء للشاشة.
  String? _productsStreamUid;
  Stream<List<MarketProduct>>? _productsStream;

  Stream<List<MarketProduct>> _myProductsStream(String uid) {
    if (_productsStream == null || _productsStreamUid != uid) {
      _productsStreamUid = uid;
      _productsStream = _marketService.getSellerProductsStream(uid);
    }
    return _productsStream!;
  }

  @override
  void initState() {
    super.initState();
    _loadUserFromCache();
    _loadUser(); // Load fresh data in background
  }

  Future<void> _loadUserFromCache() async {
    try {
      final cached = await CacheService.getUser(_userService.currentUserId ?? '');
      if (cached != null && mounted) {
        setState(() {
          _user = UserModel.fromJson(cached, _userService.currentUserId ?? '');
          _nameController.text = _user?.name ?? '';
          _phoneController.text = _user?.phone ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchData() async {
    final user = await _userService.getCurrentUser();
    var isSeller = false;
    Map<String, dynamic>? pendingReq;
    try {
      if (user != null) {
        isSeller = await _marketService.isUserSeller(user.id);
        final snap = await FirebaseFirestore.instance
            .collection('upgrade_requests')
            .where('userId', isEqualTo: user.id)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          pendingReq = {'id': snap.docs.first.id, ...snap.docs.first.data()};
        }
      }
    } catch (_) {
      // لا نُفشل الشاشة إذا تعذّر جلب حالة البائع أو الطلب (أوفلاين مثلاً).
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phone ?? '';
      _isSeller = isSeller;
      _pendingUpgradeRequest = pendingReq;
      _loadError = null;
    });
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() {
      _loadError = null;
    });
    try {
      await _fetchData();
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async => _fetchData();

  ImageProvider? _avatarImage() {
    if (_profileBytes != null) return MemoryImage(_profileBytes!);
    if (_uploadedImageUrl != null) return CachedNetworkImageProvider(_uploadedImageUrl!);
    if (_user?.photoUrl?.isNotEmpty == true) return CachedNetworkImageProvider(_user!.photoUrl!);
    return null;
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileBytes == null) return null;
    final result = await _imageUploadService.uploadImage(_profileBytes!);
    return result;
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _profileBytes = bytes;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _saveProfile({String? gender}) async {
    if (_nameController.text.isEmpty || _user == null) return;

    setState(() => _isSaving = true);

    try {
      String? newPhotoUrl = _user!.photoUrl;

      if (_profileBytes != null) {
        newPhotoUrl = await _uploadProfileImage();
      }

      final updatedUser = _user!.copyWith(
        name: _nameController.text.trim(),
        photoUrl: newPhotoUrl,
        gender: gender ?? _user!.gender,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      await _userService.updateUser(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملف الشخصي بنجاح')),
      );
      setState(() {
        _profileBytes = null;
        _uploadedImageUrl = null;
      });
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // أرضيات الشريط والأزرار هنا ألوان ثابتة في السمتين، وحبر الشريط
          // الافتراضي في الداكن داكن ⇒ البياض يُثبَّت. والأحمر هو الهادئ
          // الموثّق للحذف والخروج لا `Colors.red` الساطع (3.7 مع البياض).
          SnackBar(
              content: Text('خطأ في الحفظ: $e',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  Future<void> _signOut() async {
    await _userService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب نهائياً'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف حسابك؟\n\n'
          'سيؤدي هذا الإجراء إلى حذف بيانات ملفك الشخصي وجميع معلوماتك المسجلة نهائياً ولا يمكن التراجع عن هذه الخطوة.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري حذف الحساب...'),
                ],
              ),
            ),
          ),
        ),
      );

      await _userService.deleteAccount();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحساب بنجاح')),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حذف الحساب: $e. قد يتطلب الأمر إعادة تسجيل الدخول أولاً ثم المحاولة.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        appBar: QurityAppBar(title: 'الملف الشخصي'),
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_loadError != null && _user == null) {
      return Scaffold(
        appBar: const QurityAppBar(title: 'الملف الشخصي'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 60, color: Colors.grey[400]),
                const SizedBox(height: 14),
                Text('تعذّر تحميل الملف الشخصي',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('تحقق من الاتصال ثم أعد المحاولة',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loadUser,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const QurityAppBar(title: 'الملف الشخصي'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 16),
            _buildUpgradeCard(theme),
            const SizedBox(height: 16),
            _buildSettingsSection(theme),
            if (_isSeller) ...[
              const SizedBox(height: 16),
              _buildSellerProductsSection(theme),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  // أحمر الخروج الهادئ الموثّق مع بياض مثبّت (`Colors.red`
                  // الساطع يعطي 3.7 مع البياض لا 6.6).
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                label: const Text(
                  'حذف الحساب نهائياً',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final isAdminRole = _user?.isAdmin == true || _user?.role == 'medical_admin';
    final isMedicalOnly = _user?.role == 'medical_admin';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: _avatarImage(),
                  child: _avatarImage() == null
                      ? Icon(Icons.person, size: 46, color: theme.colorScheme.primary)
                      : null,
                ),
                GestureDetector(
                  onTap: _onCameraTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, size: 16, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RoleNameText(
              name: _user?.name.isNotEmpty == true ? _user!.name : 'المستخدم',
              role: _user?.role,
              sellerType: _user?.sellerType?.name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              _user?.email ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _roleBadge(theme),
                if (_user?.role == 'seller' && _user?.sellerType != null)
                  _sellerTypeBadge(theme, _user!.sellerType!),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _openEditSheet,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('تعديل البيانات الشخصية',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (isAdminRole) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: isMedicalOnly
                          ? const [Color(0xFF00897B), Color(0xFF4DB6AC)]
                          : const [Color(0xFF1565C0), Color(0xFFB8860B)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isMedicalOnly ? const Color(0xFF00897B) : const Color(0xFF1565C0))
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pushNamed(
                          context,
                          isMedicalOnly ? AppRoutes.medical : AppRoutes.admin),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isMedicalOnly
                                ? Icons.medical_services_rounded
                                : Icons.admin_panel_settings_rounded,
                                color: Colors.white, size: 19),
                            const SizedBox(width: 8),
                            Text(
                              isMedicalOnly ? 'إدارة المركز الطبي' : 'لوحة تحكم القرية',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onCameraTap() async {
    await _pickProfileImage();
    if (_profileBytes != null && mounted) _openEditSheet();
  }

  Future<void> _openEditSheet() async {
    final theme = Theme.of(context);
    var gender = _user?.gender ?? '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.manage_accounts_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text('تعديل البيانات الشخصية',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    await _pickProfileImage();
                    setSheet(() {});
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: _avatarImage(),
                        child: _avatarImage() == null
                            ? Icon(Icons.person,
                                size: 40, color: theme.colorScheme.primary)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'اضغط الصورة لتغييرها',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: 12),
              GenderSelector(
                value: gender.isEmpty ? null : gender,
                onChanged: (v) => setSheet(() => gender = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          await _saveProfile(gender: gender);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                      _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBadge(ThemeData theme) {
    final (label, color, icon) = switch (_user?.role ?? 'user') {
      'admin' => ('مدير عام', const Color(0xFF1565C0), Icons.admin_panel_settings_rounded),
      'assistant_admin' => ('أدمن مساعد', const Color(0xFF6A1B9A), Icons.shield_rounded),
      'medical_admin' => ('مدير المركز الطبي', const Color(0xFF00897B), Icons.medical_services_rounded),
      'legal_admin' => ('أدمن الاستشارات القانونية', const Color(0xFF2E7D32), Icons.gavel_rounded),
      'moderator' => ('مشرف', Colors.orange, Icons.verified_user_rounded),
      'seller' => ('بائع', Colors.deepPurple, Icons.store_rounded),
      _ => ('مستخدم', Colors.teal, Icons.person_rounded),
    };
    // الشارة تظليلٌ من اللون (0.12) فالرمز والنص فوقها حبرٌ لا أرضية: التركوازي
    // 3.67 والبرتقالي 2.16 فوق البياض لا يجتازان حدّ النص عند 11px، وفي الداكن
    // يسقط البياض نفسه. يُزحزح السطوع وحده فيبقى لون الدور دلالته.
    final ink = AppColors.readableInk(color, theme.brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ink),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: ink)),
        ],
      ),
    );
  }

  Widget _sellerTypeBadge(ThemeData theme, SellerType t) {
    // نفس قاعدة شارة الدور: البني أرضيةٌ تظليل لا طبقة مصمتة، وحبره فوق الداكن
    // يسقط (1.97) فلا يُقرأ اسم النوع ولا عدد الصور.
    final ink = AppColors.readableInk(Colors.brown, theme.brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.brown.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.brown.withValues(alpha: 0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(t.icon, size: 13, color: ink),
          const SizedBox(width: 5),
          Text('${t.label} • حتى ${t.maxImages} صور',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ink)),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(ThemeData theme) {
    final pendingReq = _pendingUpgradeRequest;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF673AB7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.upgrade_rounded,
                      color: Color(0xFF673AB7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ترقية الحساب والامتيازات',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        'ارتقِ بحسابك إلى بائع مميز أو اطلب الانضمام لفريق الإدارة',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pendingReq != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('طلب ترقية الحساب قيد المراجعة',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Colors.amber)),
                          const SizedBox(height: 2),
                          Text(
                            'طلب الترقية إلى «${pendingReq['targetTitle'] ?? ''}» قيد المراجعة حالياً من قبل المدير العام.',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'سيتم تحديث تصنيف حسابك فور اتخاذ القرار.',
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: pendingReq != null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'طلب ترقيتك إلى «${pendingReq['targetTitle'] ?? ''}» قيد المراجعة حالياً من قبل المدير العام.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : () => _showUpgradeDialog(context, theme),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  pendingReq != null
                      ? 'طلب الترقية قيد المراجعة'
                      : 'ترقية الحساب',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: pendingReq != null
                      ? Colors.amber[700]
                      : const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpgradeDialog(BuildContext context, ThemeData theme) async {
    if (_user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final notesController = TextEditingController();
    var isSellerCategory = true;
    var selectedTarget = 'gold'; // default
    var isSubmitting = false;

    final sellerOptions = [
      (
        'premium',
        'بائع مميز',
        'رفع حتى 10 صور لكل منتج • شارة وأولوية قصوى في العرض',
        Icons.emergency_rounded,
        const Color(0xFFD32F2F),
      ),
      (
        'super_seller',
        'بائع فائق',
        'رفع حتى 3 صور لكل منتج • شارة ولون فضي جذاب',
        Icons.storefront_rounded,
        const Color(0xFF78909C),
      ),
      (
        'gold',
        'بائع ذهبي',
        'رفع حتى 5 صور لكل منتج • شارة وإطار ولون ذهبي فاخر',
        Icons.star_rounded,
        const Color(0xFFFFB300),
      ),
    ];

    final adminOptions = [
      (
        'assistant_admin',
        'أدمن مساعد',
        'مراجعة وإدارة محتوى التطبيق مع المدير العام',
        Icons.shield_rounded,
        const Color(0xFF6A1B9A),
      ),
      (
        'medical_admin',
        'مدير المركز الطبي',
        'إدارة عيادات ومواعيد أطباء المركز الطبي الخيري',
        Icons.medical_services_rounded,
        const Color(0xFF00897B),
      ),
      (
        'agricultural_admin',
        'مدير الخدمات الزراعية',
        'إدارة بوابة المزارع والمحتوى الزراعي والاستشارات',
        Icons.agriculture_rounded,
        const Color(0xFF558B2F),
      ),
      (
        'legal_admin',
        'أدمن الاستشارات القانونية',
        'متابعة والرد على الاستشارات القانونية في مستشار القرية',
        Icons.gavel_rounded,
        const Color(0xFF2E7D32),
      ),
      (
        'moderator',
        'مشرف مجتمعي',
        'إشراف ومتابعة المجتمع ومشاركات القرية',
        Icons.verified_user_rounded,
        Colors.orange,
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final options = isSellerCategory ? sellerOptions : adminOptions;
          final currentSelectedTitle = options
              .firstWhere((o) => o.$1 == selectedTarget,
                  orElse: () => options.first)
              .$2;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.upgrade_rounded,
                            color: Color(0xFF673AB7), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'ترقية الحساب',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر التصنيف أو الدور الذي ترغب في الترقية إليه. تُرفع الطلبات إلى المدير العام للمراجعة والاعتماد.',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('ترقية بائع'),
                          icon: Icon(Icons.store_rounded),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('دور إداري'),
                          icon: Icon(Icons.admin_panel_settings_rounded),
                        ),
                      ],
                      selected: {isSellerCategory},
                      onSelectionChanged: (set) {
                        setSheet(() {
                          isSellerCategory = set.first;
                          selectedTarget =
                              isSellerCategory ? 'gold' : 'assistant_admin';
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    RadioGroup<String>(
                      groupValue: selectedTarget,
                      onChanged: (v) {
                        if (v != null) setSheet(() => selectedTarget = v);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final opt in options)
                            RadioListTile<String>(
                              value: opt.$1,
                              dense: true,
                              title: Text(opt.$2,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              subtitle: Text(opt.$3,
                                  style: const TextStyle(fontSize: 11)),
                              secondary: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: opt.$5.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(opt.$4, color: opt.$5, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات أو نبذة عن خبرتك (اختياري)',
                        hintText: 'اكتب سبب طلب الترقية أو نشاطك التجاري...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setSheet(() => isSubmitting = true);
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('upgrade_requests')
                                      .add({
                                    'userId': _user!.id,
                                    'userName': _user!.name,
                                    'userEmail': _user!.email,
                                    'userPhone': _user!.phone,
                                    'userPhoto': _user!.photoUrl,
                                    'currentRole': _user!.role,
                                    'currentSellerType':
                                        _user!.sellerType?.name ?? 'regular',
                                    'type': isSellerCategory
                                        ? 'seller'
                                        : 'admin',
                                    'targetType': selectedTarget,
                                    'targetTitle': currentSelectedTitle,
                                    'notes': notesController.text.trim(),
                                    'status': 'pending',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'تم إرسال طلب الترقية إلى «$currentSelectedTitle» بنجاح للمدير العام.'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  await _fetchData();
                                } catch (e) {
                                  setSheet(() => isSubmitting = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('تعذر إرسال الطلب: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          isSubmitting
                              ? 'جاري الإرسال...'
                              : 'إرسال طلب الترقية للمدير العام',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF673AB7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    Widget? statusCard;
    if (_isSeller) {
      final st = _user?.sellerType ?? SellerType.regular;
      statusCard = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.primary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(st.icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أنت بائع معتمد: ${st.label}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary)),
                  Text(st.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text('الحد الأقصى للصور: ${st.maxImages} صور لكل منتج',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_user != null && _user!.role != 'user') {
      final roleColor = switch (_user!.role) {
        'admin' => const Color(0xFF1565C0),
        'assistant_admin' => const Color(0xFF6A1B9A),
        'medical_admin' => const Color(0xFF00897B),
        'agricultural_admin' => const Color(0xFF558B2F),
        'legal_admin' => const Color(0xFF2E7D32),
        'moderator' => Colors.orange,
        _ => theme.colorScheme.primary,
      };
      statusCard = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: roleColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: roleColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('صلاحية الحساب: ${_user!.roleLabel}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: roleColor)),
                  Text('حسابك يملك صلاحيات إدارية معتمدة بالتطبيق',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _themeService,
            builder: (context, _) => SwitchListTile(
              title: Text('الوضع الليلي',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text('تفعيل المظهر الداكن للتطبيق',
                  style: theme.textTheme.bodySmall),
              value: _themeService.isDarkMode,
              onChanged: (value) => _themeService.setDarkMode(value),
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _themeService.isDarkMode
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _themeService.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          _SettingsTile(
            theme: theme,
            icon: Icons.favorite_rounded,
            title: 'قائمتي المفضلة',
            subtitle: 'الأخبار والمنتجات والفنيون والمحاصيل المحفوظة',
            onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
          ),
          const Divider(height: 1),
          _SettingsTile(
            theme: theme,
            icon: Icons.notifications_rounded,
            title: 'الإشعارات',
            subtitle: 'إعدادات الإشعارات التي تصلك',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notificationsSettings),
          ),
          const Divider(height: 1),
          _SettingsTile(
            theme: theme,
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            subtitle: 'المظهر واللغة والحساب',
            onTap: () => Navigator.pushNamed(context, AppRoutes.settingsIndex),
          ),
          if (statusCard != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: statusCard,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerProductsSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('منتجاتي', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<MarketProduct>>(
              stream: _myProductsStream(_user!.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 32),
                        const SizedBox(height: 8),
                        Text('خطأ في تحميل المنتجات', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                      ],
                    ),
                  );
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 48, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('لا توجد منتجات بعد', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail, arguments: product),
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(product.name,
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${product.price.toStringAsFixed(0)} ج.م',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
