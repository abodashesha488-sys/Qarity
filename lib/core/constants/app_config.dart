class AppConfig {
  // مفتاح ImgBB يُقرأ من dart-define عند البناء حتى لا يُخزَّن صراحةً في الكود.
  // مثال: flutter build web --dart-define=IMGBB_API_KEY=xxxxx
  // القيمة الافتراضية تُبقي التطوير المحلي يعمل دون إعداد إضافي.
  static const String imgbbApiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: '5adf17954a21d7d9146824fde7061c6d',
  );

  // البريد الافتراضي للمالك يُقرأ من dart-define (اختياري)، يُستخدم فقط في
  // bootstrap أول حساب إداري؛ الأدوار الفعلية تُحدَّد عبر حقل role في Firestore.
  static const String bootstrapAdminEmail = String.fromEnvironment(
    'BOOTSTRAP_ADMIN_EMAIL',
  );
}
