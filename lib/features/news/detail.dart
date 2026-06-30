import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'عام');
  final _dateController = TextEditingController();
  final List<String> _imageUrls = [];
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  final NewsService _newsService = NewsService();

  static const List<String> _categories = ['عام', 'ثقافة', 'رياضة', 'مجتمع', 'تعليم', 'اقتصاد'];

  @override
  void initState() {
    super.initState();
    _dateController.text = AppHelpers.formatDate(DateTime.now());
  }

  Future<String> _uploadImageToImgbb(Uint8List imageBytes) async {
    const String apiKey = '5adf17954a21d7d9146824fde7061c6d';
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes,
          filename: 'news_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['url'];
    }
    throw Exception('فشل رفع الصورة: ${response.statusCode}');
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isSaving = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _isSaving = false);
        return;
      }
      final bytes = await image.readAsBytes();
      final url = await _uploadImageToImgbb(bytes);
      setState(() => _imageUrls.add(url));
      if (mounted) AppHelpers.showSnackBar(context, 'تم رفع الصورة بنجاح', isSuccess: true);
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  void _saveNews() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار صورة الخبر', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final news = NewsItem(
        id: '',
        title: _titleController.text,
        subtitle: _subtitleController.text,
        imageUrl: _imageUrls.first,
        imageUrls: _imageUrls,
        date: _dateController.text,
        category: _categoryController.text,
      );
      await _newsService.addNews(news);
      if (mounted) {
        Navigator.pop(context);
        AppHelpers.showSnackBar(context, 'تم نشر الخبر بنجاح', isSuccess: true);
      }
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نشر خبر جديد'), actions: CommonAppBarActions.actions(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey, child: _buildForm()),
      ),
    );
  }

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('معلومات الخبر', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 16),
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(labelText: 'عنوان الخبر', prefixIcon: Icon(Icons.title)),
        validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _subtitleController,
        decoration: const InputDecoration(labelText: 'محتوى الخبر', prefixIcon: Icon(Icons.description)),
        maxLines: 4,
        validator: (v) => v!.isEmpty ? 'المحتوى مطلوب' : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _categoryController.text,
        decoration: const InputDecoration(labelText: 'الفئة', prefixIcon: Icon(Icons.category)),
        isExpanded: true,
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _categoryController.text = v ?? 'عام'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _dateController,
        decoration: const InputDecoration(labelText: 'تاريخ النشر', prefixIcon: Icon(Icons.calendar_today)),
        readOnly: true,
      ),
      const SizedBox(height: 24),
      Text('الصور (${_imageUrls.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (_imageUrls.isNotEmpty)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) => Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: CachedNetworkImageProvider(_imageUrls[index]), fit: BoxFit.cover),
                  ),
                ),
                Positioned(top: -8, right: -8, child: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _removeImage(index))),
              ],
            ),
          ),
        ),
      const SizedBox(height: 12),
      SizedBox(
        height: 80,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _pickAndUploadImage,
          icon: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.camera_alt),
          label: Text(_isSaving ? 'جاري الرفع...' : 'إضافة صورة'),
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveNews,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('نشر الخبر', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }
}