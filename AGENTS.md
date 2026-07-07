# Qarity Project - Agent Documentation

## Project Overview
Qarity is a comprehensive digital platform for village community services (قرية أبوديشيشة).

## Build Status
- **Errors:** 0
- **Warnings:** 0
- **Info:** 35 (pre-existing lint suggestions)
- **Status:** Compiles successfully

## Firebase Configuration

### Package Information
- **Package Name:** `qurity`
- **Project ID:** `abudshisha`

### SHA-1 Fingerprint (Debug)
```
EE:04:D2:B9:EB:84:01:02:34:53:49:C4:17:1E:09:7C:8D:2D:A8:DC
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

## Firestore Security Rules
- File: `firestore.rules`
- Deployed to project `abudshisha`
- Admin write/delete access via `users/{uid}.role == 'admin'`
- Public read for content collections: `news`, `market_products`, `obituaries`, `occasions`, `forum_posts`
- Authenticated create access for content collections
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
│   ├── market/        # Products, cart, detail, add, seller pages
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
│   └── data_models.dart  # User, NewsItem, MarketProduct, ForumPost, AppOrder, ServiceRequest, etc.
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
- `AppOrder`, `CartItem`, `EmergencyContact`, `ServiceRequest`, `Review`

## Admin Access
- Hardcoded admin email: `eleraki2040@gmail.com`
- Firestore role field: `role = 'admin'`
- Admin access granted via role == 'admin'
- `AdminScreenWrapper` checks email first, then falls back to Firestore role check via `AdminService.isAdminUser()`
- Admin drawer link conditionally shown via `AdminService` auth stream

## Admin Dashboard
- 5 real-time tabs: News, Products, Obituaries, Occasions, Forum Posts
- Stats grid with counts
- Search bar and filter chips (all / pending)
- Pending count badges on tabs and AppBar
- Card items show title, metadata, and action buttons
- Action buttons: edit, approve, reject, delete with loading states
- Tapping a card opens `AdminDetailScreen` showing full request details
- Admin edit screen supports fields by collection type

## Recent Updates
- Admin approve/reject/delete/edit buttons now working with proper loading states
- Added AdminDetailScreen to view full request content before approval
- Added AdminEditScreen for inline editing of approved/pending content
- Updated admin_dashboard to open detail view on item tap
- AdminService exposes approveItem, rejectItem, deleteItem, updateItem for direct collection access
- Fixed BuildContext usage across async gaps with mounted checks
- Reduced RenderFlex overflow in market product cards
- Fixed cart reactivity and add-to-cart logic
- Fixed cart clear dialog typo in cart_screen.dart
- Fixed stale username display and missing buyer phone in orders
- Removed silent error handling swallowing in order service streams
- Added CacheService.invalidateUser(uid) called after role changes
- Added firestore.rules with admin permissions and deployed to Firebase
- Reduced cart padding and added maxLines to prevent overflow errors
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