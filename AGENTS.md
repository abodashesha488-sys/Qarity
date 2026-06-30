# Qarity Project - Agent Documentation

## Project Overview
Qarity is a comprehensive digital platform for village community services (قرية أبوديشيشة).

## Build Status
- **Errors:** 0
- **Warnings:** 0
- **Info:** 9 (pre-existing lint warnings)
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
├── core/              # Constants, themes, utilities
│   ├── constants/     # App colors, constants
│   └── theme/         # App theme configuration
├── features/          # Feature screens
│   ├── auth/          # Authentication (login)
│   ├── home/          # Home, splash, about
│   ├── market/        # Products, cart, seller pages, seller orders
│   ├── news/          # News list, detail, view
│   ├── forum/         # Forum posts, create, detail
│   ├── profile/       # User profile (edit name, photo)
│   ├── settings/      # Settings, notifications
│   ├── services/      # Service requests
│   ├── emergency/     # Emergency contacts
│   ├── phone/         # Phone directory
│   ├── village/       # Village info
│   └── occasions/     # Occasions management
├── services/          # Firebase services
│   ├── user_service.dart
│   ├── forum_service.dart
│   ├── market_service.dart
│   ├── news_service.dart
│   ├── order_service.dart
│   ├── product_interaction_service.dart
│   ├── image_upload_service.dart
│   └── theme_service.dart
├── models/            # Data models
│   └── data_models.dart  # User, NewsItem, MarketProduct, ForumPost, AppOrder, etc.
├── widgets/           # Shared widgets
├── routes/            # App routing
│   └── app_routes.dart
└── main.dart          # App entry point
```

## Services
- `UserService` - User authentication and management (get, save, update, isAdmin, getCurrentUser)
- `ReviewService` - Product reviews
- `MarketService` - Market products (add, delete, get list, get seller products stream, isUserSeller)
- `NewsService` - News management (get, like, comments)
- `ForumService` - Forum posts and comments with likes
- `OrderService` - Order management for market (create, get seller/buyer orders, update status)
- `ProductInteractionService` - Product likes and comments
- `ImageUploadService` - Image upload to ImgBB
- `ThemeService` - Theme management (light/dark mode)

## Models
- `UserModel` - User profile with role (user/admin)
- `NewsItem` - News with carousel images, likes, comments
- `MarketProduct` - Products with seller info, likes, stock
- `ForumPost` - Forum posts with likes, comments, views
- `AppOrder` - Orders for market products
- `CartItem` - Shopping cart item
- `Obituary`, `Occasion`, `EmergencyContact`, `ServiceRequest`, `Review`

## Recent Updates
- Removed guest login option from login screen
- Created CompleteProfileScreen for first-time Google users to add phone/name
- Enhanced Profile screen: edit name, change profile photo, save to Firestore
- Added seller dashboard to Profile screen with tabs (جديدة/منفذة) for orders
- Added product detail navigation from seller's products list
- Added order status update with "تم" button for pending orders
- Added client phone display in order details
- Updated UserService.saveUserToFirestore to sync name/photo from Google
- Added MarketService.isUserSeller and getSellerProductsStream
- Added getProductById to MarketService for product detail navigation
- Improved tab counts styling: red for new orders, green for completed
- Fixed cart checkout to fetch phone from Firestore user model
- Fixed forum posts screen:
  - Current user ID now fetched from Firebase Auth
  - Likes now update correctly with proper user identification
  - Comments show user's actual name from Firestore
  - CommentsSheet receives currentUserName as parameter
- Fixed forum post detail screen:
  - Current user ID now fetched from Firebase Auth
  - Likes now update correctly
  - Comments show user's actual name

## Deployment
The app is deployed on Firebase Hosting:
- URL: https://abudshisha.web.app

## Last Updated
2026-06-30T10:50:39+03:00

## Recent Fixes (2026-06-30)
- Fixed product detail screen showing red error - now loads product by ID from Firestore
- Fixed buyer phone not showing in orders - now fetches from Firestore user model
- Fixed tab counts: red for new orders, green for completed, larger font size
- Removed back button from CompleteProfileScreen (first-time users shouldn't navigate back)
- Fixed forum posts: current user ID fetched from Firebase Auth, comments show real user name
- Fixed create post: now uses currentUser.uid instead of currentUserId
- Fixed forum posts display - removed composite index requirement, sorting done in code
- Build: 0 errors, 15 info-level warnings (pre-existing)