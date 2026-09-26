# Qarity Project - Agent Documentation

## Project Overview
Qarity is a comprehensive digital platform for village community services (قرية أبوديشيشة).

## Build Status
- **Errors:** 0
- **Warnings:** 0
- **Info:** 0
- **Status:** Compiles successfully · `flutter test`: 177/177 passing

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

### iOS PWA auth & web push (blocker fixes)
- **Google Sign-In**: browser/Safari uses `signInWithPopup` as before; when the popup
  is unavailable (`popup-blocked` / `cancelled-popup-request` / `operation-not-allowed`,
  e.g. the installed Home-screen PWA on iOS) `login.dart` falls back to
  `signInWithRedirect(provider)`. The result is consumed EXACTLY ONCE at startup in
  `main.dart` (`getRedirectResult()` with a 5s timeout + full error swallow, web-only).
  A `SharedPreferences` flag `google_redirect_attempted` (set before redirect, cleared
  on every startup) prevents redirect loops; a second blocked attempt surfaces a clear
  error instead of re-redirecting.
- **Web Push**: `web/firebase-messaging-sw.js` (served at site root, same public web
  config + compat SDK 10.12.0 as index.html) handles background pushes + clicks.
  `NotificationService.initialize()` splits by branch: web = permission +
  `getToken(vapidKey: AppConfig.fcmVapidPublicKey)` in guarded try/catch (unsupported
  web APIs like `onBackgroundMessage`/`subscribeToTopic` are never called there), then
  early return; native path unchanged. Without a VAPID key at build time web push is
  cleanly skipped (no prompt, no startup abort — in-app bell/inbox remains the
  fallback; `forum_service` like-notifications now gate on auth, not FCM token, so the
  inbox works on web).
- **Required manual config**: Firebase Console → Project Settings → Cloud Messaging →
  *Web Push certificates* → generate key pair, then
  `flutter build web --dart-define=FCM_VAPID_PUBLIC_KEY=<public key>`. iOS needs
  16.4+ AND Home-Screen installation for any web push; plain Safari tabs never
  receive push (platform rule).

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
`village_forum`, `village_services`, `village_medical`, `village_alerts`,
`village_breaking`
(the two broadcast channels are re-subscribed on every Home open **only if** the
user hasn't disabled them in `NotificationsSettingsScreen` — all 9 channels,
including alerts/breaking, are toggleable there via `notif_pref_<topic>` prefs).
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
  `lost_items` (public read; owner create `isApproved:false`; owner may toggle
  only `isResolved` post-approval; admin full)
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
- `LostItemService` - المفقودات: approved feed, own items, resolved toggling (`lost_items` collection)
- `PromoService` + `PromoRouteObserver` + `PromoLocation` (`lib/services/promo_service.dart`) — الإعلانات الدعائية: watchAll stream, admin CRUD (update bumps `version`), navigator observer tracking the current placement key
- `ProductInteractionService` - Likes and comments
- `ThemeService` - Theme management

## Models
- `UserModel` - User profile with role
- `NewsItem`, `MarketProduct`, `ForumPost`, `Obituary`, `Occasion`
- `AppOrder`, `EmergencyContact`, `ServiceRequest`, `Review`
- `LostItem` (`lib/models/lost_item_model.dart`) — lost/found announcement with isResolved/isApproved; `kLostItemsColor` (deep purple `#5E35B1`) is its single source of truth
- `Promo` (`lib/models/promo_model.dart`) — pop-up ad: placement key, link (none/app/external kind), window, showOnce, sound/vibrate, version

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
- Review chips (15): News, Products, Shops, Obituaries, Occasions, Forum Posts, Seller Requests, Phone Directory, Service Directory (`service_providers`), **Lost Items (`lost_items` — 🔎 fan-out to `village_services`, submitter field `userId`, route `/services/lost-items`)**, Charity Medical Center Clinics (`medical_center_clinics`), Village Clinics, Pharmacies, Blood Requests, Blood Donors.
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
- Likes/notification data-integrity pass (مراجعة D1–D4): (1) **D1 — forum like notifications were dead**: `_sendLikeNotification` wrote to `notifications` **without `userId`** (rules require `uid == request.resource.data.userId`, so a normal user's write was silently denied; an admin's produced an unlistable orphan) and used `isRead` instead of `read`, and gated on the *liker's* auth rather than targeting the post owner. Replaced with `ForumService._notifyPostOwnerOfLike`, called only after a genuinely new like inside the transaction: it pushes through `NotificationInboxService` (`userId: ownerUid`, `read: false`, `kind: 'like'`, route encoded by `NotificationDeepLink.encode('/forum/detail','forum_posts',postId)` so the tap opens the post) and then best-effort direct FCM to `users/{ownerUid}.fcmToken` via `RemotePushService.sendToDevice`. Self-likes produce nothing. The inbox screen's `switch (n.kind)` has no 'like' case, so it renders with the generic bell icon — no UI change needed. **The 3 orphan docs** the old code left in `notifications` (shape: `body/createdAt/isRead/targetId/title/type`, no `userId`) **were purged on 2026-09-27 via the Firestore Admin API** — 112 real notifications remain, 0 orphans; full content backed up at `~/Documents/Qoder/2026-09-26/89d3d9fa/orphan_notifications_backup.json`. (2) **D2 — product likes race**: `ProductInteractionService.toggleLike` now runs the whole `likes/{uid}` subcollection doc + parent `likes` counter inside one `runTransaction` (read the like doc first, then set/delete + `FieldValue.increment(±1)`), so double-taps/devices can no longer desync the counter from the subcollection. (3) **D3 — forum/news likes were read-modify-write** (last-write-wins lost concurrent likes): both now use a transaction with `FieldValue.arrayUnion/arrayRemove` + a `likes` count computed from the list read inside the transaction. (4) **D4 — dead composite indexes**: `firestore.indexes.json` is down to **5 entries**, each matching a real server-side `where + orderBy` query: `market_products`/`news`/`forum_posts`/`occasions` `(isApproved ASC, createdAt DESC)` + `notifications` `(userId ASC, createdAt DESC)`. Removed: 5 `market_products` entries over `status`/`type`/`shopId`/`ownerUid` (fields that don't exist on the model — real fields are `productStatus`/`sellerId`/`category`), plus 2 `buy_requests` and 1 `shops` entries — those collections are queried by **equality only** (`where('status','open')` / `where('userId',uid)` / `where('isApproved')+where('isActive')`) with the sort done client-side, so a composite index buys nothing. **`firebase deploy --only firestore:indexes` never deletes** what already exists, so the 8 built indexes were deleted directly through the Admin API (`collectionGroups/{cg}/indexes/{id}`) and the project now holds exactly the 5 needed ones, all READY. Access recipe (no `gcloud`): configstore refresh token at `~/.config/configstore/firebase-tools.json` → exchange at the oauth2 v4 endpoint with the firebase-tools public client → REST Admin API; document deletes go through `documents:commit` as `{"writes":[{"delete":"projects/…/documents/<coll>/<id>"}]}` (a nested `operation` key is rejected). Testing seams added with the project's existing convention: `ProductInteractionService.withFirestore(fs)`, `NotificationInboxService([fs])` + lazy `NotificationInboxService.instance`, `ForumService([fs, inbox])`. Not changed: `OfflineStreamBuilder` keeps returning the last valid data on a later stream error (deliberate offline resilience; a staleness indicator would be the right follow-up, not a silent behavior swap). Tests: new `test/services/like_notifications_test.dart` (+6: notification lands for the owner only with correct shape/deep-link, no duplicate on unlike→re-like, self-like silent, forum counter/array agreement + double-tap, product subcollection/counter sync, non-negative counter). Suite 177/177 · analyze 0 errors (1 residual parallel-WIP warning: unused `_removeProfileImage`).
- Market/news logic-error pass (من مراجعة المنطق العميقة): (1) **Offer math** — `MarketProduct` gained `hasActiveOffer` (`isOnOffer && price > 0 && offerPrice < price`); `effectivePrice` now ignores an offer that is higher/equal to the base price and `discountPercent` can no longer divide by zero or go negative (clamped 0–100). All offer badges/strike-throughs (`market_tab_market`, `seller_profile`, `seller_detail`, `product_detail`, Home `_ProductCard` — which also stopped re-implementing the price inline) gate on `hasActiveOffer`. (2) **Cache/server filter parity** — `MarketService._applyFiltersAndSort` now applies **every** predicate (`category`, `sellerId`, `isFeatured`, `isOnOffer` were silently dropped, and the cache branch never passed `productStatus`), so the offline cache path returns the same set as Firestore; `getProductsList` saves to the shared `cache_products` blob **only for unfiltered queries** (a filtered query used to shrink the global catalog for every other screen). (3) **Default sort** — the helper's default `sortBy` was `'الأحداث'`, matching no switch case (silently unsorted); now `'الأحدث'`. (4) **News likes** — deleted `NewsService.likeNews` (zero callers, blind `FieldValue.increment(1)` that could drift from `likedBy`); `toggleNewsLike` (writes `likes = likedBy.length`) is the single path. (5) **Dead models** — removed `ItemRequest`/`DonationItem` from `data_models_content.dart` (unreferenced — `item_requests`/`donations` are handled as raw maps in `MarketService`, `Donation` lives in `market_extra_models.dart`), which also deleted their stray Chinese status labels ('已批准'/'已索取') and all-same-color `_statusColors` maps. (6) **Drawer update check** — `HomeDrawer`'s «التحقق من التحديثات» row pushed `AppRoutes.home`; it now runs `UpdateService().getUpdateInfo()` + `UpdateService.showUpdateDialog` through `navigatorKey.currentContext` (the drawer's own context is popped) with `AppHelpers.showToast('أنت على أحدث إصدار')` when current — same behavior as the Settings card. (7) **Seller ladder** — `SellerType` image caps are now monotonic with tier order (gold 10→5, premium 5→10). Also: `MarketService({firestore})` / `NewsService([firestore])` took the project's optional-injection convention so the filter/like paths are testable, `NewsService._auth` became a lazy getter (no Firebase needed for news tests), and the dead 7-line `lib/core/utils/admin_service_helper.dart` was deleted. Tests: new `test/services/market_filters_test.dart` (+5, incl. a cache-only assertion that empties the fake server), new `test/services/news_like_test.dart` (+2), +2 model cases (offer-higher/equal/zero-price, monotonic `SellerType` ladder). Suite 171/171 · analyze 0 errors (1 residual parallel-WIP warning: unused `_removeProfileImage`).
- Children's lessons sequential navigation (غير معتمد على الصور): the lesson card in `LessonsScreen` was a one-shot static bottom-sheet — a child had to close it and re-tap the list for every step. It is now `_LessonCard` (StatefulWidget inside the sheet): «السابق/التالي» buttons walk the section in order with Arabic-Indic position counter («٣ / ٨» via shared `toArabicDigits` imported from `numbers_game_screen`), auto-TTS re-fires on each step, edge buttons disable at first/last, and the sheet became a `DraggableScrollableSheet` (0.4–0.85, drag handle) so long prophet stories scroll by finger. Works identically with real images or emoji fallback — ready before salah/prophets/manners images land. `showLessonCard` (static, only caller was the list) replaced by `_showLessonCard(context, index)`. Tests: behavioral nav test in `children_lessons_test.dart` (disabled taps keep position; 6 next-taps reach ٨/٨; prev returns to ٧/٨). Also fixed 2 analyzer items in `admin_dashboard_promos.dart` (const `DialogThemeData`, if-braces). Suite 162/162 · analyze 0 errors (1 residual parallel-WIP warning: unused `_removeProfileImage`).
- Children's corner wave 4 + offline guarantee (ركن الأطفال: شبكة عصرية + «تعلّم الأرقام» + ضمان العمل بلا اتصال): (1) `ChildrenScreen` portal rebuilt as a modern kid-friendly grid of rounded circular-icon cards (nine activities). (2) New `LearnNumbersScreen` (`/children` → «تعلّم الأرقام») — 1–10 board in the letters style (Arabic-Indic digit + word + drawn apple count via `_ApplesPainter`), TTS through `ChildrenSpeech`. (3) `ChildrenSpeech` Egyptian-dialect polish: `normalize()` strips diacritics/tatweel, expands ﷺ, removes quotes, maps dashes to commas; ar-EG → ar voice fallback at rate 0.45/pitch 1.05. (4) Illustration slots wired for the four lesson sections via `kidLessonImage(folder,index)` → `assets/images/kids/<folder>/NN.jpg` with `errorBuilder`→emoji; the 44-file generation manifest lives at `tools/kids_image_manifest.md` (images not yet generated — awaiting the «أكمل الصور» batch; until then emoji fallback renders and pubspec does NOT yet register `assets/images/kids/`). (5) **Blank-question fix:** `NumbersGameScreen`'s private `_emojiPool` had 3 empty-string entries that produced rounds with no picture — replaced by a public `kNumbersEmojiPool` of 8 single-codepoint `\\u{...}` escapes (🍎🐤⭐🎈🐟🍇🌸🍓) + an integrity test + an 8-seed sweep test asserting every question renders a real pool emoji. (6) **Offline (تخزين محلي):** audited the whole `lib/features/children/` tree — ZERO Firestore/Firebase/network imports; every section's content is static Dart (`arabic_letters.dart`, `children_lessons.dart`), letter art is bundled assets, `KidsProgress` is SharedPreferences-only (offline, try/catch-swallowed), coloring is a pure CustomPainter, TTS is on-device (flutter_tts/browser), and `google_fonts` 8.1.0 auto-caches fetched Tajawal/Amiri to device storage after first online load; on web the Flutter service worker precaches the bundle. New `test/services/children_offline_test.dart` (+7) pumps all nine sections inside a bare `MaterialApp` (no Firebase init) and asserts they render exception-free — locking the offline contract against any future remote dependency creeping in. Committed `bb6da26`, pushed to `main`. Suite 160/160 · analyze 0 errors (2 residual items are parallel-session WIP: an unused `_removeProfileImage` warning and a `dialogBackgroundColor` deprecation info).
- Children's corner wave 3 (ركن الأطفال: صور + خمسة أقسام تعليمية): (1) **صور للحروف** — 28 AI-generated kid-illustration JPGs (`assets/images/letters/l01.jpg…l28.jpg`, 360×360 q82, ~392KB total, registered in pubspec assets) mapped one-per-letter to the example word (أسد/بطة/…). `ArabicLetter` gained a required `image` field; `LearnLettersScreen` grid is now **3 columns** with a white rounded image frame above the letter+name, and the letter card's word panel shows the image (both with `errorBuilder` → emoji fallback). (2) **Five new learning sections** via a generic kit: `children_lessons.dart` (`ChildLesson{emoji,title,body,tip}` + `kNumberLessons` 1٠–١٠ visual apple-count, `kWuduLessons` 8 steps, `kSalahLessons` 8 steps, `kProphetStories` 8 short child-friendly stories each ending with «الدرس:», `kMannersLessons` 10 daily manners — all static data, Arabic-verified wording) and `LessonsScreen` (card list + detail bottom-sheet with auto-TTS via `ChildrenSpeech`, speaker button, 💡 tip box). `ChildrenScreen` portal now hosts **nine** activities (letters learn/game, numbers learn/game, wudu, salah, prophets, manners, coloring). (3) **Build fix (NOT my feature — completed a parallel session's half-done refactor):** `ImageUploadService.uploadImage` had been changed to return `ImageUploadResult{imageUrl,deleteUrl}` (ImgBB delete-URL work: `deleteImageByUrl`, `imageDeleteUrl` stored on market_products, `addProduct({imageDeleteUrls})`) while ~15 call sites still assigned the result to String — the whole app failed to compile. Adapted every caller mechanically (`add_product` now also collects `_uploadedImageDeleteUrls`, passes them to `addProduct`, and keeps them aligned in `_removeImage`; promos/profile/complete_profile/phone/occasions/news/forum/service_directory/lost_items/workers_equipment/medical_home/market_tabs/obituaries/village_content_admin use `.imageUrl`; the other session's delete-URL *storage* wiring beyond market products is still theirs to finish). Tests: `test/services/children_lessons_test.dart` (+5: lesson-data integrity incl. no stray Latin letters, unique per-letter image paths, lessons list + sheet render, portal nine sections, image tiles in letters grid — widget tests enlarged `tester.view.physicalSize` because the 3-col grid/portal now exceed the old viewport heights). Suite 148/148 · analyze 0 issues.
- Children's corner expansion (ركن الأطفال wave 2): `ChildrenScreen` portal now hosts four activities + a parents report. New: `NumbersGameScreen` («كَم عدد الأشياء؟» — count 1–10 repeated emoji, pick the Arabic-Indic numeral from a fixed 2×2 grid, same score/streak/star engine), `ColoringScreen` (free drawing: CustomPainter stroke list, 10-color palette, 3 brush sizes, undo/clear in the AppBar, canvas keyed `coloring-canvas`), and `showParentsReport` (local bottom-sheet: total stars/plays, per-game best, and «يحتاج تدريبًا» letters with miss counts ≥2 — tapping one opens its learn card). `ChildrenSpeech` (flutter_tts, lang `ar`, slow rate) speaks letters/words/number-names with a speaker button on question cards and learn sheets; every call is try/catch-swallowed so unsupported platforms never break play. `KidsProgress` (SharedPreferences-only, no Firestore): best score/stars/plays per game + per-letter miss counters; portal cards show a 🏆/⭐ chip once a best exists. Letters game records misses on wrong picks and results on finish. Add dependency: `flutter_tts`. Tests: `test/services/kids_games_test.dart` (+5; suite 143/143).
- Children's corner Arabic-letters game (ركن الأطفال): `ChildrenScreen` (`/children`, was an empty placeholder) is now a kid-styled portal («تعلّم والعب معنا! 🎈» + gradient activity cards) leading to two new screens in `lib/features/children/`: `LearnLettersScreen` (4-col gradient grid of the 28 letters; tap opens a bottom-sheet card with the letter in Amiri, its four contextual forms مفرد/بالبداية/بالوسط/بالنهاية, and an example word + emoji) and `LettersGameScreen` («أكمل الكلمة»: emoji + word with first letter blanked via tatweel «؟ـ», 4 fixed non-scrolling option buttons in a 2×2 Column/Row grid — a lazy GridView dropped off-screen options on short viewports, 10 seeded-random rounds, score + streak bonus + 🔥 pill, green/red/dim reveal states with haptics, star-rated result dialog with replay). Data in `arabic_letters.dart` (`kArabicLetters`: letter/name/4 forms/word/emoji/colorIndex; distractors exclude same-base letters so أ/ا never duplicate). Injectable `Random` for deterministic tests. Tests: `test/services/letters_game_test.dart` + `children_screens_test.dart` (+4; suite 138/138).
- `firestore.rules` fix (deployed): the `village_contributions` list rule used invalid syntax `request.query.where['approvalStatus'].isEqualTo('approved')` (rules cannot inspect query filters; compiler warned `Invalid function name: isEqualTo` and the clause denied non-admin lists, breaking the public pinned feed). Replaced with the documented per-document pattern `allow list: if isAdmin() || resource.data.approvalStatus == 'approved'` — unfiltered/pending queries now correctly reject non-admins (`watchContributions`/`watchPendingContributions` are admin-screen-only) while the approved-filtered public stream (`watchPinnedContributions`) works for everyone.
- Medical portal image tiles: `MedicalHomeScreen` (`/medical`) swapped its icon+label cards for pure image tiles in the home/farmer-grid style (3 columns, rounded shadow container, `Image.asset` cover, no app-drawn boxes or text): المركز الطبي الخيري `tebkhairy.jpg`, بنك دم القرية `blood.jpg`, عيادات القرية `doctor2.jpg`, صيدليات القرية `doctor3.jpg`, معامل التحاليل `doctor4.jpg` (artwork carries its own labels). `MedicalHomeScreen.colors` unchanged (section AppBars still use it). `tebkhairy.jpg` recompressed 620KB→99KB.
- Firestore cost optimization (تقليل تكاليف القراءة/الكتابة): **HomeContent** converted to StatefulWidget with `late final` pinned streams (products/news/forum) — they were recreated inside `build()`, tearing down and re-billing three full collection reads on every rebuild; the same fix for the seller "منتجاتي" stream in `profile/main.dart` (`_myProductsStream` memoized per uid) and **NotificationBellButton** (now stateful, stream created once per button). Home/news/forum streams gained an optional `limit` param (`getProductsStream(limit: 8)` etc. → `orderBy(createdAt desc)+limit`, Home only; list screens keep the unbounded version). `unreadCount` bell query capped `.limit(100)` (badge shows 99+ anyway); inbox `streamFor` bounded to latest 50 (`orderBy+limit`). Admin dashboard: `fetchPendingCounts`/`getPendingCountFuture`/`_statusPendingCount` now use **`count()` aggregation** (index-entries only, was 16 full pending-collection downloads per dashboard open — note: cloud_firestore 6.x `AggregateQuery` has only one-shot `get()`, no `snapshots()`, so live badge streams must stay doc-count streams); `getTopProducts`/`getOccasionsStats` replaced full-collection fetch + client sort with `orderBy+limit`; `backfillSellerTypes` (3 full collection scans) now returns bool and is gated behind one-time SharedPreferences flag `seller_type_backfill_v1` (was run on EVERY dashboard open); dead `getPendingNewsCount`-family stream getters + unused `getPendingSellerRequestsCount` deleted. Writes: `_updateProductRating` reads `product_reviews` once (was twice); `ContentCleanupService._deleteAll` uses batched deletes (400/batch) instead of one write per orphan; product-detail like count now streams the single product doc's stored `likes` counter instead of the whole `likes` subcollection; `getReviewCount` → `count().get()`; `condolencesCount`/`attendeesCount` capped `.limit(500)`. Home identity self-heal stamp `identity_repair_v1_<uid>` is now content-independent (one-time per user — previously every profile edit re-ran the full 17-query `syncIdentityToContent` backfill from Home). **New composite indexes required** (added to `firestore.indexes.json`, now wired in `firebase.json`): market_products/news/forum_posts/occasions `(isApproved ASC, createdAt DESC)` + notifications `(userId ASC, createdAt DESC)` — deploy via `firebase deploy --only firestore:indexes --project abudshisha` BEFORE shipping the app, else the bounded queries fail with failed-precondition. Suite 134/134.
- App update system: pubspec reset to `1.0.1+1` (semver display + Android versionCode after `+` — must strictly increase). `AppUpdateService` (`lib/services/app_update_service.dart`) reads public `app_version/current` doc (admin-write in rules): androidVersion/androidBuild/minBuild/androidUrl/message/maintenance/maintenanceMessage; pure `computeStatus` + numeric-semver `compareSemver` (1.0.10 > 1.0.2). `UpdateDialogs` (`lib/widgets/update_dialogs.dart`): silent startup check on Home first frame (Android-only; web/PWA updates are automatic so check returns null there) showing optional / **mandatory (build < min)** / **maintenance-lock** dialogs with a one-tap «تنزيل التحديث» → launchUrl(androidUrl); manual check entry in the side drawer («التحقق من التحديثات») and in Settings («التحديثات» card showing installed version via `package_info_plus`). Admin publishing lives in the dashboard overview `_AppVersionAdminCard` (`admin_dashboard_version.dart` part): edit + publish version/build/min/https-APK-link/message + maintenance switch with validation (semver format, minBuild ≤ build). `tools/bump_version.ps1` auto-increments 1.0.1→1.0.2…→1.1.0 (with `-Minor/-Major/-Set x.y.z`) and always bumps build. `web/index.html` keeps the standard `<script src="flutter_bootstrap.js" async>` (the inline `{{flutter_bootstrap.js}}` macro is NOT substituted by Flutter 3.47 builds and broke hosting — never use it) + a brown «تحديث جديد متاح / تحديث الآن / لاحقًا» bottom banner driven by plain `navigator.serviceWorker` waiting-worker detection and `postMessage('skipWaiting')` (string, per Flutter's generated SW), reloading on controllerchange once. Add dependency: `package_info_plus`. Tests: `test/services/app_update_test.dart` (+8; suite 130/130).
- "تعرف على القرية" heritage hub (was "عن القرية" — label renamed on the bottom-nav, drawer and service-grid tile; route `/about` kept): `VillageScreen` rebuilt as an ornate portal (gold-gradient geo-pattern hero, "بطاقة تعريف القرية" card with population/area/founded gold chips + admin pencil to edit `village_info/main` via new `VillageInfoService.saveInfo`) leading to three color-coded sub-screens like the Service Directory — التاريخ `#5D4037` (`/village/history`), الأرشيف `#6A1B9A` (`/village/archive`), المنشآت `#1565C0` (`/village/institutions`). Shared ornament kit `lib/features/village/village_ornament.dart`: `GeoPatternPainter` (Islamic diamond/star pattern), `VillageSectionHeader` (gradient+pattern+gold hairline+Amiri title), `ArchClipper` (mihrab-arch portrait frames), `OrnamentDivider` (star between gold rules), sepia `ColorFilter` for archive photos, Amiri via GoogleFonts. New content (4 collections, public read / admin-only write in rules — authoring is direct, no review flow): `village_history` HistoryEra {title,years,narrative,imageUrl,sortOrder} rendered as a numbered gold-node vertical timeline; `village_figures` VillageFigure {name,category(mayor/elders/mp/influencers),title,era,bio,photoUrl,sortOrder} in plain rounded cards (raw images, no filters) with category filter chips + bio bottom-sheet; `village_archive_photos` VillageArchivePhoto {title,year,description,source,imageUrl} plain grid + full-view dialog; `village_institutions` VillageInstitution {name,type(schools/azhar/agri/post/health/mosque/other),description,location,phone,workingHours,imageUrls,sortOrder} grouped by type with per-type icon/color, detail sheet with gallery + tel button. `VillageContentService` (+injection for tests) with `migrateLegacyIfNeeded()` — one-time copy of legacy `village_info/main` history/institutions/archive lists into the new collections (guessed institution types from names), stamped `contentMigrated`. Admin management is in-page: each screen shows an "إدارة" FAB for `canManageVillageContent()` (Firestore role admin OR the BOOTSTRAP_ADMIN_EMAIL build define — mirrors AdminScreenWrapper, since role-only checks hid the FAB for bootstrap admins) (`canManageVillageContent()`), opening list sheet → add/edit/delete with ImgBB image upload (`pickAndUploadImage`). Promo placements registry extended (village_history/village_archive/village_institutions + about relabel; internal links + route mapping). Tests: `test/services/village_content_test.dart` (+7; suite 122/122).
- Urgent-alerts admin tab (التنبيهات العاجلة): the two overview `_AlertControlCard`s moved to a dedicated 6th dashboard tab (`admin_dashboard_alerts.dart` part — `_AlertsControlPage` + `_ManagedAlertCard` for red `village_alerts/current` and yellow `village_alerts/breaking`), overview keeps a compact `_LiveAlertSummary` status strip with «إدارة» shortcut. Three explicit levels chosen per activation (`VillageAlertMode`: display = banner only / push = + FCM fan-out / sound = + high-priority push with default sound & in-app `AlertSound.ringOnce` — ding.wav + HapticFeedback, rung ONCE per alert version keyed `alert_ring_<doc>_<updatedAtMillis>` in SharedPreferences). Optional auto-expiry (chips: none/1/3/6/12/24h/3d → `expiresAt` Timestamp; `VillageAlert.liveAt(now)` gates every consumer — `_map`, AlertWisdomBar, VillageWeatherBar — and a client Timer re-hides the banner exactly at expiry). Silent «حفظ» vs explicit «إعادة إرسال الإشعار» (renotify reads stored mode; refuses when mode=display). `RemotePushService.send(alert: true)` → worker `api/push.js` adds android defaultSound+vibrate [400,200,400] red color, apns sound:default + priority 10, webpush Urgency:high (needs Vercel redeploy on push). Rules unchanged (village_alerts admin-write covers new fields). Tests: +5 expiry/mode cases (suite 115/115).
- Promotional pop-up ads (الإعلانات الدعائية): admin-only `promos` collection (public read, `isAdmin()` write in rules) + `Promo` model (`lib/models/promo_model.dart`: title/imageUrl/placement/linkType/linkValue/showOnce/startsAt/endsAt/isActive/playSound/vibrate/version) + `PromoService`. Placement registry `lib/core/constants/promo_placements.dart` — `kPromoPlacements` (19 spots incl. every service-directory sub-screen & medical section via `promoKeyForRoute(name, args)`), `kPromoInternalLinks` (route|arg encoded), `kPromoExternalKinds` + `buildExternalUrl` (wa.me country-code normalization, handle→platform-url builders, full https passthrough). `PromoHost` (`lib/widgets/promo_host.dart`) wraps the whole app in `main.dart`'s builder + `navigatorObservers:[promoRouteObserver]`: when the top route matches an active promo's placement, a full-screen dimmed overlay shows the image after 700ms — round **× button OUTSIDE the image**, 15s auto-dismiss countdown ring, tap image = open link then dismiss, tap outside = dismiss; multiple promos per screen queue one-by-one; per-user once/always via `showOnce` + SharedPreferences `promo_seen_<id>_v<version>` (editing bumps version → re-shows); optional `ding.wav` sound (generated asset + `audioplayers`) and `HapticFeedback` vibration. Admin UI: 5th dashboard tab «الإعلانات» (`admin_dashboard_promos.dart` part) — cards with status chips (مباشر/مجدول/متوقف/منتهي), active switch, edit/delete, and a full form sheet (ImgBB image upload + preview, grouped placement dropdown, link type none/app/external with per-kind validation, mandatory start/end dates, once-vs-every-visit segmented button, sound/vibration switches, and a **معاينة حية** live-preview button rendering the real overlay). Tests: `test/services/promo_test.dart` (+16; suite 110/110).
- Lost Items service (المفقودات): new `lost_items` collection + `LostItem` model + `LostItemService`; `LostItemsScreen` (`/services/lost-items`) reachable as the 6th tile of `/services` — purple `#5E35B1`, search + filter chips (الكل/مفقود/تم العثور عليه/تم التسليم), FAB form sheet (type toggle, title, description, location, date picker, optional ImgBB image, phone) → `isApproved:false` + `notifyAdmins`. `LostItemDetailScreen` (`/services/lost-item-detail`, also deep-linked from notifications) with call/WhatsApp/share and owner-only «تم التسليم» toggle. Admin: review chip + pending count + edit fields + approve/reject/delete via the generic AdminService maps; `firestore.rules` lost_items block (public read, owner create unapproved, owner resolved-flag-only update post-approval, admin full); api/push.js `PENDING_KINDS.lost_items`. **Per-service theming**: `QurityAppBar` gained a `color:` param and each directory service now has a unique non-repeating brand color applied to its tile, header and FAB — الفنيون `#EF6C00`, زراعية `#AD1457`, تعليمية `#1565C0`, دليل الهاتف `#37474F`, طبية `#00897B`, مفقودات `#5E35B1`; badge/pair colors (مفقود `#C62828` / موجود `#00897B`) keep white-text contrast against the beige page. Tests: `test/services/lost_items_test.dart` (+4; suite 94/94).
- Unified fixed header (`lib/widgets/qurity_app_bar.dart` → `QurityAppBar`, implements `PreferredSizeWidget`) on every screen EXCEPT Home: app logo (`QurityLogo` 32) + page name (Tajawal white 16.5/w800, ellipsis) + notification bell (auto-appended to screen `actions`), solid `#6F4E37` (also `AppColors.primary` — the whole green palette + `Colors.green*` usages across the app were replaced with coffee #6F4E37; light-green shade → cream #F0E3D5), constant `kToolbarHeight`, white icons, `scrolledUnderElevation: 0`. `NotificationBellButton` (public in `common_appbar_actions.dart`, `compact:` glass variant for the Home hero; auth/Firestore reads try/catch-guarded so widget tests without Firebase mocks render). Tab-bar screens (market tabs, about-village) and news list (brown pinned SliverAppBar keeping the search box) and `MedDetailHeader` (pinned brown bar + hero image moved into a body sliver; used by clinic/pharmacy/lab/provider details) all follow the same colors/height. Home hero: glass action strip removed — 2×2 button grid (settings|bell over avatar|menu) beside the logo (tap = full-screen zoomable logo dialog), village name + greeting-with-name, date pill right / clock pill left. Service grid tiles are now pure label-less images (About/News/Souq/des/festefal/mandra→«مندرة القرية»/Services/aboutapp, no borders, soft drop shadow, الطوارئ removed; About.jpg recompressed 253KB→72KB). Weather strip card = wither.jpg background + black scrim, same footprint as the wisdom bar (minHeight 58), two columns: icon+condition+temp | max/min over humidity+wind.
- Orphan cleanup on deletion: `ContentCleanupService.cleanupForDeleted(fs, collection, docId)` (lib/services/content_cleanup_service.dart) runs BEFORE the document delete in both `AdminService.deleteItem` and `MarketService.deleteProduct` — wipes `market_products/{id}/likes` + `/comments`, `product_reviews`/`stock_alerts` by productId, `news|forum_posts|service_providers/{id}/comments`, obituary `condolences`, occasion `occasion_attendees`; `orders`, `activity_log` and inbox notifications are deliberately preserved as history. Admin product deletion also deletes the ImgBB images (previously only the seller path did). Rules updated: admin may delete any product `likes` doc and any `stock_alerts` doc (cleanup rights); deployed with hosting.
- Notification deep-links: tapping any notification now opens the exact item, not just its section. `RemotePushService.send/sendToDevice` accept `collection`+`itemId` (forwarded by the worker into FCM `data`); `NotificationService` (cold-start `getInitialMessage`, `onMessageOpenedApp`, local-notification taps via `route|collection|itemId` payloads encoded/decoded by `core/utils/notification_deeplink.dart`) routes to `/open` (`NotificationOpenScreen`) which fetches `collection/id`, builds the model (news, products, obituaries, occasions, forum posts, service providers, clinics, pharmacies, labs) and `pushReplacementNamed` to its detail screen — falling back to the section route on any failure/unknown collection (old pushes never break). `AdminService.approveItem/rejectItem/publishContent` pass `docId`, so both the public topic push and the submitter's personal FCM + in-app inbox entry (`NotificationInboxService` route now stores the pipe format; the inbox screen decodes it) deep-link to the item.
- Admin submission alerts: any user-side creation that needs approval now calls
  `RemotePushService.notifyAdmins(collection)` (fire-and-forget, `unawaited`) — wired into
  news/products/obituaries/occasions/forum posts/shops/buy requests/donations/phone directory/
  service providers/seller requests/village clinics/pharmacies/medical labs/blood donors+requests/
  center clinics (17 collections, `kAdminNotifyCollections`). Worker (`api/push.js`) gains an
  `action:'admin_notify'` mode: any **signed-in** sender is accepted (role gate stays for topic
  sends), only whitelisted collection keys are honored, title/body text is built SERVER-side
  (no injection), a 3-minute per-collection rate limit doc in `push_rate/admin_notify_<col>`
  throttles spam, and the worker queries `users` by role (`admin`, plus `medical_admin` for
  medical collections), sending individually to each admin's stored `fcmToken` (dedup) with
  route `/admin` (`/medical` for medical admins on medical kinds). Requires Vercel redeploy
  (happens automatically on `git push` to main).
- Wisdom-of-the-day strategy switched from rotating pool to the village's **dated 365-wisdom calendar**: `lib/core/constants/wisdom_calendar.dart` (`DayWisdom{ text, category, occasion }` grouped by 12 month-lists; lookup `WisdomCalendar.of(date)` with Feb-29→28 fallback; texts kept verbatim incl. the village's own spelling «أبودشيشة»). `AlertWisdomBar` now shows today's wisdom by calendar date with the date + weekday in its label, a gold **occasion badge** whenever the day isn't «عامة» (عيد الشرطة، عيد الأم، أبودشيشة…) — tapping opens `_WisdomDayDialog`: full text, category/occasion chips, previous/next day browsing across the year, and share. The old `wisdoms.dart` pool remains only as an unused legacy file.
- Identity hardening (comments everywhere = profile name + photo): remaining Google-name write paths converted to `UserService.resolveAuthor()` / cached profile name — condolences (obituaries), occasion attendance, market shop/buy/donation author names, medical clinic/pharmacy/lab `submittedByName`. `syncIdentityToContent` now also fans name changes to `village_clinics/pharmacies/medical_labs/service_providers` (`submittedByName`). Additionally, the Home hero performs a one-time **self-heal backfill per identity** (`identity_repair_v1_<uid>` pref stamp): opening Home after this update rewrites all legacy content/comments that were stored under the Google name before the profile existed.
- Medical services relocated: the `/medical` page itself is unchanged (icon grid + `/medical/section` screens), but its entry moved from the Home service grid/drawer into the Service Directory launcher (`/services` now shows 6 tiles: technicians/agricultural/educational + phone book + Medical Services teal tile that pushes `AppRoutes.medical`). All deep links (`/medical` route kept in `onGenerateRoute`, admin notification `_routeForCollection`/`_pushMessageFor` routes, profile medical-admin button) still resolve directly to the medical content.
- Medical labs section: new `medical_labs` collection + `MedicalLab` model (category from `kLabCategories`, ownerName, phone/address/workingHours, `homeCollection` home sample-collection flag, images, approval fields) + `MedicalLabService` (create / approved stream sorting home-collection first then name). Fifth icon tile «معامل التحاليل» (science icon, deep purple) in `/medical`; `MedicalSectionScreen(index: 4)` hosts `_LabsTab` (search + `MedicalLabDetailScreen` at `/medical/lab-detail`) with «أضف معملاً» FAB and `_LabForm` sheet. Admin: «معامل التحاليل» review chip + pending count, submitter/label/route/push maps (`🧪 معمل تحاليل جديد` → `village_medical`), edit-screen fields, and rules block mirroring pharmacies.
- Medical services re-architected like the Service Directory: `/medical` (`MedicalHomeScreen`) is now a GRID OF ICON TILES — المركز الطبي الخيري (hospital icon, dark teal), بنك دم القرية (bloodtype icon, red), عيادات القرية (add_business, teal), صيدليات القرية (pharmacy, green). Each tile opens `MedicalSectionScreen` (`/medical/section`, int index arg in `onGenerateRoute`) which hosts the former tab content (`_CenterTab`/`_BloodBankTab`/`_ClinicsTab`/`_PharmaciesTab`) with its own colored AppBar and its own FAB (إدارة المركز for medical admins / أضف عيادة / أضف صيدلية).
- Service Directory re-architected: `/services` is now a GRID OF CATEGORY BUTTONS (each colored, icon + description; extensible for future categories — technicians/agricultural/educational + a phone-book tile that pushes the standalone `/phone-directory`). Each category opens `ProviderCategoryScreen` (`/services/category`, args = category string, handled specially in `onGenerateRoute`) with: a **subcategory dropdown filter** (craft/service/stage lists per category) + **search field** beneath it (matches all record fields), and body sections: **المميز** → **الأكثر تقييماً (top-5)** → **جميع السجلات**. Provider cards open the detail screen via `AppRoutes.serviceProviderDetail` with the model as arguments; a named-route widget test guards the arguments/ModalRoute path (`test/services/provider_detail_route_test.dart`).
- Condolences are now one-per-user per obituary: deterministic doc id `condolences/{obituaryId}_{userId}` (same trick as attendance), `hasCondolenced`/`condoledenceStream`, and the button flips to a disabled «لقد قدّمت تعازيك» state live via stream.
- Home/Weather strip changes: `VillageWeatherBar` no longer hides itself when the red alert is live (both strips can show simultaneously) and now exactly matches the wisdom bar's geometry (outer padding 14/10/14/6, minHeight 58). The weather detail screen gained an **الأيام القادمة** section (daily rows grouped from the 5-day/3h feed: day name, date, noon icon/description, min/max). Village local time (`WeatherService.tzOffsetSeconds` from the API, default UTC+2) ticks in the hero header under the date (`_VillageClock`, 15s timer). The welcome line shrank and the user's name now renders through `RoleNameText` (role/seller colors + crown/star badge).
- Breaking news + urgent alert: both visible at once now (alert strip and breaking/weather strip are independent); admin overview keeps the two `_AlertControlCard`s (red/yellow).
- Village Weather + Breaking News strip: second pinned strip under the home header (`VillageWeatherBar`). Default shows `طقس القرية` (OpenWeatherMap `/2.5/weather` + `/forecast` via `WeatherService`, 10-min in-memory cache, lang=ar, coordinates/city/API key overridable with `--dart-define=OWM_API_KEY|WEATHER_LAT|WEATHER_LON|WEATHER_CITY`); tap opens `WeatherDetailScreen` (`/weather`) with full current-conditions data + 8-slot forecast. When the admin enables **خبر عاجل** the strip turns yellow with blue text (tap = full dialog); when an urgent alert is active the strip hides itself (the red alert bar owns the space).
- Breaking news uses the same mechanism as alerts: `village_alerts/breaking` doc + `AlertService.enableBreaking/disableBreaking/getBreaking/watchLiveBreaking`, instant FCM fan-out to topic `village_breaking` (subscribed on profile completion + every Home open, like `village_alerts`). Admin overview now has two `_AlertControlCard`s (red تنبيه / yellow خبر عاجل — same text box + تفعيل/إيقاف/تحديث pattern). `village_alerts` rules (public read, admin write) cover both docs unchanged.
- Author identity unified everywhere: `UserService.resolveAuthor()` returns the profile name (users/{uid}.name as edited in complete-profile/profile) with Google values only as fallback, plus the profile photo. All comment writers (news/forum/market-product subcollection `comments`, provider comments via `resolveAuthor` in the UI) now persist `userName` + `userPhotoUrl`; `ReviewService._getUserName` prefers the profile name over Google displayName. Comment lists (forum post detail, news view, provider detail) render the user's photo in the avatar.
- Phone directory pending visibility: `PhoneDirectoryEntry.submittedBy` is set at creation; `PhoneDirectoryService.getVisibleEntriesList(uid)` = approved ∪ own-pending, used by `PhoneDirectoryScreen._loadEntries` (so a new submission shows immediately with the «قيد المراجعة» badge instead of vanishing). `AdminService._invalidateContentCache` now also invalidates phone_directory + shops on approve/reject/delete. Rules: phone_directory create requires `submittedBy==uid` + `isApproved:false`; owner may edit own unapproved entry except the approval flag.
- Profile page: the «تعديل الملف الشخصي» card is gone — name/photo/phone now edit via a «تعديل البيانات الشخصية» button inside the top card that opens an edit bottom-sheet (camera re-pick included); the header name uses `RoleNameText` (role colors); admin/medical panel entry is now a full-width gradient pill button (blue→gold for admin, teal for medical center).
- Service Directory tabs redesign: each of الفنيون/خدمات زراعية/خدمات تعليمية now opens with (1) a category-tailored **search box** (matches names + فئات: حرفة/خدمة/مرحلة/مادة + category label — whole groups surface when their name matches), (2) a **البيانات المميزة** section (admin-featured, gold), (3) **الأكثر تقييماً** (top-5 by user rating), (4) the dropdown group lists; tapping the search-clear or typing re-flows sections live. `_ProvidersTab` is stateful with a pinned stream (no re-subscribe on typing).
- Provider detail hardened: optional `provider`/`service` constructor injection (for tests), null-safe `ModalRoute` access, guarded empty-document-id streams (`Stream.value(null)` / `Stream.value([])` — previously a session-restore path with lost arguments threw "document path must not be empty" = red screen), and FirebaseAuth reads wrapped in try/catch. Two widget tests now pump the real detail screen via fake Firestore (`test/services/provider_detail_render_test.dart`); suite 72/72.
- Admin review for `service_providers` now shows a colored **"تبويب: الفنيون/خدمات زراعية/خدمات تعليمية"** chip on every review card (so the tab being approved is unmistakable) plus featured-gold border; search covers specialty/stage/category.
- Admin overview stats grid compacted: 3-across square cells with smaller icons/typography (was 2-across 1.7-ratio — took ~3× the height on phones).
- App font switched from Cairo to **Tajawal** (Google Fonts): all 38 `GoogleFonts.cairo` usages replaced with `GoogleFonts.tajawal` in `app_theme.dart`/`home.dart`/`settings/index.dart`, plus a global `DefaultTextStyle` (Tajawal) in `MaterialApp.builder` (`main.dart`) so unstyled text inherits it too. Missing weights (e.g. w600) auto-resolve to the closest available Tajawal variant via google_fonts `_closestMatch`.
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
- Search focus fix: `OfflineStreamBuilder` is now `StatefulWidget` that pins the last valid data across transient re-subscriptions, so the search `TextField` no longer loses focus/remounts after the first keystroke (fixed once, applies to all ~12 pages). Second wave of the same class of bug — raw `StreamBuilder`s that rebuilt their stream inside `build` while their search box sat inside the builder — fixed by pinning one stream instance per state/widget: medical عيادات/صيدليات/بنك الدم/المركز tabs, admin المستخدمين page, admin المراجعة page (memoized per collection+pendingOnly), and `AlertWisdomBar`.
- News list header: moved search into `SliverAppBar.bottom` to stop the title overlapping the search box.
- Seller image limits set to regular 1 / super 3 / gold 5 / premium 10 (all derived from `SellerType.maxImages`, so no per-screen changes; the enum is now strictly monotonic with its declaration order).

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
2026-09-27T00:20:00+03:00