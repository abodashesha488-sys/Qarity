import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/obituary_card_assets.dart';
import '../../models/data_models.dart';
import '../../services/image_upload_service.dart';
import '../../services/obituary_service.dart';
import '../../services/share_service.dart';
import '../../widgets/obituary_share_card.dart';
import '../../widgets/qurity_app_bar.dart';

class AddObituaryScreen extends StatefulWidget {
  const AddObituaryScreen({super.key, this.service, this.existing});

  /// حقن اختياري وفق نمط المشروع: فتح النموذج في اختبار بلا Firebase
  /// لا يجب أن يهيّئFirestore عند بناء الشاشة.
  final ObituaryService? service;

  /// سجل القائمة نفسه عند تعديله من صاحبه — النموذج يمتلئ به ويُحفظ بالمسار
  /// المالك (البند ٨) بدل إنشاء سجل جديد.
  final Obituary? existing;

  @override
  State<AddObituaryScreen> createState() => _AddObituaryScreenState();
}

class _AddObituaryScreenState extends State<AddObituaryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _funeralLocationController =
      TextEditingController(text: widget.existing?.funeralLocation ?? '');
  late final _burialLocationController =
      TextEditingController(text: widget.existing?.burialLocation ?? '');
  late final _condolenceLocationController =
      TextEditingController(text: widget.existing?.condolenceLocation ?? '');

  bool get _isEdit => widget.existing != null;

  /// موعد محفوظ لا يُعاد اختياره: يبقى نصه كما هو حتى يلمس المستخدم المنتقي.
  String _savedFuneralTime = '';
  String _savedCondolenceTime = '';

  late final ObituaryService _obituaryService =
      widget.service ?? ObituaryService();
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDeathDate;
  DateTime? _selectedFuneralDate;

  /// مواعيد تُختار بالساعة والدقيقة وتُخزَّن نصًا مقروءًا، فلا هجرة ولا طابع
  /// زمني يفسد السجلات القديمة.
  TimeOfDay? _funeralTime;
  TimeOfDay? _condolenceTime;

  /// اسم الصلاة المصاحب لكل موعد، يُختار بجوار الوقت. فارغ في السجل القديم
  /// فيبقى كما هو حتى يلمسه المستخدم.
  String _funeralPrayer = '';
  String _condolencePrayer = '';
  String? _imageUrl;
  String? _photoError;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _submittedBy;

  /// نوع المتوفى: يحسم تسميات مجموعات القرابة («عم كلاً من» مقابل «عمّة كلاً من»).
  String _gender = '';
  String? _genderError;

  /// مفتاح خلفية البطاقة: أحد مفاتيح `kObituaryCardBackgrounds` أو رابط خلفية
  /// أضافها المستخدم في هذه البطاقة نفسها.
  String _cardBackground = kDefaultObituaryCardBackground;

  /// آخر خلفية رفعها المستخدم، لتبقى بلاطة اختيارًا في القائمة بعد الرجوع إلى
  /// إحدى صور azaa الأربع.
  String? _customBackground;
  bool _bgUploading = false;
  String? _bgError;

  final List<Relative> _relatives = [];
  int _relativeSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadSubmitter();
    _seedFromExisting();
  }

  /// امتلاء النموذج بالسجل عند تعديله. الموعدان محفوظان كنص مقروء لا طابع،
  /// فيبقى النص المحفوظ كما هو ما لم يلمس المستخدم المنتقي.
  void _seedFromExisting() {
    final e = widget.existing;
    if (e == null) return;
    _gender = e.gender;
    _cardBackground = e.cardBackground.isEmpty
        ? kDefaultObituaryCardBackground
        : e.cardBackground;
    if (_cardBackground.startsWith('http')) _customBackground = _cardBackground;
    _imageUrl = e.imageUrl;
    _savedFuneralTime = e.funeralTime;
    _savedCondolenceTime = e.condolenceTime;
    _funeralPrayer = e.funeralPrayer;
    _condolencePrayer = e.condolencePrayer;
    _selectedDeathDate = _parseObituaryDate(e.dateOfDeath);
    _selectedFuneralDate = _parseObituaryDate(e.funeralDate);
    _relatives
      ..clear()
      ..addAll(e.relatives);
    _relativeSeq = _relatives.length;
  }

  static DateTime? _parseObituaryDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateFormat('yyyy/MM/dd').parseStrict(raw.trim());
    } catch (_) {
      return DateTime.tryParse(raw.trim());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _funeralLocationController.dispose();
    _burialLocationController.dispose();
    _condolenceLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmitter() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) setState(() => _submittedBy = user.uid);
    } catch (_) {
      // FirebaseAuth غير مهيأ (اختبارات بلا Firebase) — السجل يُرسل بلا مُقدِّم
    }
  }

  Future<void> _pickDeathDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeathDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null && mounted) setState(() => _selectedDeathDate = picked);
  }

  Future<void> _pickFuneralDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFuneralDate ?? _selectedDeathDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked != null && mounted) {
      setState(() => _selectedFuneralDate = picked);
    }
  }

  Future<void> _pickFuneralTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _funeralTime ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'موعد صلاة الجنازة',
    );
    if (picked != null && mounted) setState(() => _funeralTime = picked);
  }

  Future<void> _pickCondolenceTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _condolenceTime ?? const TimeOfDay(hour: 17, minute: 0),
      helpText: 'موعد العزاء',
    );
    if (picked != null && mounted) setState(() => _condolenceTime = picked);
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
      _photoError = null;
    });
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200);
      if (image == null) {
        if (mounted) setState(() => _isUploading = false);
        return;
      }
      final bytes = await image.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } catch (e) {
      // خطأ دائم تحت دائرة الصورة، لا شريط مؤقت يمسحه الرفع التالي
      if (mounted) {
        setState(() =>
            _photoError =
                'تعذّر رفع صورة المتوفى (${e.toString().replaceFirst('Exception: ', '')}) — يمكنك المتابعة بلا صورة.');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage() => setState(() {
        _imageUrl = null;
        _photoError = null;
      });

  /// خلفية البطاقة من صور المستخدم: تُرفع إلى ImgBB ويخزَّن الرابط في
  /// `cardBackground` مباشرة، فتصبح البطاقة نموذجًا مثل الصور الأربع.
  Future<void> _pickAndUploadBackground() async {
    setState(() {
      _bgUploading = true;
      _bgError = null;
    });
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1600,
          maxHeight: 1600);
      if (image == null) {
        if (mounted) setState(() => _bgUploading = false);
        return;
      }
      final bytes = await image.readAsBytes();
      final url = await ImageUploadService().uploadImage(bytes);
      if (!mounted) return;
      setState(() {
        _customBackground = url;
        _cardBackground = url;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _bgError =
            'تعذّر رفع خلفية البطاقة (${e.toString().replaceFirst('Exception: ', '')}) — يمكنك اختيار إحدى صور العزاء بدلها.');
      }
    } finally {
      if (mounted) setState(() => _bgUploading = false);
    }
  }

  /// أسماء مجموعة قرابة واحدة كما أدخلها المستخدم، بترتيب الإدخال.
  List<String> _namesOf(RelativeType group) =>
      _relatives.where((r) => r.type == group).map((r) => r.name).toList();

  void _addRelativeName(RelativeType group, String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) {
      AppHelpers.showSnackBar(context, 'اكتب اسمًا أولاً', isError: true);
      return;
    }
    if (_namesOf(group).contains(name)) {
      AppHelpers.showSnackBar(context,
          '«$name» مضاف بالفعل في «${group.labelFor(_gender)}»',
          isError: true);
      return;
    }
    setState(() {
      _relatives.add(Relative(
        id: 'rel_${DateTime.now().millisecondsSinceEpoch}_${_relativeSeq++}',
        name: name,
        type: group,
        order: _namesOf(group).length,
      ));
    });
  }

  void _removeRelativeName(RelativeType group, String name) {
    setState(() {
      _relatives.removeWhere((r) => r.type == group && r.name == name);
      var order = 0;
      for (var i = 0; i < _relatives.length; i++) {
        if (_relatives[i].type == group) {
          _relatives[i] = _relatives[i].copyWith(order: order++);
        }
      }
    });
  }

  /// الإدخالات ذات النوع المكتوب يدويًا (كتلة «قرابة أخرى») كما أُدخلت.
  List<Relative> get _customRelatives =>
      _relatives.where((r) => r.typeLabel.trim().isNotEmpty).toList();

  List<String> _customNamesFor(String type) => _customRelatives
      .where((r) => r.typeLabel.trim() == type)
      .map((r) => r.name)
      .toList();

  /// النوع والاسم كلاهما مطلوب: النوع عنوانٌ يظهر في البطاقة، والاسم تحته،
  /// ولا يُقبل أحدهما بلا الآخر صمتًا. يعيد صحيحًا فقط عند الإضافة الفعلية،
  /// فتمسح الكتلة حقلَيها ولا تضيع على الرفض ما كتبه المستخدم.
  bool _addCustomRelative(String rawType, String rawName) {
    final type = rawType.trim();
    final name = rawName.trim();
    if (type.isEmpty) {
      AppHelpers.showSnackBar(context, 'اكتب نوع القرابة أولاً', isError: true);
      return false;
    }
    if (name.isEmpty) {
      AppHelpers.showSnackBar(context, 'اكتب اسم القريب أولاً', isError: true);
      return false;
    }
    if (_customNamesFor(type).contains(name)) {
      AppHelpers.showSnackBar(
          context, '«$name» مضاف بالفعل تحت «$type»', isError: true);
      return false;
    }
    setState(() {
      _relatives.add(Relative(
        id: 'rel_${DateTime.now().millisecondsSinceEpoch}_${_relativeSeq++}',
        name: name,
        type: RelativeType.other,
        typeLabel: type,
        order: _customRelatives.length,
      ));
    });
    return true;
  }

  void _removeCustomRelative(String id) {
    setState(() {
      _relatives.removeWhere((r) => r.id == id && r.typeLabel.trim().isNotEmpty);
      var order = 0;
      for (var i = 0; i < _relatives.length; i++) {
        if (_relatives[i].typeLabel.trim().isNotEmpty) {
          _relatives[i] = _relatives[i].copyWith(order: order++);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender.isEmpty) {
      setState(() => _genderError = 'يجب اختيار نوع المتوفى (رجل أو امرأة)');
      return;
    }
    setState(() => _genderError = null);
    if (_selectedDeathDate == null) {
      AppHelpers.showSnackBar(context, 'يرجى اختيار تاريخ الوفاة',
          isError: true);
      return;
    }
    if (_isUploading) {
      AppHelpers.showSnackBar(context, 'الصورة ما زالت تُرفع… انتظر ثوانٍ ثم أرسل',
          isError: true);
      return;
    }
    if (_bgUploading) {
      AppHelpers.showSnackBar(
          context, 'خلفية البطاقة ما زالت تُرفع… انتظر ثوانٍ ثم أرسل',
          isError: true);
      return;
    }
    if (!await NetworkInfo().isConnected) {
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'لا يوجد اتصال بالإنترنت', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final editing = widget.existing;
      final obituary = Obituary(
        id: editing?.id ?? '',
        name: _nameController.text.trim(),
        age: editing?.age ?? '',
        gender: _gender,
        dateOfDeath: DateFormat('yyyy/MM/dd').format(_selectedDeathDate!),
        funeralDate: _selectedFuneralDate != null
            ? DateFormat('yyyy/MM/dd').format(_selectedFuneralDate!)
            : '',
        funeralLocation: _funeralLocationController.text.trim(),
        funeralTime: _funeralTime != null
            ? obituaryTimeLabel(_funeralTime!)
            : (editing?.funeralTime ?? _savedFuneralTime),
        funeralPrayer: _funeralPrayer,
        burialLocation: _burialLocationController.text.trim(),
        condolenceLocation: _condolenceLocationController.text.trim(),
        condolenceTime: _condolenceTime != null
            ? obituaryTimeLabel(_condolenceTime!)
            : (editing?.condolenceTime ?? _savedCondolenceTime),
        condolencePrayer: _condolencePrayer,
        mosque: editing?.mosque ?? '',
        cardBackground: _cardBackground,
        imageUrl: _imageUrl,
        description: _descriptionController.text.trim(),
        relatives: _relatives,
        isApproved: editing?.isApproved ?? false,
        submittedBy: editing?.submittedBy ?? _submittedBy,
        createdAt: editing?.createdAt,
      );
      if (editing != null) {
        await _obituaryService.updateObituary(obituary);
      } else {
        await _obituaryService.addObituary(obituary);
      }
      if (!mounted) return;
      AppHelpers.showSnackBar(
          context,
          editing == null
              ? 'تم إرسال التعزية للمراجعة'
              : 'تم حفظ التعديلات — أُعيدت النعوة للمراجعة',
          isSuccess: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Obituary _buildPreviewObituary() {
    return Obituary(
      id: 'preview',
      name: _nameController.text.trim().isEmpty
          ? 'اسم المتوفى'
          : _nameController.text.trim(),
      age: '',
      gender: _gender,
      dateOfDeath: _selectedDeathDate != null
          ? DateFormat('yyyy/MM/dd').format(_selectedDeathDate!)
          : '',
      funeralDate: _selectedFuneralDate != null
          ? DateFormat('yyyy/MM/dd').format(_selectedFuneralDate!)
          : '',
      funeralLocation: _funeralLocationController.text.trim(),
      funeralTime: _funeralTime != null
          ? obituaryTimeLabel(_funeralTime!)
          : _savedFuneralTime,
      funeralPrayer: _funeralPrayer,
      burialLocation: _burialLocationController.text.trim(),
      condolenceLocation: _condolenceLocationController.text.trim(),
      condolenceTime: _condolenceTime != null
          ? obituaryTimeLabel(_condolenceTime!)
          : _savedCondolenceTime,
      condolencePrayer: _condolencePrayer,
      cardBackground: _cardBackground,
      imageUrl: _imageUrl,
      description: _descriptionController.text.trim(),
      relatives: _relatives,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: QurityAppBar(title: _isEdit ? 'تعديل النعوة' : 'إضافة تعزية'),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildReviewNotice(theme),
            const SizedBox(height: 16),
            _buildImageSection(theme)
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildDeceasedInfoCard(theme)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildLocationsCard(theme)
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildRelativesSection(theme)
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildBackgroundCard(theme)
                .animate()
                .fadeIn(delay: 450.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildDescriptionCard(theme)
                .animate()
                .fadeIn(delay: 500.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildPreviewCard(theme)
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            _buildSubmitButton(theme)
                .animate()
                .fadeIn(delay: 700.ms)
                .scale(delay: 700.ms),
          ],
        ),
      ),
    );
  }

  /// تنبيه المراجعة أحمر صريحًا: نسخة `primaryContainer` الباهتة كانت النص
  /// يقرأ شبه معدوم فوق خلفية البطاقة الفاتحة.
  Widget _buildReviewNotice(ThemeData theme) {
    const int red = 0xFFB71C1C;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(red).withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 22, color: Color(red)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'سيتم مراجعة التعزية من قبل الإدارة قبل نشرها',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(red), fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return _SectionCard(
      title: 'صورة المتوفى',
      icon: Icons.photo_library_rounded,
      children: [
        Text(
          'اختياري — إن لم تُرفع صورة تظهر صورة العزاء الافتراضية في البطاقة',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (_imageUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, _, __) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image_rounded,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _removeImage,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            height: 90,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: _isUploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_a_photo_rounded, size: 24),
              label: Text(_isUploading ? 'جاري الرفع...' : 'إضافة صورة'),
            ),
          ),
        if (_photoError != null) ...[
          const SizedBox(height: 12),
          _FormErrorLine(message: _photoError!, keyName: 'obituary-photo-error'),
        ],
      ],
    );
  }

  Widget _buildDeceasedInfoCard(ThemeData theme) {
    return _SectionCard(
      title: 'بيانات المتوفى',
      icon: Icons.person_rounded,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'الاسم *',
          hint: 'مثال: أحمد محمد علي',
          icon: Icons.person_outline_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        _buildGenderSelector(theme),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                theme: theme,
                label: 'تاريخ الوفاة *',
                value: _selectedDeathDate,
                onTap: _pickDeathDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                theme: theme,
                label: 'تاريخ صلاة الجنازة',
                value: _selectedFuneralDate,
                onTap: _pickFuneralDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// رجل/امرأة — العنوان المطلوب، وقيمته تحسم تسميات مجموعات القرابة.
  Widget _buildGenderSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('نوع المتوفى *',
            style:
                theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final value in kObituaryGenders) ...[
              if (value != kObituaryGenders.first) const SizedBox(width: 10),
              Expanded(
                child: _ObituaryGenderOption(
                  value: value,
                  icon: value == kObituaryGenderMale
                      ? Icons.male_rounded
                      : Icons.female_rounded,
                  selected: _gender == value,
                  onTap: () => setState(() {
                    _gender = value;
                    _genderError = null;
                  }),
                ),
              ),
            ],
          ],
        ),
        if (_genderError != null) ...[
          const SizedBox(height: 6),
          _FormErrorLine(message: _genderError!, keyName: 'obituary-gender-error'),
        ],
      ],
    );
  }

  Widget _buildLocationsCard(ThemeData theme) {
    return _SectionCard(
      title: 'أماكن الدفن والعزاء',
      icon: Icons.location_on_rounded,
      children: [
        _buildTextField(
          controller: _funeralLocationController,
          label: 'صلاة الجنازة',
          hint: 'مثال: مسجد القرية الكبير',
          icon: Icons.mosque_rounded,
        ),
        const SizedBox(height: 12),
        _buildTimeAndPrayerRow(
          theme: theme,
          timeKeyName: 'funeral-time-field',
          prayerKeyName: 'funeral-prayer-field',
          timeLabel: 'موعد صلاة الجنازة',
          time: _funeralTime,
          savedTimeLabel: _savedFuneralTime,
          onPickTime: _pickFuneralTime,
          prayer: _funeralPrayer,
          onPickPrayer: (v) => setState(() => _funeralPrayer = v),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _burialLocationController,
          label: 'مكان الدفن',
          hint: 'مثال: مقابر القرية',
          icon: Icons.terrain_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _condolenceLocationController,
          label: 'مكان العزاء',
          hint: 'مثال: منزل العائلة، شارع الملك فهد',
          icon: Icons.home_rounded,
        ),
        const SizedBox(height: 12),
        _buildTimeAndPrayerRow(
          theme: theme,
          timeKeyName: 'condolence-time-field',
          prayerKeyName: 'condolence-prayer-field',
          timeLabel: 'موعد العزاء',
          time: _condolenceTime,
          savedTimeLabel: _savedCondolenceTime,
          onPickTime: _pickCondolenceTime,
          prayer: _condolencePrayer,
          onPickPrayer: (v) => setState(() => _condolencePrayer = v),
        ),
      ],
    );
  }

  /// الوقت واسم الصلاة **بجوار بعضهما** في صف واحد كما طلب المستخدم، فيُقرأ
  /// الموعد وصلاته معًا من نظرة واحدة على أي عرض شاشة.
  Widget _buildTimeAndPrayerRow({
    required ThemeData theme,
    required String timeKeyName,
    required String prayerKeyName,
    required String timeLabel,
    required TimeOfDay? time,
    required String savedTimeLabel,
    required VoidCallback onPickTime,
    required String prayer,
    required ValueChanged<String> onPickPrayer,
  }) {
    // «10:30 ص» قصيرة و«صلاة الظهر» أطول، والمنتقي يخصم سهمه من عرضه:
    // فالتقسيم ١١/٩ هو ما يُبقي تسمية الوقت كاملة والصلاة كاملة معًا.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: _buildTimeField(
            theme: theme,
            keyName: timeKeyName,
            label: timeLabel,
            value: time,
            onTap: onPickTime,
            savedLabel: savedTimeLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 9,
          child: _buildPrayerField(
            keyName: prayerKeyName,
            value: prayer,
            onChanged: onPickPrayer,
          ),
        ),
      ],
    );
  }

  /// اختيار اسم الصلاة لا كتابة: القيم الخمس مع «بدون» للسجل الذي لا يُحدَّد
  /// فيه صلاة، فيبقى الحقل نصًا عربيًا مختصرًا كما عُرِض.
  Widget _buildPrayerField({
    required String keyName,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: Key(keyName),
      initialValue: kObituaryPrayers.contains(value) ? value : '',
      isExpanded: true,
      iconSize: 18,
      // حجم ١٤ بلا لون = أسود: `style` يستبدل نمط النص كاملًا فلا يرث لون
      // الثيم، فيُمرَّر اللون صراحةً ليبقى مثل نص حقل الوقت المجاور.
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: const InputDecoration(
        labelText: 'الصلاة',
        contentPadding:
            EdgeInsetsDirectional.only(start: 8, end: 2, top: 14, bottom: 14),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('بدون')),
        ...kObituaryPrayers
            .map((p) => DropdownMenuItem(value: p, child: Text(p))),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }

  /// حقل وقت لا كتابة فيه: الضغط يفتح `showTimePicker` والقيمة تُخزَّن نصًا.
  /// `savedLabel` هو الموعد المحفوظ في السجل عند التعديل — يعرض ويُحفظ كما هو
  /// ما لم يختر المستخدم وقتًا جديدًا.
  Widget _buildTimeField({
    required ThemeData theme,
    required String keyName,
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
    String savedLabel = '',
  }) {
    final shown = value != null ? obituaryTimeLabel(value) : savedLabel;
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(Icons.schedule_rounded, color: theme.colorScheme.primary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Text(
          shown.isEmpty ? 'اختر الوقت' : shown,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: shown.isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildRelativesSection(ThemeData theme) {
    return _SectionCard(
      title: _gender == kObituaryGenderFemale ? 'قريبات المتوفاة' : 'أقارب المتوفى',
      icon: Icons.family_restroom_rounded,
      children: [
        Text(
          'كل مجموعة تقبل أسماء متعددة — اكتب الاسم ثم اضغط «إضافة». '
          'العناوين تتبدّل تلقائيًا بحسب نوع المتوفى، وإن لم تندرج القرابة تحت '
          'المجموعات فاكتب نوعها بنفسك في الكتلة الأخيرة.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (_gender.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'اختر نوع المتوفى أولًا في «بيانات المتوفى» حتى تظهر عناوين المجموعات '
              'بصيغتها الصحيحة (عم كلاً من / عمّة كلاً من …).',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          for (final group in kObituaryRelativeGroups)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RelativeGroupEditor(
                key: ValueKey('rel-group-${group.name}'),
                group: group,
                gender: _gender,
                names: _namesOf(group),
                onAdd: (name) => _addRelativeName(group, name),
                onRemove: (name) => _removeRelativeName(group, name),
              ),
            ),
        const SizedBox(height: 12),
        // بلا بوابة على النوع: العنوان هنا مكتوب حرفيًا فلا يُصرَّف بالنوع،
        // فيجوز إضافته حتى قبل اختيار رجل/امرأة.
        _CustomRelativeEditor(
          key: const ValueKey('rel-group-custom'),
          entries: _customRelatives,
          onAdd: _addCustomRelative,
          onRemove: _removeCustomRelative,
        ),
      ],
    );
  }

  /// خلفيات البطاقة: الصور الأربع المخصصة للعزاء + خلفية أضافها المستخدم،
  /// فيُخزَّن المفتاح للصور الأربع والرابط للخلفية المضافة.
  Widget _buildBackgroundCard(ThemeData theme) {
    return _SectionCard(
      title: 'خلفية بطاقة المشاركة',
      icon: Icons.wallpaper_rounded,
      children: [
        Text(
          'اختر إحدى صور العزاء الأربع، أو أضف صورتك الخاصة لتصبح خلفية البطاقة المُشارَكة',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < kObituaryCardBackgroundKeys.length; i++)
              _BackgroundOption(
                keyName: 'card-bg-${kObituaryCardBackgroundKeys[i]}',
                label: kObituaryCardBackgroundLabels[i],
                assetPath:
                    kObituaryCardBackgrounds[kObituaryCardBackgroundKeys[i]]!,
                selected: _cardBackground == kObituaryCardBackgroundKeys[i],
                onTap: () => setState(
                    () => _cardBackground = kObituaryCardBackgroundKeys[i]),
              ),
            if (_customBackground != null)
              _BackgroundOption(
                keyName: 'card-bg-custom',
                label: 'خلفيتي',
                imageUrl: _customBackground!,
                selected: _cardBackground == _customBackground,
                onTap: () => setState(
                    () => _cardBackground = _customBackground!),
              ),
            _BackgroundAddOption(
              busy: _bgUploading,
              onTap: _bgUploading ? null : _pickAndUploadBackground,
            ),
          ],
        ),
        if (_bgError != null) ...[
          const SizedBox(height: 12),
          _FormErrorLine(message: _bgError!, keyName: 'obituary-bg-error'),
        ],
      ],
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
    return _SectionCard(
      title: 'نبذة عن المتوفى',
      icon: Icons.description_rounded,
      children: [
        _buildTextField(
          controller: _descriptionController,
          label: 'نبذة (اختياري)',
          hint: 'كلمات عن حياة المتوفى وسيرته...',
          icon: Icons.description_outlined,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final obituary = _buildPreviewObituary();
    return _SectionCard(
      title: 'معاينة بطاقة المشاركة',
      icon: Icons.preview_rounded,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 620),
              child: SingleChildScrollView(
                child: Center(
                  child: ObituaryShareCardPreview(
                    obituary: obituary,
                    width: constraints.maxWidth < 300
                        ? 300
                        : constraints.maxWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => ShareService.shareObituaryAsImage(context, obituary),
            icon: const Icon(Icons.image_outlined),
            label: const Text('مشاركة كصورة'),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _submit,
        icon: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 24),
        // بدون لون مخصص: النص يرث لون الزر (أبيض) لا لون الثيم البني
        label: Text(
            _isSaving
                ? (_isEdit ? 'جاري الحفظ...' : 'جاري الإرسال...')
                : (_isEdit ? 'حفظ التعديلات' : 'إرسال التعزية للمراجعة'),
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField({
    required ThemeData theme,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Text(
          value == null ? 'اختر التاريخ' : DateFormat('yyyy/MM/dd').format(value),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// توقيت عربي مستقل عن إعدادات اللغة: «10 ص»، «10:30 ص»، «12 ص» لمنتصف الليل.
String obituaryTimeLabel(TimeOfDay t) {
  final suffix = t.hour < 12 ? 'ص' : 'م';
  var h12 = t.hour % 12;
  if (h12 == 0) h12 = 12;
  return t.minute == 0
      ? '$h12 $suffix'
      : '$h12:${t.minute.toString().padLeft(2, '0')} $suffix';
}

class _ObituaryGenderOption extends StatelessWidget {
  const _ObituaryGenderOption({
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Material(
      key: Key('obituary-gender-$value'),
      color: selected ? color.withValues(alpha: 0.12) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : theme.colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20, color: selected ? color : theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(value,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? color : theme.colorScheme.onSurface,
                  )),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// سطر خطأ أحمر دائم داخل النموذج، بمفتاح نصي واحد.
class _FormErrorLine extends StatelessWidget {
  const _FormErrorLine({required this.message, required this.keyName});

  final String message;
  final String keyName;

  @override
  Widget build(BuildContext context) => Text(
        message,
        key: Key(keyName),
        style: const TextStyle(
            color: Color(0xFFB71C1C),
            fontSize: 12.5,
            fontWeight: FontWeight.w700),
      );
}

/// محرر مجموعة قرابة واحدة: عنوان مصروف بحسب النوع + حقل اسم تقبل إضافة
/// متكررة + رقائق للأسماء المضافة يمكن حذف أي منها.
class _RelativeGroupEditor extends StatefulWidget {
  const _RelativeGroupEditor({
    super.key,
    required this.group,
    required this.gender,
    required this.names,
    required this.onAdd,
    required this.onRemove,
  });

  final RelativeType group;
  final String gender;
  final List<String> names;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_RelativeGroupEditor> createState() => _RelativeGroupEditorState();
}

class _RelativeGroupEditorState extends State<_RelativeGroupEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitName() {
    final name = _controller.text.trim();
    // الرفض ورسالته عند الأب وحده؛ الصمت هنا كان يجعل زر «الإضافة» بلا رد
    // حين يضغطه من لم يكتب اسمًا بعد.
    widget.onAdd(name);
    if (name.isNotEmpty) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(group.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(group.labelFor(widget.gender),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (widget.names.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${widget.names.length}',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: Key('relative-name-${group.name}'),
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitName(),
            decoration: InputDecoration(
              isDense: true,
              hintText: group.hintFor(widget.gender),
              hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                key: Key('relative-add-${group.name}'),
                icon: Icon(Icons.add_rounded,
                    color: theme.colorScheme.primary, size: 22),
                onPressed: _submitName,
              ),
            ),
          ),
          if (widget.names.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final name in widget.names)
                  InputChip(
                    key: Key('relative-chip-${group.name}-$name'),
                    label: Text(name,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                    onDeleted: () => widget.onRemove(name),
                    deleteIconColor: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// كتلة «قرابة أخرى — اكتبها بنفسك»: خانتان متجاورتان لنوع القرابة المكتوب
/// واسم القريب، ورقاقة «النوع: الاسم» لكل إدخال تُحذف وحدها. النوع نصّ مخزَّن
/// كما كُتب، فيظهر في البطاقة والتفاصيل ولوحة الإدارة بعنوانه الحرفي.
class _CustomRelativeEditor extends StatefulWidget {
  const _CustomRelativeEditor({
    super.key,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Relative> entries;
  final bool Function(String type, String name) onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_CustomRelativeEditor> createState() => _CustomRelativeEditorState();
}

class _CustomRelativeEditorState extends State<_CustomRelativeEditor> {
  final _typeController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _typeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final type = _typeController.text.trim();
    final name = _nameController.text.trim();
    // الرفض ورسالته عند الأب وحده — رسالتان مختلفتان لنقص النوع ونقص الاسم —
    // والحقلان يبقيان كما كتبتْهما اليد فلا يُفقد إدخال على رفض.
    if (widget.onAdd(type, name)) {
      _typeController.clear();
      _nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('قرابة أخرى — اكتبها بنفسك',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              if (widget.entries.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${widget.entries.length}',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'مثال: «جار» باسم، أو «عمّ والد» باسم — يظهر كما كتبته تمامًا.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('relative-custom-type'),
                  controller: _typeController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'نوع القرابة',
                    hintText: 'اكتبه بنفسك',
                    labelStyle: TextStyle(fontSize: 12.5),
                    hintStyle: TextStyle(fontSize: 12),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  key: const Key('relative-custom-name'),
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'اسم القريب',
                    hintText: 'الاسم ثم إضافة',
                    labelStyle: TextStyle(fontSize: 12.5),
                    hintStyle: TextStyle(fontSize: 12),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              key: const Key('relative-custom-add'),
              onPressed: _submit,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('إضافة هذه القرابة',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          if (widget.entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in widget.entries)
                  InputChip(
                    key: Key('relative-custom-chip-${entry.id}'),
                    label: Text('${entry.typeLabel.trim()}: ${entry.name}',
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                    onDeleted: () => widget.onRemove(entry.id),
                    deleteIconColor: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// اختيار خلفية البطاقة: مصغّرة من أصل azaa أو من صورة رفعها المستخدم، مع
/// تحديد واضح للخيار المختار.
class _BackgroundOption extends StatelessWidget {
  const _BackgroundOption({
    required this.keyName,
    required this.label,
    this.assetPath,
    this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final String? assetPath;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = imageUrl;
    return GestureDetector(
      key: Key(keyName),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2.4 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 84,
                width: double.infinity,
                child: link == null
                    ? Image.asset(assetPath!,
                        fit: BoxFit.cover, cacheWidth: 258)
                    : CachedNetworkImage(
                        imageUrl: link,
                        fit: BoxFit.cover,
                        memCacheWidth: 258,
                        placeholder: (context, _) => ColoredBox(
                            color:
                                theme.colorScheme.surfaceContainerHighest),
                        errorWidget: (context, _, __) => ColoredBox(
                            color:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.broken_image_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

/// بلاطة «أضف خلفيتك» في نهاية القائمة: تفتح المعرض وترفع الصورة، فتصير
/// اختيارًا مثل الصور الأربع.
class _BackgroundAddOption extends StatelessWidget {
  const _BackgroundAddOption({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: const Key('card-bg-add'),
      onTap: onTap,
      child: Container(
        width: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.55)),
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 84,
              width: double.infinity,
              child: Center(
                child: busy
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(Icons.add_a_photo_rounded,
                        size: 26, color: theme.colorScheme.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(busy ? 'جاري الرفع' : 'أضف صورة',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(icon, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}