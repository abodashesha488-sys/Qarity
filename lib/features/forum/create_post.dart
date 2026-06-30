import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/data_models.dart';
import '../../services/forum_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _forumService = ForumService();
  final _userService = UserService();
  final _picker = ImagePicker();
  final _imageUploadService = ImageUploadService();
  bool _isPosting = false;
  bool _isUploading = false;
  String _userName = 'جاري التحميل...';
  String _userPhoto = '';
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userName = user.name;
        _userPhoto = user.photoUrl ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final url = await _imageUploadService.uploadImage(bytes);
        setState(() {
          _uploadedImageUrl = url;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في اختيار الصورة: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _post() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال المحتوى'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isPosting = true);
    try {
      final authUser = _userService.currentUser;
      if (authUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول أولاً'), backgroundColor: Colors.red));
        return;
      }
      final post = ForumPost(
        id: '',
        userId: authUser.uid,
        userName: _userName,
        userPhotoUrl: _userPhoto,
        content: _contentController.text,
        imageUrl: _uploadedImageUrl ?? '',
        createdAt: DateTime.now(),
        isApproved: true,
      );
      await _forumService.addPost(post);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النشر بنجاح')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء منشور'), actions: CommonAppBarActions.actions(context)),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [CircleAvatar(backgroundImage: _userPhoto.isNotEmpty ? NetworkImage(_userPhoto) : null, child: _userPhoto.isEmpty ? const Icon(Icons.person) : null), const SizedBox(width: 12), Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 20),
        TextFormField(controller: _contentController, decoration: const InputDecoration(hintText: 'شارك فكرتك مع المجتمع...', border: InputBorder.none), maxLines: 5, style: const TextStyle(fontSize: 16), autofocus: true),
        const SizedBox(height: 12),
        if (_uploadedImageUrl != null) Stack(children: [Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(_uploadedImageUrl!), fit: BoxFit.cover)), alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.cancel, color: Colors.white), onPressed: () => setState(() => _uploadedImageUrl = null)))]),
        const Spacer(),
        Row(children: [IconButton(icon: const Icon(Icons.image), onPressed: _isUploading ? null : _pickImage), if (_isUploading) const CircularProgressIndicator(), const Spacer(), SizedBox(width: 120, child: ElevatedButton(onPressed: _isPosting ? null : _post, child: _isPosting ? const CircularProgressIndicator() : const Text('نشر'))),]),
      ])),
    );
  }
}