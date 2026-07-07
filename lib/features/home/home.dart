import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/forum_service.dart';
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
  final List<Widget> _pages = const [
    HomeContent(),
  ];

  void _onItemTapped(int index) {
    AppHelpers.hapticLight();
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.newsList);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.marketProducts);
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.forumPosts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      endDrawer: const HomeDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(key: ValueKey<int>(_selectedIndex), child: _pages[_selectedIndex]),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))]),
        child: BottomAppBar(
          color: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(context, Icons.home_outlined, Icons.home_rounded, 'الرئيسية', 0),
              _buildNavItem(context, Icons.newspaper_outlined, Icons.newspaper_rounded, 'الأخبار', 1),
              const SizedBox(width: 56),
              _buildNavItem(context, Icons.store_outlined, Icons.store_rounded, 'السوق', 2),
              _buildNavItem(context, Icons.forum_outlined, Icons.forum_rounded, 'المنتدى', 3),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildAddFab(context),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData outlined, IconData filled, String label, int index) {
    final theme = Theme.of(context);
    final selected = _selectedIndex == index;
    return Expanded(
      child: IconButton(
        onPressed: () => _onItemTapped(index),
        icon: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? filled : outlined, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFab(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: IconButton(
        onPressed: () => _showAddMenu(context),
        icon: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary, size: 32),
        style: IconButton.styleFrom(padding: const EdgeInsets.all(20)),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('إضافة محتوى', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildAddTile(context, Icons.store_rounded, 'منتج جديد', AppRoutes.marketAdd),
                  _buildAddTile(context, Icons.newspaper_rounded, 'خبر جديد', AppRoutes.newsDetail),
                  _buildAddTile(context, Icons.forum_rounded, 'نقاش جديد', AppRoutes.forumCreatePost),
                  _buildAddTile(context, Icons.card_giftcard_rounded, 'مناسبة', AppRoutes.occasionsAdd),
                  _buildAddTile(context, Icons.grade_rounded, 'خبر عزاء', AppRoutes.obituariesList),
                  _buildAddTile(context, Icons.phone_rounded, 'رقم هاتف', AppRoutes.phoneDirectory),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTile(BuildContext context, IconData icon, String label, String route) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      strokeWidth: 3,
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
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('المنتجات المميزة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Text('(مباشر)', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600))])),
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
    return StreamBuilder<List<MarketProduct>>(
      stream: MarketService().getProductsStream(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final featured = products.where((p) => p.isFeatured).take(6).toList();
        if (featured.isEmpty) return const SizedBox(height: 160);
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
                  Padding(padding: const EdgeInsets.all(8), child: Text(featured[index].name, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ])),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveNews(BuildContext context) {
    return StreamBuilder<List<NewsItem>>(
      stream: NewsService().getNewsStream(),
      builder: (context, snapshot) {
        final news = snapshot.data ?? [];
        final latest = news.take(3).toList();
        if (latest.isEmpty) return const SizedBox(height: 120);
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
                  Padding(padding: const EdgeInsets.all(6), child: Text(latest[index].title, style: Theme.of(context).textTheme.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                ])),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLivePosts(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<ForumPost>>(
      stream: ForumService().getPostsStream(),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        final latest = posts.take(5).toList();
        if (latest.isEmpty) return const SizedBox(height: 180);
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
                    Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(post.userName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)), Text(post.content, style: GoogleFonts.cairo(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)])),
                  ]),
                ),
              );
            },
          ),
        );
      },
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

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)]),
                  child: const Icon(Icons.villa_rounded, color: AppColors.primary, size: 32),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text('قرية أبوديشيشة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('خدمات المجتمع والمحتوى المحلي', style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
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
                  StreamBuilder<firebase_auth.User?>(
                    stream: AdminService().authStateChanges,
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      if (user?.email?.toLowerCase() == 'eleraki2040@gmail.com') {
                        return _buildDrawerItem(context, 'لوحة التحكم', Icons.admin_panel_settings_rounded, AppRoutes.admin);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String route) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () {
          Navigator.pop(context);
          if (route != AppRoutes.home) Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
