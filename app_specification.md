# توثيق تطبيق قرية أبوديشيشة - المشروع النهائي

## 1. الهيكل الشجري (Project Structure)

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
│   │   └── login.dart
│   ├── home/
│   │   ├── home.dart
│   │   ├── splash.dart
│   │   └── about_app.dart
│   ├── village/
│   │   └── about.dart
│   ├── news/
│   │   ├── list.dart
│   │   └── detail.dart
│   ├── obituaries/
│   │   ├── list.dart
│   │   └── detail.dart
│   ├── occasions/
│   │   ├── list.dart
│   │   └── detail.dart
│   ├── market/
│   │   ├── products.dart
│   │   ├── product_detail.dart
│   │   ├── seller_detail.dart
│   │   ├── seller_gallery.dart
│   │   ├── seller_reviews.dart
│   │   ├── cart.dart
│   │   ├── cart_screen.dart
│   │   └── add_product.dart
│   ├── services/
│   │   ├── detail.dart
│   │   └── request.dart
│   ├── forum/
│   │   ├── posts.dart
│   │   └── create_post.dart
│   ├── emergency/
│   │   └── contacts.dart
│   ├── phone/
│   │   └── directory.dart
│   ├── profile/
│   │   └── main.dart
│   ├── settings/
│   │   └── index.dart
│   └── admin/
│       └── admin_dashboard.dart
├── models/
│   └── data_models.dart
├── routes/
│   └── app_routes.dart
└── services/
    ├── user_service.dart
    ├── review_service.dart
    ├── market_service.dart
    ├── news_service.dart
    ├── obituary_service.dart
    ├── occasion_service.dart
    └── phone_directory_service.dart
```

## 2. الحزم (Dependencies)

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
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
  flutter_slidable: ^3.0.0
  pull_to_refresh_flutter3: ^2.0.0
  skeletonizer: ^1.4.3
  connectivity_plus: ^5.0.2
  fluttertoast: ^8.2.14
  smooth_page_indicator: ^1.2.1
  flutter_animate: ^4.5.0
  google_fonts: ^6.3.3
```

## 3. مسارات التنقل (Routes)

| المسار | الشاشة | الملف |
|--------|--------|--------|
| `/splash` | شاشة البداية | `home/splash.dart` |
| `/` | الشاشة الرئيسية | `home/home.dart` |
| `/login` | شاشة تسجيل الدخول | `auth/login.dart` |
| `/about-app` | عن التطبيق | `home/about_app.dart` |
| `/about` | عن القرية | `village/about.dart` |
| `/obituaries` | سجل العزاء | `obituaries/list.dart` |
| `/obituaries/detail` | تفاصيل العزاء | `obituaries/detail.dart` |
| `/occasions` | سجل المناسبات | `occasions/list.dart` |
| `/occasions/detail` | تفاصيل المناسبة | `occasions/detail.dart` |
| `/news` | أخبار القرية | `news/list.dart` |
| `/news/detail` | تفاصيل الخبر | `news/detail.dart` |
| `/admin` | لوحة التحكم | `admin/admin_dashboard.dart` |
| `/market` | سوق القرية | `market/products.dart` |
| `/market/add` | إضافة منتج | `market/add_product.dart` |
| `/market/product` | تفاصيل المنتج | `market/product_detail.dart` |
| `/market/seller` | بيانات البائع | `market/seller_detail.dart` |
| `/market/seller/gallery` | معرض البائع | `market/seller_gallery.dart` |
| `/market/seller/reviews` | مراجعات البائع | `market/seller_reviews.dart` |
| `/market/cart` | سلة المشتريات | `market/cart_screen.dart` |
| `/service-request` | طلب خدمة | `services/request.dart` |
| `/service/detail` | تفاصيل الخدمة | `services/detail.dart` |
| `/forum` | المنتدى | `forum/posts.dart` |
| `/forum/create` | إنشاء منشور | `forum/create_post.dart` |
| `/emergency` | الطوارئ | `emergency/contacts.dart` |
| `/phone-directory` | دليل الهاتف | `phone/directory.dart` |
| `/profile` | الملف الشخصي | `profile/main.dart` |
| `/settings` | الإعدادات | `settings/index.dart` |

## 4. الميزات الرئيسية

- تسجيل دخول Google عبر Firebase
- شاشة رئيسية بتبويبات وخدمات قرية
- سوق إلكتروني محلي مع منتجات وعروض وسلة مشتريات
- تحميل صور المنتجات والبائعين تدريجيًا عبر `FadeInImage.assetNetwork`
- تقييم ومراجعات البائع مع حفظ في Firestore
- معرض صور مستقل للبائع
- مشاركة المنتجات عبر `share_plus`
- الاتصال والرسائل عبر `url_launcher`
- نظام أخبار ومناسبات وتعازي
- طلب خدمات ودليل هاتف للطوارئ
- شاشة مسؤول

## 5. Firebase Services

| الخدمة | الغرض |
|--------|--------|
| `UserService` | تسجيل الدخول وإدارة المستخدمين |
| `ReviewService` | إدارة تقييمات المنتجات |
| `MarketService` | إدارة منتجات السوق في Firestore |
| `NewsService` | إدارة أخبار المناسبات |
| `ObituaryService` | إدارة سجل العزاء |
| `OccasionService` | إدارة سجل المناسبات |
| `PhoneDirectoryService` | إدارة الدليل الهاتفي |
| `ImageUploadService` | رفع الصور إلى Firebase Storage |
| `ThemeService` | إدارة الثيم (فاتح/داكن) |

## 6. إعداد Firebase

### SHA-1 Fingerprint (Debug)
```
EE:04:D2:B9:EB:84:01:02:34:53:49:C4:17:1E:09:7C:8D:2D:A8:DC
```

### خطوات الإعداد:
1. أضف SHA-1 fingerprint إلى Firebase Console → Project Settings
2. فعّل "Sign in with Google" في Authentication
3. ضع `google-services.json` في `android/app/`
4. ضع `GoogleService-Info.plist` في `ios/Runner/`

## 7. حالة التوثيق والمراجعة

- ✅ تم تحديث المسارات لتطابق `lib/routes/app_routes.dart`
- ✅ تم تحديث التبعيات لتطابق `pubspec.yaml`
- ✅ تم توثيق الميزات الحالية للواجهة العربية وميزات السوق
- ✅ تم التأكين على وجود شاشة البداية وملفات Firebase الأساسية
- ✅ تم دمج Firestore مع جميع الأقسام
- ✅ تمت إضافة `firebase_options.dart` للتهيئة الصحيحة

## 8. طريقة التشغيل

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 9. حالة البناء

| البناء | الحالة |
|--------|--------|
| الأخطاء | 0 |
| التحذيرات | 0 |
| النتيجة | ✅ جاهز للعرض |