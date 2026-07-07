# Qarity Project - Agent Documentation

## Project Overview
Qarity is a comprehensive digital platform for village community services (قرية أبوديشيشة).

## Build Status
- **Errors:** 0
- **Warnings:** 0
- **Info:** 39 (pre-existing lint suggestions)
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

## Project Structure
```
lib/
├── core/
│   ├── constants/     # App colors, constants
│   ├── theme/         # App theme configuration
│   └── utils/         # Helpers, navigator key
├── features/
│   ├── auth/          # Authentication (login)
│   ├── home/          # Home, splash, about
│   ├── market/        # Products, cart, detail, add, seller pages
│   ├── news/          # News list, detail, view
│   ├── forum/         # Forum posts, create, detail
│   ├── profile/       # User profile (edit name, photo)
│   ├── settings/      # Settings, notifications
│   ├── services/      # Service requests
│   ├── emergency/     # Emergency contacts
│   ├── phone/         # Phone directory
│   ├── village/       # Village info
│   ├── occasions/     # Occasions management
│   └── admin/         # Admin dashboard
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
- `AdminService` - Admin moderation, real-time streams, approve/reject/delete, stats, activity log
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
- Firestore role field: `role == 'admin'`
- Admin drawer link is conditionally shown via `AdminService.isAdminUser()`

## Recent Updates
- Fixed Firebase connectivity: added missing web packages (firebase_auth_web, firebase_storage_web)
- Fixed silent Firebase initialization failure in main.dart
- Updated login screen for web/mobile compatibility (signInWithPopup on web)
- Removed redundant floating action buttons from services pages and admin dashboard
- Redesigned bottom nav: الرئيسية - الأخبار - + - السوق - المنتدى with bottom sheet
- Advanced admin dashboard with 5 real-time tabs, stats grid, search, filters, approve/reject/delete actions
- Modernized home screen drawer and splash screen
- Fixed cart reactivity and add-to-cart logic
- Fixed forum likes/comments and stale username display
- Restored splash-based post-login routing for complete profile
- Upgraded Firebase web packages to fix Dart 3.12 JS interop errors
- Fixed cache serialization for Firestore types
- Modernized market products UI with glassmorphism search and animated category pills
- Modernized product detail and cart screens
- Modernized forum post detail screen with real-time comments
- Modernized seller detail screen
- Modernized service request and emergency contact screens with Firebase connectivity
- Added `AdminService` with full Firestore integration
- Added `CacheService` for offline support
- Added `ServiceRequestService` for community service requests

## Deployment
The app is deployed on Firebase Hosting:
- URL: https://abudshisha.web.app

## Last Updated
2026-07-06T09:05:00+03:00
