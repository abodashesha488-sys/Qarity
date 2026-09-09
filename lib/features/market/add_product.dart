import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
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
  final UserService _userService = UserService();
  final MarketService _marketService = MarketService();
  final ImagePicker _picker = ImagePicker();

  SellerType _sellerType = SellerType.regular;
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
    'ورش وصيانة',
    'مخازن ومستودعات',
    'حرف يدوية',
    'خدمات أخرى',
  ];
  String _selectedCategory = 'مواد غذائية';
  final List<String> _uploadedImageUrls = [];
  String _sellerName = 'عام';
  String _sellerPhone = '';
  String? _sellerId;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  int get _maxImagesAllowed => _sellerType.maxImages;

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _sellerName = user.name;
        _sellerPhone = user.phone ?? '';
        _sellerId = user.id;
        _sellerType = user.sellerType ?? SellerType.regular;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploadedImageUrls.length >= _maxImagesAllowed) {
      AppHelpers.showSnackBar(
          context, 'وصلت للحد الأقصى $_maxImagesAllowed صور (${_sellerType.label})', isError: true);
      return;
    }
    setState(() => _isUploading = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      setState(() => _uploadedImageUrls.add(url));
      if (mounted) {
        AppHelpers.showSnackBar(context, 'تم رفع الصورة بنجاح', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _uploadedImageUrls.removeAt(index));
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
              _buildInfoCard(theme),
              const SizedBox(height: 16),
              _buildImagesCard(theme),
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

  Widget _buildInfoCard(ThemeData theme) {
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
            Text('معلومات المنتج', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم المنتج', prefixIcon: Icon(Icons.title)),
              validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'الوصف', prefixIcon: Icon(Icons.description)),
              maxLines: 3,
              validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
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
              validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Tooltip(message: c, child: Text(c, overflow: TextOverflow.ellipsis)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'عام'),
              decoration: const InputDecoration(labelText: 'الفئة', prefixIcon: Icon(Icons.category)),
              menuMaxHeight: 360,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesCard(ThemeData theme) {
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
                Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الصور (${_uploadedImageUrls.length}/$_maxImagesAllowed)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sellerType.icon == Icons.star_rounded
                        ? Colors.amber.withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(_sellerType.icon, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(_sellerType.label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
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
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: (_isUploading || _uploadedImageUrls.length >= _maxImagesAllowed) ? null : _pickAndUploadImage,
                icon: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt),
                label: Text(_isUploading
                    ? 'جاري الرفع...'
                    : (_uploadedImageUrls.length >= _maxImagesAllowed
                        ? 'وصلت للحد الأقصى'
                        : 'إضافة صورة')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
