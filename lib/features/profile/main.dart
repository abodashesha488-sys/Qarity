import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/order_service.dart';
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

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _userService.getCurrentUser();
    final isSeller = await _marketService.isUserSeller(user?.id ?? '');
    setState(() {
      _user = user;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phone ?? '';
      _isSeller = isSeller;
      _isLoading = false;
    });
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;
    final bytes = await _profileImage!.readAsBytes();
    final url = await _imageUploadService.uploadImage(bytes);
    return url;
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
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
        _loadUser();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 24),
            _buildEditForm(theme),
            const SizedBox(height: 24),
            _buildStatsSection(theme),
            const SizedBox(height: 24),
            _buildSellerOrdersSection(theme),
            const SizedBox(height: 24),
            _buildSellerProductsSection(theme),
            const SizedBox(height: 24),
            _buildSettingsSection(theme),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    ImageProvider? getBackground() {
      if (_profileImage != null) return FileImage(_profileImage!);
      if (_uploadedImageUrl != null) return CachedNetworkImageProvider(_uploadedImageUrl!);
      if (_user?.photoUrl?.isNotEmpty == true) return CachedNetworkImageProvider(_user!.photoUrl!);
      return null;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage: getBackground(),
              child: _user?.photoUrl?.isEmpty == true && _profileImage == null && _uploadedImageUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعديل الملف الشخصي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
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
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('حفظ', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إحصائياتي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildStat('0', 'منشور'),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              _buildStat('0', 'إعجاب'),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              _buildStat('0', 'تعليق'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text('إعدادات', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              leading: const Icon(Icons.settings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.settingsIndex),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text('الإشعارات', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              leading: const Icon(Icons.notifications),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text('اللغة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              leading: const Icon(Icons.language),
              trailing: const Text('العربية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  void _showOrderDetails(AppOrder order, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(order.productName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
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
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('إنهاء الطلب؟'), content: const Text('هل أنت متأكد أنك أنهيت هذا الطلب؟'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), TextButton(onPressed: () => _orderService.updateOrderStatus(order.id, 'delivered').then((_) => Navigator.pop(context)), child: const Text('إنهاء'))]));
}

  Widget _buildSellerOrdersSection(ThemeData theme) {
    if (!_isSeller) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('طلباتي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(child: _buildCountTab('جديدة', _pendingCount(theme), Colors.red)),
                      Tab(child: _buildCountTab('منفذة', _deliveredCount(theme), Colors.green)),
                    ],
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
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
      stream: _orderService.getSellerOrdersStream(_user!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = (snapshot.data ?? []).where((o) => o.status == status).toList();
        if (orders.isEmpty) {
          return const Center(child: Text('لا توجد طلبات', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(order.productName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('من ${order.buyerName} • ${order.quantity} قطعة', style: GoogleFonts.cairo(color: Colors.grey[700])),
                    Text('هاتف: ${order.buyerPhone}', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)),
                    Text(order.statusLabel, style: GoogleFonts.cairo(color: order.statusColor, fontSize: 11)),
                  ],
                ),
                isThreeLine: true,
                trailing: status == 'pending'
                    ? IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _showCompleteDialog(order))
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
      stream: _orderService.getSellerOrdersStream(_user!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Text('0', style: TextStyle(color: Colors.grey));
        final count = (snapshot.data ?? []).where((o) => o.status == 'pending').length;
        return Text('$count', style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14));
      },
    );
  }

  Widget _deliveredCount(ThemeData theme) {
    return StreamBuilder<List<AppOrder>>(
      stream: _orderService.getSellerOrdersStream(_user!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Text('0', style: TextStyle(color: Colors.grey));
        final count = (snapshot.data ?? []).where((o) => o.status == 'delivered').length;
        return Text('$count', style: GoogleFonts.cairo(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14));
      },
    );
  }

  Widget _buildCountTab(String label, Widget countWidget, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: GoogleFonts.cairo(color: color)), const SizedBox(width: 4), countWidget]);
  }

  Widget _buildSellerProductsSection(ThemeData theme) {
    if (!_isSeller) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('منتجاتي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<MarketProduct>>(
              stream: _marketService.getSellerProductsStream(_user!.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Column(
                    children: [
                      Icon(Icons.inventory, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('لا توجد منتجات بعد', style: TextStyle(color: Colors.grey)),
                    ],
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
                              Text(product.name, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${product.price.toStringAsFixed(0)} ج.م', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600])),
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