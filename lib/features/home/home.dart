import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../features/forum/posts.dart';
import '../../features/market/products.dart';
import '../../features/profile/main.dart';
import '../../features/village/about.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/market_service.dart';
import '../../services/news_service.dart';
import '../../widgets/common_appbar_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const VillageScreen(),
    const MarketProductsScreen(),
    const ForumPostsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    AppHelpers.hapticLight();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const HomeDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: DecoratedBox(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))]), child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
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
            _buildDrawerItem(context, 'طلب الخدمات', Icons.add_task_rounded, AppRoutes.serviceRequest),
            _buildDrawerItem(context, 'المنتدى', Icons.forum_rounded, AppRoutes.forumPosts),
            _buildDrawerItem(context, 'الطوارئ', Icons.contact_phone_rounded, AppRoutes.emergencyContacts),
            _buildDrawerItem(context, 'دليل الهاتف', Icons.phone_rounded, AppRoutes.phoneDirectory),
            _buildDrawerItem(context, 'الملف الشخصي', Icons.person_rounded, AppRoutes.profileMain),
            _buildDrawerItem(context, 'الإعدادات', Icons.settings_rounded, AppRoutes.settingsIndex),
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

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<MarketProduct> _featuredProducts = [];
  List<NewsItem> _featuredNews = [];
  List<ForumPost> _latestPosts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final marketService = MarketService();
    final newsService = NewsService();
    final products = await marketService.getProductsList();
    final news = await newsService.getNewsList();
    setState(() {
      _featuredProducts = products.where((p) => p.isFeatured).take(6).toList();
      _featuredNews = news.take(3).toList();
      _latestPosts = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
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
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('المنتجات المميزة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Text('(${_featuredProducts.length})', style: TextStyle(color: Colors.grey[600]))])),
          ),
          if (_featuredProducts.isNotEmpty) SliverToBoxAdapter(child: _buildFeaturedProducts()),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('أحدث الأخبار', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.newsList), child: Text('عرض الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)))])),
          ),
          if (_featuredNews.isNotEmpty) SliverToBoxAdapter(child: _buildFeaturedNews()),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('أحدث المنشورات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.forumPosts), child: Text('عرض الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)))])),
          ),
          SliverToBoxAdapter(child: _buildLatestPosts()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    if (_featuredProducts.isEmpty) return const SizedBox(height: 160);
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _featuredProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail, arguments: _featuredProducts[index]),
          child: SizedBox(
            width: 120,
            child: Card(elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: SizedBox(width: double.infinity, height: 80, child: CachedNetworkImage(imageUrl: _featuredProducts[index].imageUrl, fit: BoxFit.cover))),
              Padding(padding: const EdgeInsets.all(8), child: Text(_featuredProducts[index].name, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedNews() {
    if (_featuredNews.isEmpty) return const SizedBox(height: 120);
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _featuredNews.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.newsView, arguments: _featuredNews[index]),
          child: SizedBox(
            width: 140,
            child: Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: SizedBox(width: double.infinity, height: 70, child: CachedNetworkImage(imageUrl: _featuredNews[index].imageUrl, fit: BoxFit.cover))),
              Padding(padding: const EdgeInsets.all(6), child: Text(_featuredNews[index].title, style: Theme.of(context).textTheme.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            ])),
          ),
        ),
      ),
    );
  }

  Widget _buildLatestPosts() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _latestPosts.length,
        itemBuilder: (context, index) {
          final post = _latestPosts[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.forumPostDetail, arguments: post),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 80, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), child: Center(child: Icon(Icons.forum, color: Colors.grey[500]))),
                Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(post.userName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)), Text(post.content, style: GoogleFonts.cairo(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)])),
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
  const _ServiceItem(this.title, this.icon, this.route) : color = AppColors.primary;
}