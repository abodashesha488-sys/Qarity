import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/village_content_models.dart';
import '../../services/village_content_service.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_content_admin.dart';

const Color kVillageArchiveColor = Color(0xFF6A1B9A);

/// «أرشيف القرية» — شخصيات مؤرخة بأقواس أرشيفية + صور ووثائق تاريخية.
class VillageArchiveScreen extends StatefulWidget {
  const VillageArchiveScreen({super.key});

  @override
  State<VillageArchiveScreen> createState() => _VillageArchiveScreenState();
}

class _VillageArchiveScreenState extends State<VillageArchiveScreen> {
  final VillageContentService _service = VillageContentService();
  late final Stream<List<VillageFigure>> _figures = _service.watchFigures();
  late final Stream<List<VillageArchivePhoto>> _photos =
      _service.watchArchivePhotos();
  bool _isAdmin = false;
  String _category = '';

  @override
  void initState() {
    super.initState();
    _initAdmin();
  }

  Future<void> _initAdmin() async {
    final admin = await canManageVillageContent();
    if (!mounted) return;
    setState(() => _isAdmin = admin);
    if (admin) {
      unawaited(_service.migrateLegacyIfNeeded().catchError((_) => 0));
    }
  }

  Future<void> _manageFigures() => manageVillageContent<VillageFigure>(
        context,
        title: 'شخصيات القرية',
        accent: kVillageArchiveColor,
        stream: _figures,
        nameOf: (f) => f.name,
        subtitleOf: (f) => FigureCategory.label(f.category),
        remove: (id) => _service.deleteDoc('village_figures', id),
        formBuilder: (ctx, editing) => FigureForm(editing: editing),
      );

  Future<void> _managePhotos() => manageVillageContent<VillageArchivePhoto>(
        context,
        title: 'صور ووثائق الأرشيف',
        accent: kVillageArchiveColor,
        stream: _photos,
        nameOf: (p) => p.title,
        subtitleOf: (p) => p.year,
        remove: (id) => _service.deleteDoc('village_archive_photos', id),
        formBuilder: (ctx, editing) => ArchivePhotoForm(editing: editing),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'أرشيف القرية', color: kVillageArchiveColor),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'village_archive_manage',
              backgroundColor: kVillageArchiveColor,
              foregroundColor: Colors.white,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.portrait_rounded,
                            color: kVillageArchiveColor),
                        title: const Text('إدارة الشخصيات',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _manageFigures();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.photo_library_rounded,
                            color: kVillageArchiveColor),
                        title: const Text('إدارة الصور والوثائق',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _managePhotos();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('إدارة الأرشيف',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const VillageSectionHeader(
            accent: kVillageArchiveColor,
            title: 'أرشيف القرية',
            subtitle: 'وجوهٌ صنعت تاريخ أبوديشيشة، وصورٌ تحفظ ذاكرتها للأجيال',
            icon: Icons.architecture_rounded,
          ),
          const SizedBox(height: 14),
          // ── فلترات التصنيف ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _catChip('', 'الكل', Icons.apps_rounded),
                for (final c in FigureCategory.all)
                  _catChip(c, FigureCategory.label(c), FigureCategory.icon(c)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.portrait_rounded,
                    size: 18, color: kVillageArchiveColor),
                const SizedBox(width: 7),
                Text('شخصيات القرية',
                    style: VillageOrnament.amiri(
                        size: 19, color: kVillageArchiveColor)),
              ],
            ),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OrnamentDivider()),
          StreamBuilder<List<VillageFigure>>(
            stream: _figures,
            builder: (context, snap) {
              final all = snap.data ?? const <VillageFigure>[];
              final figures = _category.isEmpty
                  ? all
                  : all.where((f) => f.category == _category).toList();
              if (figures.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      snap.hasData ? 'لا توجد شخصيات في هذا التصنيف بعد' : '',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: figures.length,
                  itemBuilder: (context, i) =>
                      _FigureCard(figure: figures[i], index: i),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.photo_camera_back_rounded,
                    size: 18, color: kVillageArchiveColor),
                const SizedBox(width: 7),
                Text('صور تاريخية ووثائق',
                    style: VillageOrnament.amiri(
                        size: 19, color: kVillageArchiveColor)),
              ],
            ),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OrnamentDivider()),
          StreamBuilder<List<VillageArchivePhoto>>(
            stream: _photos,
            builder: (context, snap) {
              final photos = snap.data ?? const <VillageArchivePhoto>[];
              if (photos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      snap.hasData ? 'لا توجد صور مؤرشفة بعد' : '',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, i) =>
                      _ArchivePhotoCard(photo: photos[i], index: i),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _catChip(String value, String label, IconData icon) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _category = value),
        avatar: Icon(icon,
            size: 15, color: selected ? Colors.white : kVillageArchiveColor),
        label: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : null)),
        selectedColor: kVillageArchiveColor,
      ),
    );
  }
}

class _FigureCard extends StatelessWidget {
  const _FigureCard({required this.figure, required this.index});
  final VillageFigure figure;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = FigureCategory.color(figure.category);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: () => _showBio(context),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // الصورة كما رُفعت — بلا فلاتر أو قص
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 104,
                  color: color.withValues(alpha: 0.08),
                  child: figure.photoUrl.isEmpty
                      ? Icon(FigureCategory.icon(figure.category),
                          size: 42, color: color.withValues(alpha: 0.5))
                      : CachedNetworkImage(
                          imageUrl: figure.photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                              FigureCategory.icon(figure.category),
                              size: 42,
                              color: color.withValues(alpha: 0.5)),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(figure.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: VillageOrnament.amiri(size: 15)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7)),
              child: Text(
                  figure.title.isNotEmpty
                      ? figure.title
                      : FigureCategory.shortLabel(figure.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w900, color: color)),
            ),
            if (figure.era.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(figure.era,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 9.5,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            const Spacer(),
          ],
        ),
      ),
    )
        .animate(delay: (index * 45).ms)
        .fadeIn()
        .scale(begin: const Offset(0.94, 0.94), duration: 280.ms);
  }

  void _showBio(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final color = FigureCategory.color(figure.category);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 130,
                    height: 150,
                    color: color.withValues(alpha: 0.08),
                    child: figure.photoUrl.isEmpty
                        ? Icon(FigureCategory.icon(figure.category),
                            size: 56, color: color.withValues(alpha: 0.5))
                        : CachedNetworkImage(
                            imageUrl: figure.photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                                FigureCategory.icon(figure.category),
                                size: 56,
                                color: color.withValues(alpha: 0.5)),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(figure.name,
                    textAlign: TextAlign.center,
                    style: VillageOrnament.amiri(size: 21)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                      figure.title.isNotEmpty
                          ? figure.title
                          : FigureCategory.label(figure.category),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: color)),
                ),
                if (figure.era.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(figure.era,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54)),
                ],
                const SizedBox(height: 10),
                const OrnamentDivider(),
                const SizedBox(height: 10),
                if (figure.bio.isNotEmpty)
                  Text(figure.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, height: 1.9))
                else
                  Text(
                      'لم تُدوَّن سيرة هذه الشخصية بعد — '
                      'أرشيف القرية يرحّب بأي معلومة موثّقة عنها',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArchivePhotoCard extends StatelessWidget {
  const _ArchivePhotoCard({required this.photo, required this.index});
  final VillageArchivePhoto photo;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kVillageArchiveColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _showFull(context, theme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: kVillageArchiveColor.withValues(alpha: 0.06),
                child: photo.imageUrl.isEmpty
                    ? const Center(
                        child: Icon(Icons.photo_album_rounded,
                            size: 36, color: Color(0x55000000)))
                    : CachedNetworkImage(
                        imageUrl: photo.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: Colors.black26))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(photo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 12)),
                  if (photo.year.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 11, color: Colors.black45),
                        const SizedBox(width: 3),
                        Text(photo.year,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 45).ms).fadeIn();
  }

  void _showFull(BuildContext context, ThemeData theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (photo.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: CachedNetworkImage(
                      imageUrl: photo.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const SizedBox.shrink()),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(photo.title, style: VillageOrnament.amiri(size: 18)),
                    if (photo.year.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(photo.year,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: kVillageArchiveColor)),
                      ),
                    if (photo.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const OrnamentDivider(),
                      const SizedBox(height: 10),
                      Text(photo.description,
                          style: const TextStyle(fontSize: 13, height: 1.8)),
                    ],
                    if (photo.source.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('المصدر: ${photo.source}',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إغلاق')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
