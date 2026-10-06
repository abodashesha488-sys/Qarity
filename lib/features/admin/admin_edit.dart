import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/firebase_ts.dart';
import '../../models/data_models.dart';
import '../../services/admin_service.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة تعديل الأدمن لأي عنصر — تُظهر **كل** حقول الوثيقة لا ما تعرفه القائمة
/// فقط، وتُدير الصور (معاينة وحذف ورفع ولصق رابط) في مواضعها كلها.
class AdminEditScreen extends StatefulWidget {
  final String collection;
  final String docId;
  final Map<String, dynamic> item;
  final AdminService? service;

  const AdminEditScreen(
      {super.key,
      required this.collection,
      required this.docId,
      required this.item,
      this.service});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final DocumentEditor _editor = DocumentEditor();
  late final List<DocFieldSpec> _fields;
  bool _isSaving = false;

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
          DocFieldSpec('offerPrice', 'سعر العرض',
              kind: DocFieldKind.number),
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
          DocFieldSpec('userName', 'اسم صاحب السؤال'),
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

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final f in _fields)
        DocFieldRow(editor: _editor, spec: f, onChanged: () => setState(() {})),
    ];
    return Scaffold(
      appBar: QurityAppBar(
        title: 'تعديل',
        actions: [
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
          ...rows,
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
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات',
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
        ],
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
