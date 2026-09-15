import '../../routes/app_routes.dart';

/// ─── الإعلانات الدعائية المنبثقة ───
/// سجل أماكن العرض المعتمدة: إضافة شاشة جديدة مستقبلًا = سطر واحد هنا،
/// وقائمة الأدمن المنسدلة تُبنى من هذا السجل تلقائيًا.
class PromoPlacement {
  const PromoPlacement(this.key, this.label, this.group);
  final String key;
  final String label;
  final String group;
}

const List<PromoPlacement> kPromoPlacements = [
  PromoPlacement('home', 'الشاشة الرئيسية', 'عام'),
  PromoPlacement('news', 'أخبار القرية', 'عام'),
  PromoPlacement('market', 'سوق القرية', 'عام'),
  PromoPlacement('forum', 'مندرة القرية', 'عام'),
  PromoPlacement('obituaries', 'سجل العزاء', 'عام'),
  PromoPlacement('occasions', 'المناسبات', 'عام'),
  PromoPlacement('about', 'عن القرية', 'عام'),
  PromoPlacement('services', 'دليل الخدمات — الصفحة الرئيسية', 'دليل الخدمات'),
  PromoPlacement('svc_technicians', 'دليل الخدمات — الفنيون', 'دليل الخدمات'),
  PromoPlacement('svc_agricultural', 'دليل الخدمات — خدمات زراعية', 'دليل الخدمات'),
  PromoPlacement('svc_educational', 'دليل الخدمات — خدمات تعليمية', 'دليل الخدمات'),
  PromoPlacement('phone_directory', 'دليل الخدمات — دليل الهاتف', 'دليل الخدمات'),
  PromoPlacement('lost_items', 'دليل الخدمات — المفقودات', 'دليل الخدمات'),
  PromoPlacement('medical', 'المركز الطبي — الصفحة الرئيسية', 'المركز الطبي'),
  PromoPlacement('med_center', 'المركز الطبي — المركز الخيري', 'المركز الطبي'),
  PromoPlacement('med_blood', 'المركز الطبي — بنك الدم', 'المركز الطبي'),
  PromoPlacement('med_clinics', 'المركز الطبي — عيادات القرية', 'المركز الطبي'),
  PromoPlacement('med_pharmacies', 'المركز الطبي — الصيدليات', 'المركز الطبي'),
  PromoPlacement('med_labs', 'المركز الطبي — معامل التحاليل', 'المركز الطبي'),
];

String promoPlacementLabel(String key) => kPromoPlacements
        .firstWhere((p) => p.key == key,
            orElse: () => const PromoPlacement('', 'غير محدد', ''))
        .label;

/// تحويل اسم المسار +وسيطاته إلى مفتاح مكان الإعلان ('' = مكان غير مستهدف).
String promoKeyForRoute(String name, Object? args) {
  switch (name) {
    case AppRoutes.home:
      return 'home';
    case AppRoutes.newsList:
      return 'news';
    case AppRoutes.marketProducts:
    case AppRoutes.marketTabs:
      return 'market';
    case AppRoutes.forumPosts:
      return 'forum';
    case AppRoutes.obituariesList:
      return 'obituaries';
    case AppRoutes.occasionsList:
      return 'occasions';
    case AppRoutes.about:
      return 'about';
    case AppRoutes.serviceRequest:
      return 'services';
    case AppRoutes.serviceCategory:
      return switch (args) {
        'technicians' => 'svc_technicians',
        'agricultural' => 'svc_agricultural',
        'educational' => 'svc_educational',
        _ => 'services',
      };
    case AppRoutes.lostItems:
      return 'lost_items';
    case AppRoutes.phoneDirectory:
      return 'phone_directory';
    case AppRoutes.medical:
      return 'medical';
    case AppRoutes.medicalSection:
      return switch (args) {
        0 => 'med_center',
        1 => 'med_blood',
        2 => 'med_clinics',
        3 => 'med_pharmacies',
        4 => 'med_labs',
        _ => 'medical',
      };
    default:
      return '';
  }
}

/// وجهات الروابط الداخلية (داخل التطبيق) — تُعرض بالأسماء في لوحة الأدمن.
class PromoInternalLink {
  const PromoInternalLink(this.label, this.route, [this.arg]);
  final String label;
  final String route;
  final String? arg;

  /// ترميز القيمة المخزّنة في Firestore: `route|arg`
  String get encoded => arg == null ? route : '$route|$arg';

  static (String route, Object? args) decode(String value) {
    final i = value.indexOf('|');
    if (i < 0) return (value, null);
    final route = value.substring(0, i);
    final arg = value.substring(i + 1);
    if (route == AppRoutes.medicalSection) {
      return (route, int.tryParse(arg) ?? 0);
    }
    return (route, arg);
  }
}

const List<PromoInternalLink> kPromoInternalLinks = [
  PromoInternalLink('الشاشة الرئيسية', AppRoutes.home),
  PromoInternalLink('أخبار القرية', AppRoutes.newsList),
  PromoInternalLink('سوق القرية', AppRoutes.marketProducts),
  PromoInternalLink('مندرة القرية', AppRoutes.forumPosts),
  PromoInternalLink('سجل العزاء', AppRoutes.obituariesList),
  PromoInternalLink('المناسبات', AppRoutes.occasionsList),
  PromoInternalLink('عن القرية', AppRoutes.about),
  PromoInternalLink('دليل الخدمات', AppRoutes.serviceRequest),
  PromoInternalLink('دليل الخدمات — الفنيون', AppRoutes.serviceCategory, 'technicians'),
  PromoInternalLink('دليل الخدمات — خدمات زراعية', AppRoutes.serviceCategory, 'agricultural'),
  PromoInternalLink('دليل الخدمات — خدمات تعليمية', AppRoutes.serviceCategory, 'educational'),
  PromoInternalLink('دليل الهاتف', AppRoutes.phoneDirectory),
  PromoInternalLink('المفقودات', AppRoutes.lostItems),
  PromoInternalLink('المركز الطبي', AppRoutes.medical),
  PromoInternalLink('المركز الطبي — المركز الخيري', AppRoutes.medicalSection, '0'),
  PromoInternalLink('المركز الطبي — بنك الدم', AppRoutes.medicalSection, '1'),
  PromoInternalLink('المركز الطبي — عيادات القرية', AppRoutes.medicalSection, '2'),
  PromoInternalLink('المركز الطبي — الصيدليات', AppRoutes.medicalSection, '3'),
  PromoInternalLink('المركز الطبي — معامل التحاليل', AppRoutes.medicalSection, '4'),
  PromoInternalLink('حالة الطقس', AppRoutes.weather),
  PromoInternalLink('ملفي الشخصي', AppRoutes.profileMain),
  PromoInternalLink('الإعدادات', AppRoutes.settingsIndex),
];

/// أنواع الروابط الخارجية مع خصائص الربط لكل نوع.
class PromoLinkKind {
  const PromoLinkKind(this.key, this.label, this.hint, this.prefix);
  final String key;
  final String label;

  /// نص إرشادي لحقل القيمة في نموذج الأدمن.
  final String hint;

  /// بادئة تُبنى منها النتيجة إن كتب الأدمن معرّفًا فقط (واتساب/معرفات).
  final String prefix;
}

const List<PromoLinkKind> kPromoExternalKinds = [
  PromoLinkKind('url', 'رابط موقع (URL)', 'https://example.com/page', ''),
  PromoLinkKind('whatsapp', 'واتساب', '01001234567 أو رقم كامل بالتشفيع الدولي', 'https://wa.me/'),
  PromoLinkKind('facebook', 'فيسبوك', 'اسم الصفحة أو رابط كامل', 'https://www.facebook.com/'),
  PromoLinkKind('instagram', 'إنستجرام', 'المعرف (username) أو رابط كامل', 'https://www.instagram.com/'),
  PromoLinkKind('youtube', 'يوتيوب', 'اسم القناة أو رابط كامل', 'https://www.youtube.com/@'),
  PromoLinkKind('telegram', 'تيليجرام', 'المعرف أو رابط كامل', 'https://t.me/'),
  PromoLinkKind('tiktok', 'تيك توك', 'المعرف أو رابط كامل', 'https://www.tiktok.com/@'),
];

/// تحويل قيمة الرابط المخزّنة إلى URL قابل للتشغيل حسب النوع (خصائص الربط).
String? buildExternalUrl(String? kindKey, String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final kind = kPromoExternalKinds.firstWhere(
    (k) => k.key == kindKey,
    orElse: () => const PromoLinkKind('url', '', '', ''),
  );
  if (kind.key == 'whatsapp') {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final local = digits.replaceAll(RegExp(r'^0+'), '');
    final full = digits.startsWith('00')
        ? digits.substring(2)
        : (digits.startsWith('20') ? digits : '20$local');
    return 'https://wa.me/$full';
  }
  if (kind.prefix.isEmpty) return 'https://$value';
  final handle = value.replaceFirst('@', '').replaceAll('/', '');
  return '${kind.prefix}$handle';
}
