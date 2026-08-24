import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_appbar_actions.dart';

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
  bool _isSubmitting = false;
  final List<String> _uploadedImageUrls = [];
  String _sellerName = 'عام';
  String _sellerPhone = '';
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
        _sellerPhone = user.phone ?? '';
        _sellerId = user.id;
      });
    }
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
      final url = await ImageUploadService().uploadImage(bytes);
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
    if (!await NetworkInfo().isConnected) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'لا يوجد اتصال بالإنترنت', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
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
        sellerPhone: _sellerPhone,
        sellerId: _sellerId,
        stock: 10,
      );
      await _marketService.addProduct(product);
      await CacheService.invalidateProducts();
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
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
                      Text('معلومات المنتج', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        items: _categories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Tooltip(message: c, child: Text(c, overflow: TextOverflow.ellipsis)),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v ?? 'عام'),
                        decoration: const InputDecoration(labelText: 'الفئة', prefixIcon: Icon(Icons.category)),
                        menuMaxHeight: 300,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                          Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('الصور (${_uploadedImageUrls.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadImage,
                          icon: _isUploading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.camera_alt),
                          label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_isSubmitting ? 'جاري الحفظ...' : 'حفظ المنتج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
