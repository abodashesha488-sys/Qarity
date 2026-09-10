import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/theme_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

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
  File? _profileImage;
  String? _uploadedImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSeller = false;
  SellerRequest? _sellerRequest;
  bool _checkingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _fetchData() async {
    final user = await _userService.getCurrentUser();
    final isSeller = user != null ? await _marketService.isUserSeller(user.id) : false;
    SellerRequest? request;
    if (user != null && !isSeller) {
      request = await _marketService.getUserSellerRequest(user.id);
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phone ?? '';
      _isSeller = isSeller;
      _sellerRequest = request;
    });
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    await _fetchData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh() async => _fetchData();

  ImageProvider? _avatarImage() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_uploadedImageUrl != null) return CachedNetworkImageProvider(_uploadedImageUrl!);
    if (_user?.photoUrl?.isNotEmpty == true) return CachedNetworkImageProvider(_user!.photoUrl!);
    return null;
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;
    final bytes = await _profileImage!.readAsBytes();
    return _imageUploadService.uploadImage(bytes);
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() {
        _profileImage = File(image.path);
        _uploadedImageUrl = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _user == null) return;

    setState(() => _isSaving = true);

    try {
      String? newPhotoUrl = _user!.photoUrl;

      if (_profileImage != null) {
        newPhotoUrl = await _uploadProfileImage();
      }

      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        photoUrl: newPhotoUrl,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      await _userService.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الملف الشخصي بنجاح')),
        );
        await _fetchData();
      }
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
        const SnackBar(content: Text('تم إرسال طلبك بنجاح! سنراجعه قريباً'), backgroundColor: Colors.green),
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: theme.colorScheme.surface,
          actions: CommonAppBarActions.actions(context),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 16),
            _buildEditForm(theme),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  onTap: _pickProfileImage,
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
            Text(
              _user?.name.isNotEmpty == true ? _user!.name : 'المستخدم',
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
            if (_user?.role == 'admin' || _user?.role == 'medical_admin') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                    context,
                    _user!.role == 'admin'
                        ? AppRoutes.admin
                        : AppRoutes.medical),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: Text(_user!.role == 'admin' ? 'لوحة التحكم' : 'إدارة المركز الطبي'),
              ),
            ],
          ],
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

  Widget _buildEditForm(ThemeData theme) {
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
            Text('تعديل الملف الشخصي', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 45,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('حفظ', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
              stream: _marketService.getSellerProductsStream(_user!.id),
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
