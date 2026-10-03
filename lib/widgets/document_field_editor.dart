import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_upload_service.dart';

/// أنواع الحقول التي يرسمها المُحرِّر المشترك.
enum DocFieldKind {
  text,
  multiline,
  number,
  boolean,
  list,
  image,
  images,
  readOnly
}

/// وصف حقل واحد: مفتاح الوثيقة وتسميته العربية ونوعه.
class DocFieldSpec {
  final String key;
  final String label;
  final DocFieldKind kind;
  final bool required;
  final int maxImages;

  /// القيمة الخام — تُعرض فقط في الحقول للقراءة فقط (تواريخ وخرائط ومعرّفات).
  final dynamic rawValue;

  const DocFieldSpec(this.key, this.label,
      {this.kind = DocFieldKind.text,
      this.required = false,
      this.maxImages = 5,
      this.rawValue});
}

bool looksLikeImageUrl(String value) =>
    value.startsWith('http://') || value.startsWith('https://');

/// المفتاح حقل صورة **بغضّ النظر عن قيمته**: رابط فارغ أو مفتاح خلفية محلي
/// مثل `azaa1` يبقى مكانه محرّر صور، لا خانة نص.
bool isImageFieldKey(String key) {
  final k = key.toLowerCase();
  if (k == 'cardbackground') return false; // مفاتيح azaa أو رابط، نصّ حرّ
  return k.endsWith('imageurl') ||
      k.endsWith('imageurls') ||
      k.endsWith('photourl') ||
      k.endsWith('image') ||
      k.endsWith('photo') ||
      k.endsWith('thumbnail') ||
      k.endsWith('banner');
}

/// المفاتيح التي لا تُحرَّر إطلاقًا: هوية وتواريخ وعلامة الموافقة — فالحفظ
/// عليها إما عديم معنى وإما يفتح باب تجاوز الأدمن.
const Set<String> kDocReadOnlyKeys = {
  'id',
  'createdAt',
  'updatedAt',
  'approvedAt',
  'approvedBy',
  'rejectedAt',
  'rejectedBy',
  'reviewedAt',
  'reviewedBy',
  'isApproved',
  'signupAt',
  'joinDate',
  'lastLogin',
  'fcmToken',
  'fcmTokenUpdatedAt',
};

/// تسمية عربية عامة لمفتاح لا تعرفه قائمة المجموعة الحالية.
String docFieldLabel(String key) {
  const labels = {
    'title': 'العنوان',
    'name': 'الاسم',
    'content': 'المحتوى',
    'subtitle': 'المحتوى',
    'description': 'الوصف',
    'details': 'التفاصيل',
    'notes': 'ملاحظات',
    'category': 'التصنيف',
    'kind': 'النوع',
    'phone': 'الهاتف',
    'whatsapp': 'واتساب',
    'address': 'العنوان',
    'location': 'المكان',
    'status': 'الحالة',
    'specialty': 'التخصص',
    'price': 'السعر',
    'offerPrice': 'سعر العرض',
    'stock': 'المخزون',
    'budget': 'الميزانية',
    'fees': 'الأجر',
    'units': 'العدد',
    'rating': 'التقييم',
    'ratingCount': 'عدد التقييمات',
    'likes': 'الإعجابات',
    'views': 'المشاهدات',
    'commentsCount': 'عدد التعليقات',
    'condolencesCount': 'عدد التعازي',
    'attendeesCount': 'عدد الحضور',
    'userId': 'معرّف صاحب المحتوى',
    'authorId': 'معرّف الكاتب',
    'sellerId': 'معرّف البائع',
    'ownerUid': 'معرّف المالك',
    'submittedBy': 'معرّف مقدّم البيان',
    'userName': 'اسم صاحب الطلب',
    'userPhotoUrl': 'صورة صاحب الطلب',
    'authorName': 'اسم الكاتب',
    'sellerName': 'اسم البائع',
    'sellerType': 'نوع البائع',
    'ownerName': 'اسم المالك/المسؤول',
    'submittedByName': 'اسم مقدّم البيان',
    'businessName': 'اسم النشاط',
    'requesterName': 'اسم مقدّم الطلب',
    'patientName': 'اسم المريض',
    'doctorName': 'اسم الطبيب',
    'organizer': 'المنظم',
    'workingHours': 'مواعيد العمل',
    'hospital': 'المستشفى/المكان',
    'urgency': 'درجة الأهمية',
    'bloodType': 'فصيلة الدم',
    'gender': 'النوع',
    'age': 'السن',
    'date': 'التاريخ',
    'time': 'الوقت',
    'isResolved': 'تم الحل',
    'isRecovery': 'بيان استرجاع',
    'isActive': 'نشط',
    'isPublic': 'ظاهر للجميع',
    'isFeatured': 'بيان مميز',
    'isAvailable': 'متاح',
    'isVerified': 'موثّق',
    'isOnOffer': 'عليه عرض',
    'isInStock': 'متوفر',
    'homeCollection': 'سحب عينات بالمنزل',
    'offersPrivateTutoring': 'تدريس خاص',
    'adType': 'نوع الإعلان',
    'featuredUntil': 'نهاية العرض المميز',
    'answer': 'رد المستشار',
    'question': 'نص السؤال',
    'office': 'المكتب',
    'version': 'الإصدار',
    'showOnce': 'تظهر مرة واحدة',
    'playSound': 'صوت عند الظهور',
    'vibrate': 'اهتزاز',
    'linkType': 'نوع الرابط',
    'linkValue': 'قيمة الرابط',
    'placement': 'موضع الظهور',
    'startsAt': 'بداية النافذة',
    'endsAt': 'نهاية النافذة',
  };
  return labels[key] ?? key;
}

/// يشتق بقية مفاتيح الوثيقة التي لم تذكرها قائمة المجموعة، فيظهر **كل** حقل
/// في المستند لا ما تعرفه القائمة فقط. الصور تُكتشف من شكل القيمة، والخرائط
/// والطوابع الزمنية تُعرض للقراءة فقط لأن كتابة نص فوقها تُفسد الوثيقة.
List<DocFieldSpec> deriveMissingFields(
    Map<String, dynamic> item, Set<String> covered) {
  final out = <DocFieldSpec>[];
  for (final entry in item.entries) {
    if (covered.contains(entry.key)) continue;
    final v = entry.value;
    if (kDocReadOnlyKeys.contains(entry.key)) {
      out.add(DocFieldSpec(entry.key, docFieldLabel(entry.key),
          kind: DocFieldKind.readOnly, rawValue: v));
      continue;
    }
    if (v == null) {
      out.add(DocFieldSpec(entry.key, docFieldLabel(entry.key),
          kind: isImageFieldKey(entry.key)
              ? (entry.key.toLowerCase().endsWith('imageurls')
                  ? DocFieldKind.images
                  : DocFieldKind.image)
              : DocFieldKind.text));
    } else if (v is bool) {
      out.add(DocFieldSpec(entry.key, docFieldLabel(entry.key),
          kind: DocFieldKind.boolean));
    } else if (v is num) {
      out.add(DocFieldSpec(entry.key, docFieldLabel(entry.key),
          kind: DocFieldKind.number));
    } else if (v is String) {
      out.add(DocFieldSpec(entry.key, docFieldLabel(entry.key),
          kind: isImageFieldKey(entry.key)
              ? DocFieldKind.image
              : (v.length > 60 ? DocFieldKind.multiline : DocFieldKind.text)));
    } else if (v is List) {
      final strings = v.map((e) => e?.toString() ?? '').toList();
      out.add(isImageFieldKey(entry.key) || strings.every(looksLikeImageUrl)
          ? DocFieldSpec(entry.key, docFieldLabel(entry.key),
              kind: DocFieldKind.images, maxImages: 6)
          : DocFieldSpec(entry.key, docFieldLabel(entry.key),
              kind: DocFieldKind.list));
    } else {
      out.add(DocFieldSpec(entry.key, docFieldLabel(entry.key),
          kind: DocFieldKind.readOnly, rawValue: v));
    }
  }
  return out;
}

/// حالة مُحرِّر الوثيقة: نصّات وقيم منطقية وقوائم نصوص وروابط صور بمفتاح واحد.
class DocumentEditor {
  final Map<String, TextEditingController> texts = {};
  final Map<String, bool> booleans = {};
  final Map<String, List<String>> imageLists = {};

  void seed(List<DocFieldSpec> specs, Map<String, dynamic> item) {
    for (final f in specs) {
      final v = item[f.key];
      switch (f.kind) {
        case DocFieldKind.boolean:
          booleans[f.key] = v is bool ? v : false;
        case DocFieldKind.image:
          final single = '${v ?? ''}'.trim();
          imageLists[f.key] = single.isEmpty ? [] : [single];
        case DocFieldKind.images:
          imageLists[f.key] = _stringsOf(v);
        case DocFieldKind.list:
          texts[f.key] = TextEditingController(
              text: v is List
                  ? v.map((e) => e?.toString() ?? '').join('، ')
                  : (v?.toString() ?? ''));
        case DocFieldKind.readOnly:
          break;
        case DocFieldKind.number:
        case DocFieldKind.text:
        case DocFieldKind.multiline:
          texts[f.key] =
              TextEditingController(text: v?.toString() ?? '');
      }
    }
  }

  static List<String> _stringsOf(dynamic v) => v is List
      ? v
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList()
      : <String>[];

  void setImageUrls(String key, List<String> urls) {
    imageLists[key] = List<String>.from(urls);
  }

  /// يبني ما يُكتب في الوثيقة. الصور والقوائم والقيم المنطقية تُكتب دائمًا
  /// (فحذف آخر صورة أو تفريغ حقل يجب أن يصل للوثيقة)، والأرقام الفارغة
  /// تُتخطّى لأن النص الفارغ لا يُخزَّن في حقل رقمي.
  Map<String, dynamic> collect(List<DocFieldSpec> specs) {
    final data = <String, dynamic>{};
    for (final f in specs) {
      switch (f.kind) {
        case DocFieldKind.readOnly:
          break;
        case DocFieldKind.boolean:
          data[f.key] = booleans[f.key] ?? false;
        case DocFieldKind.image:
          data[f.key] = (imageLists[f.key] ?? const []).firstOrNull ?? '';
        case DocFieldKind.images:
          data[f.key] = List<String>.from(imageLists[f.key] ?? const []);
        case DocFieldKind.list:
          data[f.key] = (texts[f.key]?.text.trim() ?? '')
              .split(RegExp(r'[،,]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        case DocFieldKind.number:
          final n = num.tryParse(texts[f.key]?.text.trim() ?? '');
          if (n != null) data[f.key] = n;
        case DocFieldKind.text:
        case DocFieldKind.multiline:
          data[f.key] = texts[f.key]?.text.trim() ?? '';
      }
    }
    return data;
  }

  /// اسم أول حقل مطلوب ومُفرَغ — رسالة عربية واحدة بدل صمت الحفظ.
  String? missingRequiredLabel(List<DocFieldSpec> specs) {
    for (final f in specs) {
      if (!f.required) continue;
      if (f.kind == DocFieldKind.boolean || f.kind == DocFieldKind.readOnly) {
        continue;
      }
      if (f.kind == DocFieldKind.image || f.kind == DocFieldKind.images) {
        if ((imageLists[f.key] ?? const []).isEmpty) return f.label;
        continue;
      }
      if ((texts[f.key]?.text.trim() ?? '').isEmpty) return f.label;
    }
    return null;
  }

  void dispose() {
    for (final c in texts.values) {
      c.dispose();
    }
    texts.clear();
  }
}

/// صف حقل واحد بكل الأشكال، مع محرر الصور عند الحاجة.
class DocFieldRow extends StatefulWidget {
  final DocumentEditor editor;
  final DocFieldSpec spec;
  final VoidCallback? onChanged;

  const DocFieldRow({
    super.key,
    required this.editor,
    required this.spec,
    this.onChanged,
  });

  @override
  State<DocFieldRow> createState() => _DocFieldRowState();
}

class _DocFieldRowState extends State<DocFieldRow> {
  DocumentEditor get editor => widget.editor;
  DocFieldSpec get spec => widget.spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = docFieldIcon(spec.key);
    if (spec.kind == DocFieldKind.boolean) {
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(spec.label),
        secondary: Icon(icon, color: theme.colorScheme.primary),
        value: editor.booleans[spec.key] ?? false,
        onChanged: (v) {
          setState(() => editor.booleans[spec.key] = v);
          widget.onChanged?.call();
        },
      );
    }
    if (spec.kind == DocFieldKind.readOnly) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: '${spec.label} (للقراءة فقط)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4))),
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: theme.colorScheme.onSurfaceVariant),
          ),
          child: Text(_readable(spec.rawValue, theme),
              style: TextStyle(
                  fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }
    if (spec.kind == DocFieldKind.image || spec.kind == DocFieldKind.images) {
      return ImageListEditor(
        key: ValueKey('img-editor-${spec.key}'),
        label: spec.label,
        fieldKey: spec.key,
        single: spec.kind == DocFieldKind.image,
        maxImages: spec.maxImages,
        urls: editor.imageLists[spec.key] ?? const [],
        onChanged: (urls) {
          editor.setImageUrls(spec.key, urls);
          widget.onChanged?.call();
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('doc-field-${spec.key}'),
        controller: editor.texts[spec.key],
        maxLines: (spec.kind == DocFieldKind.multiline ||
                spec.kind == DocFieldKind.list)
            ? 4
            : 1,
        keyboardType:
            spec.kind == DocFieldKind.number ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: spec.label + (spec.required ? ' *' : ''),
          helperText: spec.kind == DocFieldKind.list
              ? 'افصل بين القيم بفاصلة'
              : null,
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6))),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  static String _readable(dynamic v, ThemeData theme) {
    if (v == null) return '—';
    final s = v is List ? v.map((e) => e.toString()).join('، ') : '$v';
    return s.length > 160 ? '${s.substring(0, 157)}…' : s;
  }
}

/// محرر الصور: مصغّرات بحذف فردي + رفع من الجهاز + لصق رابط.
///
/// `bytesSource` هو الممرّ الاختياري لالتقاط الصور (حتى `remaining` صورة)؛
/// الافتراضي يفتح معرض الجهاز. وجوده يجعل الرفع قابلًا للاختبار بلا كاميرا.
typedef ImageBytesSource = Future<List<Uint8List>> Function(int remaining);

class ImageListEditor extends StatefulWidget {
  final String label;
  final String fieldKey;
  final bool single;
  final int maxImages;
  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;

  /// سقف مقاس الصورة عند الالتقاط من المعرض (بلا سقف في الافتراضي). كانت بعض
  /// النماذج تلتقط بمقاس أصغر لتخفّض حجم الرفع، فيمرّر النموذج سقفه هنا بدل
  /// أن يستعيد picker خاصًا به.
  final double? maxSide;

  /// انشغال الرفع عند المالك حتى لا يحفظ النموذج والصورة ما زالت في الطريق —
  /// ضياع صورة بصمتًا هو نفس الخطأ الذي أُصلح في دليل الخدمات.
  final ValueChanged<bool>? onBusyChanged;

  /// فشل الرفع يصل للمالك كما يُعرض هنا، فلا تُبتلع رسالة ImgBB في نموذج
  /// يكتفي بمصغّرة ناقصة.
  final ValueChanged<String>? onError;

  const ImageListEditor({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.urls,
    required this.onChanged,
    this.single = false,
    this.maxImages = 5,
    this.uploader,
    this.bytesSource,
    this.maxSide,
    this.onBusyChanged,
    this.onError,
  });

  @override
  State<ImageListEditor> createState() => _ImageListEditorState();
}

class _ImageListEditorState extends State<ImageListEditor> {
  bool _uploading = false;
  String? _error;

  int get _remaining =>
      widget.single ? (widget.urls.isEmpty ? 1 : 0) : widget.maxImages - widget.urls.length;

  bool get _blocked => _remaining <= 0;

  /// الزرّان يبقيان مضغوطين عند الامتلاء حتى **يُقال السبب**: تعطيل صامت
  /// يترك الأدمن ينقر بلا ردّ — وهو نفس خطأ الفشل الصامت في المشروع.
  bool _explainIfBlocked() {
    if (!_blocked) return false;
    setState(() => _error = widget.single
        ? 'الصورة موجودة بالفعل — احذفها أولًا لرفع غيرها'
        : 'الحد الأقصى ${widget.maxImages} صور');
    return true;
  }

  Future<List<Uint8List>> _defaultSource(int remaining) async {
    final side = widget.maxSide;
    final picker = ImagePicker();
    final picked = widget.single
        ? [
            await picker.pickImage(source: ImageSource.gallery,
                imageQuality: 85, maxWidth: side, maxHeight: side)
          ].whereType<XFile>().toList()
        : (await picker.pickMultiImage(
                imageQuality: 85, maxWidth: side, maxHeight: side))
            .take(remaining)
            .toList();
    final bytes = <Uint8List>[];
    for (final file in picked) {
      bytes.add(await file.readAsBytes());
    }
    return bytes;
  }

  /// الخطر واحد في الموضعين: يظهر هنا كمصغّرة ناقصة، ويصل للمالك ليمنع الحفظ
  /// أو يسمّي الفشل بلغته.
  void _reportError(String message) {
    setState(() => _error = message);
    widget.onError?.call(message);
  }

  void _setBusy(bool busy) {
    setState(() => _uploading = busy);
    widget.onBusyChanged?.call(busy);
  }

  Future<void> _pick() async {
    if (_explainIfBlocked()) return;
    _setBusy(true);
    setState(() => _error = null);
    try {
      final source = widget.bytesSource ?? _defaultSource;
      final picked = await source(_remaining);
      if (picked.isEmpty) return;
      final uploader = widget.uploader ?? ImageUploadService();
      final uploaded = <String>[];
      for (final bytes in picked) {
        uploaded.add(await uploader.uploadImage(bytes));
      }
      if (!mounted) return;
      widget.onChanged(
          widget.single ? uploaded : [...widget.urls, ...uploaded]);
    } catch (e) {
      if (!mounted) return;
      _reportError(
          'تعذّر رفع الصورة: ${'$e'.replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  /// المعاينة كاملة عند الضغط على المصغّرة: كل نماذج المحتوى كان لها مُعاينتها
  /// الخاصة (أبرزها نموذج الخبر)، وبلا هذه النسخة المشتركة يصبح الموحّد **أقلّ**
  /// مما استُبدل منه لا مثلَه.
  void _showFullImage(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              minScale: 1,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white, size: 40)),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(ctx),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.close_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteLink() async {
    if (_explainIfBlocked()) return;
    final value = (await showDialog<String>(
          context: context,
          builder: (_) => _LinkDialog(label: widget.label, fieldKey: widget.fieldKey),
        ))
        ?.trim();
    if (value == null || value.isEmpty) return;
    if (!looksLikeImageUrl(value)) {
      if (!mounted) return;
      setState(() => _error = 'الرابط يجب أن يبدأ بـ http أو https');
      return;
    }
    widget.onChanged(widget.single
        ? [value]
        : [...widget.urls, value].take(widget.maxImages).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    widget.single
                        ? widget.label
                        : '${widget.label} (${widget.urls.length}/${widget.maxImages})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.urls.isEmpty)
            Text('لا صورة — ارفع من الجهاز أو الصق رابطًا',
                style: TextStyle(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < widget.urls.length; i++)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          key: ValueKey('img-preview-${widget.fieldKey}-$i'),
                          onTap: () => _showFullImage(widget.urls[i]),
                          child: CachedNetworkImage(
                            imageUrl: widget.urls[i],
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            memCacheWidth: 252,
                            placeholder: (_, __) => Container(
                                width: 84,
                                height: 84,
                                color: theme
                                    .colorScheme.surfaceContainerHighest),
                            errorWidget: (_, __, ___) => Container(
                                width: 84,
                                height: 84,
                                color: theme
                                    .colorScheme.surfaceContainerHighest,
                                child: const Icon(
                                    Icons.broken_image_rounded)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: const CircleBorder(),
                          child: InkWell(
                            key: ValueKey('img-delete-${widget.fieldKey}-$i'),
                            customBorder: const CircleBorder(),
                            onTap: () {
                              final next = [...widget.urls]..removeAt(i);
                              widget.onChanged(next);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                key: ValueKey('img-add-${widget.fieldKey}'),
                onPressed: _uploading ? null : _pick,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_rounded, size: 18),
                label: Text(_uploading ? 'جاري الرفع…' : 'رفع صورة'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                key: ValueKey('img-paste-${widget.fieldKey}'),
                onPressed: _uploading ? null : _pasteLink,
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('رابط'),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error!,
                key: ValueKey('img-error-${widget.fieldKey}'),
                style: const TextStyle(
                    color: Color(0xFFB71C1C), fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

/// حوار لصق رابط صورة. يملك مُتحكّم النص ويُتلفه مع نفسه: الإتلاف مباشرة بعد
/// `Navigator.pop` يحدث أثناء حركة الانسحاب فيُرمى «استُخدم بعد إتلافه».
class _LinkDialog extends StatefulWidget {
  final String label;
  final String fieldKey;

  const _LinkDialog({required this.label, required this.fieldKey});

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة رابط ${widget.label}'),
      content: TextField(
        key: ValueKey('img-link-${widget.fieldKey}'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(labelText: 'https://…', isDense: true),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: () =>
                Navigator.pop(context, _controller.text.trim()),
            child: const Text('إضافة')),
      ],
    );
  }
}

/// الأيقونة الافتراضية لكل مفتاح — مصدر واحد حتى لا تتفارق الشاشات.
IconData docFieldIcon(String key) {
  switch (key) {
    case 'title':
    case 'name':
      return Icons.title_rounded;
    case 'content':
    case 'subtitle':
    case 'message':
    case 'description':
    case 'details':
    case 'notes':
    case 'universityNote':
    case 'bio':
    case 'question':
    case 'answer':
      return Icons.notes_rounded;
    case 'price':
    case 'offerPrice':
    case 'budget':
    case 'fees':
      return Icons.attach_money_rounded;
    case 'stock':
    case 'units':
    case 'age':
    case 'rating':
    case 'ratingCount':
    case 'likes':
    case 'views':
      return Icons.straighten_rounded;
    case 'location':
    case 'funeralLocation':
    case 'condolenceLocation':
    case 'burialLocation':
    case 'address':
    case 'hospital':
    case 'office':
      return Icons.location_on_rounded;
    case 'imageUrl':
    case 'imageUrls':
    case 'photoUrl':
    case 'userPhotoUrl':
    case 'cardBackground':
      return Icons.image_rounded;
    case 'mosque':
      return Icons.mosque_rounded;
    case 'providerKind':
      return Icons.badge_rounded;
    case 'stages':
      return Icons.school_rounded;
    case 'subjects':
      return Icons.menu_book_rounded;
    case 'eduTypes':
    case 'categories':
    case 'specializations':
      return Icons.category_rounded;
    case 'funeralTime':
    case 'condolenceTime':
    case 'workingHours':
    case 'time':
      return Icons.schedule_rounded;
    case 'date':
    case 'dateOfDeath':
    case 'funeralDate':
    case 'featuredUntil':
    case 'startsAt':
    case 'endsAt':
      return Icons.calendar_today_rounded;
    case 'phone':
    case 'sellerPhone':
    case 'contactPhone':
    case 'secondaryPhone':
    case 'whatsapp':
      return Icons.phone_rounded;
    case 'category':
    case 'specialty':
    case 'kind':
      return Icons.category_rounded;
    case 'status':
      return Icons.flag_rounded;
    case 'adType':
      return Icons.campaign_rounded;
    default:
      return Icons.edit_rounded;
  }
}
