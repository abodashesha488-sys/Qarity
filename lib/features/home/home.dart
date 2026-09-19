import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/role_style.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/forum_service.dart';
import '../../services/market_service.dart';
import '../../services/news_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/alert_wisdom_bar.dart';
import '../../widgets/common_appbar_actions.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_logo.dart';
import '../../widgets/village_weather_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // اشتراك بقنوات البث الجماعي عند كل فتح — مع احترام إيقاف المستخدم
    // لها من «إعدادات الإشعارات» (يُعاد الاشتراك فقط إن كانت مفعّلة).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // فحص إصدار التطبيق (أندرويد فقط) — صامت ما لم يوجد جديد فعلًا.
      if (FirebaseAuth.instance.currentUser == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('notif_pref_village_alerts') ?? true) {
        unawaited(NotificationService.subscribeToTopic('village_alerts'));
      }
      if (prefs.getBool('notif_pref_village_breaking') ?? true) {
        unawaited(NotificationService.subscribeToTopic('village_breaking'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      endDrawer: HomeDrawer(),
      body: HomeContent(),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(10, 2, 10, 10),
        child: HomeIdentityBar(),
      ),
    );
  }
}

/// شريط الهوية السفلي — صورة المستخدم + الترحيب باسمه (يتقلّص تلقائيًا
/// مع الأسماء الطويلة بلا تداخل) + الإعدادات + القائمة الجانبية.
class HomeIdentityBar extends StatefulWidget {
  const HomeIdentityBar({super.key});

  @override
  State<HomeIdentityBar> createState() => _HomeIdentityBarState();
}

class _HomeIdentityBarState extends State<HomeIdentityBar> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final svc = UserService();
    final u = await svc.getCurrentUser();
    if (mounted) setState(() => _user = u);
    if (u == null) return;
    final name = u.name.trim();
    if (name.isEmpty) return;
    final photo = (u.photoUrl ?? '').trim();
    // إصلاح ذاتي مرة واحدة لكل هوية جديدة: يحدّث المحتوى والتعليقات
    // التي أُنشئت قديماً باسم Google قبل تعديل الاسم في الملف الشخصي.
    final prefs = await SharedPreferences.getInstance();
    final stamp = '$name|$photo';
    if (prefs.getString('identity_repair_v1_${u.id}') != stamp) {
      await prefs.setString('identity_repair_v1_${u.id}', stamp);
      unawaited(svc.syncIdentityToContent(u.id,
          name: name, photoUrl: photo.isEmpty ? null : photo));
    }
  }

  Future<void> _openProfile() async {
    HapticFeedback.lightImpact();
    await Navigator.pushNamed(context, AppRoutes.profileMain);
    if (mounted) _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final photo = _user?.photoUrl ?? '';
    final name = (_user?.name ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6F4E37),
        borderRadius: BorderRadius.circular(26),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000),
              blurRadius: 14,
              offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        child: Row(
          children: [
            _ProfileAvatarButton(
                photoUrl: photo, size: 38, onTap: _openProfile),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${HomeContent.greeting()}،',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 5),
                    RoleNameText(
                      name: name.isEmpty ? 'أهلاً بك' : name,
                      role: _user?.role,
                      sellerType: _user?.sellerType?.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900),
                      iconSize: 14,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Builder(builder: (context) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GlassIconButton(
                        icon: Icons.settings_outlined,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.settingsIndex)),
                    const SizedBox(width: 6),
                    _GlassIconButton(
                        icon: Icons.menu_rounded,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Scaffold.of(context).openEndDrawer();
                        }),
                  ],
                )),
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
                InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => showQurityLogoDialog(context),
                  child: const QurityLogo(size: 56),
                ),
                const SizedBox(height: 16),
                const Text('قرية أبوديشيشة', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('خدمات المجتمع والمحتوى المحلي', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              ]),
            ),
            _buildDrawerItem(context, 'الرئيسية', Icons.home_rounded, AppRoutes.home),
            _buildDrawerItem(context, 'عن التطبيق', Icons.info_rounded, AppRoutes.aboutApp),
            _buildDrawerItem(context, 'تعرف على القرية', Icons.villa_rounded, AppRoutes.about,
                leading: const QurityLogo(size: 28, withBorder: false, withShadow: false)),
            _buildDrawerItem(context, 'أخبار القرية', Icons.newspaper_rounded, AppRoutes.newsList),
            _buildDrawerItem(context, 'سجل العزاء', Icons.grade_rounded, AppRoutes.obituariesList),
            _buildDrawerItem(context, 'المناسبات', Icons.card_giftcard_rounded, AppRoutes.occasionsList),
            _buildDrawerItem(context, 'سوق القرية', Icons.store_rounded, AppRoutes.marketProducts),
            _buildDrawerItem(context, 'دليل البائعين', Icons.business_center_rounded, AppRoutes.marketSellers),
            _buildDrawerItem(context, 'دليل الخدمات', Icons.category_rounded, AppRoutes.serviceRequest),
            _buildDrawerItem(context, 'مندرة القرية', Icons.forum_rounded, AppRoutes.forumPosts),
            _buildDrawerItem(context, 'الطوارئ', Icons.contact_phone_rounded, AppRoutes.emergencyContacts),
            _buildDrawerItem(context, 'دليل الهاتف', Icons.phone_rounded, AppRoutes.phoneDirectory),
            _buildDrawerItem(context, 'الملف الشخصي', Icons.person_rounded, AppRoutes.profileMain),
            _buildDrawerItem(context, 'الإعدادات', Icons.settings_rounded, AppRoutes.settingsIndex),
            ListTile(
              leading: Icon(Icons.system_update_rounded,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('التحقق من التحديثات',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.home);
              },
            ),
            _buildDrawerItem(context, 'لوحة التحكم', Icons.admin_panel_settings_rounded, AppRoutes.admin),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon,
      String route, {Widget? leading}) {
    return ListTile(
      leading: leading ??
          Icon(icon, color: Theme.of(context).colorScheme.primary),
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

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'نهارك سعيد 🌤️';
    return 'مساء الخير 🌙';
  }

  static String _dateLabel() {
    const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    // تاريخ القرية نفسه — مشتق من توقيت إحداثيات الطقس وليس من جهاز المستخدم.
    final n = WeatherService.villageNow();
    final d = n.day.toString().padLeft(2, '0');
    final m = n.month.toString().padLeft(2, '0');
    return '${days[n.weekday % 7]} : $d-$m-${n.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroHeader(dateLabel: _dateLabel()),
        const AlertWisdomBar(),
        const VillageWeatherBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: ModernServiceGrid())),
                const SliverToBoxAdapter(
                    child: _SectionHead(
                        title: 'آخر المنتجات',
                        subtitle: 'أحدث ما عرضه بائعو القرية',
                        icon: Icons.bolt_rounded,
                        actionRoute: AppRoutes.marketProducts)),
                SliverToBoxAdapter(child: _buildLatestProducts(context)),
                const SliverToBoxAdapter(
                    child: _SectionHead(
                        title: 'أخبار القرية',
                        subtitle: 'مستجدات أبوديشيشة أولاً بأول',
                        icon: Icons.newspaper_rounded,
                        actionRoute: AppRoutes.newsList)),
                SliverToBoxAdapter(child: _buildLiveNews(context)),
                const SliverToBoxAdapter(
                    child: _SectionHead(
                        title: 'من المنتدى',
                        subtitle: 'نقاشات أهل القرية وآخر المنشورات',
                        icon: Icons.forum_rounded,
                        actionRoute: AppRoutes.forumPosts)),
                SliverToBoxAdapter(child: _buildLivePosts(context)),
                const SliverToBoxAdapter(child: _HomeFooter()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestProducts(BuildContext context) {
    Widget list(List<MarketProduct> products) {
      final latest = [...products]
        ..sort((a, b) => (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));
      final items = latest.take(8).toList();
      if (items.isEmpty) return const SizedBox(height: 170);
      return SizedBox(
        height: 205,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _ProductCard(product: items[index]),
        ),
      );
    }

    return OfflineStreamBuilder<List<MarketProduct>>(
      stream: MarketService().getProductsStream(),
      onlineBuilder: (context, snapshot) => list(snapshot.data ?? []),
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 170);
          final all = (snapshot.data ?? [])
              .map((j) => MarketProduct.fromJson(j, 'cache'))
              .toList();
          return list(all);
        },
      ),
    );
  }

  Widget _buildLiveNews(BuildContext context) {
    final theme = Theme.of(context);
    Widget list(List<NewsItem> news) {
      final sorted = [...news]
        ..sort((a, b) => (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));
      final latest = sorted.take(6).toList();
      if (latest.isEmpty) return const SizedBox(height: 150);
      return SizedBox(
        height: 158,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: latest.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.newsView, arguments: latest[index]),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.35)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      height: 78,
                      width: double.infinity,
                      child: CachedNetworkImage(
                          imageUrl: latest[index].imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => ColoredBox(
                              color: theme
                                  .colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.newspaper_rounded))),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(9),
                    child: Text(latest[index].title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                            fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return OfflineStreamBuilder<List<NewsItem>>(
      stream: NewsService().getNewsStream(),
      onlineBuilder: (context, snapshot) => list(snapshot.data ?? []),
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getNews(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 150);
          final all = (snapshot.data ?? [])
              .map((j) => NewsItem.fromJson(j, 'cache'))
              .toList();
          return list(all);
        },
      ),
    );
  }

  Widget _buildLivePosts(BuildContext context) {
    final theme = Theme.of(context);
    Widget list(List<ForumPost> posts) {
      final latest = posts.take(5).toList();
      if (latest.isEmpty) return const SizedBox(height: 185);
      return SizedBox(
        height: 192,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: latest.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final post = latest[index];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                  context, AppRoutes.forumPostDetail, arguments: post),
              child: Container(
                width: 152,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.35)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        height: 82,
                        width: double.infinity,
                        child: post.imageUrl != null &&
                                post.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: post.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _postIcon(theme))
                            : _postIcon(theme)),
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RoleNameText(
                              name: post.userName,
                              role: post.userRole,
                              sellerType: post.userSellerType,
                              style: GoogleFonts.tajawal(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                              iconSize: 11),
                          const SizedBox(height: 3),
                          Text(post.content,
                              style: GoogleFonts.tajawal(fontSize: 10.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return OfflineStreamBuilder<List<ForumPost>>(
      stream: ForumService().getPostsStream(),
      onlineBuilder: (context, snapshot) => list(snapshot.data ?? []),
      cacheBuilder: (context) => FutureBuilder(
        future: CacheService.getForumPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 185);
          final all = (snapshot.data ?? [])
              .map((j) => ForumPost.fromJson(j, 'cache'))
              .toList();
          return list(all);
        },
      ),
    );
  }

  static Widget _postIcon(ThemeData theme) => ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
          child: Icon(Icons.forum_rounded,
              color: theme.colorScheme.onSurfaceVariant)));
}

// ═══════════════ هيدر علوي مبسّط: الجرس + التاريخ والوقت ═══════════════
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.dateLabel});
  final String dateLabel;

  Widget _pill({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xE66F4E37),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.4)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 18,
              offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1) أرضية بديلة بلون الخلفية (تظهر فقط إن تعذّر تحميل الصورة)
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFFF5F5DC)),
          ),
          // 2) صورة الهيدر كما هي — بلا أي حجابات أو تأثيرات
          Positioned.fill(
            child: Image.asset('assets/images/heder.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── الوقت فوق التاريخ يمينًا، والجرس أعلى اليسار ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // توقيت القرية ثم تاريخها (حسب إحداثيات الطقس، لا جهاز المستخدم)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pill(child: const _VillageClock()),
                          const SizedBox(height: 6),
                          _pill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_rounded,
                                    size: 11, color: Color(0xFFFFE082)),
                                const SizedBox(width: 5),
                                Text(dateLabel,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const NotificationBellButton(compact: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 3) خط ذهبي رفيع على الحافة السفلية
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0x00F1C40F),
                    Color(0xFFF1C40F),
                    Color(0x00F1C40F),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// عرض الشعار بالحجم الكامل — يفتح من الضغط على شعار القائمة الجانبية.
void showQurityLogoDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/images/Qurity.png',
                      fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white24),
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('إغلاق'),
          ),
        ],
      ),
    ),
  );
}


class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: CircleBorder(side: BorderSide(
          color: Colors.white.withValues(alpha: 0.28))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.5),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

/// زر الملف الشخصي — صورة المستخدم المسجلة، وبديل أنيق بغيابها.
class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton(
      {required this.photoUrl, required this.onTap, this.size = 36});
  final String photoUrl;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
            color:
                const Color(0xFFF1C40F).withValues(alpha: 0.85),
            width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: photoUrl.isEmpty
                ? const Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 19)
                : CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white, size: 19),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white, size: 19),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════ عناوين الأقسام ═══════════════════
class _SectionHead extends StatelessWidget {
  const _SectionHead({
    required this.title,
    required this.icon,
    this.subtitle,
    this.actionRoute,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ]),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (actionRoute != null)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pushNamed(context, actionRoute!),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Text('عرض الكل',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_left_rounded,
                        size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════ شبكة الخدمات ═══════════════════
class ModernServiceGrid extends StatelessWidget {
  const ModernServiceGrid({super.key});

  static const _services = [
    _ServiceItem('تعرف على القرية', AppRoutes.about, 'assets/images/About.jpg'),
    _ServiceItem('أخبار القرية', AppRoutes.newsList, 'assets/images/News.jpg'),
    _ServiceItem('سوق القرية', AppRoutes.marketProducts, 'assets/images/Souq.jpg'),
    _ServiceItem('دليل الخدمات', AppRoutes.serviceRequest, 'assets/images/Services.jpg'),
    _ServiceItem('مندرة القرية', AppRoutes.forumPosts, 'assets/images/mandra.jpg'),
    _ServiceItem('دليل الحرفيين', AppRoutes.serviceCategory, 'assets/images/herafeen.jpg', arguments: ServiceCategory.technicians),
    _ServiceItem('خدمات المزارع', AppRoutes.farmerServices, 'assets/images/farmer.jpg'),
    _ServiceItem('المناسبات', AppRoutes.occasionsList, 'assets/images/festefal.jpg'),
    _ServiceItem('سجل العزاء', AppRoutes.obituariesList, 'assets/images/des.jpg'),
    _ServiceItem('ركن الأطفال', AppRoutes.children, 'assets/images/childern.jpg'),
    _ServiceItem('حول التطبيق', AppRoutes.aboutApp, 'assets/images/aboutapp.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95),
      itemBuilder: (context, index) => _buildServiceCard(context, _services[index], index),
    );
  }

  Widget _buildServiceCard(BuildContext context, _ServiceItem service, int index) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: theme.colorScheme.surface,
        child: InkWell(
          borderRadius: radius,
          onTap: () => Navigator.pushNamed(context, service.route, arguments: service.arguments),
          child: Image.asset(service.image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 280,
              semanticLabel: service.title),
        ),
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.92, 0.92));
  }
}

class _ServiceItem {
  final String title;
  final String route;
  final String image;
  final Object? arguments;
  const _ServiceItem(this.title, this.route, this.image, {this.arguments});
}

// ═══════════════ ساعة التوقيت المحلي للقرية (تحت التاريخ) ═══════════════
class _VillageClock extends StatefulWidget {
  const _VillageClock();

  @override
  State<_VillageClock> createState() => _VillageClockState();
}

class _VillageClockState extends State<_VillageClock> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = WeatherService.villageNow();
    final h12 = n.hour % 12 == 0 ? 12 : n.hour % 12;
    final period = n.hour < 12 ? 'ص' : 'م';
    final text =
        '${h12.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')} $period';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded,
            size: 11, color: Color(0xFFFFE082)),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontFeatures: [FontFeature.tabularFigures()])),
      ],
    );
  }
}

// ═══════════════════ بطاقة منتج ═══════════════════
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final MarketProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context,
          AppRoutes.marketProductDetail, arguments: product),
      child: Container(
        width: 136,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_rounded))),
                ),
                if (product.isOnOffer)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(7)),
                      child: const Text('عرض',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${((product.isOnOffer && product.offerPrice != null) ? product.offerPrice! : product.price).toStringAsFixed(0)} ج.م',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                      if (product.isOnOffer && product.offerPrice != null)
                        Text(
                          product.price.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 8.5,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
      child: Column(
        children: [
          Container(
            height: 3,
            width: 44,
            decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Text('قريتك بين يديك — صُنع بحب لأهل أبوديشيشة 💙',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
