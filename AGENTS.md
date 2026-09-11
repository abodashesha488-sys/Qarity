# Qarity Project - Agent Documentation

## Project Overview
Qarity is a comprehensive digital platform for village community services (قرية أبوديشيشة).

## Build Status
- **Errors:** 0
- **Warnings:** 0
- **Info:** 0
- **Status:** Compiles successfully · `flutter test`: 70/70 passing

## Firebase Configuration

### Package Information
- **Package Name:** `qurity`
- **Project ID:** `abudshisha`

### SHA-1 Fingerprint (Debug)
```
لا تنشر SHA-1 أو SHA-256 علناً. أضفها فقط في Firebase Console من بيئة آمنة.
```

### Setup Instructions
1. Add SHA-1 to Firebase Console → Project Settings → Your apps
2. Enable "Sign in with Google" in Authentication
3. Ensure `google-services.json` is in `android/app/`

### Web Authentication Setup
For Google Sign-In to work on web:
1. Firebase Console → Project Settings → Authentication → Authorized domains
2. Add `abudshisha.web.app` to authorized domains
3. Ensure the Firebase config matches `lib/firebase_options.dart`

## ImgBB Image Upload (client-side)
- Image upload/delete is done directly from the client via the ImgBB API in `lib/services/image_upload_service.dart`.
- The API key is read from `AppConfig.imgbbApiKey` (`lib/core/constants/app_config.dart`).
- **For production**, inject the key at build time so the real value never lives in the repo:
  - `flutter build web --dart-define=IMGBB_API_KEY=<your_key>`
  - The value in `app_config.dart` is only a **dev default**; override it for releases and rotate it in ImgBB if leaked.
- Used by: add product, add news, medical submissions, and image deletion flows.

## Push Notifications (Vercel worker — no Blaze plan required)
Because Firebase Cloud Functions require the Blaze plan and this project is on Spark,
push notifications go through a Vercel Serverless function instead.

- Worker code: `api/push.js` (Node 18+, uses `firebase-admin`).
- Vercel config: `vercel.json` and root `package.json` (dep on `firebase-admin`).
- Client service: `lib/services/remote_push_service.dart` — fired on approve/publish
  in `AdminService.approveItem` and `AdminService.publishContent`.

### One-time setup
1. Create a **Service Account** key: Firebase Console → Project Settings → Service
   accounts → *Generate new private key*. Keep the JSON safe (it is git-ignored).
2. Push to GitHub, then in Vercel:
   - Import this repository.
   - Environment Variables:
     - `FIREBASE_SERVICE_ACCOUNT` — paste the JSON (or base64 of it).
   - Deploy → note the resulting URL (default baked in the client is
     `https://qarity.vercel.app/api/push`).
3. Every `git push` to `main` auto-redeploys the worker on Vercel.

### Authentication model (no shared secret, no build flags)
The worker authenticates each request with the sender's **Firebase ID Token**,
then verifies `users/{uid}.role in ['admin','medical_admin']` in Firestore.
Only a signed-in admin can trigger a village push. There is no secret to
embed, rotate, or leak.

### Build the Flutter app
Plain commands — push works out of the box:
```
flutter build web
flutter build apk --release
```
Optional override only if the worker moves: `--dart-define=PUSH_ENDPOINT=https://...`.
If the user isn't signed in, `RemotePushService` silently no-ops.

### Topics subscribed by every user on profile completion
`village_news`, `village_obituaries`, `village_occasions`, `village_market`,
`village_forum`, `village_services`, `village_medical`, `village_alerts`
(also re-subscribed on every Home open so existing installs join the alert channel).
Approval fan-out (`AdminService._pushMessageFor`) + `kPushTopicForCollection`
cover: news, obituaries, occasions, products, **shops**, forum, **service_providers**
(`village_services`, route `/services`), and medical (`village_clinics`, `pharmacies`,
**`medical_center_clinics`**, `blood_requests`, `blood_donors`).

### Legacy `functions/` folder
The original Cloud Functions code is still present at `functions/index.js`. It is
**not** deployed. Keep it as a reference — it will work identically if you upgrade
to Blaze and run `firebase deploy --only functions`.

## Firestore Security (server-side only)
- File: `firestore.rules`
- Deployed to project `abudshisha`
- Admin write/delete access via `users/{uid}.role == 'admin'`
- Medical content review access via `users/{uid}.role in ['admin','medical_admin']`
- Public read for content collections: `news`, `market_products`, `obituaries`,
  `occasions`, `forum_posts`, `village_clinics`, `pharmacies`, `blood_requests`,
  `blood_donors`, `medical_center_clinics`, `shops`, `buy_requests`, `donations`,
  `price_history`, `phone_directory`, `emergency_contacts`, `village_info`,
  `village_alerts/current` (urgent home alert; admin-only write)
- Authenticated create access for content collections (starts `isApproved: false`)
- **Service Directory (`service_providers`)**: public read; owner create only with `isApproved: false`; owner may update their own *unapproved* entry without touching `isApproved`; admin full access.
- ** Important:** Firestore rules are versioned in `firestore.rules` and published via `firebase.json`

## Project Structure
```
lib/
├── core/
│   ├── constants/     # App colors, constants
│   ├── theme/         # App theme configuration
│   └── utils/         # Helpers, navigator key
├── features/
│   ├── auth/          # Authentication (login, complete profile)
│   ├── home/          # Home, splash, about app
│   ├── market/        # Products, detail, add, seller pages
│   ├── news/          # News list, detail, view
│   ├── forum/         # Forum posts, create, detail
│   ├── profile/       # User profile (edit name, photo)
│   ├── settings/      # Settings, notifications
│   ├── services/      # Service requests, detail
│   ├── emergency/     # Emergency contacts
│   ├── phone/         # Phone directory
│   ├── village/       # Village info
│   ├── occasions/     # Occasions management
│   └── admin/         # Admin dashboard, detail, edit
├── services/
│   ├── user_service.dart
│   ├── forum_service.dart
│   ├── market_service.dart
│   ├── news_service.dart
│   ├── order_service.dart
│   ├── service_request_service.dart
│   ├── product_interaction_service.dart
│   ├── image_upload_service.dart
│   ├── theme_service.dart
│   ├── admin_service.dart
│   └── cache_service.dart
├── models/
│   ├── data_models.dart          # Parent — BaseModel + parts
│   ├── data_models_content.dart  # part — UserModel, NewsItem, MarketProduct, SellerProfile, SellerType, etc.
│   ├── data_models_community.dart# part — Obituary, Occasion, EmergencyContact, VillageInfo, ServiceRequest, ForumPost, etc.
│   ├── market_extra_models.dart  # Shop, BuyRequest, Donation
│   └── medical_models.dart       # MedicalCenterClinic, VillageClinic, Pharmacy, BloodDonor/Request, BloodType
├── widgets/           # Shared widgets
├── routes/
│   └── app_routes.dart
└── main.dart
```

## Services
- `UserService` - User authentication and management
- `AdminService` - Admin moderation, real-time streams, approve/reject/delete/edit, stats, activity log, admin detail/edit routes
- `CacheService` - Offline cache with Firestore type serialization
- `MarketService` - Market products and seller management
- `NewsService` - News management
- `ForumService` - Forum posts and comments
- `OrderService` - Order management
- `ServiceRequestService` - Service request creation and tracking
- `ProductInteractionService` - Likes and comments
- `ThemeService` - Theme management

## Models
- `UserModel` - User profile with role
- `NewsItem`, `MarketProduct`, `ForumPost`, `Obituary`, `Occasion`
- `AppOrder`, `EmergencyContact`, `ServiceRequest`, `Review`

## Admin Access
- **Role-based only** (no hardcoded email in Firestore rules).
- Firestore role values: `'user'` (default), `'seller'`, `'moderator'`, `'medical_admin'`, `'admin'`.
- **Privilege hardening (firestore.rules):** a user updating their *own* doc may NOT change `role`/`sellerType`/`isActive` — only `isAdmin()` (role `admin`) may change roles. Users `list` is admin-only; `get` is signed-in. New accounts cannot be created with a privileged role. `UserService.setRoleIfNeeded` was removed (dead + escalation vector).
- **Bootstrapping the first admin**: create your Firestore user document and set `role: 'admin'` (Firebase Console → Firestore → `users/{uid}`). After that, use the admin dashboard's Users tab to assign further roles.
- Optionally, at build time you may pass `--dart-define=BOOTSTRAP_ADMIN_EMAIL=<email>` to grant one email a client-side shortcut (empty by default — the source of truth is always the Firestore role).
- `AdminScreenWrapper` checks the optional bootstrap email, then falls back to Firestore role check via `AdminService.isAdminUser()`.
- `AdminService.isMedicalAdmin()` grants access to the Medical Center management when role is `medical_admin` or `admin`.

### User & seller role management (admin dashboard → المستخدمون)- Search by name/email + role filter chips (الكل/مستخدمون/بائعون/مشرفون/مدير طبي/مدراء/معطّلون) + live counters.
- Each account opens a management sheet: role (with per-role permission hints), seller type (image limits 1/3/5/10), enable/disable account (`setUserActive`), and delete.
- Self-protection: the signed-in admin sees the role controls disabled for their own account.
- `UserModel.roleLabel`/`canAccessAdminPanel` expose unified Arabic role labels; the profile header shows the role badge (+ seller type with image limit) and a panel shortcut for admin/medical_admin.
- Seller conversion flow: user request (`seller_requests`) → admin approval (`approveSellerRequest`) → creates `seller_profiles/{uid}` + sets `role:'seller'` + `sellerType` from `requestedSellerType` + invalidates user cache.

### Role Colors & Badges (single source of truth: `lib/core/utils/role_style.dart`)
- Sellers: gold seller → gold name + gold product/shop card border; super seller → silver; premium seller → red; regular seller → normal color.
- Admins: general admin (`role: admin`) → gold name + crown icon; `medical_admin`/`moderator` → role-colored name + star icon.
- Content (products, shops, forum posts, news, buy requests, donations) denormalizes the author's `role`/`sellerType` at creation time, so cards render colors/borders without extra reads.
- Disabled accounts (`isActive == false`) are signed out at splash and shown a notice.
- Use `RoleNameText(name, role, sellerType)` for any user-facing author/seller name.

## Admin Dashboard
- Review chips (14): News, Products, Shops, Obituaries, Occasions, Forum Posts, Seller Requests, Phone Directory, Service Directory (`service_providers`), Charity Medical Center Clinics (`medical_center_clinics`), Village Clinics, Pharmacies, Blood Requests, Blood Donors.
- Stats grid with counts
- Search bar and filter chips (all / pending)
- Pending count badges on tabs and AppBar
- Card items show title, metadata, and action buttons
- Action buttons: edit, approve, reject, delete with loading states
- Tapping a card opens `AdminDetailScreen` showing full request details
- Admin edit screen supports fields by collection type
- `medical_center_clinics` approval flow: clinics added by a `medical_admin` start `isApproved:false` (legacy/seeded docs default to approved via `fromJson ?? true`); the public Medical tab shows only approved+active; the admin dashboard gates new ones.
- Service Directory (`/services`, route `serviceRequest` → `ServiceDirectoryScreen`): tabs الفنيون/خدمات زراعية/خدمات تعليمية (user-submitted `service_providers`, admin-approved, dropdown-grouped lists) + دليل الهاتف (`PhoneDirectoryScreen(embedded: true)` keeps its own design/logic). Replaced the old "طلب الخدمة" request screens (`request.dart`/`detail.dart` deleted; `service_requests` collection kept for legacy stats).

## Recent Updates
- Service Directory details + engagement: tapping any provider card (الفنيون/زراعية/تعليمية — not the phone-book tab) opens `ServiceProviderDetailScreen` (`/services/detail`) with formatted content, a 5-star rating (aggregate kept on the parent doc via a Firestore transaction in `ServiceProviderService.addComment`; one rating per user — replaced on re-rate) and comments under `service_providers/{id}/comments`. Rules: comments public read / owner-or-admin write; any signed-in user may update only `rating`/`ratingCount`. Admin can mark an entry **مميز** (gold accent, badge, sorted first) via a toggle in `AdminDetailScreen` or the edit-screen boolean field.
- App branding: `assets/images/Qurity.png` is now the launcher icon for Android/iOS/web (`dart run flutter_launcher_icons`; config key renamed `flutter_launcher_icons:` + `remove_alpha_ios`) and the logo in the Login screen and Home hero header (user photo circle next to settings). The redundant "دليل الهاتف" tile was removed from the home grid (it lives as a tab in Service Directory).
- Home screen full modern redesign (`features/home/home.dart`): fixed `_HeroHeader` (gradient, greeting + date, glass icon buttons), pinned `AlertWisdomBar` strip directly under it, sectioned scroller (`_SectionHead` with "عرض الكل" routes), gradient-circle `ModernServiceGrid`, and **"المنتجات المميزة" → "آخر المنتجات"** (newest-first). `_buildLiveProducts`/`_buildLiveNews` sort by `createdAt` desc client-side.
- Urgent village alert: `village_alerts/current` doc (`VillageAlert` model + `AlertService`) shown in `AlertWisdomBar` when active (red pulsing banner, tap = full dialog); when inactive/empty the strip shows rotating **"حكمة اليوم"** (`lib/core/constants/wisdoms.dart`, deterministic daily pick + tap to cycle). Admin dashboard overview has an `_AlertControlCard` (text box + تفعيل/إيقاف/تحديث); enabling writes the doc and fires a topic push to `village_alerts` (subscribed on profile completion + every Home open). Rules: `village_alerts` public read, admin-only write.
- Service Directory (دليل الخدمات): new `service_providers` collection + `ServiceProvider` model + `ServiceProviderService`; `ServiceDirectoryScreen` at `/services` with dropdown-grouped tabs الفنيون/خدمات زراعية/خدمات تعليمية (Egypt-education stages & subjects presets) + embedded `PhoneDirectoryScreen(embedded:true)`; submissions start `isApproved:false` and go through the new admin review chip with FCM fan-out (`village_services`). Old request screens `features/services/request.dart` + `detail.dart` deleted.
- Admin review gained chips for **المحلات** (`shops` — fixes: created shops never appeared for approval), **دليل الخدمات** (`service_providers`), and **عيادات المركز الخيري** (`medical_center_clinics`); personal approve/reject notifications + routes extended for all three.
- Charity Medical Center approval flow: `MedicalCenterClinic.isApproved` (legacy/seeded default approved), new center clinics from `medical_admin` wait for admin approval, public list filters approved+active.
- Village clinics & pharmacies: cards redesigned (compact professional rows) and now open full detail screens `VillageClinicDetailScreen`/`PharmacyDetailScreen` (`/medical/clinic-detail`, `/medical/pharmacy-detail`).
- Firestore rules hardened: `shops` create requires `isApproved:false` + owner-field updates; new `service_providers` block; `phone_directory` create requires `isApproved:false`.
- Tests: +6 (`test/services/service_directory_test.dart`); suite now 58/58.
- `navigatorKey` is now wired into `MaterialApp` (`main.dart`), so global toasts (`AppHelpers.showToast`) and notification-tap navigation (`NotificationService._tryNavigate`) actually resolve a context. The bottom nav remains home-only (a global persistent bar was implemented then reverted at user request).
- Search focus fix: `OfflineStreamBuilder` is now `StatefulWidget` that pins the last valid data across transient re-subscriptions, so the search `TextField` no longer loses focus/remounts after the first keystroke (fixed once, applies to all ~12 pages).
- News list header: moved search into `SliverAppBar.bottom` to stop the title overlapping the search box.
- Seller image limits set to regular 1 / super 3 / premium 5 / gold 10 (all derived from `SellerType.maxImages`, so no per-screen changes).

- Removed dead code: `features/market/products.dart` (was unused, ~1178 lines).
- Removed unused l10n: `lib/l10n/*` and `l10n.yaml` and `generate: true` in pubspec (all strings hardcoded Arabic).
- Fixed latent bug: `AdminService.getPendingSellerRequestsCount` now uses `status == 'pending'` (was `isApproved == false` which never matched).
- Firestore rules: removed hardcoded admin email — admin access is purely `users/{uid}.role == 'admin'`.
- ImgBB API key: reads `--dart-define=IMGBB_API_KEY`; dev default retained but should be overridden for production.
- Offline-first: Firestore persistence enabled (`persistenceEnabled: true, CACHE_SIZE_UNLIMITED`), `ConnectivityOverlay` shows offline banner globally, background init (notifications + connectivity) no longer blocks `runApp`, splash opens faster from cached auth.
- Split monolithic files via Dart `part`: `data_models.dart` → content/community parts, `admin_dashboard.dart` → models/overview/review/users/reports parts, `market_tabs_screen.dart` → market/shops/buy-donate parts.
- Services made test-friendly with optional `FirebaseFirestore` injection: `MedicalCenterService`, `VillageClinicService`, `PharmacyService`, `BloodBankService`, `ShopService`, `DonationService`, `BuyRequestService`, `PhoneDirectoryService`.
- Added 21 service tests (`test/services/medical_service_test.dart`, `phone_and_shop_test.dart`). Suite now 50/50.
- Push notifications: implemented via Vercel serverless (`api/push.js`) + `RemotePushService` since Firebase
  Cloud Functions require a Blaze plan. Admin `approveItem` / `publishContent` now fan out to FCM topics.
- Admin approve/reject/delete/edit buttons now working with proper loading states
- Added AdminDetailScreen to view full request content before approval
- Added AdminEditScreen for inline editing of approved/pending content
- Updated admin_dashboard to open detail view on item tap
- AdminService exposes approveItem, rejectItem, deleteItem, updateItem for direct collection access
- Fixed BuildContext usage across async gaps with mounted checks
- Reduced RenderFlex overflow in market product cards
- Fixed stale username display and missing buyer phone in orders
- Removed silent error handling swallowing in order service streams
- Added CacheService.invalidateUser(uid) called after role changes
- Added firestore.rules with admin permissions and deployed to Firebase
- Added navigator_key.dart for global scaffold messaging
- Added service_request_service.dart for service_requests collection
- Removed redundant floating action buttons from services pages and admin dashboard
- Redesigned home screen bottom nav with centered FAB and bottom sheet
- Redesigned obituaries, occasions, phone directory, and village about screens
- Fixed theme.textMedium typo in about.dart
- Added NotificationsSettingsScreen route
- Fixed seller order history StreamBuilder error states

## Deployment
The app is deployed on Firebase Hosting:
- URL: https://abudshisha.web.app

## Last Updated
2026-07-07T03:54:00+03:00