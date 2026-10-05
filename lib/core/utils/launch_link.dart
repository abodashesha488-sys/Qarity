import 'package:url_launcher/url_launcher.dart';

/// يفتح الرابط مباشرة ويعيد رسالة الفشل العربية عند التعذّر، أو `null` عند النجاح.
///
/// السبب في وجوده: كانت `canLaunchUrl` تُستعمل بوّابةً قبل الفتح، وعلى أندرويد 11+
/// لا يرى التطبيق حزم واتساب والمتصفح ولا نوايا الاتصال إلا إذا صُرّح عنها في
/// `<queries>` بالـmanifest — فكانت ترجع false لأزرار سليمة فتُعطَّل أو تصمت بلا أي
/// محاولة فعلية. التجربة المباشرة تُبلّغ الفشل الحقيقي فقط: `false` عند تعذّر
/// الوصول إلى تطبيق يعالج الرابط، واستثناء عند غياب الاتصال أو فساد الرابط.
Future<String?> launchContactUrl(String url,
    {required String unavailable,
    required String failed,
    LaunchMode mode = LaunchMode.externalApplication}) async {
  try {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: mode);
    return opened ? null : unavailable;
  } on Object catch (_) {
    return failed;
  }
}

/// اتصال هاتفي من رقم مكتوب في سجل — `null` عند النجاح ورسالة عربية عند الفشل.
/// موجودة لأن تسعة مواضع في التطبيق كانت بوّابة `canLaunchUrl` وحدها تفصل بينها
/// وبين المكالمة، فتصمت حين لا تُرى حزمة الطلب على أندرويد 11+.
Future<String?> launchPhoneCall(String phone) => launchContactUrl(
      Uri(scheme: 'tel', path: phone.trim()).toString(),
      unavailable: 'لا يمكن الاتصال على هذا الجهاز.',
      failed: 'تعذّر بدء المكالمة — أعد المحاولة.',
      mode: LaunchMode.platformDefault,
    );

/// مراسلة SMS من رقم مكتوب في سجل — نفس عقد [launchPhoneCall].
Future<String?> launchSms(String phone) => launchContactUrl(
      Uri(scheme: 'sms', path: phone.trim()).toString(),
      unavailable: 'لا يمكن فتح الرسائل على هذا الجهاز.',
      failed: 'تعذّر بدء الرسالة — أعد المحاولة.',
      mode: LaunchMode.platformDefault,
    );

/// فتح رابط واتساب جاهز (من `egyptianWhatsAppUrl` أو رابط مشاركة) في المحادثة.
/// الرسالة هنا واحدة في كل مواضع التطبيق حتى لا يختلف لسان الفشل من صفحة إلى أخرى.
Future<String?> launchWhatsAppUrl(String url) => launchContactUrl(url,
    unavailable: 'واتساب غير متاح على هذا الجهاز.',
    failed: 'تعذّر فتح المراسلة — تحقّق من الاتصال ثم أعد المحاولة.');
