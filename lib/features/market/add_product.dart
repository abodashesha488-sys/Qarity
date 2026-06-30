import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/user_service.dart';

class AddMarketProductScreen extends StatefulWidget {
  const AddMarketProductScreen({super.key});

  @override
  State<AddMarketProductScreen> createState() => _AddMarketProductScreenState();
}

class _AddMarketProductScreenState extends State<AddMarketProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'مواد غذائية';
  final List<String> _categories = [
    'مواد غذائية',
    'خضار وفواكه',
    'لحوم وطيور وأسماك',
    'ألبان وخير البلد',
    'حلويات ومخبوزات',
    'مشروبات ومقاهي',
    'أدوات منزلية ومنظفات',
    'إلكترونيات وهواتف',
    'أثاث ومفروشات',
    'ملابس وأحذية',
    'مستلزمات زراعة وأعلاف',
    'سوق المستعمل',
  ];

  final MarketService _marketService = MarketService();
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();
  bool _isUploading = false;
  final List<String> _uploadedImageUrls = [];
  String _sellerName = 'عام';
  String? _sellerId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      setState(() {
        _sellerName = user.name;
        _sellerId = user.id;
      });
    }
  }

  Future<String> _uploadImageToImgbb(Uint8List imageBytes) async {
    const String apiKey = '5adf17954a21d7d9146824fde7061c6d';
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['url'];
    }
    throw Exception('فشل رفع الصورة: ${response.statusCode}');
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }
      final bytes = await image.readAsBytes();
      final url = await _uploadImageToImgbb(bytes);
      setState(() {
        _uploadedImageUrls.add(url);
      });
      if (mounted) {
        AppHelpers.showSnackBar(context, 'تم رفع الصورة بنجاح', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedImageUrls.isEmpty) {
      AppHelpers.showSnackBar(context, 'يرجى إضافة صورة المنتج', isError: true);
      return;
    }
    try {
      final product = MarketProduct(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        imageUrl: _uploadedImageUrls.first,
        imageUrls: _uploadedImageUrls,
        category: _selectedCategory,
        sellerName: _sellerName,
        sellerPhone: '',
        sellerId: _sellerId,
        stock: 10,
        isApproved: true,
      );
      await _marketService.addProduct(product);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'تمت الإضافة بنجاح', isSuccess: true);
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushNamed(context, AppRoutes.marketProducts);
          }
        });
      }
    } catch (e) {
      if (mounted) AppHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('معلومات المنتج', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج', prefixIcon: Icon(Icons.title)),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف', prefixIcon: Icon(Icons.description)),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر (ج.م)',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'جنية مصري',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Tooltip(message: c, child: Text(c, overflow: TextOverflow.ellipsis)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v ?? 'عام'),
                  decoration: const InputDecoration(labelText: 'الفئة', prefixIcon: Icon(Icons.category)),
                  menuMaxHeight: 300,
                ),
              ),
              const SizedBox(height: 24),
              Text('الصور (${_uploadedImageUrls.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_uploadedImageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _uploadedImageUrls.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(_uploadedImageUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  icon: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_alt),
                  label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('حفظ المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}