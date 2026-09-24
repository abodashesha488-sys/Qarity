import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kArchiveColor = Color(0xFF6A1B9A);

/// «الأرشيف الرقمي» — مكتبة موحّدة لمواد المرجع (صور، وثائق، فيديو، صوت،
/// صحف، خرائط) مع بحث وشرائح فلترة وعرض تفصيلي لكل مادة.
class VillageDigitalArchiveScreen extends StatefulWidget {
  const VillageDigitalArchiveScreen({super.key});

  @override
  State<VillageDigitalArchiveScreen> createState() =>
      _VillageDigitalArchiveScreenState();
}

class _VillageDigitalArchiveScreenState
    extends State<VillageDigitalArchiveScreen> {
  static final VillageExtendedService _service = VillageExtendedService();
  String _category = '';

  Stream<List<VillageArchiveItem>> _stream() =>
      _service.watchApprovedArchiveItems().map((items) => _category.isEmpty
          ? items
          : items.where((i) => i.category == _category).toList());

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageArchiveItem>(
      title: 'الأرشيف الرقمي',
      subtitle: 'ذاكرة أبودشيشة محفوظة: صور ووثائق وفيديو وصوت',
      accent: kArchiveColor,
      icon: Icons.archive_rounded,
      stream: _stream(),
      emptyText: 'الأرشيف فارغ — أضف أول عنصر من زر الإدارة ＋',
      searchHint: 'ابحث في الأرشيف…',
      searchText: (i) =>
          '${i.title} ${i.description} ${i.contributor} ${i.location} ${i.people} ${i.period}',
      nameOf: (i) => i.title,
      subtitleOf: (i) => ArchiveItemCategory.label(i.category),
      remove: (id) => _service.deleteArchiveItem(id),
      formBuilder: (ctx, editing) => ArchiveItemForm(editing: editing),
      topBuilder: (_) => SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _catChip('', Icons.apps_rounded, 'الكل'),
            for (final c in ArchiveItemCategory.all)
              _catChip(
                  c, ArchiveItemCategory.icon(c), ArchiveItemCategory.label(c)),
          ],
        ),
      ),
      cardBuilder: (ctx, item, i) => _ArchiveTile(item: item, index: i),
    );
  }

  Widget _catChip(String value, IconData icon, String label) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _category = value),
        avatar: Icon(icon,
            size: 15, color: selected ? Colors.white : kArchiveColor),
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
      ),
    );
  }
}

/// بطاقة مادة أرشيف واحدة — صورة + شارة الفئة + بيانات مختصرة.
/// النقر يفتح ورقة التفاصيل الكاملة (روابط المستند/الفيديو/الصوت).
class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({required this.item, required this.index});

  final VillageArchiveItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = ArchiveItemCategory.color(item.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ArchiveDetails(item: item),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(16)),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _catBox(color),
                    )
                  : _catBox(color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(ArchiveItemCategory.label(item.category),
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ),
                    const SizedBox(height: 5),
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    if (item.year.isNotEmpty || item.location.isNotEmpty)
                      Text('${item.year} · ${item.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    if (item.contributor.isNotEmpty)
                      Text('المساهم: ${item.contributor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (40 * index).ms);
  }

  Widget _catBox(Color color) => Container(
        width: 96,
        height: 96,
        color: color.withValues(alpha: 0.12),
        child: Icon(ArchiveItemCategory.icon(item.category),
            size: 32, color: color),
      );
}

/// ورقة التفاصيل الكاملة للمادة (الوصف + أزرار الوسائط + بيانات التوثيق).
class _ArchiveDetails extends StatelessWidget {
  const _ArchiveDetails({required this.item});

  final VillageArchiveItem item;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ArchiveItemCategory.color(item.category);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(ArchiveItemCategory.label(item.category),
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
            const SizedBox(height: 8),
            Text(item.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(item.description,
                  style: const TextStyle(fontSize: 12.5, height: 1.9)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.year.isNotEmpty)
                  _detailBadge(Icons.event_rounded, item.year),
                if (item.period.isNotEmpty)
                  _detailBadge(Icons.history_rounded, item.period),
                if (item.location.isNotEmpty)
                  _detailBadge(Icons.location_on_rounded, item.location),
                if (item.people.isNotEmpty)
                  _detailBadge(Icons.groups_rounded, item.people),
                if (item.contributor.isNotEmpty)
                  _detailBadge(
                      Icons.volunteer_activism_rounded, item.contributor),
                if (item.source.isNotEmpty)
                  _detailBadge(Icons.source_rounded, item.source),
              ],
            ),
            if (item.documentUrl.isNotEmpty ||
                item.videoUrl.isNotEmpty ||
                item.audioUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (item.documentUrl.isNotEmpty)
                _mediaButton(
                    Icons.description_rounded, 'فتح الوثيقة', item.documentUrl),
              if (item.videoUrl.isNotEmpty)
                _mediaButton(
                    Icons.play_circle_rounded, 'مشاهدة الفيديو', item.videoUrl),
              if (item.audioUrl.isNotEmpty)
                _mediaButton(Icons.graphic_eq_rounded, 'تشغيل التسجيل الصوتي',
                    item.audioUrl),
            ],
            const SizedBox(height: 6),
            Text('كل مادة في الأرشيف موثّقة المصدر والمساهم.',
                style: TextStyle(
                    fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _detailBadge(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0x0F000000),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: kArchiveColor),
            const SizedBox(width: 5),
            Flexible(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w700))),
          ],
        ),
      );

  Widget _mediaButton(IconData icon, String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _open(url),
          style: FilledButton.styleFrom(backgroundColor: kArchiveColor),
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 12.5)),
        ),
      ),
    );
  }
}
