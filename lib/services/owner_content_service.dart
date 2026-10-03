import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cache_service.dart';
import 'content_cleanup_service.dart';
import 'image_upload_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

/// إعداد مجموعة محتوى يملكها مستخدم، كما تمرّ عبر [OwnerContentService].
class OwnerCollectionSpec {
  const OwnerCollectionSpec({
    required this.collection,
    required this.ownerField,
    required this.itemLabel,
    required this.titleField,
    required this.route,
    this.attributionFields = const <String>[],
    this.imageFields = const <String>[],
    this.protectedOnEdit = const <String>[],
    this.cacheKey,
    this.extraWritesOnEdit = const <String, dynamic>{},
  });

  final String collection;

  /// الحقل الذي يحدّد صاحب الإضافة في الوثيقة (`authorId`/`sellerId`/…).
  final String ownerField;

  /// اسم القسم بالعربية لنص الإشعار عند غياب عنوان العنصر.
  final String itemLabel;

  /// الحقل الذي يحمل العنوان المعروض للإشعار.
  final String titleField;

  /// مسار فتح القسم بعد التعديل (قابل للتجاوز عند النداء).
  final String route;

  /// حقول النسبة التي تملكها مزامنة الملف الشخصي؛ تعديل المالك لا يلمسها
  /// أبدًا (هي المحروسة في `firestore.rules` بالمثل).
  final List<String> attributionFields;

  /// حقول الروابط التي يمسحها الحذف من ImgBB (نص أو قائمة نصوص).
  final List<String> imageFields;

  /// حقول يملك قرارها غير تعديل المحتوى: حالة التمييز في لوحة الإدارة،
  /// تفعيل محل، تثبيت منشور، نافذة عرض مميز، حالة إعلان مفقودات…
  /// النموذج يعيد طباعتها من نسخة قرأها وقت فتح الشاشة، فتمريرها مع رقعة
  /// المالك كان يستعمل قرارًا قديمًا ضد ما هو قائم في الوثيقة (أو رفضًا من
  /// القواعد لأن هذه الرخص لا تعدّل المضمون فلا تستحق إعادة مراجعة).
  final List<String> protectedOnEdit;

  /// مفتاح الكاش المرتبط بالقائمة، إن وُجد.
  final String? cacheKey;

  /// ما يجب كتابته مع كل تعديل المالك خارج رقعة النموذج (كإفراغ رد المستشار).
  final Map<String, dynamic> extraWritesOnEdit;
}

/// المحرّك المشترك لتعديل المالك وحذفه في كل مجموعة يقبل إنشائها من مستخدم.
///
/// القواعد في `firestore.rules` تقول: تعديل المالك مسموح في أي وقت **بشرط أن
/// تكون الوثيقة الناتجة غير معتمدة** (فكل تعديل يعود بصاحبه إلى طابور
/// المراجعة)، والحذف فوري له. هذه الطبقة هي الوجه العميل لذلك العقد حتى لا
/// يكرّره كل service على حدة ولا ينسى أحدها `isApproved: false` فتُرفض
/// الكتابة بـ`permission-denied` ويظهر للمستخدم «فشل بلا سبب»:
///   * [edit] — يجرّد حقول النسبة، يفرض العودة للمراجعة، يخطر الإدارة والمالك.
///   * [remove] — يمرّ بـ`ContentCleanupService` ثم يمسح صور ImgBB ويحذف
///     الوثيقة ويصفّر الكاش.
class OwnerContentService {
  OwnerContentService._();

  static const List<OwnerCollectionSpec> _all = [
    OwnerCollectionSpec(
      collection: 'news',
      ownerField: 'authorId',
      itemLabel: 'الخبر',
      titleField: 'title',
      route: '/news',
      attributionFields: ['authorName', 'authorRole', 'authorSellerType'],
      imageFields: ['imageUrl', 'imageUrls'],
      cacheKey: CacheKeys.news,
    ),
    OwnerCollectionSpec(
      collection: 'market_products',
      ownerField: 'sellerId',
      itemLabel: 'المنتج',
      titleField: 'name',
      route: '/market',
      attributionFields: ['sellerName', 'sellerType'],
      imageFields: ['imageUrl', 'imageUrls'],
      protectedOnEdit: ['isFeatured'],
      cacheKey: CacheKeys.products,
    ),
    OwnerCollectionSpec(
      collection: 'shops',
      ownerField: 'ownerUid',
      itemLabel: 'المحل',
      titleField: 'name',
      route: '/market',
      attributionFields: ['ownerName'],
      imageFields: ['imageUrls', 'logoUrl', 'coverUrl'],
      protectedOnEdit: ['isActive'],
      cacheKey: CacheKeys.shops,
    ),
    OwnerCollectionSpec(
      collection: 'obituaries',
      ownerField: 'submittedBy',
      itemLabel: 'نعوة العزاء',
      titleField: 'name',
      route: '/obituaries',
      imageFields: ['imageUrl'],
      cacheKey: CacheKeys.obituaries,
    ),
    OwnerCollectionSpec(
      collection: 'occasions',
      ownerField: 'submittedBy',
      itemLabel: 'المناسبة',
      titleField: 'title',
      route: '/occasions',
      imageFields: ['imageUrl'],
      cacheKey: CacheKeys.occasions,
    ),
    OwnerCollectionSpec(
      collection: 'forum_posts',
      ownerField: 'userId',
      itemLabel: 'منشور المندرة',
      titleField: 'title',
      route: '/forum',
      attributionFields: ['userName', 'userPhotoUrl'],
      imageFields: ['imageUrl'],
      protectedOnEdit: ['isPinned'],
      cacheKey: CacheKeys.forumPosts,
    ),
    OwnerCollectionSpec(
      collection: 'phone_directory',
      ownerField: 'submittedBy',
      itemLabel: 'البيان',
      titleField: 'name',
      route: '/phone-directory',
      imageFields: ['photoUrl'],
      cacheKey: CacheKeys.phone,
    ),
    OwnerCollectionSpec(
      collection: 'service_providers',
      ownerField: 'submittedBy',
      itemLabel: 'سجل الخدمة',
      titleField: 'name',
      route: '/services/technicians',
      attributionFields: ['submittedByName'],
      imageFields: ['photoUrl'],
      protectedOnEdit: ['isFeatured'],
    ),
    OwnerCollectionSpec(
      collection: 'lost_items',
      ownerField: 'userId',
      itemLabel: 'إعلان المفقودات',
      titleField: 'title',
      route: '/services/lost-items',
      attributionFields: ['userName'],
      imageFields: ['imageUrl'],
      // «تم التسليم» رخصة حالة يملكها المالك وحده بإجراء مستقل، فلا يجوز أن
      // تُكتب نسخته القديمة مع كل تعديل محتوى.
      protectedOnEdit: ['isResolved'],
    ),
    OwnerCollectionSpec(
      collection: 'village_clinics',
      ownerField: 'submittedBy',
      itemLabel: 'العيادة',
      titleField: 'name',
      route: '/medical',
      attributionFields: ['submittedByName'],
      imageFields: ['imageUrl', 'imageUrls'],
      cacheKey: CacheKeys.medical,
    ),
    OwnerCollectionSpec(
      collection: 'pharmacies',
      ownerField: 'submittedBy',
      itemLabel: 'الصيدلية',
      titleField: 'name',
      route: '/medical',
      attributionFields: ['submittedByName'],
      imageFields: ['imageUrls'],
      cacheKey: CacheKeys.medical,
    ),
    OwnerCollectionSpec(
      collection: 'medical_labs',
      ownerField: 'submittedBy',
      itemLabel: 'المعمل',
      titleField: 'name',
      route: '/medical',
      attributionFields: ['submittedByName'],
      imageFields: ['imageUrls'],
      cacheKey: CacheKeys.medical,
    ),
    OwnerCollectionSpec(
      collection: 'optical_shops',
      ownerField: 'submittedBy',
      itemLabel: 'محل النظارات',
      titleField: 'name',
      route: '/medical',
      attributionFields: ['submittedByName'],
      imageFields: ['imageUrls'],
      // نافذة العرض المميز يملكها إجراء مستقل (تجديد) فلا تكتبها نسخة قديمة.
      protectedOnEdit: ['adType', 'featuredUntil'],
      cacheKey: CacheKeys.medical,
    ),
    OwnerCollectionSpec(
      collection: 'blood_requests',
      ownerField: 'userId',
      itemLabel: 'طلب التبرع',
      titleField: 'requesterName',
      route: '/medical',
      attributionFields: ['requesterName'],
      // إغلاق الطلب رخصة حالة مستقلة عن تعديل المحتوى.
      protectedOnEdit: ['status'],
    ),
    OwnerCollectionSpec(
      collection: 'blood_donors',
      ownerField: 'userId',
      itemLabel: 'سجل المتبرِّع',
      titleField: 'name',
      route: '/medical',
      attributionFields: ['name'],
    ),
    OwnerCollectionSpec(
      collection: 'village_ads',
      ownerField: 'userId',
      itemLabel: 'الإعلان',
      titleField: 'title',
      route: '/ads',
      attributionFields: ['userName'],
      imageFields: ['imageUrls'],
    ),
    OwnerCollectionSpec(
      collection: 'lawyers',
      ownerField: 'submittedBy',
      itemLabel: 'تسجيل المحامي',
      titleField: 'name',
      route: '/legal',
      attributionFields: ['submittedByName'],
      imageFields: ['photoUrl'],
    ),
    OwnerCollectionSpec(
      collection: 'legal_consultations',
      ownerField: 'userId',
      itemLabel: 'الاستشارة',
      titleField: 'question',
      route: '/legal',
      attributionFields: ['userName'],
      // سؤالٌ معدَّل لم يعد السؤال الذي أُجيب عنه، فردّ المستشار القديم يُفرَّغ
      // معه — والقواعد ترفض تعديل المالك ما بقي على وثيقته ردّ.
      extraWritesOnEdit: {'answer': ''},
    ),
  ];

  static final Map<String, OwnerCollectionSpec> _specs = {
    for (final spec in _all) spec.collection: spec,
  };

  /// إعداد المجموعة، أو null إن لم تكن إضافة مستخدم لها مالك.
  static OwnerCollectionSpec? specFor(String collection) =>
      _specs[collection];

  /// المجموعات التي تمرّ بمحرك المالك (عقد للاختبارات وللوحة الإدارة).
  static List<String> get editableCollections =>
      _all.map((s) => s.collection).toList(growable: false);

  /// حقول التفاعل التي يملكها العدّاد على الوثيقة لا النموذج: تمريرها مع
  /// رقعة المالك كان يكتب قيمًا قديمة (اقرأها وقت فتح الشاشة) فوق إعجابات/
  /// مشاهدات/تقييمات جمعتها الوثيقة بعدها.
  static const Set<String> _interactionKeys = {
    'likes',
    'likedBy',
    'views',
    'comments',
    'rating',
    'ratingCount',
    'reviewCount',
  };

  /// تعديل المالك لإضافته. يرمي استثناءً عند الرفض ليُبلَّغ المستخدم بصدق.
  static Future<void> edit(
    FirebaseFirestore fs,
    String collection,
    String docId,
    Map<String, dynamic> changes, {
    String? label,
    String? route,
  }) async {
    final spec = _require(collection, docId);
    final write = Map<String, dynamic>.from(changes)
      ..remove(spec.ownerField)
      ..remove('createdAt');
    for (final field in spec.attributionFields) {
      write.remove(field);
    }
    for (final field in spec.protectedOnEdit) {
      write.remove(field);
    }
    for (final field in _interactionKeys) {
      write.remove(field);
    }
    // التعديل يعود إلى المراجعة دائمًا: فالوثيقة المعتمدة المنشورة للقرية لا
    // تصلح أن تتغيّر في الخفاء، والقواعد ترفض أي نتيجة كتابة معتمدة.
    write['isApproved'] = false;
    write.addAll(spec.extraWritesOnEdit);

    await fs.collection(collection).doc(docId).update(write);
    await _invalidateCache(spec);
    unawaited(RemotePushService.notifyAdmins(collection));
    _announceEdit(spec, write, label: label, route: route);
  }

  /// حذف المالك لإضافته: تنظيف الأيتام، ثم صور ImgBB المخزّنة، ثم الوثيقة، ثم الكاش.
  static Future<void> remove(
    FirebaseFirestore fs,
    String collection,
    String docId,
  ) async {
    final spec = _require(collection, docId);
    await ContentCleanupService.cleanupForDeleted(fs, collection, docId);
    for (final url in await _storedImages(fs, spec, docId)) {
      await ImageUploadService().deleteImage(url);
    }
    await fs.collection(collection).doc(docId).delete();
    await _invalidateCache(spec);
  }

  static OwnerCollectionSpec _require(String collection, String docId) {
    final spec = _specs[collection];
    if (spec == null) {
      throw Exception('هذا القسم لا يقبل تعديل صاحبه أو حذفه.');
    }
    if (docId.isEmpty) {
      throw Exception('بيانات غير صالحة: معرّف العنصر فارغ.');
    }
    return spec;
  }

  /// الكاش أفضل-جهد: الكتابة نفسها نجحت، فلا يصحّ أن يفشل العمل في الواجهة
  /// لأنّ تصفير نسخة محلية غير متاحة (منصّة بلا SharedPreferences مثلًا).
  static Future<void> _invalidateCache(OwnerCollectionSpec spec) async {
    final key = spec.cacheKey;
    if (key == null) return;
    try {
      await CacheService.invalidate(key);
    } catch (_) {}
  }

  /// روابط الصور المكتوبة فعلًا في الوثيقة (نص واحد أو قائمة نصوص).
  static Future<List<String>> _storedImages(
      FirebaseFirestore fs, OwnerCollectionSpec spec, String docId) async {
    if (spec.imageFields.isEmpty) return const [];
    try {
      final snap = await fs.collection(spec.collection).doc(docId).get();
      final data = snap.data();
      if (data == null) return const [];
      return _imageUrlsOf(spec, data);
    } catch (_) {
      // تعذّرت قراءة الروابط: الحذف يكمل، وتبقى الصور على المستضيف بدل أن
      // يُمنع المستخدم من حذف إضافته بسبب فشل في خطوة تنظيف ثانوية.
      return const [];
    }
  }

  static List<String> _imageUrlsOf(
          OwnerCollectionSpec spec, Map<String, dynamic> data) =>
      [
        for (final field in spec.imageFields) ..._oneOrMany(data[field]),
      ];

  static Iterable<String> _oneOrMany(Object? value) {
    if (value is String) return value.isEmpty ? const [] : [value];
    if (value is List) {
      return value.whereType<String>().where((v) => v.isNotEmpty);
    }
    return const [];
  }

  static void _announceEdit(
    OwnerCollectionSpec spec,
    Map<String, dynamic> write, {
    String? label,
    String? route,
  }) {
    final written = write[spec.titleField];
    final title = (label != null && label.isNotEmpty)
        ? label
        : (written is String && written.isNotEmpty)
            ? written
            : spec.itemLabel;
    final target = (route != null && route.isNotEmpty) ? route : spec.route;
    final section = spec.itemLabel;
    unawaited(NotificationService.showLocalNotification(
      title: '✏️ تعديل بانتظار المراجعة',
      body: 'تم حفظ تعديل $section «$title» وأُرسل للمراجعة',
      payload: target,
    ));
    final uid = _currentUid();
    if (uid == null) return;
    unawaited(NotificationInboxService.instance.push(
      userId: uid,
      title: '✏️ تم حفظ تعديلك',
      body:
          'تعديل $section «$title» عاد إلى طابور المراجعة وسيظهر للقرية بعد موافقة الإدارة',
      route: target,
      kind: 'info',
    ));
  }

  static String? _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth غير مهيأ (اختبارات الواجهة) — الإشعار أفضل-جهد.
      return null;
    }
  }
}
