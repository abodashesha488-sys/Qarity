import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/medical_models.dart';
import '../../services/share_service.dart';

/// صف معلومة (أيقونة + عنوان + قيمة) — مشترك بين شاشات التفاصيل الطبية.
class MedInfoRow extends StatelessWidget {
  const MedInfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      this.accent = const Color(0xFF00897B)});
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة قسم بعنوان — مشتركة.
class MedSection extends StatelessWidget {
  const MedSection(
      {super.key,
      required this.title,
      required this.accent,
      required this.child});
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// رأس متدرج/صورة مشترك لشاشات التفاصيل.
class MedDetailHeader extends StatelessWidget {
  const MedDetailHeader({
    super.key,
    required this.title,
    required this.accent,
    required this.accentDark,
    required this.imageUrl,
    required this.icon,
    this.onShare,
  });
  final String title;
  final Color accent;
  final Color accentDark;
  final String imageUrl;
  final IconData icon;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: imageUrl.isNotEmpty ? 230 : 150,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        if (onShare != null)
          IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share_rounded),
              onPressed: onShare),
      ],
      flexibleSpace: imageUrl.isNotEmpty
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _gradientFallback(context)),
                ],
              ),
            )
          : FlexibleSpaceBar(background: _gradientFallback(context)),
    );
  }

  Widget _gradientFallback(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accentDark, accent])),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Icon(icon, size: 72, color: Colors.white.withValues(alpha: 0.55)),
          ),
        ),
      );
}

/// شاشة تفاصيل عيادة القرية — عرض احترافي كامل مع الاتصال والمشاركة.
class VillageClinicDetailScreen extends StatelessWidget {
  const VillageClinicDetailScreen({super.key});

  static const _teal = Color(0xFF00897B);
  static const _tealDark = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ModalRoute.of(context)!.settings.arguments as VillageClinic? ??
        const VillageClinic(id: '', name: '');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: clinic.name,
            accent: _teal,
            accentDark: _tealDark,
            imageUrl: clinic.imageUrl,
            icon: Icons.add_business_rounded,
            onShare: () => ShareService.shareText(
                title: '🏥 ${clinic.name}',
                body: [
                  if (clinic.specialty.isNotEmpty)
                    'التخصص: ${clinic.specialty}',
                  if (clinic.ownerName.isNotEmpty)
                    'الطبيب: ${clinic.ownerName}',
                  if (clinic.workingHours.isNotEmpty)
                    'المواعيد: ${clinic.workingHours}',
                  if (clinic.address.isNotEmpty) 'العنوان: ${clinic.address}',
                  if (clinic.phone.isNotEmpty) 'هاتف: ${clinic.phone}',
                ].join('\n')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(clinic.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900)),
                      ),
                      if (clinic.specialty.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _teal.withValues(alpha: 0.3))),
                          child: Text(clinic.specialty,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _teal)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MedSection(
                    title: 'بيانات العيادة',
                    accent: _teal,
                    child: Column(
                      children: [
                        if (clinic.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'الطبيب المسؤول',
                              value: clinic.ownerName),
                        if (clinic.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'هاتف العيادة',
                              value: clinic.phone),
                        if (clinic.workingHours.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'مواعيد العمل',
                              value: clinic.workingHours),
                        if (clinic.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: clinic.address),
                      ],
                    ),
                  ),
                  if (clinic.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن العيادة',
                      accent: _teal,
                      child: Text(clinic.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (clinic.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور العيادة',
                      accent: _teal,
                      child: SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: clinic.imageUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                                imageUrl: clinic.imageUrls[i],
                                width: 180,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                    width: 180,
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: const Icon(
                                        Icons.broken_image_rounded))),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (clinic.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: clinic.phone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالعيادة',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة تفاصيل صيدلية القرية.
class PharmacyDetailScreen extends StatelessWidget {
  const PharmacyDetailScreen({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pharmacy = ModalRoute.of(context)!.settings.arguments as Pharmacy? ??
        const Pharmacy(id: '', name: '');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          MedDetailHeader(
            title: pharmacy.name,
            accent: _green,
            accentDark: _greenDark,
            imageUrl: pharmacy.imageUrl,
            icon: Icons.local_pharmacy_rounded,
            onShare: () => ShareService.shareText(
                title: '💊 ${pharmacy.name}',
                body: [
                  if (pharmacy.ownerName.isNotEmpty)
                    'المسؤول: ${pharmacy.ownerName}',
                  pharmacy.is24Hours
                      ? 'تعمل على مدار ٢٤ ساعة'
                      : (pharmacy.workingHours.isNotEmpty
                          ? 'المواعيد: ${pharmacy.workingHours}'
                          : ''),
                  if (pharmacy.address.isNotEmpty)
                    'العنوان: ${pharmacy.address}',
                  if (pharmacy.phone.isNotEmpty) 'هاتف: ${pharmacy.phone}',
                ].where((e) => e.isNotEmpty).join('\n')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(pharmacy.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900)),
                      ),
                      if (pharmacy.is24Hours)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _green.withValues(alpha: 0.3))),
                          child: const Text('٢٤ ساعة',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _green)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MedSection(
                    title: 'بيانات الصيدلية',
                    accent: _green,
                    child: Column(
                      children: [
                        if (pharmacy.ownerName.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.person_rounded,
                              label: 'الصيدلي المسؤول',
                              value: pharmacy.ownerName,
                              accent: _green),
                        if (pharmacy.phone.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.phone_rounded,
                              label: 'الهاتف',
                              value: pharmacy.phone,
                              accent: _green),
                        if (pharmacy.workingHours.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'مواعيد العمل',
                              value: pharmacy.workingHours,
                              accent: _green),
                        if (pharmacy.address.isNotEmpty)
                          MedInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'العنوان',
                              value: pharmacy.address,
                              accent: _green),
                      ],
                    ),
                  ),
                  if (pharmacy.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'عن الصيدلية',
                      accent: _green,
                      child: Text(pharmacy.description,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],
                  if (pharmacy.imageUrls.length > 1) ...[
                    const SizedBox(height: 16),
                    MedSection(
                      title: 'صور الصيدلية',
                      accent: _green,
                      child: SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pharmacy.imageUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                                imageUrl: pharmacy.imageUrls[i],
                                width: 180,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                    width: 180,
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: const Icon(
                                        Icons.broken_image_rounded))),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (pharmacy.phone.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: pharmacy.phone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('اتصال بالصيدلية',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
