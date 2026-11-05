class AppConfig {
  // إعدادات Cloudinary لرفع ومعالجة الصور السحابية فائقة السرعة.
  // مثال: flutter build web --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'ygfhtwug',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'eleraki',
  );

  // مفتاح ImgBB الاحتياطي يُقرأ من dart-define عند البناء.
  // مثال: flutter build web --dart-define=IMGBB_API_KEY=xxxxx
  static const String imgbbApiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
  );

  // البريد الافتراضي للمالك يُقرأ من dart-define (اختياري)، يُستخدم فقط في
  // bootstrap أول حساب إداري؛ الأدوار الفعلية تُحدَّد عبر حقل role في Firestore.
  static const String bootstrapAdminEmail = String.fromEnvironment(
    'BOOTSTRAP_ADMIN_EMAIL',
  );

  // مفتاح OpenWeatherMap — احتياطي اختياري يُقرأ من dart-define (المزود الأساسي هو Open-Meteo ولا يتطلب أي مفتاح).
  // مثال: flutter build web --dart-define=OWM_API_KEY=xxxxx
  static const String openWeatherApiKey = String.fromEnvironment(
    'OWM_API_KEY',
  );

  // مفتاح VAPID العام للـWeb Push (Firebase Console → Project Settings →
  // Cloud Messaging → Web configuration → Web Push certificates).
  // عام بطبيعته ويُمرر وقت البناء:
  //   flutter build web --dart-define=FCM_VAPID_PUBLIC_KEY=<public key>
  // إن لم يُضبط، يُلغى تجهيز الـPush على الويب بأمان (بدون أي كسر).
  static const String fcmVapidPublicKey = String.fromEnvironment(
    'FCM_VAPID_PUBLIC_KEY',
  );

  // علم لمرة واحدة يمنع حلقة إعادة التوجيه في OAuth على الـPWA المثبت (iOS).
  static const String googleRedirectFlagKey = 'google_redirect_attempted';

  // مسار الـ Worker في Vercel لإشعارات البوش والعمليات السحابية الآمنة
  static const String pushEndpoint = String.fromEnvironment(
    'PUSH_ENDPOINT',
    defaultValue: 'https://qarity.vercel.app/api/push',
  );

  // موقع القرية (خط الطول/العرض) لعرض طقسها — قابل للتحديث من dart-define.
  static final double weatherLat = double.tryParse(
          const String.fromEnvironment('WEATHER_LAT', defaultValue: '31.299677')) ??
      31.299677;
  static final double weatherLon = double.tryParse(
          const String.fromEnvironment('WEATHER_LON', defaultValue: '31.354846')) ??
      31.354846;
  static const String weatherCityName = String.fromEnvironment(
    'WEATHER_CITY',
    defaultValue: 'قرية أبوديشيشة',
  );
}
