# Qarity

تطبيق قرية أبوديشيشة - منصة رقمية متكاملة لخدمات المجتمع القروي

## نظرة عامة

`Qarity` هو تطبيق Flutter متعدد المنصات يُقدّم خدمات مجتمعية للقرية مثل:
- سوق محلي مع منتجات وبائعين
- نظام تقييم وآراء
- قائمة أخبار وسجل مناسبات وتعازي
- طلب الخدمات والدليل الهاتفي
- منتدى اجتماعي
- شاشة إدارة المسؤول مع موافقة/رفض/تعديل المحتوى

## هيكل المشروع

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/
│   │   └── app_colors.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── animations.dart
│       └── helpers.dart
├── features/
│   ├── auth/
│   │   ├── login.dart
│   │   └── complete_profile.dart
│   ├── home/
│   │   ├── home.dart
│   │   ├── splash.dart
│   │   └── about_app.dart
│   ├── village/
│   │   └── about.dart
│   ├── news/
│   │   ├── list.dart
│   │   ├── detail.dart
│   │   └── view.dart
│   ├── obituaries/
│   │   ├── list.dart
│   │   └── detail.dart
│   ├── occasions/
│   │   ├── list.dart
│   │   ├── detail.dart
│   │   └── add.dart
│   ├── market/
│   │   ├── products.dart
│   │   ├── product_detail.dart
│   │   ├── seller_detail.dart
│   │   ├── seller_gallery.dart
│   │   ├── seller_reviews.dart
│   │   ├── seller_orders.dart
│   │   ├── cart.dart
│   │   ├── cart_screen.dart
│   │   └── add_product.dart
│   ├── services/
│   │   ├── detail.dart
│   │   └── request.dart
│   ├── forum/
│   │   ├── posts.dart
│   │   ├── post_detail.dart
│   │   └── create_post.dart
│   ├── emergency/
│   │   └── contacts.dart
│   ├── phone/
│   │   └── directory.dart
│   ├── profile/
│   │   └── main.dart
│   ├── settings/
│   │   ├── index.dart
│   │   └── notifications.dart
│   └── admin/
│       ├── admin_dashboard.dart
│       ├── admin_detail.dart
│       └── admin_edit.dart
├── models/
│   └── data_models.dart
├── routes/
│   └── app_routes.dart
└── services/
    ├── user_service.dart
    ├── forum_service.dart
    ├── market_service.dart
    ├── news_service.dart
    ├── order_service.dart
    ├── service_request_service.dart
    ├── product_interaction_service.dart
    ├── image_upload_service.dart
    ├── theme_service.dart
    ├── admin_service.dart
    └── cache_service.dart
```

## Firebase Configuration

### SHA-1 Fingerprint (Debug)
```
EE:04:D2:B9:EB:84:01:02:34:53:49:C4:17:1E:09:7C:8D:2D:A8:DC
```

### إعداد Firebase
1. أضف SHA-1 fingerprint إلى Firebase Console → Project Settings → Your apps
2. فعّل "Sign in with Google" في Authentication
3. ضع ملف `google-services.json` في `android/app/`
4. ضع ملف `GoogleService-Info.plist` في `ios/Runner/`

## المميزات الرئيسية

- دعم تسجيل الدخول بـ Google عبر Firebase
- شاشة رئيسية تحتوي على تبويبات خدمات القرية
- سوق إلكتروني محلي مع عروض ومنتجات بنظام صورة متأخرة التحميل (`lazy loading`)
- عرض تفاصيل المنتج، الاتصال بالبائع، ومشاركة المنتج
- معرض صور للبائع مع تحميل صور الشبكة تدريجيًا
- صفحة مراجعات البائع مع حفظ التعليقات في Firestore
- سلة مشتريات متكاملة
- قسم أخبار وقسم مناسبات وتعازي
- نظام خدمات وتعليمات طوارئ ودليل هاتف
- لوحة تحكم للمسؤول تعرض الطلبات المعلقة وإمكانية:
  - عرض تفاصيل الطلب كاملة
  - تعديل المحتوى
  - موافقة / رفض / حذف مع حالات تحميل

## التبعيات الأساسية

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_localizations:
    sdk: flutter
  firebase_core: ^3.15.2
  cloud_firestore: ^5.6.12
  google_sign_in: ^6.3.0
  firebase_auth: ^5.7.0
  firebase_storage: ^12.4.10
  image_picker: ^1.2.2
  http: ^1.2.2
  url_launcher: ^6.2.0
  share_plus: ^13.1.0
  shared_preferences: ^2.3.0
  lottie: ^3.0.0
  flutter_rating_bar: ^4.0.0
  confetti: ^0.7.0
```

## مسارات التنقّل

- `AppRoutes.home` -> `lib/features/home/home.dart`
- `AppRoutes.market` -> `lib/features/market/products.dart`
- `AppRoutes.marketProductDetail` -> `lib/features/market/product_detail.dart`
- `AppRoutes.marketCart` -> `lib/features/market/cart_screen.dart`
- `AppRoutes.admin` -> `lib/features/admin/admin_dashboard.dart`
- `AppRoutes.adminDetail` -> `lib/features/admin/admin_detail.dart`
- `AppRoutes.adminEdit` -> `lib/features/admin/admin_edit.dart`
- `/market/seller` -> `lib/features/market/seller_detail.dart`
- `/market/seller/gallery` -> `lib/features/market/seller_gallery.dart`
- `/market/seller/reviews` -> `lib/features/market/seller_reviews.dart`

## كيفية التشغيل

1. تثبيت الحزم:
   ```bash
   flutter pub get
   ```
2. تشغيل التطبيق على جهاز أو محاكي:
   ```bash
   flutter run
   ```
3. تشغيل فحص التحليل:
   ```bash
   flutter analyze
   ```
4. تشغيل الاختبارات:
   ```bash
   flutter test
   ```

## حالة المشروع

| البناء | الحالة |
|--------|--------|
| الأخطاء | 0 |
| التحذيرات | 0 |
| النتيجة | ✅ جاهز للعرض |

## ملاحظات إضافية

- يعتمد التطبيق على ملفات `google-services.json` و `GoogleService-Info.plist` للتكامل مع Firebase.
- تمت محاولة المحافظة على تجربة عربية وواجهة RTL في معظم الشاشات.
- يحتوي السوق على خاصية عرض صور الشبكة تدريجيًا مع `FadeInImage.assetNetwork`.
- البيانات تُخزن في Firestore مع دعم المصادقة عبر Google.
- التحديثات الآن لحظية (real-time) في: السوق، الأخبار، المنتدى، الطلبات، والشاشة الرئيسية عبر Firestore Streams.
- السلة استخدمت `ChangeNotifier` مع `ListenableBuilder` لضمان تحديث فوري عند الإضافة/الحذف/تعديل الكمية.
- قواعد أمان Firestore منشورة على مشروع `abudshisha` مع صلاحيات أدمن للتعديل والحذف على جميع الأقسام.
- جميع أزرار لوحة التحكم (موافقة/رفض/حذف/تعديل) تعمل مع حالة تحميل وتأكيدات مناسبة.
