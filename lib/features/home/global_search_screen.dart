import 'package:cached_network_image/cached_network_image.dart';
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
import '../market/market_tabs_screen.dart';

enum SearchCategoryFilter {
  all('الكل', Icons.search_rounded),
  market('سوق القرية والمحلات', Icons.storefront_rounded),
  services('دليل الحرفيين', Icons.handyman_rounded),
  agricultural('خدمات زراعية', Icons.agriculture_rounded),
  medical('الصحة والأطباء', Icons.medical_services_rounded),
  phone('دليل الهاتف', Icons.contact_page_rounded),
  news('الأخبار والمناسبات', Icons.newspaper_rounded),
  ads('إعلانات القرية', Icons.campaign_rounded),
  legal('المحامين والاستشارات', Icons.gavel_rounded),
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
  final String? imageUrl;
  final dynamic originalRecord;
  final String? phone;
  final String? route;
  final dynamic routeArgs;
  final VoidCallback? onTapCustom;
  final String? badgeLabel;

  const GlobalSearchResultItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.accentColor,
    this.imageUrl,
    this.originalRecord,
    this.phone,
    this.route,
    this.routeArgs,
    this.onTapCustom,
    this.badgeLabel,
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
  List<Donation> _donations = [];
  List<BuyRequest> _buyRequests = [];
  List<NewsItem> _news = [];
  List<Occasion> _occasions = [];
  List<Obituary> _obituaries = [];
  List<ForumPost> _forumPosts = [];
  List<LostItem> _lostItems = [];
  List<VillageAd> _villageAds = [];
  List<Lawyer> _lawyers = [];
  List<LegalConsultation> _legalConsultations = [];
  List<BloodRequest> _bloodRequests = [];
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
    FirebaseFirestore? fs;
    try {
      fs = FirebaseFirestore.instance;
    } catch (_) {
      // Firebase not initialized in tests
    }
    if (fs == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

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

    // 3.1 تبرعات وتكافل السوق
    try {
      final snap = await fs
          .collection('donations')
          .where('isApproved', isEqualTo: true)
          .get();
      _donations = snap.docs
          .map((d) => Donation.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}

    // 3.2 سلع السوق المطلوبة
    try {
      final snap = await fs
          .collection('buy_requests')
          .where('isApproved', isEqualTo: true)
          .get();
      _buyRequests = snap.docs
          .map((d) => BuyRequest.fromJson(d.data(), d.id))
          .toList();
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
    try {
      final snap = await fs
          .collection('blood_requests')
          .where('isApproved', isEqualTo: true)
          .get();
      _bloodRequests = snap.docs
          .map((d) => BloodRequest.fromJson(d.data(), d.id))
          .toList();
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

    // 9. مندرة القرية (تحميل المنشورات المعتمدة كاملة دون حجب بالليميت)
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

    // 12. سجل المحامين والاستشارات
    try {
      final snap = await fs
          .collection('lawyers')
          .where('isApproved', isEqualTo: true)
          .get();
      _lawyers = snap.docs
          .map((d) => Lawyer.fromJson(d.data(), d.id))
          .toList();
    } catch (_) {}
    try {
      final snap = await fs
          .collection('legal_consultations')
          .where('isApproved', isEqualTo: true)
          .get();
      _legalConsultations = snap.docs
          .map((d) => LegalConsultation.fromJson(d.data(), d.id))
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
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // التشكيل
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
  }

  static bool _matches(String? text, String query) {
    if (text == null || text.trim().isEmpty || query.trim().isEmpty) return false;
    final cleanText = _norm(text);
    final cleanQuery = _norm(query);
    if (cleanText.contains(cleanQuery)) return true;

    // استبعاد الكلمات الزائدة العامة
    const stopWords = {
      'في', 'من', 'علي', 'على', 'عن', 'مع', 'او', 'و',
      'القريه', 'قريه', 'ابوديشيشه', 'مركز'
    };
    final tokens = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !stopWords.contains(t))
        .toList();

    if (tokens.isEmpty) return cleanText.contains(cleanQuery);
    return tokens.every((token) => cleanText.contains(token));
  }

  static bool _matchesPhone(String? phone, String query) {
    if (phone == null || phone.isEmpty || query.isEmpty) return false;
    final cleanP = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanQ = query.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanQ.isEmpty) return false;
    return cleanP.contains(cleanQ);
  }

  void _performSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final list = <GlobalSearchResultItem>[];

    // 1. دليل الهاتف وأرقام الطوارئ
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.phone) {
      for (final e in _phoneEntries) {
        if (_matches(e.name, q) ||
            _matches(e.title, q) ||
            _matches(e.job, q) ||
            _matches(e.address, q) ||
            _matchesPhone(e.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: e.name,
            subtitle: '${e.title}${e.job != null && e.job!.isNotEmpty ? ' · ${e.job}' : ''} · ${e.phone}',
            category: 'دليل الهاتف',
            icon: Icons.contact_phone_rounded,
            accentColor: const Color(0xFF0288D1),
            imageUrl: e.photoUrl,
            originalRecord: e,
            phone: e.phone,
            onTapCustom: () => _showPhoneContactSheet(context, e),
          ));
        }
      }
      for (final ec in _emergencyContacts) {
        if (_matches(ec.name, q) || _matchesPhone(ec.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: ec.name,
            subtitle: 'طوارئ القرية · ${ec.phone}',
            category: 'أرقام الطوارئ',
            icon: Icons.emergency_rounded,
            accentColor: const Color(0xFFD32F2F),
            originalRecord: ec,
            phone: ec.phone,
            route: AppRoutes.emergencyContacts,
          ));
        }
      }
    }

    // 2. الخدمات الطبية وبنك الدم
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.medical) {
      for (final c in _centerClinics) {
        if (_matches(c.name, q) ||
            _matches(c.specialty, q) ||
            _matches(c.doctorName, q) ||
            _matches(c.description, q) ||
            _matches(q, 'المركز الطبي') ||
            _matches(q, 'طبيب') ||
            _matches(q, 'دكتور')) {
          list.add(GlobalSearchResultItem(
            title: c.name,
            subtitle: 'المركز الطبي الخيري · ${c.specialty}${c.doctorName.isNotEmpty ? ' · د. ${c.doctorName}' : ''}',
            category: 'المركز الطبي',
            icon: Icons.local_hospital_rounded,
            accentColor: const Color(0xFF00695C),
            imageUrl: c.imageUrl,
            originalRecord: c,
            badgeLabel: c.scheduleStatusLabel,
            onTapCustom: () => _showCenterClinicSheet(context, c),
          ));
        }
      }
      for (final vc in _villageClinics) {
        if (_matches(vc.name, q) ||
            _matches(vc.specialty, q) ||
            _matches(vc.ownerName, q) ||
            _matches(vc.address, q) ||
            _matches(vc.workingHours, q) ||
            _matchesPhone(vc.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: vc.name,
            subtitle: 'عيادة خاصة · ${vc.specialty} · ${vc.phone}',
            category: 'عيادات القرية',
            icon: Icons.medical_services_rounded,
            accentColor: const Color(0xFF00897B),
            imageUrl: vc.imageUrl,
            originalRecord: vc,
            phone: vc.phone,
            route: AppRoutes.medicalClinicDetail,
            routeArgs: vc,
          ));
        }
      }
      for (final p in _pharmacies) {
        if (_matches(p.name, q) ||
            _matches(p.address, q) ||
            _matches(p.workingHours, q) ||
            _matches(q, 'دواء') ||
            _matches(q, 'صيدلية') ||
            _matchesPhone(p.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: p.name,
            subtitle: 'صيدلية · ${p.address} · ${p.phone}',
            category: 'صيدليات القرية',
            icon: Icons.local_pharmacy_rounded,
            accentColor: AppColors.primary,
            imageUrl: p.imageUrl,
            originalRecord: p,
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
            _matches(q, 'تحليل') ||
            _matches(q, 'معمل') ||
            _matchesPhone(l.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: l.name,
            subtitle: 'معمل تحاليل · ${l.category} · ${l.phone}',
            category: 'معامل التحاليل',
            icon: Icons.biotech_rounded,
            accentColor: const Color(0xFF00838F),
            imageUrl: l.imageUrl,
            originalRecord: l,
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
            _matches(q, 'نظارة') ||
            _matches(q, 'بصريات') ||
            _matchesPhone(o.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: o.name,
            subtitle: 'محل نظارات · ${o.address} · ${o.phone}',
            category: 'نظارات وبصريات',
            icon: Icons.visibility_rounded,
            accentColor: const Color(0xFF3949AB),
            imageUrl: o.imageUrl,
            originalRecord: o,
            phone: o.phone,
            route: AppRoutes.medicalOpticalDetail,
            routeArgs: o,
          ));
        }
      }
      for (final br in _bloodRequests) {
        if (_matches(br.bloodType.label, q) ||
            _matches(br.bloodType.code, q) ||
            _matches(br.hospital, q) ||
            _matches(br.patientName, q) ||
            _matches(q, 'دم') ||
            _matches(q, 'فصيلة') ||
            _matchesPhone(br.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: 'طلب فصيلة دم (${br.bloodType.label})',
            subtitle: 'مريض في ${br.hospital} · ${br.phone}',
            category: 'بنك الدم',
            icon: Icons.bloodtype_rounded,
            accentColor: const Color(0xFFC2185B),
            originalRecord: br,
            phone: br.phone,
            onTapCustom: () => _showBloodRequestSheet(context, br),
          ));
        }
      }
    }

    // 3. الحرفيون والفنيون والخدمات التعليمية
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
            _matchesPhone(s.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: s.name,
            subtitle:
                '${s.displaySpecialty}${s.address.isNotEmpty ? ' · ${s.address}' : ''}${s.phone.isNotEmpty ? ' · ${s.phone}' : ''}',
            category: ServiceCategory.label(s.category),
            icon: ServiceCategory.icon(s.category),
            accentColor: ServiceCategory.color(s.category),
            imageUrl: s.photoUrl,
            originalRecord: s,
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
            _matchesPhone(s.phone, q) ||
            _matches(q, 'عمال') ||
            _matches(q, 'معدات') ||
            _matches(q, 'تجهيز') ||
            _matches(q, 'زراع') ||
            _matches(q, 'جرار')) {
          list.add(GlobalSearchResultItem(
            title: s.name,
            subtitle:
                '${s.displaySpecialty}${s.address.isNotEmpty ? ' · ${s.address}' : ''}${s.phone.isNotEmpty ? ' · ${s.phone}' : ''}',
            category: 'خدمات زراعية · عمال ومعدات',
            icon: Icons.agriculture_rounded,
            accentColor: const Color(0xFF2E7D32),
            imageUrl: s.photoUrl,
            originalRecord: s,
            phone: s.phone,
            route: AppRoutes.serviceProviderDetail,
            routeArgs: s,
          ));
        }
      }
    }

    // 5. سوق القرية والمحلات والتبرعات والسلع المطلوبة
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.market) {
      for (final p in _products) {
        if (_matches(p.name, q) ||
            _matches(p.description, q) ||
            _matches(p.category, q) ||
            _matches(p.sellerName, q) ||
            _matchesPhone(p.sellerPhone, q)) {
          final prodImg = p.imageUrl.isNotEmpty
              ? p.imageUrl
              : (p.imageUrls.isNotEmpty ? p.imageUrls.first : null);
          list.add(GlobalSearchResultItem(
            title: p.name,
            subtitle: '${p.price.toStringAsFixed(0)} ج.م · ${p.category} · ${p.sellerName}',
            category: 'منتج في السوق',
            icon: Icons.shopping_bag_rounded,
            accentColor: const Color(0xFF6A1B9A),
            imageUrl: prodImg,
            originalRecord: p,
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
            _matches(q, 'محل') ||
            _matches(q, 'دكان') ||
            _matches(q, 'متجر') ||
            _matchesPhone(s.whatsapp, q)) {
          list.add(GlobalSearchResultItem(
            title: s.name,
            subtitle: 'محل تجاري · ${s.category} · ${s.ownerName}',
            category: 'محلات القرية',
            icon: Icons.storefront_rounded,
            accentColor: const Color(0xFF8E24AA),
            imageUrl: s.imageUrl,
            originalRecord: s,
            phone: s.whatsapp,
            onTapCustom: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: s)),
            ),
          ));
        }
      }
      for (final d in _donations) {
        if (_matches(d.title, q) ||
            _matches(d.description, q) ||
            _matches(d.category, q) ||
            _matches(d.userName, q) ||
            _matches(q, 'خير') ||
            _matches(q, 'تبرع') ||
            _matchesPhone(d.contactPhone, q)) {
          list.add(GlobalSearchResultItem(
            title: d.title,
            subtitle: 'تكافل وخير · ${d.category} · ${d.statusLabel}',
            category: 'تبرعات وخير',
            icon: Icons.volunteer_activism_rounded,
            accentColor: const Color(0xFF00897B),
            imageUrl: d.imageUrl,
            originalRecord: d,
            phone: d.contactPhone,
            onTapCustom: () => _showDonationSheet(context, d),
          ));
        }
      }
      for (final br in _buyRequests) {
        if (_matches(br.title, q) ||
            _matches(br.details, q) ||
            _matches(br.userName, q) ||
            _matches(q, 'مطلوب') ||
            _matchesPhone(br.contactPhone, q)) {
          list.add(GlobalSearchResultItem(
            title: br.title,
            subtitle: 'سلعة مطلوبة · ${br.budget.isNotEmpty ? 'الميزانية: ${br.budget} ج.م · ' : ''}${br.statusLabel}',
            category: 'سلع مطلوبة',
            icon: Icons.production_quantity_limits_rounded,
            accentColor: const Color(0xFF1565C0),
            imageUrl: br.imageUrl,
            originalRecord: br,
            phone: br.contactPhone,
            onTapCustom: () => _showBuyRequestSheet(context, br),
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
            imageUrl: n.imageUrl,
            originalRecord: n,
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
            imageUrl: o.imageUrl,
            originalRecord: o,
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
            _matchesPhone(va.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: va.title,
            subtitle: 'إعلان مبوب · ${va.kindLabel} · ${va.businessName.isNotEmpty ? va.businessName : va.userName}',
            category: 'إعلانات القرية',
            icon: Icons.campaign_rounded,
            accentColor: const Color(0xFFE65100),
            imageUrl: va.imageUrl,
            originalRecord: va,
            phone: va.phone,
            route: AppRoutes.villageAdDetail,
            routeArgs: va,
          ));
        }
      }
    }

    // 8. المحامين والاستشارات القانونية
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.legal) {
      for (final law in _lawyers) {
        if (_matches(law.name, q) ||
            _matches(law.office, q) ||
            _matches(law.specializationsLine, q) ||
            _matches(law.bio, q) ||
            _matches(q, 'محامي') ||
            _matches(q, 'قضية') ||
            _matchesPhone(law.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: law.name,
            subtitle: 'محامٍ · ${law.specializationsLine.isNotEmpty ? law.specializationsLine : law.office}',
            category: 'مستشار القرية',
            icon: Icons.gavel_rounded,
            accentColor: const Color(0xFF37474F),
            imageUrl: law.photoUrl,
            originalRecord: law,
            phone: law.phone,
            route: AppRoutes.lawyerDetail,
            routeArgs: law,
          ));
        }
      }
      for (final lc in _legalConsultations) {
        if (_matches(lc.question, q) ||
            _matches(lc.details, q) ||
            _matches(lc.category, q) ||
            _matches(lc.answer, q)) {
          final lcImg = lc.images.isNotEmpty ? lc.images.first : null;
          list.add(GlobalSearchResultItem(
            title: lc.question,
            subtitle: 'استشارة قانونية · ${lc.category}${lc.hasAnswer ? ' · تم الرد' : ''}',
            category: 'مستشار القرية',
            icon: Icons.help_outline_rounded,
            accentColor: kLegalAdvisorColor,
            imageUrl: lcImg,
            originalRecord: lc,
            onTapCustom: () => _showLegalConsultationSheet(context, lc),
          ));
        }
      }
    }

    // 9. مندرة القرية والمفقودات وسجل العزاء
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.community) {
      for (final fp in _forumPosts) {
        if (_matches(fp.content, q) || _matches(fp.userName, q)) {
          final postImg = (fp.imageUrl != null && fp.imageUrl!.isNotEmpty)
              ? fp.imageUrl
              : (fp.userPhotoUrl.isNotEmpty ? fp.userPhotoUrl : null);
          list.add(GlobalSearchResultItem(
            title: fp.content.length > 60 ? '${fp.content.substring(0, 60)}...' : fp.content,
            subtitle: 'منشور مندرة بواسطة ${fp.userName}',
            category: 'مندرة القرية',
            icon: Icons.forum_rounded,
            accentColor: const Color(0xFF1565C0),
            imageUrl: postImg,
            originalRecord: fp,
            route: AppRoutes.forumPostDetail,
            routeArgs: fp,
          ));
        }
      }
      for (final li in _lostItems) {
        if (_matches(li.title, q) ||
            _matches(li.description, q) ||
            _matches(li.location, q) ||
            _matches(q, 'مفقود') ||
            _matches(q, 'ضائع') ||
            _matchesPhone(li.phone, q)) {
          list.add(GlobalSearchResultItem(
            title: li.title,
            subtitle: '${li.typeLabel} · ${li.location}',
            category: 'المفقودات',
            icon: Icons.search_rounded,
            accentColor: const Color(0xFF5E35B1),
            imageUrl: li.imageUrl,
            originalRecord: li,
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
            _matches(ob.funeralLocation, q) ||
            _matches(q, 'وفاة') ||
            _matches(q, 'عزاء') ||
            _matches(q, 'مرحوم') ||
            _matches(q, 'مرحومة')) {
          list.add(GlobalSearchResultItem(
            title: ob.name,
            subtitle: 'سجل العزاء · ${ob.burialLocation.isNotEmpty ? ob.burialLocation : ob.funeralLocation}',
            category: 'سجل العزاء',
            icon: Icons.person_pin_rounded,
            accentColor: const Color(0xFF424242),
            imageUrl: ob.imageUrl,
            originalRecord: ob,
            route: AppRoutes.obituariesDetail,
            routeArgs: ob,
          ));
        }
      }
    }

    setState(() => _results = list);
  }

  // ═══════════════════════ النوافذ التفاعلية للسجلات الأصلية ═══════════════════════

  void _showCenterClinicSheet(BuildContext context, MedicalCenterClinic clinic) {
    final theme = Theme.of(context);
    const accent = Color(0xFF00695C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (clinic.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: clinic.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 80,
                            height: 80,
                            color: accent.withValues(alpha: 0.1),
                            child: const Icon(Icons.local_hospital_rounded, color: accent, size: 36),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: accent.withValues(alpha: 0.1),
                            child: const Icon(Icons.local_hospital_rounded, color: accent, size: 36),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: accent, size: 40),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.name,
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              clinic.specialty,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          if (clinic.doctorName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'د. ${clinic.doctorName}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // حالة التواجد والأجر
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            clinic.isDoctorOnDuty ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            color: clinic.isDoctorOnDuty ? Colors.green : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            clinic.scheduleStatusLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: clinic.isDoctorOnDuty ? Colors.green : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (clinic.fees > 0) ...[
                        const Divider(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.payments_rounded, color: Color(0xFFB8860B), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'أجر رمزي: ${clinic.fees.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      if (clinic.scheduleLabel.isNotEmpty) ...[
                        const Divider(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, color: accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                clinic.scheduleLabel,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (clinic.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'نبذة عن العيادة والخدمات',
                    style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clinic.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, AppRoutes.medical);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('الانتقال لقسم المركز الطبي الخيري'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPhoneContactSheet(BuildContext context, PhoneDirectoryEntry entry) {
    final theme = Theme.of(context);
    const accent = Color(0xFF0288D1);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: accent.withValues(alpha: 0.12),
                foregroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(entry.photoUrl!)
                    : null,
                child: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                    ? null
                    : Text(
                        entry.name.isNotEmpty ? entry.name[0] : '',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: accent),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                entry.name,
                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              if (entry.title.isNotEmpty || (entry.job != null && entry.job!.isNotEmpty)) ...[
                const SizedBox(height: 4),
                Text(
                  [entry.title, entry.job].where((s) => s != null && s.isNotEmpty).join(' · '),
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (entry.address != null && entry.address!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      entry.address!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // أزرار التواصل السريع
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        launchPhoneCall(entry.phone);
                      },
                      icon: const Icon(Icons.phone_rounded),
                      label: const Text('اتصال مباشر'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final wa = egyptianWhatsAppUrl(entry.phone);
                        if (wa != null) launchWhatsAppUrl(wa);
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('واتساب'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ رقم الهاتف')),
                  );
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text('نسخ الرقم (${entry.phone})'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDonationSheet(BuildContext context, Donation donation) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (donation.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: donation.imageUrl,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                donation.title,
                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'مقدم بواسطة: ${donation.userName} · تصنيف: ${donation.category}',
                style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
              ),
              if (donation.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  donation.description,
                  style: TextStyle(fontSize: 13, height: 1.5, color: theme.colorScheme.onSurface),
                ),
              ],
              const SizedBox(height: 20),
              if (donation.contactPhone.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => launchPhoneCall(donation.contactPhone),
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text('اتصال بصاحب التبرع'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () {
                        final wa = egyptianWhatsAppUrl(donation.contactPhone);
                        if (wa != null) launchWhatsAppUrl(wa);
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      style: IconButton.styleFrom(backgroundColor: Colors.teal),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBuyRequestSheet(BuildContext context, BuyRequest req) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (req.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: req.imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                req.title,
                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'طالب السلعة: ${req.userName}${req.budget.isNotEmpty ? ' · الميزانية: ${req.budget} ج.م' : ''}',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              if (req.details.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(req.details, style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
              const SizedBox(height: 20),
              if (req.contactPhone.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => launchPhoneCall(req.contactPhone),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('اتصال لتلبية الطلب'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBloodRequestSheet(BuildContext context, BloodRequest br) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFC2185B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bloodtype_rounded, size: 48, color: Color(0xFFC2185B)),
              ),
              const SizedBox(height: 14),
              Text(
                'طلب تبرع عاجل بفصيلة (${br.bloodType.label})',
                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'المستشفى: ${br.hospital} · أكياس مطلوبة: ${br.units}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => launchPhoneCall(br.phone),
                icon: const Icon(Icons.phone_rounded),
                label: const Text('اتصال عاجل للتبرع بالدم'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLegalConsultationSheet(BuildContext context, LegalConsultation lc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kLegalAdvisorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lc.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kLegalAdvisorColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (lc.hasAnswer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'تم الرد القانوني',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  lc.question,
                  style: GoogleFonts.tajawal(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                if (lc.details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(lc.details, style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
                if (lc.hasAnswer) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kLegalAdvisorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kLegalAdvisorColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gavel_rounded, color: kLegalAdvisorColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'الرد القانوني (${lc.answeredByName.isNotEmpty ? lc.answeredByName : 'مستشار القرية'})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kLegalAdvisorColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lc.answer,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
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
                  'ابحث بالاسم أو المهنة أو رقم الهاتف أو التخصص للوصول الفوري لكل خدمات القرية وسجلاتها الأصلية.',
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

  Widget _buildLeadingThumbnail(GlobalSearchResultItem item) {
    final hasImg = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: item.accentColor.withValues(alpha: 0.1),
            border: Border.all(
              color: item.accentColor.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImg
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!.trim(),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color: item.accentColor.withValues(alpha: 0.08),
                      child: Center(
                        child: Icon(item.icon, size: 24, color: item.accentColor.withValues(alpha: 0.6)),
                      ),
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: item.accentColor.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(item.icon, size: 24, color: item.accentColor),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(item.icon, size: 26, color: item.accentColor),
                  ),
          ),
        ),
        if (hasImg)
          PositionedDirectional(
            bottom: -3,
            end: -3,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: item.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(item.icon, size: 10, color: Colors.white),
            ),
          ),
      ],
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
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (item.onTapCustom != null) {
                item.onTapCustom!();
              } else if (item.route != null) {
                Navigator.pushNamed(context, item.route!, arguments: item.routeArgs);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _buildLeadingThumbnail(item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(7),
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
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (item.badgeLabel != null && item.badgeLabel!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.badgeLabel!,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.phone != null && item.phone!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                          tooltip: 'اتصال',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            launchPhoneCall(item.phone!);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.teal, size: 20),
                          tooltip: 'واتساب',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final wa = egyptianWhatsAppUrl(item.phone!);
                            if (wa != null) launchWhatsAppUrl(wa);
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
