import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kHeritageColor = Color(0xFF6A1B9A);

/// «تراث أبودشيشة» — العادات والأكلات والأمثال والحرف، مصنّفة بشرائح فلترة.
class VillageHeritageScreen extends StatefulWidget {
  const VillageHeritageScreen({super.key});

  @override
  State<VillageHeritageScreen> createState() => _VillageHeritageScreenState();
}

class _VillageHeritageScreenState extends State<VillageHeritageScreen> {
  static final VillageExtendedService _service = VillageExtendedService();
  String _category = '';

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageHeritage>(
      title: 'تراث أبودشيشة',
      subtitle: 'عادات وأكلات وأمثال وحرف من تراث القرية',
      accent: kHeritageColor,
      icon: Icons.diversity_3_rounded,
      stream: _heritageStream(),
      searchHint: 'ابحث في التراث…',
      searchText: (h) => '${h.title} ${h.description} ${h.contributor}',
      nameOf: (h) => h.title,
      subtitleOf: (h) => HeritageCategory.label(h.category),
      remove: (id) => _service.deleteHeritage(id),
      formBuilder: (ctx, editing) => HeritageForm(editing: editing),
      topBuilder: (_) => SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _catChip('', 'الكل'),
            for (final c in HeritageCategory.all) _catChip(c, null),
          ],
        ),
      ),
      cardBuilder: (ctx, h, i) => VillageInfoCard(
        accent: kHeritageColor,
        title: h.title,
        subtitle: HeritageCategory.label(h.category),
        imageUrl: h.images.isNotEmpty ? h.images.first : '',
        index: i,
        body: [
          if (h.description.isNotEmpty) h.description,
          if (h.historicalPeriod.isNotEmpty)
            'الفترة الزمنية: ${h.historicalPeriod}',
          if (h.contributor.isNotEmpty) 'الراوي/المساهم: ${h.contributor}',
          if (h.source.isNotEmpty) 'المصدر: ${h.source}',
        ],
      ),
    );
  }

  Stream<List<VillageHeritage>> _heritageStream() =>
      _service.watchHeritage().map((items) => _category.isEmpty
          ? items
          : items.where((h) => h.category == _category).toList());

  Widget _catChip(String value, String? unused) {
    final selected = _category == value;
    final label = value.isEmpty ? 'الكل' : HeritageCategory.label(value);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _category = value),
        avatar: value.isEmpty
            ? null
            : Icon(HeritageCategory.icon(value),
                size: 15, color: selected ? Colors.white : kHeritageColor),
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
      ),
    );
  }
}
