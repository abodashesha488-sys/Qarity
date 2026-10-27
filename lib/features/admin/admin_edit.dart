import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/firebase_ts.dart';
import '../../models/data_models.dart';
import '../../models/service_provider_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';
import '../services/service_directory_screen.dart';

/// شاشة تعديل الأدمن لأي عنصر — تُظهر **كل** حقول الوثيقة لا ما تعرفه القائمة
/// فقط، وتُدير الصور (معاينة وحذف ورفع ولصق رابط) في مواضعها كلها.
class AdminEditScreen extends StatefulWidget {
  final String collection;
  final String docId;
  final Map<String, dynamic> item;
  final AdminService? service;
  final bool useRawEditor;

  const AdminEditScreen({
    super.key,
    required this.collection,
    required this.docId,
    required this.item,
    this.service,
    this.useRawEditor = false,
  });

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final DocumentEditor _editor = DocumentEditor();
  late final List<DocFieldSpec> _fields;
  bool _isSaving = false;
  late bool _showRawEditor = widget.useRawEditor;

  @override
  void initState() {
    super.initState();
    _fields = _buildFields();
    _editor.seed(_fields, widget.item);
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  /// الحقول المسمّاة للمجموعة + كل ما تبقى في الوثيقة من مفاتيح.
  List<DocFieldSpec> _buildFields() {
    final named = _namedFieldsFor(widget.collection);
    return [
      ...named,
      ...deriveMissingFields(
          widget.item, named.map((f) => f.key).toSet())
    ];
  }

  List<DocFieldSpec> _namedFieldsFor(String c) {
    switch (c) {
      case 'news':
        return const [
          DocFieldSpec('title', 'العنوان', required: true),
          DocFieldSpec('subtitle', 'المحتوى',
              kind: DocFieldKind.multiline),
          DocFieldSpec('category', 'التصنيف'),
          DocFieldSpec('authorName', 'اسم الكاتب'),
          DocFieldSpec('imageUrls', 'صور الخبر',
              kind: DocFieldKind.images, maxImages: 3),
          DocFieldSpec('imageUrl', 'الصورة الرئيسية',
              kind: DocFieldKind.image),
        ];
      case 'market_products':
        return const [
          DocFieldSpec('name', 'اسم المنتج', required: true),
          DocFieldSpec('description', 'الوصف',
              kind: DocFieldKind.multiline),
          DocFieldSpec('price', 'السعر', kind: DocFieldKind.number),
          DocFieldSpec('isOnOffer', 'تفعيل العرض والتخفيض',
              kind: DocFieldKind.boolean),
          DocFieldSpec('offerPrice', 'سعر العرض',
              kind: DocFieldKind.number),
          DocFieldSpec('isFeatured', 'منتج مميز (يظهر في البانر العلوي)',
              kind: DocFieldKind.boolean),
          DocFieldSpec('category', 'الفئة'),
          DocFieldSpec('stock', 'المخزون', kind: DocFieldKind.number),
          DocFieldSpec('sellerName', 'اسم البائع'),
          DocFieldSpec('sellerPhone', 'هاتف البائع'),
          DocFieldSpec('imageUrls', 'صور المنتج',
              kind: DocFieldKind.images),
          DocFieldSpec('imageUrl', 'الصورة الرئيسية',
              kind: DocFieldKind.image),
        ];
      case 'obituaries':
        return const [
          DocFieldSpec('name', 'اسم المتوفى', required: true),
          DocFieldSpec('gender', 'نوع المتوفى (رجل أو امرأة)'),
          DocFieldSpec('dateOfDeath', 'تاريخ الوفاة'),
          DocFieldSpec('funeralDate', 'تاريخ صلاة الجنازة'),
          DocFieldSpec('funeralLocation', 'مكان صلاة الجنازة'),
          DocFieldSpec('funeralTime', 'موعد صلاة الجنازة (مثال: 10:30 ص)'),
          DocFieldSpec('funeralPrayer',
              'صلاة الجنازة (صلاة الظهر / العصر / المغرب / العشاء / الفجر)'),
          DocFieldSpec('burialLocation', 'مكان الدفن'),
          DocFieldSpec('condolenceLocation', 'مكان العزاء'),
          DocFieldSpec('condolenceTime', 'موعد العزاء (مثال: 8 م)'),
          DocFieldSpec('condolencePrayer',
              'صلاة العزاء (صلاة الظهر / العصر / المغرب / العشاء / الفجر)'),
          DocFieldSpec('imageUrl', 'صورة المتوفى',
              kind: DocFieldKind.image),
          DocFieldSpec('cardBackground',
              'خلفية البطاقة (azaa1 / azaa2 / azaa3 / azaa4 أو رابط صورة)'),
          DocFieldSpec('age', 'العمر (حقل قديم)'),
          DocFieldSpec('mosque', 'المسجد (حقل قديم)'),
          DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
        ];
      case 'occasions':
        return const [
          DocFieldSpec('title', 'العنوان', required: true),
          DocFieldSpec('description', 'الوصف',
              kind: DocFieldKind.multiline),
          DocFieldSpec('date', 'التاريخ'),
          DocFieldSpec('location', 'المكان'),
          DocFieldSpec('organizer', 'المنظم'),
          DocFieldSpec('imageUrl', 'صورة المناسبة',
              kind: DocFieldKind.image),
        ];
      case 'forum_posts':
        return const [
          DocFieldSpec('title', 'العنوان'),
          DocFieldSpec('content', 'المحتوى',
              required: true, kind: DocFieldKind.multiline),
          DocFieldSpec('category', 'التصنيف'),
          DocFieldSpec('userName', 'اسم الناشر'),
          DocFieldSpec('imageUrl', 'صورة المنشور',
              kind: DocFieldKind.image),
        ];
      case 'phone_directory':
        return const [
          DocFieldSpec('name', 'الاسم', required: true),
          DocFieldSpec('title', 'المسمى/اللقب'),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('secondaryPhone', 'هاتف إضافي'),
          DocFieldSpec('job', 'الوظيفة'),
          DocFieldSpec('address', 'العنوان'),
          DocFieldSpec('email', 'البريد'),
          DocFieldSpec('photoUrl', 'صورة الرقم',
              kind: DocFieldKind.image),
          DocFieldSpec('isPublic', 'ظاهر للجميع',
              kind: DocFieldKind.boolean),
        ];
      case 'shops':
        return const [
          DocFieldSpec('name', 'اسم المحل', required: true),
          DocFieldSpec('category', 'التصنيف'),
          DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
          DocFieldSpec('whatsapp', 'واتساب للتواصل'),
          DocFieldSpec('ownerName', 'اسم المالك'),
          DocFieldSpec('imageUrls', 'صور المحل', kind: DocFieldKind.images),
          DocFieldSpec('isActive', 'نشط', kind: DocFieldKind.boolean),
        ];
      case 'seller_profiles':
        return const [
          DocFieldSpec('name', 'اسم المتجر', required: true),
          DocFieldSpec('bio', 'نبذة', kind: DocFieldKind.multiline),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('address', 'العنوان'),
          DocFieldSpec('isVerified', 'موثّق', kind: DocFieldKind.boolean),
        ];
      case 'village_clinics':
        return const [
          DocFieldSpec('name', 'اسم العيادة', required: true),
          DocFieldSpec('specialty', 'التخصص'),
          DocFieldSpec('ownerName', 'اسم الطبيب'),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('address', 'العنوان'),
          DocFieldSpec('workingHours', 'مواعيد العمل'),
          DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
          DocFieldSpec('imageUrls', 'صور العيادة',
              kind: DocFieldKind.images),
        ];
      case 'pharmacies':
        return const [
          DocFieldSpec('name', 'اسم الصيدلية', required: true),
          DocFieldSpec('ownerName', 'الصيدلي/المسؤول'),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('address', 'العنوان'),
          DocFieldSpec('workingHours', 'مواعيد العمل'),
          DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
          DocFieldSpec('imageUrls', 'صور الصيدلية',
              kind: DocFieldKind.images),
          DocFieldSpec('is24Hours', '٢٤ ساعة',
              kind: DocFieldKind.boolean),
        ];
      case 'medical_labs':
        return const [
          DocFieldSpec('name', 'اسم المعمل', required: true),
          DocFieldSpec('category', 'نوع التحاليل'),
          DocFieldSpec('ownerName', 'المسؤول / مدير المعمل'),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('address', 'العنوان'),
          DocFieldSpec('workingHours', 'مواعيد العمل'),
          DocFieldSpec('homeCollection', 'سحب عينات بالمنزل',
              kind: DocFieldKind.boolean),
          DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
          DocFieldSpec('imageUrls', 'صور المعمل',
              kind: DocFieldKind.images),
        ];
      case 'optical_shops':
        return const [
          DocFieldSpec('name', 'اسم محل النظارات', required: true),
          DocFieldSpec('ownerName', 'صاحب المحل / المسؤول'),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('address', 'العنوان'),
          DocFieldSpec('workingHours', 'مواعيد العمل'),
          DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
          DocFieldSpec('categories', 'تصنيفات المحل',
              kind: DocFieldKind.list),
          DocFieldSpec('imageUrls', 'صور المحل', kind: DocFieldKind.images),
          DocFieldSpec('adType', 'نوع الإعلان (normal / featured)'),
        ];
      case 'blood_requests':
        return const [
          DocFieldSpec('patientName', 'اسم المريض', required: true),
          DocFieldSpec('bloodType', 'الفصيلة'),
          DocFieldSpec('units', 'عدد الوحدات',
              kind: DocFieldKind.number),
          DocFieldSpec('hospital', 'المستشفى/المكان'),
          DocFieldSpec('phone', 'هاتف التواصل'),
          DocFieldSpec('urgency', 'درجة الأهمية'),
          DocFieldSpec('notes', 'ملاحظات', kind: DocFieldKind.multiline),
          DocFieldSpec('requesterName', 'اسم مقدم الطلب'),
        ];
      case 'blood_donors':
        return const [
          DocFieldSpec('name', 'اسم المتبرع', required: true),
          DocFieldSpec('bloodType', 'الفصيلة'),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('age', 'السن', kind: DocFieldKind.number),
          DocFieldSpec('gender', 'النوع'),
          DocFieldSpec('address', 'العنوان'),
          DocFieldSpec('isAvailable', 'متبرع متاح',
              kind: DocFieldKind.boolean),
        ];
      case 'service_providers':
        // حقول السجل التعليمي (اختيار متعدد) تظهر لسجل التعليمية فقط.
        final isEdu = widget.item['category'] == 'educational';
        return [
          DocFieldSpec(
              'name',
              isEdu ? 'اسم المدرّس / اسم المدرسة' : 'الاسم / اسم الورشة',
              required: true),
          // الفئة تحسم **أي صفحة مستقلة** يظهر فيها السجل.
          const DocFieldSpec('category',
              'الصفحة (technicians = دليل الحرفيين / agricultural = خدمات زراعية / educational = خدمات تعليمية)'),
          if (isEdu) ...[
            const DocFieldSpec('providerKind', 'الصفة (مدرس / مدرسة)'),
            const DocFieldSpec(
                'eduTypes', 'أنواع التعليم (تعليم عام، أزهري، خاص)',
                kind: DocFieldKind.list),
            const DocFieldSpec(
                'stages', 'المراحل (تمهيدي، ابتدائي، إعدادي، ثانوي، جامعي)',
                kind: DocFieldKind.list),
            const DocFieldSpec('subjects', 'المواد الدراسية',
                kind: DocFieldKind.list),
            const DocFieldSpec('universityNote', 'التخصص الجامعي',
                kind: DocFieldKind.multiline),
            const DocFieldSpec('offersPrivateTutoring',
                'تدريس خاص (دروس خصوصية)',
                kind: DocFieldKind.boolean),
          ] else
            const DocFieldSpec('specialty', 'الحرفة / الخدمة'),
          const DocFieldSpec('phone', 'الهاتف'),
          const DocFieldSpec('photoUrl', 'صورة السجل',
              kind: DocFieldKind.image),
          const DocFieldSpec('address', 'العنوان'),
          const DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
          const DocFieldSpec('isFeatured',
              'بيان مميز (يظهر ذهبيًا وفي المقدمة)',
              kind: DocFieldKind.boolean),
        ];
      case 'lost_items':
        return const [
          DocFieldSpec('title', 'اسم الغرض', required: true),
          DocFieldSpec('type', 'النوع (lost/found)'),
          DocFieldSpec('description', 'الوصف',
              kind: DocFieldKind.multiline),
          DocFieldSpec('location', 'المكان'),
          DocFieldSpec('phone', 'هاتف التواصل'),
          DocFieldSpec('userName', 'اسم صاحب الإعلان'),
          DocFieldSpec('imageUrl', 'صورة الغرض', kind: DocFieldKind.image),
          DocFieldSpec('isResolved', 'تم التسليم (مغلق)',
              kind: DocFieldKind.boolean),
        ];
      case 'village_ads':
        return const [
          DocFieldSpec('title', 'عنوان الإعلان', required: true),
          DocFieldSpec('kind', 'النوع (تجارية / خدمية / إنشائية)'),
          DocFieldSpec('businessName', 'اسم النشاط'),
          DocFieldSpec('description', 'نص الإعلان',
              kind: DocFieldKind.multiline),
          DocFieldSpec('location', 'المكان'),
          DocFieldSpec('phone', 'هاتف التواصل'),
          DocFieldSpec('userName', 'اسم صاحب الإعلان'),
          DocFieldSpec('imageUrls', 'صور الإعلان',
              kind: DocFieldKind.images, maxImages: 3),
        ];
      case 'lawyers':
        return const [
          DocFieldSpec('name', 'اسم المحامي', required: true),
          DocFieldSpec('phone', 'الهاتف'),
          DocFieldSpec('specializations', 'التخصصات (افصل بينها بفاصلة)',
              kind: DocFieldKind.list),
          DocFieldSpec('office', 'المكتب / العنوان'),
          DocFieldSpec('workingHours', 'مواعيد العمل'),
          DocFieldSpec('photoUrl', 'صورة المحامي',
              kind: DocFieldKind.image),
          DocFieldSpec('bio', 'نبذة', kind: DocFieldKind.multiline),
          DocFieldSpec('submittedByName', 'اسم مقدّم التسجيل'),
        ];
      case 'legal_consultations':
        return const [
          DocFieldSpec('question', 'نص السؤال',
              required: true, kind: DocFieldKind.multiline),
          DocFieldSpec('details', 'تفاصيل إضافية',
              kind: DocFieldKind.multiline),
          DocFieldSpec('category', 'التصنيف (أحوال شخصية / قضايا جنائية / …)'),
          DocFieldSpec('answer', 'رد المستشار (يظهر للقرية)',
              kind: DocFieldKind.multiline),
          DocFieldSpec('answeredByName', 'صفة / اسم المستشار الراد'),
          DocFieldSpec('userName', 'اسم صاحب السؤال'),
        ];
      case 'agriculture_consultations':
        return const [
          DocFieldSpec('question', 'موضوع الاستشارة',
              required: true, kind: DocFieldKind.multiline),
          DocFieldSpec('details', 'تفاصيل المشكلة / الأعراض',
              kind: DocFieldKind.multiline),
          DocFieldSpec('category', 'التصنيف (زراعة محصول / آفات / …)'),
          DocFieldSpec('cropName', 'اسم المحصول'),
          DocFieldSpec('answer', 'رد المستشار الزراعي (يظهر للقرية)',
              kind: DocFieldKind.multiline),
          DocFieldSpec('answeredByName', 'صفة / اسم المستشار الراد'),
          DocFieldSpec('userName', 'اسم صاحب الاستشارة'),
        ];
      case 'medical_center_clinics':
        return const [
          DocFieldSpec('name', 'اسم العيادة', required: true),
          DocFieldSpec('specialty', 'التخصص'),
          DocFieldSpec('doctorName', 'اسم الطبيب'),
          DocFieldSpec('workingHours', 'مواعيد العمل'),
          DocFieldSpec('fees', 'الأجر الرمزي', kind: DocFieldKind.number),
          DocFieldSpec('description', 'نبذة',
              kind: DocFieldKind.multiline),
          DocFieldSpec('imageUrl', 'صورة العيادة', kind: DocFieldKind.image),
          DocFieldSpec('isActive', 'ظاهرة للجمهور',
              kind: DocFieldKind.boolean),
        ];
      case 'service_requests':
        return const [
          DocFieldSpec('type', 'نوع الطلب', required: true),
          DocFieldSpec('description', 'الوصف',
              kind: DocFieldKind.multiline),
          DocFieldSpec('location', 'الموقع'),
          DocFieldSpec('status',
              'الحالة (pending/in_progress/completed/cancelled)'),
          DocFieldSpec('notes', 'ملاحظات', kind: DocFieldKind.multiline),
          DocFieldSpec('userName', 'اسم مقدم الطلب'),
        ];
      case 'product_reviews':
      case 'reviews':
        return const [
          DocFieldSpec('comment', 'نص المراجعة',
              kind: DocFieldKind.multiline),
          DocFieldSpec('rating', 'التقييم (1-5)',
              kind: DocFieldKind.number),
          DocFieldSpec('userName', 'اسم المراجع'),
          DocFieldSpec('imageUrl', 'صورة المراجعة',
              kind: DocFieldKind.image),
        ];
      case 'donations':
        return const [
          DocFieldSpec('title', 'اسم السلعة', required: true),
          DocFieldSpec('description', 'الوصف',
              kind: DocFieldKind.multiline),
          DocFieldSpec('category', 'التصنيف'),
          DocFieldSpec('contactPhone', 'هاتف التواصل'),
          DocFieldSpec('status', 'الحالة (available/donated)'),
          DocFieldSpec('imageUrls', 'صور السلعة', kind: DocFieldKind.images),
        ];
      case 'buy_requests':
        return const [
          DocFieldSpec('title', 'العنوان', required: true),
          DocFieldSpec('details', 'التفاصيل',
              kind: DocFieldKind.multiline),
          DocFieldSpec('budget', 'الميزانية'),
          DocFieldSpec('status', 'الحالة (open/closed)'),
          DocFieldSpec('imageUrls', 'صور الطلب', kind: DocFieldKind.images),
        ];
      default:
        return const [];
    }
  }

  Future<void> _save() async {
    final missing = _editor.missingRequiredLabel(_fields);
    if (missing != null) {
      _toast('الحقل مطلوب: $missing', error: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final data = _editor.collect(_fields);
      // حفظ التعديلات يعتمد البيان مباشرة لسهولة النشر دون حاجة لزر إضافي
      data['isApproved'] = true;
      // المرآتان اللتان تقرأهما الواجهات القديمة والشرائح المثبّتة.
      syncImageMirrors(_fields, data);
      if (widget.collection == 'market_products') {
        stampOfferWindow(widget.item, data);
      }
      if (widget.collection == 'service_providers') {
        final subjects = data['subjects'];
        final stages = data['stages'];
        if (subjects is List && subjects.isNotEmpty) {
          data['specialty'] = subjects.join('، ');
        }
        if (stages is List && stages.isNotEmpty) {
          data['stage'] = stages.join('، ');
        }
      }
      await (widget.service ?? AdminService())
          .updateItem(widget.collection, widget.docId, data);
      if (mounted) {
        _toast('تم الحفظ بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _toast('خطأ: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primary));
  }

  static String _sectionForField(DocFieldSpec f) {
    if (f.key == 'relatives') return 'relatives';
    if (f.kind == DocFieldKind.image ||
        f.kind == DocFieldKind.images ||
        f.key == 'cardBackground') {
      return 'images';
    }
    if (f.kind == DocFieldKind.readOnly) return 'system';

    final k = f.key.toLowerCase();
    if (isDateFieldKey(f.key) || isTimeFieldKey(f.key) || k.contains('prayer')) {
      return 'dates';
    }
    if (k.contains('phone') ||
        k.contains('location') ||
        k.contains('address') ||
        k.contains('hospital') ||
        k.contains('office') ||
        k.contains('whatsapp')) {
      return 'contact';
    }
    if (f.kind == DocFieldKind.boolean ||
        k.contains('category') ||
        k.contains('kind') ||
        k.contains('type') ||
        k.contains('status') ||
        k.contains('price') ||
        k.contains('offer') ||
        k.contains('stock') ||
        k.contains('budget') ||
        k.contains('fees') ||
        k.contains('urgency') ||
        k.contains('bloodtype') ||
        k.contains('gender') ||
        k.contains('stage') ||
        k.contains('subject') ||
        k.contains('specialty') ||
        k.contains('specialization') ||
        k.contains('rating')) {
      return 'options';
    }
    return 'basic';
  }

  String _collectionName(String c) {
    switch (c) {
      case 'news':
        return 'الأخبار';
      case 'market_products':
        return 'سوق القرية';
      case 'obituaries':
        return 'الوفيات والتعازي';
      case 'occasions':
        return 'المناسبات';
      case 'forum_posts':
        return 'منتدى القرية';
      case 'phone_directory':
        return 'دليل الهواتف';
      case 'village_clinics':
        return 'عيادات القرية';
      case 'pharmacies':
        return 'الصيدليات';
      case 'medical_labs':
        return 'معامل التحاليل';
      case 'optical_shops':
        return 'محلات النظارات';
      case 'medical_center_clinics':
        return 'المركز الطبي الخيري';
      case 'blood_requests':
        return 'طلبات فصائل الدم';
      case 'blood_donors':
        return 'سجل المتبرعين';
      case 'shops':
        return 'المحلات والأنشطة';
      case 'service_providers':
        return 'دليل الحرف والخدمات';
      case 'lost_items':
        return 'المفقودات والمعثورات';
      case 'village_ads':
        return 'إعلانات القرية';
      case 'lawyers':
        return 'دليل المحامين';
      case 'legal_consultations':
        return 'الاستشارات القانونية';
      case 'agriculture_consultations':
        return 'الاستشارات الزراعية';
      case 'service_requests':
        return 'طلبات الخدمات';
      case 'donations':
        return 'التبرعات الخيرية';
      case 'buy_requests':
        return 'طلبات الشراء';
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // تصنيف الحقول في أقسام مطابقة لشاشات الإدخال
    final basicFields = <DocFieldSpec>[];
    final optionsFields = <DocFieldSpec>[];
    final datesFields = <DocFieldSpec>[];
    final imagesFields = <DocFieldSpec>[];
    final contactFields = <DocFieldSpec>[];
    final relativesFields = <DocFieldSpec>[];
    final systemFields = <DocFieldSpec>[];

    for (final f in _fields) {
      switch (_sectionForField(f)) {
        case 'basic':
          basicFields.add(f);
        case 'options':
          optionsFields.add(f);
        case 'dates':
          datesFields.add(f);
        case 'images':
          imagesFields.add(f);
        case 'contact':
          contactFields.add(f);
        case 'relatives':
          relativesFields.add(f);
        case 'system':
          systemFields.add(f);
      }
    }

    Widget buildFieldList(List<DocFieldSpec> list) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list
            .map((f) => DocFieldRow(
                  editor: _editor,
                  spec: f,
                  collection: widget.collection,
                  onChanged: () => setState(() {}),
                ))
            .toList(),
      );
    }

    final isServiceProvider = widget.collection == 'service_providers' ||
        widget.collection.startsWith('tab_svc_');

    if (isServiceProvider && !_showRawEditor) {
      final provider = ServiceProvider.fromJson(widget.item, widget.docId);
      final cat = provider.category.isNotEmpty
          ? provider.category
          : (widget.collection == 'tab_svc_agricultural'
              ? ServiceCategory.agricultural
              : (widget.collection == 'tab_svc_educational'
                  ? ServiceCategory.educational
                  : ServiceCategory.technicians));

      return Scaffold(
        appBar: QurityAppBar(
          title: 'تعديل ${ServiceCategory.label(cat)}',
          actions: [
            IconButton(
              tooltip: 'التبديل إلى محرر الحقول المتقدمة',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => setState(() => _showRawEditor = true),
            ),
          ],
        ),
        body: SafeArea(
          child: ProviderFormSheet(
            category: cat,
            userId: provider.submittedBy ?? '',
            userName: provider.submittedByName ?? '',
            existing: provider,
            isAdmin: true,
            onSave: (updated) async {
              final data = updated.toJson();
              data['isApproved'] = true;
              await (widget.service ?? AdminService()).updateItem(
                'service_providers',
                widget.docId,
                data,
              );
              if (mounted) {
                _toast('تم الحفظ بنجاح');
              }
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: QurityAppBar(
        title: 'تعديل ${_collectionName(widget.collection)}',
        actions: [
          if (isServiceProvider)
            IconButton(
              tooltip: 'التبديل إلى نموذج الخدمة الأساسي',
              icon: const Icon(Icons.dashboard_customize_rounded),
              onPressed: () => setState(() => _showRawEditor = false),
            ),
          TextButton.icon(
            key: const ValueKey('admin-edit-save'),
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('حفظ'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // شريط إرشادي علوي يوضح اعتماد ونشر التعديل فوراً
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded,
                    color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعديل ونشر فوري (${_collectionName(widget.collection)})',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'عند الضغط على حفظ، يتم نشر واعتماد البيان فوراً دون الحاجة لإعادة الموافقة.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (basicFields.isNotEmpty)
            _SectionCard(
              title: 'البيانات الأساسية والمحتوى',
              icon: Icons.article_rounded,
              child: buildFieldList(basicFields),
            ),

          if (optionsFields.isNotEmpty)
            _SectionCard(
              title: 'التصنيف والخيارات والأسعار',
              icon: Icons.tune_rounded,
              child: buildFieldList(optionsFields),
            ),

          if (datesFields.isNotEmpty)
            _SectionCard(
              title: 'المواعيد والتواريخ والصلوات',
              icon: Icons.calendar_month_rounded,
              child: buildFieldList(datesFields),
            ),

          if (contactFields.isNotEmpty)
            _SectionCard(
              title: 'معلومات التواصل والعناوين',
              icon: Icons.contact_phone_rounded,
              child: buildFieldList(contactFields),
            ),

          if (imagesFields.isNotEmpty)
            _SectionCard(
              title: 'الصور والوسائط والمرفقات',
              icon: Icons.photo_library_rounded,
              child: buildFieldList(imagesFields),
            ),

          if (relativesFields.isNotEmpty)
            _SectionCard(
              title: 'أقارب المتوفى ومجموعات القرابة',
              icon: Icons.family_restroom_rounded,
              child: buildFieldList(relativesFields),
            ),

          if (systemFields.isNotEmpty)
            _SectionCard(
              title: 'بيانات النظام والإدارة (للقراءة فقط)',
              icon: Icons.admin_panel_settings_rounded,
              child: buildFieldList(systemFields),
            ),

          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                  _isSaving
                      ? 'جاري الحفظ...'
                      : 'حفظ التعديلات',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// حيثما وُجدت قائمة صور و«صورة رئيسية» في نفس الوثيقة تبقى الصورة الأولى
/// هي المرآة، فالقائمة والواجهات القديمة لا يتفارقان. المستند القديم الذي
/// يحمل `imageUrl` وحده تُملأ قائمته الفارغة منه، لا يُمحى رابطه.
void syncImageMirrors(List<DocFieldSpec> fields, Map<String, dynamic> data) {
  if (!fields.any((f) => f.key == 'imageUrl')) return;
  final urls = data['imageUrls'];
  if (urls is! List) return;
  final single = data['imageUrl'];
  if (urls.isEmpty && single is String && single.isNotEmpty) {
    data['imageUrls'] = [single];
    return;
  }
  data['imageUrl'] = urls.isEmpty ? '' : urls.first.toString();
}

/// العرض الذي لا أجل له يبقى مخفَّضًا إلى الأبد، فالمُحرِّر يكتب العلم وحده.
/// التفعيل الجديد (أو إعادة تفعيل نافذة منتهية) يحصل على نافذة `offerEndsAt`
/// محسوبة الآن، وأما نافذة ما زالت سارية فتُترك كما هي — فحفظ تعديلٍ عرضي
/// كالوصف لا يُمطّط المدة ولا يجدّد شيئًا.
void stampOfferWindow(Map<String, dynamic> item, Map<String, dynamic> data,
    {DateTime? now}) {
  final on = data['isOnOffer'];
  if (on is! bool) return;
  final moment = now ?? DateTime.now();
  if (!on) {
    if (tsToDateTime(item['offerEndsAt']) != null) {
      data['offerStartsAt'] = null;
      data['offerEndsAt'] = null;
    }
    return;
  }
  final ends = tsToDateTime(item['offerEndsAt']);
  if (ends != null && ends.isAfter(moment)) return;
  data.addAll(MarketProduct.offerWindow(moment));
}
