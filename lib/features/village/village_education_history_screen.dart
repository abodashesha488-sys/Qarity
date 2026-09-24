import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/village_extended_service.dart';
import 'village_extended_admin.dart';
import 'village_section_scaffold.dart';

const Color kEducationColor = Color(0xFF1565C0);

/// «تاريخ التعليم» — سجلّات التعليم (المدارس القديمة والحديثة،
/// المعلمون، الشخصيات التعليمية، ذكريات الطلاب).
class VillageEducationHistoryScreen extends StatelessWidget {
  const VillageEducationHistoryScreen({super.key});

  static final VillageExtendedService _service = VillageExtendedService();

  @override
  Widget build(BuildContext context) {
    return VillageSectionScaffold<VillageEducationHistory>(
      title: 'تاريخ التعليم',
      subtitle: 'رحلة التعليم في أبودشيشة: مدارس ومعلمون وذكريات',
      accent: kEducationColor,
      icon: Icons.school_rounded,
      stream: _service.watchEducationHistory(),
      searchText: (e) =>
          '${e.historyOfEducation} ${e.oldSchools.join(' ')} ${e.formerTeachers.join(' ')}',
      nameOf: (e) => e.historyOfEducation.isNotEmpty
          ? e.historyOfEducation.split('\n').first.trim()
          : 'سجل تعليمي',
      remove: (id) => _service.deleteEducationHistory(id),
      formBuilder: (ctx, editing) => EducationHistoryForm(editing: editing),
      cardBuilder: (ctx, e, i) => VillageInfoCard(
        accent: kEducationColor,
        title: e.historyOfEducation.isNotEmpty
            ? e.historyOfEducation
            : 'تاريخ التعليم في القرية',
        index: i,
        body: [
          if (e.oldSchools.isNotEmpty)
            'المدارس القديمة: ${e.oldSchools.join('، ')}',
          if (e.currentSchools.isNotEmpty)
            'المدارس الحالية: ${e.currentSchools.join('، ')}',
          if (e.formerTeachers.isNotEmpty)
            'معلمون سابقون: ${e.formerTeachers.join('، ')}',
          if (e.educationalFigures.isNotEmpty)
            'شخصيات تعليمية: ${e.educationalFigures.join('، ')}',
          if (e.studentMemories.isNotEmpty)
            'من ذكريات الطلاب: ${e.studentMemories.join(' — ')}',
          if (e.sources.isNotEmpty) 'المصادر: ${e.sources.join('، ')}',
        ],
      ),
    );
  }
}
