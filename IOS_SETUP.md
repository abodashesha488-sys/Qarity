# إعداد iOS لتطبيق Qarity

## ⚠️ قبل البدء: المتطلبات
- **Mac** مع **Xcode 15+**
- **Apple Developer Program** ($99/سنة) للنشر على TestFlight
- **CocoaPods** (`sudo gem install cocoapods`)

---

## 1️⃣ تغيير Bundle Identifier (مهم جداً!)

البندل الحالي `com.example.qarity` **مخصص للتجربة فقط** ولن يعمل للإنتاج.

### في Xcode:
1. افتح `ios/Runner.xcworkspace`
2. اختر **Runner** (المشروع) → **Targets → Runner** → **Signing & Capabilities**
3. غير **Bundle Identifier** لشيء فريد (مثلاً: `com.yourname.qarity`)
4. تأكد أن **Team** مختار (Apple Developer Account)

### في `firebase_options.dart`:
حدث `appId` لـ iOS ليطابق البندل الجديد (من Firebase Console).

### في `ios/Runner/GoogleService-Info.plist`:
حدث `BUNDLE_ID` و `REVERSED_CLIENT_ID` و `GOOGLE_APP_ID`.

---

## 2️⃣ تحميل GoogleService-Info.plist الحقيقي

1. اذهب إلى **Firebase Console** → Project Settings → iOS App
2. إذا لم يكن موجوداً: **Add App** → Bundle ID: `com.yourname.qarity`
3. حمل **GoogleService-Info.plist**
4. استبدل الملف في `ios/Runner/GoogleService-Info.plist`
5. **اسحب الملف** إلى Xcode في مجموعة **Runner** (اختر "Copy items if needed")

---

## 3️⃣ إعداد Push Notifications (APNs)

### في Firebase Console:
1. Project Settings → Cloud Messaging → **APNs Authentication Key**
2. إذا لم يوجد: **Upload** → اختر ملف `.p8` من Apple Developer
3. أدخل **Key ID** و **Team ID**

### في Xcode:
1. **Runner** → **Signing & Capabilities** → **+ Capability**
2. أضف **Push Notifications**
3. أضف **Background Modes** → ✅ **Remote notifications**
4. أضف **App Groups** (اختياري) → `group.com.yourname.qarity`

### في `ios/Runner/Runner.entitlements`:
```xml
<key>aps-environment</key>
<string>production</string>  <!-- development للاختبار، production للإنتاج -->
```

---

## 4️⃣ تثبيت Pods والبناء

```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

---

## 5️⃣ الأرشيف والرفع لـ TestFlight

### في Xcode:
1. **Product → Archive** (انتظر حتى ينتهي)
2. النافذة تفتح تلقائياً → **Distribute App**
3. اختر **TestFlight & App Store** → **Next**
4. اختر **Automatically manage signing** → **Next**
5. **Upload** → انتظر حتى ينتهي

### في App Store Connect:
1. اذهب إلى **TestFlight** → **Internal Testing**
2. أضف **Internal Testers** (إيميلات فريقك)
3. يرسل لهم دعوة بتطبيق **TestFlight** على الآيفون

---

## 6️⃣ تحديثات مستقبلية

لإصدار جديد:
```bash
# غيّر الإصدار في pubspec.yaml
version: 1.0.5+5

flutter build ios --release
# ثم Archive في Xcode كما سبق
```

---

## 🔧 الملفات المضافة/المحدثة

| الملف | الوصف |
|-------|--------|
| `ios/Podfile` | إعدادات CocoaPods مع platform 13.0 |
| `ios/Runner/Info.plist` | Permissions للكاميرا، الصور، الموقع، الإشعارات، إلخ |
| `ios/Runner/Runner.entitlements` | Push Notifications + App Groups |
| `ios/Runner/GoogleService-Info.plist` | **قالب** - استبدله بالملف الحقيقي من Firebase |

---

## ❗ مشاكل شائعة وحلولها

| المشكلة | الحل |
|----------|------|
| `Pod install` يفشل | `pod repo update` ثم `pod install --repo-update` |
| خطأ Signing | تأكد أن Team مختار و Bundle ID فريد |
| Push لا يعمل على الجهاز الحقيقي | يجب أن يكون `aps-environment: production` ويتم البناء بـ Release profile |
| Google Sign-In يفشل | تأكد أن `REVERSED_CLIENT_ID` في Info.plist يطابق GoogleService-Info.plist |
| Firebase لا يتصل | تأكد أن `GoogleService-Info.plist` مضاف في Xcode Target |

---

## 📱 اختبار سريع بدون $99 (للترجيع فقط)

على ماك مع Apple ID مجاني:
```bash
flutter build ios --debug
# في Xcode: Product → Run على الآيفون الموصول بـ USB
```
⚠️ التطبيق يعمل **7 أيام فقط** ثم يحتاج إعادة تثبيت.

---

## 📞 تحتاج مساعدة؟

- راجع [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- راجع [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)