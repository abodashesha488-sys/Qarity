import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import '../features/admin/admin_dashboard.dart';
import '../features/admin/admin_detail.dart';
import '../features/admin/admin_edit.dart';
import '../features/auth/complete_profile.dart';
import '../features/auth/login.dart';
import '../features/emergency/contacts.dart';
import '../features/forum/create_post.dart';
import '../features/forum/post_detail.dart';
import '../features/forum/posts.dart';
import '../features/home/about_app.dart';
import '../features/home/home.dart';
import '../features/home/splash.dart';
import '../features/market/add_product.dart';
import '../features/market/cart_screen.dart';
import '../features/market/product_detail.dart';
import '../features/market/products.dart';
import '../features/market/seller_detail.dart';
import '../features/market/seller_gallery.dart';
import '../features/market/seller_orders.dart';
import '../features/market/seller_reviews.dart';
import '../features/news/detail.dart';
import '../features/news/list.dart';
import '../features/news/view.dart';
import '../features/obituaries/detail.dart';
import '../features/obituaries/list.dart';
import '../features/occasions/add.dart';
import '../features/occasions/detail.dart';
import '../features/occasions/list.dart';
import '../features/phone/directory.dart';
import '../features/profile/main.dart';
import '../features/services/detail.dart';
import '../features/services/request.dart';
import '../features/settings/index.dart';
import '../features/settings/notifications.dart';
import '../features/village/about.dart';
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
  static const String obituariesList = '/obituaries';
  static const String obituariesDetail = '/obituaries/detail';
  static const String occasionsList = '/occasions';
  static const String occasionsDetail = '/occasions/detail';
  static const String occasionsAdd = '/occasions/add';
  static const String newsList = '/news';
  static const String newsDetail = '/news/detail';
  static const String newsView = '/news/view';
  static const String admin = '/admin';
  static const String adminEdit = '/admin/edit';
  static const String adminDetail = '/admin/detail';
  static const String marketProducts = '/market';
  static const String marketAdd = '/market/add';
  static const String marketProductDetail = '/market/product';
  static const String marketSellerDetail = '/market/seller';
  static const String serviceRequest = '/service-request';
  static const String serviceDetail = '/service/detail';
  static const String marketSellerGallery = '/market/seller/gallery';
  static const String marketSellerReviews = '/market/seller/reviews';
  static const String marketSellerOrders = '/market/seller/orders';
  static const String marketCart = '/market/cart';
  static const String forumPosts = '/forum';
  static const String forumCreatePost = '/forum/create';
  static const String forumPostDetail = '/forum/detail';
  static const String emergencyContacts = '/emergency';
  static const String phoneDirectory = '/phone-directory';
  static const String profileMain = '/profile';
  static const String completeProfile = '/complete-profile';
  static const String settingsIndex = '/settings';
  static const String notificationsSettings = '/settings/notifications';

  static final routes = <String, Widget Function(BuildContext)>{
    splash: (_) => const SplashScreen(),
    home: (_) => const HomeScreen(),
    login: (_) => const LoginScreen(),
    aboutApp: (_) => const AboutScreen(),
    about: (_) => const VillageScreen(),
    obituariesList: (_) => const ObituariesListScreen(),
    obituariesDetail: (_) => const ObituaryDetailScreen(),
    occasionsList: (_) => const OccasionsListScreen(),
    occasionsDetail: (_) => const OccasionDetailScreen(),
    occasionsAdd: (_) => const AddOccasionScreen(),
    newsList: (_) => const NewsScreen(),
    newsDetail: (_) => const NewsDetailScreen(),
    newsView: (_) => const NewsViewScreen(),
    marketProducts: (_) => const MarketProductsScreen(),
    marketAdd: (_) => const AddMarketProductScreen(),
    marketProductDetail: (_) => const ProductDetailScreen(),
    marketSellerDetail: (_) => const SellerDetailScreen(),
    marketSellerGallery: (_) => const SellerGalleryScreen(),
    marketSellerReviews: (_) => const SellerReviewsScreen(),
    marketSellerOrders: (_) => const SellerOrdersScreen(),
    marketCart: (_) => const CartScreen(),
    serviceRequest: (_) => const ServicesScreen(),
    serviceDetail: (_) => const ServiceDetailScreen(),
    forumPosts: (_) => const ForumPostsScreen(),
    forumCreatePost: (_) => const CreatePostScreen(),
    forumPostDetail: (_) => const ForumPostDetailScreen(),
    emergencyContacts: (_) => const EmergencyContactsScreen(),
    phoneDirectory: (_) => const PhoneDirectoryScreen(),
    profileMain: (_) => const ProfileScreen(),
    settingsIndex: (_) => const SettingsScreen(),
    notificationsSettings: (_) => const NotificationsSettingsScreen(),
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

            final isAdminByEmail = user.email != null &&
                user.email!.toLowerCase().trim() == 'eleraki2040@gmail.com';

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