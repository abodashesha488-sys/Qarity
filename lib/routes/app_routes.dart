import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import '../core/constants/app_config.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/admin_detail.dart';
import '../features/admin/admin_edit.dart';
import '../features/auth/complete_profile.dart';
import '../features/auth/login.dart';
import '../features/children/children_screen.dart';
import '../features/emergency/contacts.dart';
import '../features/forum/create_post.dart';
import '../features/forum/post_detail.dart';
import '../features/forum/posts.dart';
import '../features/home/about_app.dart';
import '../features/home/home.dart';
import '../features/home/splash.dart';
import '../features/market/add_product.dart';
import '../features/market/market_tabs_screen.dart';
import '../features/market/product_detail.dart';
import '../features/market/seller_detail.dart';
import '../features/market/seller_gallery.dart';
import '../features/market/seller_profile.dart';
import '../features/market/seller_reviews.dart';
import '../features/market/sellers_list.dart';
import '../features/medical/clinic_detail_screen.dart';
import '../features/medical/medical_home_screen.dart';
import '../features/news/add.dart';
import '../features/news/list.dart';
import '../features/news/view.dart';
import '../features/notifications/notification_open_screen.dart';
import '../features/notifications/notifications_inbox_screen.dart';
import '../features/obituaries/add.dart';
import '../features/obituaries/detail.dart';
import '../features/obituaries/list.dart';
import '../features/occasions/add.dart';
import '../features/occasions/detail.dart';
import '../features/occasions/list.dart';
import '../features/phone/add_directory.dart';
import '../features/phone/directory.dart';
import '../features/profile/main.dart';
import '../features/services/lost_items_screen.dart';
import '../features/services/service_directory_screen.dart';
import '../features/services/service_provider_detail_screen.dart';
import '../features/settings/index.dart';
import '../features/settings/notifications.dart';
import '../features/village/about.dart';
import '../features/village/village_archive_screen.dart';
import '../features/village/village_history_screen.dart';
import '../features/village/village_institutions_screen.dart';
import '../features/weather/weather_detail_screen.dart';
import '../models/service_provider_model.dart';
import '../services/admin_service.dart';

/// 🛣️ Qarity App Routes
/// 
/// Centralized routing with beautiful page transitions.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String aboutApp = '/about-app';
  static const String about = '/about';
  static const String villageHistory = '/village/history';
  static const String villageArchive = '/village/archive';
  static const String villageInstitutions = '/village/institutions';
  static const String obituariesList = '/obituaries';
  static const String obituariesDetail = '/obituaries/detail';
  static const String obituariesAdd = '/obituaries/add';
  static const String occasionsList = '/occasions';
  static const String occasionsDetail = '/occasions/detail';
  static const String occasionsAdd = '/occasions/add';
  static const String newsList = '/news';
  static const String newsView = '/news/view';
  static const String newsAdd = '/news/add';
  static const String admin = '/admin';
  static const String adminEdit = '/admin/edit';
  static const String adminDetail = '/admin/detail';
static const String marketProducts = '/market';
  static const String marketAdd = '/market/add';
  static const String marketProductDetail = '/market/product';
  static const String marketSellerDetail = '/market/seller';
  static const String marketSellerProfile = '/market/seller/profile';
  static const String marketSellers = '/market/sellers';
  static const String marketSellerGallery = '/market/seller/gallery';
  static const String marketSellerReviews = '/market/seller/reviews';
  static const String marketTabs = '/market/tabs';
  static const String forumPosts = '/forum';
  static const String forumCreatePost = '/forum/create';
  static const String forumPostDetail = '/forum/detail';
  static const String emergencyContacts = '/emergency';
  static const String phoneDirectory = '/phone-directory';
  static const String phoneDirectoryAdd = '/phone-directory-add';
  static const String profileMain = '/profile';
  static const String completeProfile = '/complete-profile';
  static const String settingsIndex = '/settings';
  static const String notificationsSettings = '/settings/notifications';
  static const String serviceRequest = '/services';
  static const String serviceCategory = '/services/category';
  static const String farmerServices = '/services/farmer';
  static const String serviceProviderDetail = '/services/detail';
  static const String lostItems = '/services/lost-items';
  static const String lostItemDetail = '/services/lost-item-detail';
  static const String medicalClinicDetail = '/medical/clinic-detail';
  static const String medicalPharmacyDetail = '/medical/pharmacy-detail';
  static const String medicalLabDetail = '/medical/lab-detail';
  static const String medical = '/medical';
  static const String medicalSection = '/medical/section';
  static const String notificationsInbox = '/notifications';
  static const String notificationOpen = '/open';
  static const String weather = '/weather';
  static const String children = '/children';

  static final routes = <String, Widget Function(BuildContext)>{
    splash: (_) => const SplashScreen(),
    home: (_) => const HomeScreen(),
    login: (_) => const LoginScreen(),
    aboutApp: (_) => const AboutScreen(),
    about: (_) => const VillageScreen(),
    villageHistory: (_) => const VillageHistoryScreen(),
    villageArchive: (_) => const VillageArchiveScreen(),
    villageInstitutions: (_) => const VillageInstitutionsScreen(),
    obituariesList: (_) => const ObituariesListScreen(),
    obituariesDetail: (_) => const ObituaryDetailScreen(),
    obituariesAdd: (_) => const AddObituaryScreen(),
    occasionsList: (_) => const OccasionsListScreen(),
    occasionsDetail: (_) => const OccasionDetailScreen(),
    occasionsAdd: (_) => const AddOccasionScreen(),
    newsList: (_) => const NewsScreen(),
    newsView: (_) => const NewsViewScreen(),
    newsAdd: (_) => const AddNewsScreen(),
    marketProducts: (_) => const MarketTabsScreen(),
    marketAdd: (_) => const AddMarketProductScreen(),
    marketProductDetail: (_) => const ProductDetailScreen(),
    marketSellerDetail: (_) => const SellerDetailScreen(),
    marketSellerProfile: (_) => const SellerProfileScreen(sellerId: ''),
    marketSellers: (_) => const MarketSellersScreen(),
    marketSellerGallery: (_) => const SellerGalleryScreen(),
    marketSellerReviews: (_) => const SellerReviewsScreen(),
    marketTabs: (_) => const MarketTabsScreen(),
    forumPosts: (_) => const ForumPostsScreen(),
    forumCreatePost: (_) => const CreatePostScreen(),
    forumPostDetail: (_) => const ForumPostDetailScreen(),
    emergencyContacts: (_) => const EmergencyContactsScreen(),
    phoneDirectory: (_) => const PhoneDirectoryScreen(),
    phoneDirectoryAdd: (_) => const AddPhoneDirectoryScreen(),
    profileMain: (_) => const ProfileScreen(),
    settingsIndex: (_) => const SettingsScreen(),
    notificationsSettings: (_) => const NotificationsSettingsScreen(),
    serviceRequest: (_) => const ServiceDirectoryScreen(),
    serviceProviderDetail: (_) => const ServiceProviderDetailScreen(),
    lostItems: (_) => const LostItemsScreen(),
    lostItemDetail: (_) => const LostItemDetailScreen(),
    medicalClinicDetail: (_) => const VillageClinicDetailScreen(),
    medicalPharmacyDetail: (_) => const PharmacyDetailScreen(),
    medicalLabDetail: (_) => const MedicalLabDetailScreen(),
    medical: (_) => const MedicalHomeScreen(),
    notificationsInbox: (_) => const NotificationsInboxScreen(),
    notificationOpen: (_) => const NotificationOpenScreen(),
    weather: (_) => const WeatherDetailScreen(),
    children: (_) => const ChildrenScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == admin) {
      return _buildFadeRoute(
        (_) => const AdminScreenWrapper(),
        settings,
      );
    }
    if (settings.name == adminEdit) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      final collection = args['collection'] as String? ?? '';
      final docId = args['docId'] as String? ?? '';
      final item = args['item'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return _buildSlideRoute(
        (_) => AdminEditScreen(collection: collection, docId: docId, item: item),
        settings,
      );
    }
    if (settings.name == adminDetail) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      final collection = args['collection'] as String? ?? '';
      final docId = args['docId'] as String? ?? '';
      final item = args['item'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return _buildSlideRoute(
        (_) => AdminDetailScreen(collection: collection, docId: docId, item: item),
        settings,
      );
    }
    if (settings.name == completeProfile) {
      final userId = settings.arguments as String? ?? '';
      return _buildSlideRoute(
        (_) => CompleteProfileScreen(userId: userId),
        settings,
      );
    }
    if (settings.name == marketSellerProfile) {
      final sellerId = settings.arguments as String? ?? '';
      return _buildSlideRoute(
        (_) => SellerProfileScreen(sellerId: sellerId),
        settings,
      );
    }
    if (settings.name == medicalSection) {
      final index = settings.arguments is int ? settings.arguments as int : 0;
      return _buildSlideRoute(
        (_) => MedicalSectionScreen(index: index),
        settings,
      );
    }
    if (settings.name == serviceCategory) {
      final category = settings.arguments as String? ?? 'technicians';
      return _buildSlideRoute(
        (_) => ProviderCategoryScreen(category: category),
        settings,
      );
    }
    if (settings.name == farmerServices) {
      return _buildSlideRoute(
        (_) => const ProviderCategoryScreen(category: ServiceCategory.agricultural),
        settings,
      );
    }
    final builder = routes[settings.name];
    if (builder != null) {
      return _buildSlideRoute(builder, settings);
    }
    return _buildSlideRoute((_) => const HomeScreen(), settings);
  }

  static PageRouteBuilder<dynamic> _buildSlideRoute(
    Widget Function(BuildContext) builder,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  static PageRouteBuilder<dynamic> _buildFadeRoute(
    Widget Function(BuildContext) builder,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

/// 🔐 Admin Authentication Wrapper
/// 
/// Protects admin routes with authentication and role verification.
class AdminScreenWrapper extends StatelessWidget {
  const AdminScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return StreamBuilder<firebase_auth.User?>(
      stream: adminService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<bool>(
          future: adminService.isAdminUser(user.uid),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // بريد المالك للاختصار عبر dart-define (اختياري). بدون ضبطه،
            // الوصول للأدمن يتطلب users/{uid}.role == 'admin' في Firestore.
            final bootstrapEmail = AppConfig.bootstrapAdminEmail.trim().toLowerCase();
            final isAdminByEmail = bootstrapEmail.isNotEmpty &&
                user.email != null &&
                user.email!.toLowerCase().trim() == bootstrapEmail;

            final isAdminByRole = adminSnapshot.data == true;

            final isAdmin = isAdminByEmail || isAdminByRole;

            if (!isAdmin) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('غير مصرح لك بالوصول إلى لوحة الإدارة'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return const AdminDashboardScreen();
          },
        );
      },
    );
  }
}