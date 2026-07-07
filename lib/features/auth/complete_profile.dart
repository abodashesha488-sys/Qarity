import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/image_upload_service.dart';
import '../../services/user_service.dart';

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _profileImage;
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الاسم مطلوب'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      String? newPhotoUrl = _user?.photoUrl;
      if (_profileImage != null) {
        final bytes = await _profileImage!.readAsBytes();
        newPhotoUrl = await _imageUploadService.uploadImage(bytes);
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
        const SnackBar(content: Text('تم حفظ الملف الشخصي بنجاح'), backgroundColor: Colors.green),
      );

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
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_user != null && _user!.photoUrl?.isNotEmpty == true) return CachedNetworkImageProvider(_user!.photoUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إكمال الملف الشخصي')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_errorMessage != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إكمال الملف الشخصي')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('إكمال الملف الشخصي'), centerTitle: true, elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: theme.colorScheme.surface),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  backgroundImage: _getImageProvider(),
                  child: _getImageProvider() == null
                      ? Icon(Icons.person_rounded, size: 50, color: theme.colorScheme.onPrimaryContainer)
                      : null,
                ),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.surface, width: 2)),
                    child: Icon(Icons.camera_alt_rounded, size: 16, color: theme.colorScheme.onSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.phone_rounded, color: theme.colorScheme.primary),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
