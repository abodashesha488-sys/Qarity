import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../widgets/qurity_app_bar.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String userId;
  const CompleteProfileScreen({super.key, required this.userId});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final UserService _userService = UserService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Uint8List? _profileBytes;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<UserModel?> _createFallbackUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid == widget.userId) {
      return UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        joinDate: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
    }
    return null;
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _userService.getUser(widget.userId);
      if (!mounted) return;

      if (user != null) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _phoneController.text = user.phone ?? '';
        });
      } else {
        final fallback = await _createFallbackUser();
        if (!mounted) return;
        if (fallback != null) {
          setState(() {
            _user = fallback;
            _nameController.text = fallback.name;
            _phoneController.text = fallback.phone ?? '';
          });
        } else {
          setState(() {
            _errorMessage = 'تعذر تحميل بيانات المستخدم';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'خطأ في تحميل البيانات: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _profileBytes = bytes;
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الاسم ورقم الهاتف مطلوبان'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      String? newPhotoUrl = _user?.photoUrl;
      if (_profileBytes != null) {
        newPhotoUrl = await _imageUploadService.uploadImage(_profileBytes!);
      }

      final now = DateTime.now();
      final updatedUser = UserModel(
        id: widget.userId,
        name: name,
        email: _user?.email ?? '',
        photoUrl: newPhotoUrl,
        joinDate: _user?.joinDate ?? now,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      await _userService.updateUser(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملف الشخصي بنجاح'), backgroundColor: Color(0xFF6F4E37)),
      );

      await NotificationService.subscribeToTopic('village_news');
      await NotificationService.subscribeToTopic('village_obituaries');
      await NotificationService.subscribeToTopic('village_occasions');
      await NotificationService.subscribeToTopic('village_market');
      await NotificationService.subscribeToTopic('village_forum');
      await NotificationService.subscribeToTopic('village_services');
      await NotificationService.subscribeToTopic('village_medical');
    await NotificationService.subscribeToTopic('village_alerts');
    await NotificationService.subscribeToTopic('village_breaking');

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  ImageProvider<Object>? _getImageProvider() {
    if (_profileBytes != null) return MemoryImage(_profileBytes!);
    if (_user != null && _user!.photoUrl?.isNotEmpty == true) return CachedNetworkImageProvider(_user!.photoUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        appBar: QurityAppBar(title: 'إكمال الملف الشخصي'),
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_errorMessage != null || _user == null) {
      return Scaffold(
        appBar: const QurityAppBar(title: 'إكمال الملف الشخصي'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'تعذر تحميل الملف الشخصي', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(onPressed: _loadUser, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      );
    }

    final imageProvider = _getImageProvider();

    return Scaffold(
      appBar: const QurityAppBar(title: 'إكمال الملف الشخصي'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? Icon(Icons.person_rounded, size: 52, color: theme.colorScheme.onPrimaryContainer)
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.surface, width: 2)),
                      child: Icon(Icons.camera_alt_rounded, size: 18, color: theme.colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أهلًا بك! أكمل بياناتك لنتمكن من خدمتك بشكل أفضل',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'الاسم',
                          hintText: 'أدخل اسمك الكامل',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6))),
                          prefixIcon: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف *',
                          hintText: 'مثال: 01xxxxxxxxx',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6))),
                          prefixIcon: Icon(Icons.phone_rounded, color: theme.colorScheme.primary),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'رقم الهاتف مطلوب' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () {
                            if (_formKey.currentState?.validate() ?? false) _saveProfile();
                          },
                          icon: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded, size: 20),
                          label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
