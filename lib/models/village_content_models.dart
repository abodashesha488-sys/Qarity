import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils/firebase_ts.dart';

// ═══════════════ حقبة تاريخية (village_history) ═══════════════
class HistoryEra {
  final String id;
  final String title;
  final String years;
  final String narrative;
  final String imageUrl;
  final int sortOrder;
  final DateTime? createdAt;

  const HistoryEra({
    this.id = '',
    required this.title,
    this.years = '',
    this.narrative = '',
    this.imageUrl = '',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory HistoryEra.fromJson(Map<String, dynamic> j, String docId) =>
      HistoryEra(
        id: docId,
        title: j['title'] as String? ?? '',
        years: j['years'] as String? ?? '',
        narrative: j['narrative'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'years': years,
        'narrative': narrative,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  HistoryEra copyWith({String? id}) => HistoryEra(
        id: id ?? this.id,
        title: title,
        years: years,
        narrative: narrative,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

// ═══════════════ شخصيات القرية (village_figures) ═══════════════
class FigureCategory {
  FigureCategory._();
  static const mp = 'mp';
  static const mayor = 'mayor';
  static const elders = 'elders';
  static const influencers = 'influencers';

  static const List<String> all = [mayor, elders, mp, influencers];

  static String label(String c) => switch (c) {
        mp => 'أعضاء مجلس الشعب',
        mayor => 'عمدة القرية',
        elders => 'شيوخ القرية',
        influencers => 'أشخاص مؤثرون',
        _ => c,
      };

  static String shortLabel(String c) => switch (c) {
        mp => 'نائب برلماني',
        mayor => 'عمدة',
        elders => 'من مشايخ البلد',
        influencers => 'شخصية مؤثرة',
        _ => '',
      };

  static IconData icon(String c) => switch (c) {
        mp => Icons.how_to_vote_rounded,
        mayor => Icons.gavel_rounded,
        elders => Icons.workspace_premium_rounded,
        influencers => Icons.star_rounded,
        _ => Icons.person_rounded,
      };

  static Color color(String c) => switch (c) {
        mp => const Color(0xFF1565C0),
        mayor => const Color(0xFF6F4E37),
        elders => const Color(0xFF00695C),
        influencers => const Color(0xFFAD1457),
        _ => Colors.blueGrey,
      };
}

class VillageFigure {
  final String id;
  final String name;
  final String category;
  final String title;
  final String era;
  final String bio;
  final String photoUrl;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageFigure({
    this.id = '',
    required this.name,
    this.category = FigureCategory.influencers,
    this.title = '',
    this.era = '',
    this.bio = '',
    this.photoUrl = '',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageFigure.fromJson(Map<String, dynamic> j, String docId) =>
      VillageFigure(
        id: docId,
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? FigureCategory.influencers,
        title: j['title'] as String? ?? '',
        era: j['era'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        photoUrl: j['photoUrl'] as String? ?? '',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'title': title,
        'era': era,
        'bio': bio,
        'photoUrl': photoUrl,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageFigure copyWith({String? id}) => VillageFigure(
        id: id ?? this.id,
        name: name,
        category: category,
        title: title,
        era: era,
        bio: bio,
        photoUrl: photoUrl,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

// ═══════════════ صور ووثائق الأرشيف (village_archive_photos) ═══════════════
class VillageArchivePhoto {
  final String id;
  final String title;
  final String year;
  final String description;
  final String source;
  final String imageUrl;
  final DateTime? createdAt;

  const VillageArchivePhoto({
    this.id = '',
    required this.title,
    this.year = '',
    this.description = '',
    this.source = '',
    this.imageUrl = '',
    this.createdAt,
  });

  factory VillageArchivePhoto.fromJson(
          Map<String, dynamic> j, String docId) =>
      VillageArchivePhoto(
        id: docId,
        title: j['title'] as String? ?? '',
        year: j['year'] as String? ?? '',
        description: j['description'] as String? ?? '',
        source: j['source'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'year': year,
        'description': description,
        'source': source,
        'imageUrl': imageUrl,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageArchivePhoto copyWith({String? id}) => VillageArchivePhoto(
        id: id ?? this.id,
        title: title,
        year: year,
        description: description,
        source: source,
        imageUrl: imageUrl,
        createdAt: createdAt,
      );
}

// ═══════════════ منشآت القرية (village_institutions) ═══════════════
class InstitutionType {
  InstitutionType._();
  static const schools = 'schools';
  static const azhar = 'azhar';
  static const agri = 'agri';
  static const post = 'post';
  static const health = 'health';
  static const mosque = 'mosque';
  static const other = 'other';

  static const List<String> ordered = [
    schools, azhar, agri, post, health, mosque, other
  ];

  static String label(String t) => switch (t) {
        schools => 'مدارس',
        azhar => 'معاهد أزهرية',
        agri => 'الجمعية الزراعية',
        post => 'مكتب البريد',
        health => 'الوحدة الصحية',
        mosque => 'مساجد القرية',
        _ => 'منشآت أخرى',
      };

  static IconData icon(String t) => switch (t) {
        schools => Icons.school_rounded,
        azhar => Icons.menu_book_rounded,
        agri => Icons.agriculture_rounded,
        post => Icons.local_post_office_rounded,
        health => Icons.local_hospital_rounded,
        mosque => Icons.mosque_rounded,
        _ => Icons.account_balance_rounded,
      };

  static Color color(String t) => switch (t) {
        schools => const Color(0xFF1565C0),
        azhar => const Color(0xFF00695C),
        agri => const Color(0xFFEF6C00),
        post => const Color(0xFF6A1B9A),
        health => const Color(0xFFC62828),
        mosque => const Color(0xFF00897B),
        _ => Colors.blueGrey,
      };

  static String guessFromName(String name) {
    if (name.contains('مدرسة') || name.contains('تعليم')) return schools;
    if (name.contains('أزهر') || name.contains('معهد')) return azhar;
    if (name.contains('زراع')) return agri;
    if (name.contains('بريد')) return post;
    if (name.contains('صحة') || name.contains('وحدة')) return health;
    if (name.contains('مسجد') || name.contains('جامع')) return mosque;
    return other;
  }
}

class VillageInstitution {
  final String id;
  final String name;
  final String type;
  final String description;
  final String location;
  final String phone;
  final String workingHours;
  final List<String> imageUrls;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageInstitution({
    this.id = '',
    required this.name,
    this.type = InstitutionType.other,
    this.description = '',
    this.location = '',
    this.phone = '',
    this.workingHours = '',
    this.imageUrls = const [],
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageInstitution.fromJson(
          Map<String, dynamic> j, String docId) =>
      VillageInstitution(
        id: docId,
        name: j['name'] as String? ?? '',
        type: j['type'] as String? ?? InstitutionType.other,
        description: j['description'] as String? ?? '',
        location: j['location'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        workingHours: j['workingHours'] as String? ?? '',
        imageUrls:
            (j['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'description': description,
        'location': location,
        'phone': phone,
        'workingHours': workingHours,
        'imageUrls': imageUrls,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageInstitution copyWith({String? id}) => VillageInstitution(
        id: id ?? this.id,
        name: name,
        type: type,
        description: description,
        location: location,
        phone: phone,
        workingHours: workingHours,
        imageUrls: imageUrls,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}
