import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/contact_links.dart';
import '../../core/utils/launch_link.dart';
import '../../models/data_models.dart';
import '../../models/medical_models.dart';
import '../../models/service_provider_model.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/medical_service.dart';
import '../../services/service_provider_service.dart';

enum SearchCategoryFilter {
  all('الكل', Icons.search_rounded),
  phone('دليل الهاتف', Icons.contact_page_rounded),
  medical('الصحة والأطباء', Icons.medical_services_rounded),
  services('دليل الحرفيين', Icons.handyman_rounded),
  agricultural('خدمات زراعية وعمال', Icons.agriculture_rounded),
  market('سوق القرية', Icons.storefront_rounded),
  news('الأخبار', Icons.newspaper_rounded);

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

  // قواعد البيانات المجمعة
  List<PhoneDirectoryEntry> _phoneEntries = [];
  List<ServiceProvider> _serviceProviders = [];
  List<MedicalCenterClinic> _centerClinics = [];
  List<VillageClinic> _villageClinics = [];
  List<Pharmacy> _pharmacies = [];
  List<MarketProduct> _products = [];
  List<NewsItem> _news = [];

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
    try {
      final phoneJson = await CacheService.getPhoneDirectory();
      final productsJson = await CacheService.getProducts();
      final newsJson = await CacheService.getNews();

      if (phoneJson != null) {
        _phoneEntries = phoneJson
            .map((j) => PhoneDirectoryEntry.fromJson(j, j['id'] ?? ''))
            .toList();
      }
      if (productsJson != null) {
        _products = productsJson
            .map((j) => MarketProduct.fromJson(j, j['id'] ?? ''))
            .toList();
      }
      if (newsJson != null) {
        _news =
            newsJson.map((j) => NewsItem.fromJson(j, j['id'] ?? '')).toList();
      }

      // الأطباء والخدمات الطبية
      try {
        _centerClinics =
            await MedicalCenterService().getClinicsStream().first;
        _villageClinics =
            await VillageClinicService().getApprovedStream().first;
        _pharmacies = await PharmacyService().getApprovedStream().first;
      } catch (_) {}

      // الحرفيون والخدمات
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
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
      _performSearch(_searchCtrl.text);
    }
  }

  void _performSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final list = <GlobalSearchResultItem>[];

    // 1. دليل الهاتف
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.phone) {
      for (final e in _phoneEntries) {
        final j = e.job ?? '';
        final a = e.address ?? '';
        if (e.name.toLowerCase().contains(q) ||
            e.title.toLowerCase().contains(q) ||
            j.toLowerCase().contains(q) ||
            a.toLowerCase().contains(q) ||
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
    }

    // 2. الخدمات الطبية
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.medical) {
      for (final c in _centerClinics) {
        if (c.name.toLowerCase().contains(q) ||
            c.specialty.toLowerCase().contains(q) ||
            c.doctorName.toLowerCase().contains(q)) {
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
        if (vc.name.toLowerCase().contains(q) ||
            vc.specialty.toLowerCase().contains(q) ||
            vc.ownerName.toLowerCase().contains(q) ||
            vc.address.toLowerCase().contains(q)) {
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
        if (p.name.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q) ||
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
    }

    // 3. الحرفيون والفنيون
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.services) {
      for (final s in _serviceProviders.where((p) =>
          p.category == ServiceCategory.technicians ||
          p.category == ServiceCategory.educational)) {
        if (s.name.toLowerCase().contains(q) ||
            s.specialty.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q)) {
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
        if (s.name.toLowerCase().contains(q) ||
            s.specialty.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            (q.contains('عمال') ||
                q.contains('معدات') ||
                q.contains('تجهيز') ||
                q.contains('زراع'))) {
          list.add(GlobalSearchResultItem(
            title: s.name,
            subtitle:
                '${s.displaySpecialty}${s.address.isNotEmpty ? ' · ${s.address}' : ''}${s.phone.isNotEmpty ? ' · ${s.phone}' : ''}',
            category: 'خدمات زراعية · عمال ومعدات',
            icon: Icons.agriculture_rounded,
            accentColor: const Color(0xFFAD1457),
            phone: s.phone,
            route: AppRoutes.serviceProviderDetail,
            routeArgs: s,
          ));
        }
      }
    }

    // 4. سوق القرية
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.market) {
      for (final p in _products) {
        if (p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.sellerName.toLowerCase().contains(q)) {
          list.add(GlobalSearchResultItem(
            title: p.name,
            subtitle: '${p.price} ج.م · ${p.category}',
            category: 'سوق القرية',
            icon: Icons.storefront_rounded,
            accentColor: const Color(0xFF6A1B9A),
            phone: p.sellerPhone,
            route: AppRoutes.marketProductDetail,
            routeArgs: p,
          ));
        }
      }
    }

    // 5. الأخبار
    if (_selectedFilter == SearchCategoryFilter.all ||
        _selectedFilter == SearchCategoryFilter.news) {
      for (final n in _news) {
        if (n.title.toLowerCase().contains(q) ||
            n.subtitle.toLowerCase().contains(q) ||
            n.category.toLowerCase().contains(q)) {
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
