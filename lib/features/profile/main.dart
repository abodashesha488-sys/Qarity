import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/order_service.dart';
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
  final OrderService _orderService = OrderService();
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _fetchData() async {
    final user = await _userService.getCurrentUser();
    final isSeller = await _marketService.isUserSeller(user?.id ?? '');
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phone ?? '';
      _isSeller = isSeller;
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
              _buildSellerOrdersSection(theme),
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
          ],
        ),
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
        ],
      ),
    );
  }

  void _showOrderDetails(AppOrder order, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(order.productName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          ListTile(title: Text('العميل: ${order.buyerName}'), leading: const Icon(Icons.person)),
          ListTile(title: Text('هاتف العميل: ${order.buyerPhone}'), leading: const Icon(Icons.phone)),
          ListTile(title: Text('الكمية: ${order.quantity} قطعة'), leading: const Icon(Icons.shopping_cart)),
          ListTile(title: Text('السعر: ${order.price.toStringAsFixed(0)} ج.م'), leading: const Icon(Icons.money)),
          ListTile(title: Text('الحالة: ${order.statusLabel}'), leading: Icon(Icons.info, color: order.statusColor)),
        ]),
      ),
    );
  }

  void _showCompleteDialog(AppOrder order) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الطلب؟'),
        content: const Text('هل أنت متأكد أنك أنهيت هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              _orderService
                  .updateOrderStatus(order.id, 'delivered')
                  .then((_) => navigator.pop());
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerOrdersSection(ThemeData theme) {
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
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('طلباتي', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(child: _buildCountTab('جديدة', _pendingCount(theme), theme.colorScheme.error)),
                      Tab(child: _buildCountTab('منفذة', _deliveredCount(theme), Colors.green)),
                    ],
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildOrdersList('pending', theme),
                        _buildOrdersList('delivered', theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(String status, ThemeData theme) {
    return StreamBuilder<List<AppOrder>>(
      stream: _orderService.getSellerOrdersStream(_user?.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 32),
                  const SizedBox(height: 8),
                  Text('خطأ في تحميل الطلبات', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }
        final orders = (snapshot.data ?? []).where((o) => o.status == status).toList();
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(status == 'pending' ? 'لا توجد طلبات جديدة' : 'لا توجد طلبات منفذة',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: ListTile(
                title: Text(
                  order.productName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('من ${order.buyerName} • ${order.quantity} قطعة',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (order.buyerPhone.isNotEmpty)
                      Text('هاتف: ${order.buyerPhone}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(order.statusLabel, style: theme.textTheme.bodySmall?.copyWith(color: order.statusColor)),
                  ],
                ),
                isThreeLine: true,
                trailing: status == 'pending'
                    ? IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _showCompleteDialog(order))
                    : null,
                onTap: () => _showOrderDetails(order, theme),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pendingCount(ThemeData theme) {
    return StreamBuilder<List<AppOrder>>(
      stream: _orderService.getSellerOrdersStream(_user?.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Icon(Icons.error_outline_rounded, size: 16, color: theme.colorScheme.error);
        if (!snapshot.hasData) return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
        final count = (snapshot.data ?? []).where((o) => o.status == 'pending').length;
        return Text('$count', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 14));
      },
    );
  }

  Widget _deliveredCount(ThemeData theme) {
    return StreamBuilder<List<AppOrder>>(
      stream: _orderService.getSellerOrdersStream(_user?.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Icon(Icons.error_outline_rounded, size: 16, color: theme.colorScheme.error);
        if (!snapshot.hasData) return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
        final count = (snapshot.data ?? []).where((o) => o.status == 'delivered').length;
        return Text('$count', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14));
      },
    );
  }

  Widget _buildCountTab(String label, Widget countWidget, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      const SizedBox(width: 4),
      countWidget,
    ]);
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
