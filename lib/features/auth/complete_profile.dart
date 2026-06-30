import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
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
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getUser(widget.userId);
    if (user != null) {
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _phoneController.text = user.phone ?? '';
      });
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
    if (_nameController.text.isEmpty || _user == null) return;
    setState(() => _isSaving = true);
    try {
      String? newPhotoUrl = _user!.photoUrl;
      if (_profileImage != null) {
        final bytes = await _profileImage!.readAsBytes();
        newPhotoUrl = await _imageUploadService.uploadImage(bytes);
      }
      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        photoUrl: newPhotoUrl,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      );
      await _userService.updateUser(updatedUser);
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
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
    return Scaffold(
      appBar: AppBar(title: const Text('إكمال الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _getImageProvider(),
                  child: _profileImage == null && (_user?.photoUrl?.isEmpty ?? true)
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
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
}