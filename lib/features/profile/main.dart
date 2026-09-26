import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/role_style.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/theme_service.dart';
import '../../services/user_service.dart';
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
  SellerRequest? _sellerRequest;
  bool _checkingRequest = false;
  String? _loadError;

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
    SellerRequest? request;
    try {
      if (user != null) isSeller = await _marketService.isUserSeller(user.id);
      if (user != null && !isSeller) {
        request = await _marketService.getUserSellerRequest(user.id);
      }
    } catch (_) {
      // لا نُفشل الشاشة إذا تعذّر جلب حالة البائع (أوفلاين مثلاً).
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phone ?? '';
      _isSeller = isSeller;
      _sellerRequest = request;
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
    return _imageUploadService.uploadImage(_profileBytes!);
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

  Future<void> _saveProfile() async {
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
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitSellerRequest() async {
    if (_user == null) return;

    // Show dialog to get shop details
    final shopNameController =
        TextEditingController(text: '${_user!.name}\'s Shop');
    final shopDescController = TextEditingController();
    final shopAddressController = TextEditingController();
    String? selectedCategory;
    SellerType selectedType = SellerType.regular;

    final categories = [
      'مواد غذائية', 'خضار وفواكه', 'لحوم وطيور وأسماك',
      'ألبان وخير البلد', 'حلويات ومخبوزات', 'مشروبات ومقاهي',
      'أدوات منزلية ومنظفات', 'إلكترونيات وهواتف', 'أثاث ومفروشات',
      'ملابس وأحذية', 'مستلزمات زراعة وأعلاف', 'سوق المستعمل',
      'ورش صيانة', 'كهرباء وسباكة', 'نجارة وألمنيوم', 'حدادة ولحام',
      'تكييف وتبريد', 'سيارات وموتوسيكلات', 'مخازن ومستودعات',
      'حرف يدوية', 'خياطة وتفصيل', 'مطاعم ومخابز', 'صيدليات', 'خدمات أخرى',
    ];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('طلب فتح متجر'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: shopNameController,
                  decoration: const InputDecoration(labelText: 'اسم المتجر *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: shopDescController,
                  decoration: const InputDecoration(labelText: 'وصف المتجر', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: shopAddressController,
                  decoration: const InputDecoration(labelText: 'عنوان المتجر', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'الفئة الرئيسية *', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v),
                  menuMaxHeight: 360,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SellerType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'نوع البائع *', border: OutlineInputBorder()),
                  items: SellerType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('${t.label} (حتى ${t.maxImages} صور)'),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedType = v ?? selectedType),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (shopNameController.text.isEmpty || selectedCategory == null) return;
                Navigator.pop(context, {
                  'shopName': shopNameController.text,
                  'shopDescription': shopDescController.text,
                  'shopAddress': shopAddressController.text,
                  'category': selectedCategory!,
                  'sellerType': selectedType.name,
                });
              },
              child: const Text('إرسال الطلب'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() => _checkingRequest = true);
    try {
      final request = SellerRequest(
        id: '',
        userId: _user!.id,
        userName: _user!.name,
        userPhone: _user!.phone ?? '',
        userPhotoUrl: _user!.photoUrl,
        shopName: result['shopName'] as String,
        shopDescription: result['shopDescription'] as String,
        shopAddress: result['shopAddress'] as String,
        categories: [result['category'] as String],
        requestedSellerType: result['sellerType'] as String,
      );
      await _marketService.submitSellerRequest(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلبك بنجاح! سنراجعه قريباً'), backgroundColor: Color(0xFF6F4E37)),
      );
      await _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _checkingRequest = false);
    }
  }

  Future<void> _signOut() async {
    await _userService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
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
                  backgroundColor: Colors.red,
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
    final isAdminRole = _user?.role == 'admin' || _user?.role == 'medical_admin';
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
                            const Icon(Icons.chevron_left_rounded,
                                color: Colors.white70, size: 18),
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
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          await _saveProfile();
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
      'medical_admin' => ('مدير المركز الطبي', const Color(0xFF00897B), Icons.medical_services_rounded),
      'moderator' => ('مشرف', Colors.orange, Icons.verified_user_rounded),
      'seller' => ('بائع', Colors.deepPurple, Icons.store_rounded),
      _ => ('مستخدم', Colors.teal, Icons.person_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _sellerTypeBadge(ThemeData theme, SellerType t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.brown.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.brown.withValues(alpha: 0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(t.icon, size: 13, color: Colors.brown),
          const SizedBox(width: 5),
          Text('${t.label} • حتى ${t.maxImages} صور',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.brown)),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    Widget? sellerAction;
    if (_isSeller) {
      final st = _user?.sellerType ?? SellerType.regular;
      sellerAction = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.primary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(st.icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أنت بائع', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                  Text(st.label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text('الحد الأقصى للصور: ${st.maxImages}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_sellerRequest?.isPending == true) {
      sellerAction = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('طلبك قيد المراجعة', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.orange[800])),
                  Text('سيتم مراجعة طلبك من قبل الإدارة', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_sellerRequest?.isRejected == true) {
      sellerAction = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel_rounded, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Text('تم رفض طلبك', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.error)),
              ],
            ),
            if (_sellerRequest!.adminNotes != null) ...[
              const SizedBox(height: 8),
              Text('السبب: ${_sellerRequest!.adminNotes}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _checkingRequest ? null : _submitSellerRequest,
              icon: _checkingRequest ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_business_rounded),
              label: Text(_checkingRequest ? 'جاري الإرسال...' : 'إعادة المحاولة'),
            ),
          ],
        ),
      );
    } else {
      sellerAction = FilledButton.icon(
        onPressed: _checkingRequest ? null : _submitSellerRequest,
        icon: _checkingRequest ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.storefront_rounded),
        label: Text(_checkingRequest ? 'جاري الإرسال...' : 'أريد أن أصبح بائع'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _themeService,
            builder: (context, _) => SwitchListTile(
              title: Text('الوضع الليلي', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text('تفعيل المظهر الداكن للتطبيق', style: theme.textTheme.bodySmall),
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
                  _themeService.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          _SettingsTile(
            theme: theme,
            icon: Icons.notifications_rounded,
            title: 'الإشعارات',
            subtitle: 'إعدادات الإشعارات التي تصلك',
            onTap: () => Navigator.pushNamed(context, AppRoutes.notificationsSettings),
          ),
          const Divider(height: 1),
          _SettingsTile(
            theme: theme,
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            subtitle: 'المظهر واللغة والحساب',
            onTap: () => Navigator.pushNamed(context, AppRoutes.settingsIndex),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: sellerAction,
          ),
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
            Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}
