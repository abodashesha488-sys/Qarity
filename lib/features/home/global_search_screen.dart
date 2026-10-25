import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/contact_links.dart';
import '../../core/utils/launch_link.dart';
import '../../models/data_models.dart';
import '../../models/legal_models.dart';
import '../../models/lost_item_model.dart';
import '../../models/market_extra_models.dart';
import '../../models/medical_models.dart';
import '../../models/service_provider_model.dart';
import '../../models/village_ad_model.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/medical_service.dart';
import '../../services/service_provider_service.dart';
import '../../services/shop_service.dart';

enum SearchCategoryFilter {
  all('الكل', Icons.search_rounded),
  market('سوق القرية والمحلات', Icons.storefront_rounded),
  services('دليل الحرفيين', Icons.handyman_rounded),
  agricultural('خدمات زراعية', Icons.agriculture_rounded),
  medical('الصحة والأطباء', Icons.medical_services_rounded),
  phone('دليل الهاتف', Icons.contact_page_rounded),
  news('الأخبار والمناسبات', Icons.newspaper_rounded),
  ads('إعلانات القرية', Icons.campaign_rounded),
  legal('المحامين', Icons.gavel_rounded),
  community('المندرة والمفقودات', Icons.forum_rounded);

  final String label;
  final IconData icon;
  const SearchCategoryFilter(this.label, this.icon);
}

class GlobalSearchResultItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color accentColor;
  final String? phone;
  final String? route;
  final dynamic routeArgs;
  final VoidCallback? onTapCustom;

  const GlobalSearchResultItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.accentColor,
    this.phone,
    this.route,
    this.routeArgs,
    this.onTapCustom,
  });
}

/// شاشة البحث الشامل الموحد في قرية أبوديشيشة
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  SearchCategoryFilter _selectedFilter = SearchCategoryFilter.all;
  bool _loading = true;

  // قواعد البيانات المجمعة من كافة أقسام التطبيق
  List<PhoneDirectoryEntry> _phoneEntries = [];
  List<ServiceProvider> _serviceProviders = [];
  List<MedicalCenterClinic> _centerClinics = [];
  List<VillageClinic> _villageClinics = [];
  List<Pharmacy> _pharmacies = [];
  List<MedicalLab> _medicalLabs = [];
  List<OpticalShop> _opticalShops = [];
  List<MarketProduct> _products = [];
  List<Shop> _shops = [];
  List<NewsItem> _news = [];
  List<Occasion> _occasions = [];
  List<Obituary> _obituaries = [];
  List<ForumPost> _forumPosts = [];
  List<LostItem> _lostItems = [];
  List<VillageAd> _villageAds = [];
  List<Lawyer> _lawyers = [];
  List<EmergencyContact> _emergencyContacts = [];

  List<GlobalSearchResultItem> _results = [];

  static const List<String> _popularSuggestions = [
    'دكتور أطفال',
    'صيدلية',
    'عمال ومعدات',
    'عمالة زراعية',
    'خدمات تجهيز الأرض',
    'كهربائي',
    'سباك',
    'غاز',
    'نجار',
    'طوارئ',
    'تحاليل',
    'جرار زراعي',
    'محامي',
    'مفقود',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllSearchSources();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllSearchSources() async {
    setState(() => _loading = true);
    final fs = FirebaseFirestore.instance;

    // 1. دليل الهاتف
    try {
      final phoneJson = await CacheService.getPhoneDirectory();
      if (phoneJson != null && phoneJson.isNotEmpty) {
        _phoneEntries = phoneJson
            .map((j) => PhoneDirectoryEntry.fromJson(j, j['id'] ?? ''))
            .toList();
      } else {
        final snap = await fs
            .collection('phone_directory')
            .where('isApproved', isEqualTo: true)
            .get();
        _phoneEntries = snap.docs
            .map((d) => PhoneDirectoryEntry.fromJson(d.data(), d.id))
            .toList();
      }
    } catch (_) {}

    // 2. منتجات السوق
    try {
      final productsJson = await CacheService.getProducts();
      if (productsJson != null && productsJson.isNotEmpty) {
        _products = productsJson
            .map((j) => MarketProduct.fromJson(j, j['id'] ?? ''))
            .toList();
      } else {
        final snap = await fs
            .collection('market_products')
            .where('isApproved', isEqualTo: true)
            .get();
        _products = snap.docs
            .map((d) => MarketProduct.fromJson(d.data(), d.id))
            .toList();
      }
    } catch (_) {}

    // 3. محلات القرية
    try {
      _shops = await ShopService().getApprovedShops();
    } catch (_) {}

    // 4. الأخبار
    try {
      final newsJson = await CacheService.getNews();
      if (newsJson != null && newsJson.isNotEmpty) {
        _news =
            newsJson.map((j) => NewsItem.fromJson(j, j['id'] ?? '')).toList();
      } else {
        final snap = await fs
            .collection('news')
            .where('isApproved', isEqualTo: true)
            .get();
        _news = snap.docs
            .map((d) => NewsItem.fromJson(d.data(), d.id))
            .toList();
      }
    } catch (_) {}

    // 5. الأطباء والخدمات الطبية
    try {
      _centerClinics =
          await MedicalCenterService().getClinicsStream().first;
    } catch (_) {}
    try {
      _villageClinics =
          await VillageClinicService().getApprovedStream().first;
    } catch (_) {}
    try {
      _pharmacies = await PharmacyService().getApprovedStream().first;
    } catch (_) {}
    try {
      _medicalLabs = await MedicalLabService().getApprovedStream().first;
    } catch (_) {}
    try {
      _opticalShops = await OpticalShopService().getApprovedStream().first;
    } catch (_) {}

    // 6. الحرفيون والخدمات (فنيين - زراعية - تعليمية)
    try {
      final provSvc = ServiceProviderService();
      final techs =
          await provSvc.getApprovedByCategory(ServiceCategory.technicians).first;
      final agris =
          await provSvc.getApprovedByCategory(ServiceCategory.agricultural).first;
      final edus =
          await provSvc.getApprovedByCategory(ServiceCategory.educational).first;
      _serviceProviders = [...techs, ...agris, ...edus];
    } catch (_) {}

    // 7. المناسبات
    try {
      final snap = await fs
          .collection('occasions')
          .where('isApproved', isEqualTo: true)
          .get();
      _occasions = snap.docs
          .map((d) => Occasion.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}

    // 8. سجل العزاء
    try {
      final snap = await fs
          .collection('obituaries')
          .where('isApproved', isEqualTo: true)
          .get();
      _obituaries = snap.docs
          .map((d) => Obituary.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}

    // 9. مندرة القرية
    try {
      final postsJson = await CacheService.getForumPosts();
      if (postsJson != null && postsJson.isNotEmpty) {
        _forumPosts = postsJson
            .map((j) => ForumPost.fromJson(j, j['id'] ?? ''))
            .toList();
      } else {
        final snap = await fs
            .collection('forum_posts')
            .where('isApproved', isEqualTo: true)
            .limit(30)
            .get();
        _forumPosts = snap.docs
            .map((d) => ForumPost.fromJson(d.data(), d.id))
            .toList();
      }
    } catch (_) {}

    // 10. المفقودات
    try {
      final snap = await fs
          .collection('lost_items')
          .where('isApproved', isEqualTo: true)
          .get();
      _lostItems = snap.docs
          .map((d) => LostItem.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}

    // 11. إعلانات القرية
    try {
      final snap = await fs
          .collection('village_ads')
          .where('isApproved', isEqualTo: true)
          .get();
      _villageAds = snap.docs
          .map((d) => VillageAd.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}

    // 12. سجل المحامين
    try {
      final snap = await fs
          .collection('lawyers')
          .where('isApproved', isEqualTo: true)
          .get();
      _lawyers = snap.docs
          .map((d) => Lawyer.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}

    // 13. أرقام الطوارئ
    try {
      final snap = await fs.collection('emergency_contacts').get();
      _emergencyContacts = snap.docs
          .map((d) => EmergencyContact.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
      _performSearch(_searchCtrl.text);
    }
  }

  static String _norm(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  static bool _matches(String? text, String query) {
    if (text == null || text.isEmpty || query.isEmpty) return false;
    final cleanText = _norm(text);
    final cleanQuery = _norm(query);
    if (cleanText.contains(cleanQuery)) return true;
    final tokens = cleanQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    if (tokens.isEmpty) return false;
    return tokens.every((token) => cleanText.contains(token));
  }

  void _performSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final list = <GlobalSearchResultItem>[];

    // 1. دليل الهاتف
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.phone) {
      for (final e in _phoneEntries) {
        if (_matches(e.name, q) ||
            _matches(e.title, q) ||
            _matches(e.job, q) ||
            _matches(e.address, q) ||
            e.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: e.name,
            subtitle: '${e.title} · ${e.phone}',
            category: 'دليل الهاتف',
            icon: Icons.contact_phone_rounded,
            accentColor: const Color(0xFF0288D1),
            phone: e.phone,
            route: AppRoutes.phoneDirectory,
          ));
        }
      }
      for (final ec in _emergencyContacts) {
        if (_matches(ec.name, q) || ec.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: ec.name,
            subtitle: 'طوارئ القرية · ${ec.phone}',
            category: 'أرقام الطوارئ',
            icon: Icons.emergency_rounded,
            accentColor: const Color(0xFFD32F2F),
            phone: ec.phone,
            route: AppRoutes.emergencyContacts,
          ));
        }
      }
    }

    // 2. الخدمات الطبية
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.medical) {
      for (final c in _centerClinics) {
        if (_matches(c.name, q) ||
            _matches(c.specialty, q) ||
            _matches(c.doctorName, q)) {
          list.add(GlobalSearchResultItem(
            title: c.name,
            subtitle: 'المركز الطبي الخيري · ${c.specialty} ${c.doctorName}',
            category: 'المركز الطبي',
            icon: Icons.local_hospital_rounded,
            accentColor: const Color(0xFF00695C),
            route: AppRoutes.medical,
          ));
        }
      }
      for (final vc in _villageClinics) {
        if (_matches(vc.name, q) ||
            _matches(vc.specialty, q) ||
            _matches(vc.ownerName, q) ||
            _matches(vc.address, q) ||
            vc.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: vc.name,
            subtitle: 'عيادة خاصة · ${vc.specialty} · ${vc.phone}',
            category: 'عيادات القرية',
            icon: Icons.medical_services_rounded,
            accentColor: const Color(0xFF00897B),
            phone: vc.phone,
            route: AppRoutes.medicalClinicDetail,
            routeArgs: vc,
          ));
        }
      }
      for (final p in _pharmacies) {
        if (_matches(p.name, q) ||
            _matches(p.address, q) ||
            p.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: p.name,
            subtitle: 'صيدلية · ${p.address} · ${p.phone}',
            category: 'صيدليات القرية',
            icon: Icons.local_pharmacy_rounded,
            accentColor: AppColors.primary,
            phone: p.phone,
            route: AppRoutes.medicalPharmacyDetail,
            routeArgs: p,
          ));
        }
      }
      for (final l in _medicalLabs) {
        if (_matches(l.name, q) ||
            _matches(l.category, q) ||
            _matches(l.address, q) ||
            l.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: l.name,
            subtitle: 'معمل تحاليل · ${l.category} · ${l.phone}',
            category: 'معامل التحاليل',
            icon: Icons.biotech_rounded,
            accentColor: const Color(0xFF00838F),
            phone: l.phone,
            route: AppRoutes.medicalLabDetail,
            routeArgs: l,
          ));
        }
      }
      for (final o in _opticalShops) {
        if (_matches(o.name, q) ||
            _matches(o.ownerName, q) ||
            _matches(o.address, q) ||
            o.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: o.name,
            subtitle: 'محل نظارات · ${o.address} · ${o.phone}',
            category: 'نظارات وبصريات',
            icon: Icons.visibility_rounded,
            accentColor: const Color(0xFF3949AB),
            phone: o.phone,
            route: AppRoutes.medicalOpticalDetail,
            routeArgs: o,
          ));
        }
      }
    }

    // 3. الحرفيون والفنيون
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.services) {
      for (final s in _serviceProviders.where((p) =>
          p.category == ServiceCategory.technicians ||
          p.category == ServiceCategory.educational)) {
        if (_matches(s.name, q) ||
            _matches(s.specialty, q) ||
            _matches(s.category, q) ||
            _matches(s.address, q) ||
            _matches(s.description, q) ||
            s.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: s.name,
            subtitle:
                '${s.displaySpecialty}${s.address.isNotEmpty ? ' · ${s.address}' : ''}${s.phone.isNotEmpty ? ' · ${s.phone}' : ''}',
            category: ServiceCategory.label(s.category),
            icon: ServiceCategory.icon(s.category),
            accentColor: ServiceCategory.color(s.category),
            phone: s.phone,
            route: AppRoutes.serviceProviderDetail,
            routeArgs: s,
          ));
        }
      }
    }

    // 4. خدمات زراعية وعمال ومعدات
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.agricultural) {
      for (final s in _serviceProviders
          .where((p) => p.category == ServiceCategory.agricultural)) {
        if (_matches(s.name, q) ||
            _matches(s.specialty, q) ||
            _matches(s.address, q) ||
            _matches(s.description, q) ||
            s.phone.contains(q) ||
            _matches(q, 'عمال') ||
            _matches(q, 'معدات') ||
            _matches(q, 'تجهيز') ||
            _matches(q, 'زراع')) {
          list.add(GlobalSearchResultItem(
            title: s.name,
            subtitle:
                '${s.displaySpecialty}${s.address.isNotEmpty ? ' · ${s.address}' : ''}${s.phone.isNotEmpty ? ' · ${s.phone}' : ''}',
            category: 'خدمات زراعية · عمال ومعدات',
            icon: Icons.agriculture_rounded,
            accentColor: const Color(0xFF2E7D32),
            phone: s.phone,
            route: AppRoutes.serviceProviderDetail,
            routeArgs: s,
          ));
        }
      }
    }

    // 5. سوق القرية والمحلات
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.market) {
      for (final p in _products) {
        if (_matches(p.name, q) ||
            _matches(p.description, q) ||
            _matches(p.category, q) ||
            _matches(p.sellerName, q)) {
          list.add(GlobalSearchResultItem(
            title: p.name,
            subtitle: '${p.price.toStringAsFixed(0)} ج.م · ${p.category} · ${p.sellerName}',
            category: 'منتج في السوق',
            icon: Icons.shopping_bag_rounded,
            accentColor: const Color(0xFF6A1B9A),
            phone: p.sellerPhone,
            route: AppRoutes.marketProductDetail,
            routeArgs: p,
          ));
        }
      }
      for (final s in _shops) {
        if (_matches(s.name, q) ||
            _matches(s.description, q) ||
            _matches(s.category, q) ||
            _matches(s.ownerName, q) ||
            s.whatsapp.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: s.name,
            subtitle: 'محل تجاري · ${s.category} · ${s.ownerName}',
            category: 'محلات القرية',
            icon: Icons.storefront_rounded,
            accentColor: const Color(0xFF8E24AA),
            phone: s.whatsapp,
            route: AppRoutes.marketTabs,
          ));
        }
      }
    }

    // 6. الأخبار والمناسبات
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.news) {
      for (final n in _news) {
        if (_matches(n.title, q) ||
            _matches(n.subtitle, q) ||
            _matches(n.category, q)) {
          list.add(GlobalSearchResultItem(
            title: n.title,
            subtitle: n.category,
            category: 'أخبار القرية',
            icon: Icons.newspaper_rounded,
            accentColor: const Color(0xFFC62828),
            route: AppRoutes.newsView,
            routeArgs: n,
          ));
        }
      }
      for (final o in _occasions) {
        if (_matches(o.title, q) ||
            _matches(o.description, q) ||
            _matches(o.location, q)) {
          list.add(GlobalSearchResultItem(
            title: o.title,
            subtitle: 'مناسبة · ${o.location}',
            category: 'مناسبات القرية',
            icon: Icons.celebration_rounded,
            accentColor: const Color(0xFFF57F17),
            route: AppRoutes.occasionsDetail,
            routeArgs: o,
          ));
        }
      }
    }

    // 7. إعلانات القرية
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.ads) {
      for (final va in _villageAds) {
        if (_matches(va.title, q) ||
            _matches(va.description, q) ||
            _matches(va.businessName, q) ||
            _matches(va.userName, q) ||
            va.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: va.title,
            subtitle: 'إعلان مبوب · ${va.kindLabel} · ${va.businessName.isNotEmpty ? va.businessName : va.userName}',
            category: 'إعلانات القرية',
            icon: Icons.campaign_rounded,
            accentColor: const Color(0xFFE65100),
            phone: va.phone,
            route: AppRoutes.villageAdDetail,
            routeArgs: va,
          ));
        }
      }
    }

    // 8. المحامين
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.legal) {
      for (final law in _lawyers) {
        if (_matches(law.name, q) ||
            _matches(law.office, q) ||
            _matches(law.specializationsLine, q) ||
            _matches(law.bio, q) ||
            law.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: law.name,
            subtitle: 'محامٍ · ${law.specializationsLine.isNotEmpty ? law.specializationsLine : law.office}',
            category: 'مستشار القرية',
            icon: Icons.gavel_rounded,
            accentColor: const Color(0xFF37474F),
            phone: law.phone,
            route: AppRoutes.lawyerDetail,
            routeArgs: law,
          ));
        }
      }
    }

    // 9. مندرة القرية والمفقودات وسجل العزاء
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.community) {
      for (final fp in _forumPosts) {
        if (_matches(fp.content, q) || _matches(fp.userName, q)) {
          list.add(GlobalSearchResultItem(
            title: fp.content.length > 50 ? '${fp.content.substring(0, 50)}...' : fp.content,
            subtitle: 'منشور مندرة بواسطة ${fp.userName}',
            category: 'مندرة القرية',
            icon: Icons.forum_rounded,
            accentColor: const Color(0xFF1565C0),
            route: AppRoutes.forumPostDetail,
            routeArgs: fp,
          ));
        }
      }
      for (final li in _lostItems) {
        if (_matches(li.title, q) ||
            _matches(li.description, q) ||
            _matches(li.location, q) ||
            li.phone.contains(q)) {
          list.add(GlobalSearchResultItem(
            title: li.title,
            subtitle: '${li.typeLabel} · ${li.location}',
            category: 'المفقودات',
            icon: Icons.search_rounded,
            accentColor: const Color(0xFF5E35B1),
            phone: li.phone,
            route: AppRoutes.lostItemDetail,
            routeArgs: li,
          ));
        }
      }
      for (final ob in _obituaries) {
        if (_matches(ob.name, q) ||
            _matches(ob.description ?? '', q) ||
            _matches(ob.burialLocation, q) ||
            _matches(ob.funeralLocation, q)) {
          list.add(GlobalSearchResultItem(
            title: ob.name,
            subtitle: 'سجل العزاء · ${ob.burialLocation.isNotEmpty ? ob.burialLocation : ob.funeralLocation}',
            category: 'سجل العزاء',
            icon: Icons.volunteer_activism_rounded,
            accentColor: const Color(0xFF424242),
            route: AppRoutes.obituariesDetail,
            routeArgs: ob,
          ));
        }
      }
    }

    setState(() => _results = list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'رجوع',
        ),
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن طبيب، صيدلية، سباك، منتج، خبر...',
                hintStyle: GoogleFonts.tajawal(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // شريط المرشحات السريعة
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: SearchCategoryFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = SearchCategoryFilter.values[i];
                final isSelected = filter == _selectedFilter;
                return ChoiceChip(
                  avatar: Icon(filter.icon, size: 14),
                  label: Text(filter.label, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedFilter = filter);
                      _performSearch(_searchCtrl.text);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // المحتوى
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _searchCtrl.text.trim().isEmpty
                    ? _buildInitialSuggestions(context)
                    : _results.isEmpty
                        ? _buildNoResults(context)
                        : _buildResultsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'عمليات بحث شائعة في القرية',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSuggestions.map((term) {
            return ActionChip(
              label: Text(term, style: const TextStyle(fontSize: 12.5)),
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              onPressed: () {
                _searchCtrl.text = term;
                _searchCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: term.length),
                );
                _performSearch(term);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ابحث بالاسم أو المهنة أو رقم الهاتف أو التخصص للوصول الفوري لكل خدمات القرية.',
                  style: GoogleFonts.tajawal(fontSize: 12, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'لم يتم العثور على نتائج لـ "${_searchCtrl.text}"',
            style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'جرّب كتابة كلمة بحث مختلفة أو تصفح الأقسام المباشرة.',
            style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = _results[i];
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.accentColor, size: 22),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: item.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: item.phone != null && item.phone!.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                        tooltip: 'اتصال',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          launchPhoneCall(item.phone!);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.teal, size: 20),
                        tooltip: 'واتساب',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final wa = egyptianWhatsAppUrl(item.phone!);
                          if (wa != null) launchWhatsAppUrl(wa);
                        },
                      ),
                    ],
                  )
                : const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
            onTap: () {
              if (item.onTapCustom != null) {
                item.onTapCustom!();
              } else if (item.route != null) {
                Navigator.pushNamed(context, item.route!, arguments: item.routeArgs);
              }
            },
          ),
        );
      },
    );
  }
}
