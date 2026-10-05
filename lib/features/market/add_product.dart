import 'package:flutter/material.dart';
import '../../core/constants/product_categories.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../services/cache_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/user_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';

class AddMarketProductScreen extends StatefulWidget {
  const AddMarketProductScreen(
      {super.key,
      this.userService,
      this.marketService,
      this.uploader,
      this.bytesSource,
      this.existing});

  /// حقن اختياري — النمط المعتمد في المشروع (اختبارات بلا Firebase حقيقي).
  final UserService? userService;
  final MarketService? marketService;

  /// مُحرِّك الرفع ومصدر البايتات اللذان يمرّران إلى `ImageListEditor` —
  /// المحرر المشترك وحده يرفع.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  /// المنتج المحرَّر — عند وجوده يحفظ النموذج بتعديل بائعه (البند ٨).
  final MarketProduct? existing;

  @override
  State<AddMarketProductScreen> createState() => _AddMarketProductScreenState();
}

/// مسار «إضافة منتج» من صفحة محل نظارات: الفئات المعروضة هي تخصصات المحل نفسها.
const String kCategoryOptionsArgKey = 'categoryOptions';

/// صفحة المحل تمرّر معرّفها فيُربط المنتج بمحلّه لا بصاحبه وحده، فلا يظهر
/// المنتج في كل محلات البائع حين يكون له أكثر من محل.
const String kShopIdArgKey = 'shopId';

class _AddMarketProductScreenState extends State<AddMarketProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _priceController = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.price.toStringAsFixed(0));
  late final UserService _userService = widget.userService ?? UserService();
  late final MarketService _marketService = widget.marketService ?? MarketService();

  SellerType _sellerType = SellerType.regular;
  // نفس قوائم التصنيف في تبويب «السوق» — مصدر واحد مشترك، إلا إذا مرّر
  // مصدرٌ قائمة خاصة به (محل نظارات يمرّر تخصصاته).
  List<String> _categories =
      kProductCategories.where((c) => c != 'عام').toList();
  String _selectedCategory = 'مواد غذائية';
  bool _presetApplied = false;
  final List<String> _uploadedImageUrls = [];
  String _sellerName = 'عام';
  String _sellerPhone = '';
  String? _sellerId;
  String? _shopId;
  bool _isSubmitting = false;
  bool _isUploading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _uploadedImageUrls.addAll(e.imageUrls.isNotEmpty
          ? e.imageUrls
          : (e.imageUrl.isEmpty ? const <String>[] : [e.imageUrl]));
      // تصنيف السجل المحرَّر قد يكون خارج القائمة الممرَّرة (تخصصات محل)،
      // فيُضاف إليها بدل أن يُبدَّل صامتًا — فالقائمة المغلقة ترمي في Dropdown.
      if (e.category.isNotEmpty && !_categories.contains(e.category)) {
        _categories = [..._categories, e.category];
      }
      _selectedCategory =
          _categories.contains(e.category) ? e.category : _categories.first;
      _shopId = e.shopId;
    }
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_presetApplied) return;
    _presetApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) return;
    final shop = args[kShopIdArgKey];
    if (shop is String && shop.isNotEmpty) _shopId = shop;
    final options = (args[kCategoryOptionsArgKey] as List?)
            ?.whereType<String>()
            .toList() ??
        const [];
    if (options.isEmpty) return;
    _categories = options;
    _selectedCategory = options.first;
  }

  int get _maxImagesAllowed => _sellerType.maxImages;

  Future<void> _loadCurrentUser() async {
    UserModel? loaded;
    try {
      loaded = await _userService.getCurrentUser();
    } catch (_) {
      // لا مصادقة في اختبارات Widgets — النموذج يعمل ببيانات فارغة.
    }
    if (!mounted || loaded == null) return;
    final user = loaded;
    setState(() {
      _sellerName = user.name;
      _sellerPhone = user.phone ?? '';
      _sellerId = user.id;
      _sellerType = user.sellerType ?? SellerType.regular;
    });
  }

  /// المحرر المشترك يرفع ويحذف ويعوّض؛ كل ما يبقى هنا هو مرآة القائمة التي
  /// تُكتب في المنتج عند الحفظ.
  void _onImagesChanged(List<String> urls) {
    setState(() {
      _uploadedImageUrls
        ..clear()
        ..addAll(urls);
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
    final editing = widget.existing;
    try {
      final product = MarketProduct(
        id: editing?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        imageUrl: _uploadedImageUrls.first,
        imageUrls: _uploadedImageUrls,
        category: _selectedCategory,
        sellerName: _sellerName,
        sellerPhone: _sellerPhone,
        sellerId: _sellerId,
        shopId: _shopId,
        sellerType: _sellerType.name,
        stock: editing?.stock ?? 10,
        // العرض والنوافذ وحالة المنتج يملكها البائع بإجراء مستقل لا من هذه
        // الورقة، فتُنقل كما هي كي لا تُمسح نسخة قديمة منها وقت التعديل.
        isOnOffer: editing?.isOnOffer ?? false,
        offerPrice: editing?.offerPrice,
        offerStartsAt: editing?.offerStartsAt,
        offerEndsAt: editing?.offerEndsAt,
        productStatus: editing?.productStatus ?? 'regular',
        createdAt: editing?.createdAt,
      );
      if (editing == null) {
        await _marketService.addProduct(product);
      } else {
        await _marketService.updateProduct(product);
      }
      await CacheService.invalidateProducts();
      if (mounted) {
        AppHelpers.showSnackBar(context,
            editing == null
                ? 'تمت الإضافة بنجاح — يظهر المنتج في سوق القرية بعد موافقة الإدارة'
                : 'تم حفظ التعديلات — أُعيد للمراجعة',
            isSuccess: true);
        Navigator.pop(context, true);
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
      appBar: QurityAppBar(title: _isEdit ? 'تعديل المنتج' : 'إضافة منتج'),
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
                  onPressed: _isSubmitting || _isUploading ? null : _submitForm,
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
                const Expanded(child: SizedBox()),
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
            // المحرر المشترك: مصغّرات بحذف فردي + رفع + لصق رابط + سبب واضح
            // عند الامتلاء أو فشل الرفع، فسطور رفع الصور الخاصة لا تبقى هنا.
            ImageListEditor(
              label: 'صور المنتج',
              fieldKey: 'imageUrls',
              urls: _uploadedImageUrls,
              maxImages: _maxImagesAllowed,
              uploader: widget.uploader,
              bytesSource: widget.bytesSource,
              maxSide: 1200,
              onBusyChanged: (busy) => setState(() => _isUploading = busy),
              onChanged: _onImagesChanged,
            ),
          ],
        ),
      ),
    );
  }
}
