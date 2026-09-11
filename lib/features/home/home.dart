import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/role_style.dart';
import '../../features/forum/posts.dart';
import '../../features/market/market_tabs_screen.dart';
import '../../features/profile/main.dart';
import '../../features/village/about.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/forum_service.dart';
import '../../services/market_service.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';
import '../../widgets/global_bottom_nav.dart';
import '../../widgets/offline_stream_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _pages = [
    const HomeContent(),
    const VillageScreen(),
    const MarketTabsScreen(),
    const ForumPostsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GlobalNav.tab,
      builder: (context, selectedIndex, _) => Scaffold(
        endDrawer: const HomeDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey<int>(selectedIndex),
            child: _pages[selectedIndex],
          ),
        ),
        bottomNavigationBar: DecoratedBox(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))]), child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: GlobalNav.select,
          animationDuration: const Duration(milliseconds: 400),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.villa_outlined), selectedIcon: Icon(Icons.villa_rounded), label: 'عن القرية'),
            NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store_rounded), label: 'السوق'),
            NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'المنتدى'),
            NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person_rounded), label: 'الملف'),
          ],
        ),
        ),
      ),
    );
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)]),
                  child: const Icon(Icons.villa_rounded, color: AppColors.primary, size: 32),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                const Text('قرية أبوديشيشة', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('خدمات المجتمع والمحتوى المحلي', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              ]),
            ),
            _buildDrawerItem(context, 'الرئيسية', Icons.home_rounded, AppRoutes.home),
            _buildDrawerItem(context, 'عن التطبيق', Icons.info_rounded, AppRoutes.aboutApp),
            _buildDrawerItem(context, 'عن القرية', Icons.villa_rounded, AppRoutes.about),
            _buildDrawerItem(context, 'أخبار القرية', Icons.newspaper_rounded, AppRoutes.newsList),
            _buildDrawerItem(context, 'سجل العزاء', Icons.grade_rounded, AppRoutes.obituariesList),
            _buildDrawerItem(context, 'المناسبات', Icons.card_giftcard_rounded, AppRoutes.occasionsList),
            _buildDrawerItem(context, 'سوق القرية', Icons.store_rounded, AppRoutes.marketProducts),
            _buildDrawerItem(context, 'الخدمات الطبية', Icons.medical_services_rounded, AppRoutes.medical),
            _buildDrawerItem(context, 'دليل البائعين', Icons.business_center_rounded, AppRoutes.marketSellers),
            _buildDrawerItem(context, 'طلب الخدمات', Icons.add_task_rounded, AppRoutes.serviceRequest),
            _buildDrawerItem(context, 'المنتدى', Icons.forum_rounded, AppRoutes.forumPosts),
            _buildDrawerItem(context, 'الطوارئ', Icons.contact_phone_rounded, AppRoutes.emergencyContacts),
            _buildDrawerItem(context, 'دليل الهاتف', Icons.phone_rounded, AppRoutes.phoneDirectory),
            _buildDrawerItem(context, 'الملف الشخصي', Icons.person_rounded, AppRoutes.profileMain),
            _buildDrawerItem(context, 'الإعدادات', Icons.settings_rounded, AppRoutes.settingsIndex),
            _buildDrawerItem(context, 'لوحة التحكم', Icons.admin_panel_settings_rounded, AppRoutes.admin),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        if (route != AppRoutes.home) Navigator.pushNamed(context, route);
      },
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: CustomHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مرحباً بك في', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text('قرية أبوديشيشة', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
              ]),
            ).animate().fade(delay: 100.ms).slideY(begin: 0.2, delay: 100.ms),
          ),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), child: Text('الخدمات الرئيسية', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ),
          const SliverToBoxAdapter(child: ModernServiceGrid()),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('المنتجات المميزة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Text('(مباشر)', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600))])),
          ),
          SliverToBoxAdapter(child: _buildLiveProducts(context)),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('أحدث الأخبار', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.newsList), child: Text('عرض الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)))])),
          ),
          SliverToBoxAdapter(child: _buildLiveNews(context)),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('أحدث المنشورات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.forumPosts), child: Text('عرض الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)))])),
          ),
          SliverToBoxAdapter(child: _buildLivePosts(context)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildLiveProducts(BuildContext context) {
    final theme = Theme.of(context);
    return OfflineStreamBuilder<List<MarketProduct>>(
      stream: MarketService().getProductsStream(),
      onlineBuilder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final featured = products.where((p) => p.isFeatured).take(6).toList();
        if (featured.isEmpty) return const SizedBox(height: 160);
        return _buildProductList(theme, featured);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 160);
          final all = (snapshot.data ?? []).map((j) => MarketProduct.fromJson(j, 'cache')).toList();
          final featured = all.where((p) => p.isFeatured).take(6).toList();
          if (featured.isEmpty) return const SizedBox(height: 160);
          return _buildProductList(theme, featured);
        },
      ),
    );
  }

  Widget _buildProductList(ThemeData theme, List<MarketProduct> featured) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail, arguments: featured[index]),
          child: SizedBox(
            width: 120,
            child: Card(elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: SizedBox(width: double.infinity, height: 80, child: CachedNetworkImage(imageUrl: featured[index].imageUrl, fit: BoxFit.cover))),
              Padding(padding: const EdgeInsets.all(8), child: Text(featured[index].name, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveNews(BuildContext context) {
    final theme = Theme.of(context);
    return OfflineStreamBuilder<List<NewsItem>>(
      stream: NewsService().getNewsStream(),
      onlineBuilder: (context, snapshot) {
        final news = snapshot.data ?? [];
        final latest = news.take(3).toList();
        if (latest.isEmpty) return const SizedBox(height: 120);
        return _buildNewsList(theme, latest);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getNews(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 120);
          final all = (snapshot.data ?? []).map((j) => NewsItem.fromJson(j, 'cache')).toList()
            ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
          final latest = all.take(3).toList();
          if (latest.isEmpty) return const SizedBox(height: 120);
          return _buildNewsList(theme, latest);
        },
      ),
    );
  }

  Widget _buildNewsList(ThemeData theme, List<NewsItem> latest) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: latest.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.newsView, arguments: latest[index]),
          child: SizedBox(
            width: 140,
            child: Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: SizedBox(width: double.infinity, height: 70, child: CachedNetworkImage(imageUrl: latest[index].imageUrl, fit: BoxFit.cover))),
              Padding(padding: const EdgeInsets.all(6), child: Text(latest[index].title, style: theme.textTheme.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            ])),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePosts(BuildContext context) {
    final theme = Theme.of(context);
    return OfflineStreamBuilder<List<ForumPost>>(
      stream: ForumService().getPostsStream(),
      onlineBuilder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        final latest = posts.take(5).toList();
        if (latest.isEmpty) return const SizedBox(height: 180);
        return _buildPostsList(theme, latest);
      },
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getForumPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 180);
          final all = (snapshot.data ?? []).map((j) => ForumPost.fromJson(j, 'cache')).toList();
          final latest = all.take(5).toList();
          if (latest.isEmpty) return const SizedBox(height: 180);
          return _buildPostsList(theme, latest);
        },
      ),
    );
  }

  Widget _buildPostsList(ThemeData theme, List<ForumPost> latest) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: latest.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final post = latest[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.forumPostDetail, arguments: post),
            child: Container(
              width: 140,
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 80, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), child: post.imageUrl != null && post.imageUrl!.isNotEmpty ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: CachedNetworkImage(imageUrl: post.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 80, errorWidget: (context, url, error) => Center(child: Icon(Icons.forum, color: theme.colorScheme.onSurfaceVariant)))) : Center(child: Icon(Icons.forum, color: theme.colorScheme.onSurfaceVariant))),
                Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [RoleNameText(name: post.userName, role: post.userRole, sellerType: post.userSellerType, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12), iconSize: 12), Text(post.content, style: GoogleFonts.cairo(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)])),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class CustomHeader extends StatelessWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
      decoration: BoxDecoration(borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)), gradient: AppColors.primaryGradient, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
      child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () => Scaffold.of(context).openEndDrawer())),
          Row(children: [
            IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () => Navigator.pushNamed(context, AppRoutes.profileMain)),
            IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () => Navigator.pushNamed(context, AppRoutes.settingsIndex)),
            ...CommonAppBarActions.actions(context).map((w) => IconTheme(data: const IconThemeData(color: Colors.white), child: w)),
          ]),
        ]),
        const SizedBox(height: 20),
        const Text('خدمات القرية', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.2)),
        const SizedBox(height: 8),
        Text('منصة شاملة لخدمات المجتمع المحلي', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16, height: 1.4)),
      ])),
    );
  }
}

class ModernServiceGrid extends StatelessWidget {
  const ModernServiceGrid({super.key});

  static const _services = [
    _ServiceItem('عن القرية', Icons.villa_rounded, AppRoutes.about),
    _ServiceItem('أخبار القرية', Icons.newspaper_rounded, AppRoutes.newsList),
    _ServiceItem('سوق القرية', Icons.store_rounded, AppRoutes.marketProducts),
    _ServiceItem('الخدمات الطبية', Icons.medical_services_rounded, AppRoutes.medical, Color(0xFF00897B)),
    _ServiceItem('سجل العزاء', Icons.grade_rounded, AppRoutes.obituariesList),
    _ServiceItem('المناسبات', Icons.card_giftcard_rounded, AppRoutes.occasionsList),
    _ServiceItem('المنتدى', Icons.forum_rounded, AppRoutes.forumPosts),
    _ServiceItem('طلب الخدمة', Icons.add_task_rounded, AppRoutes.serviceRequest),
    _ServiceItem('دليل الهاتف', Icons.phone_rounded, AppRoutes.phoneDirectory),
    _ServiceItem('الطوارئ', Icons.contact_phone_rounded, AppRoutes.emergencyContacts),
    _ServiceItem('حول التطبيق', Icons.info_rounded, AppRoutes.aboutApp),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12),
      itemBuilder: (context, index) => _buildServiceCard(context, _services[index], index),
    );
  }

  Widget _buildServiceCard(BuildContext context, _ServiceItem service, int index) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, service.route),
        child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: service.color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Center(child: Icon(service.icon, color: service.color, size: 22))),
          const SizedBox(height: 8),
          Text(service.title, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ).animate(delay: (index * 50).ms).fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _ServiceItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;
  const _ServiceItem(this.title, this.icon, this.route,
      [this.color = AppColors.primary]);
}
