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

  factory VillageArchivePhoto.fromJson(Map<String, dynamic> j, String docId) =>
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

// ═══════════════ العائلات (village_families) ═══════════════
class FamilyCategory {
  FamilyCategory._();
  static const notable = 'notable';
  static const scholarly = 'scholarly';
  static const merchant = 'merchant';
  static const agricultural = 'agricultural';
  static const other = 'other';

  static const List<String> all = [
    notable,
    scholarly,
    merchant,
    agricultural,
    other
  ];

  static String label(String c) => switch (c) {
        notable => 'عائلات معروفة',
        scholarly => 'عائلات علمية/أكاديمية',
        merchant => 'عائلات تجارية',
        agricultural => 'عائلات زراعية',
        _ => 'أخرى',
      };

  static String shortLabel(String c) => switch (c) {
        notable => 'معروفة',
        scholarly => 'علمية',
        merchant => 'تجارية',
        agricultural => 'زراعية',
        _ => '',
      };

  static IconData icon(String c) => switch (c) {
        notable => Icons.family_restroom_rounded,
        scholarly => Icons.menu_book_rounded,
        merchant => Icons.store_rounded,
        agricultural => Icons.agriculture_rounded,
        _ => Icons.family_restroom_rounded,
      };

  static Color color(String c) => switch (c) {
        notable => const Color(0xFF6F4E37),
        scholarly => const Color(0xFF1565C0),
        merchant => const Color(0xFFEF6C00),
        agricultural => const Color(0xFF558B2F),
        _ => Colors.blueGrey,
      };
}

class VillageFamily {
  final String id;
  final String name;
  final String category;
  final String description;
  final String originHistory;
  final List<String> branches;
  final String residenceArea;
  final String historicalInfo;
  final List<String> sources;
  final List<String> imageUrls;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageFamily({
    this.id = '',
    required this.name,
    this.category = FamilyCategory.other,
    this.description = '',
    this.originHistory = '',
    this.branches = const [],
    this.residenceArea = '',
    this.historicalInfo = '',
    this.sources = const [],
    this.imageUrls = const [],
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageFamily.fromJson(Map<String, dynamic> j, String docId) =>
      VillageFamily(
        id: docId,
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? FamilyCategory.other,
        description: j['description'] as String? ?? '',
        originHistory: j['originHistory'] as String? ?? '',
        branches: (j['branches'] as List<dynamic>?)?.cast<String>() ?? const [],
        residenceArea: j['residenceArea'] as String? ?? '',
        historicalInfo: j['historicalInfo'] as String? ?? '',
        sources: (j['sources'] as List<dynamic>?)?.cast<String>() ?? const [],
        imageUrls:
            (j['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'originHistory': originHistory,
        'branches': branches,
        'residenceArea': residenceArea,
        'historicalInfo': historicalInfo,
        'sources': sources,
        'imageUrls': imageUrls,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageFamily copyWith({String? id}) => VillageFamily(
        id: id ?? this.id,
        name: name,
        category: category,
        description: description,
        originHistory: originHistory,
        branches: branches,
        residenceArea: residenceArea,
        historicalInfo: historicalInfo,
        sources: sources,
        imageUrls: imageUrls,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}

class VillageNotablePerson {
  final String id;
  final String fullName;
  final String photoUrl;
  final String field;
  final String biography;
  final List<String> achievements;
  final String relationshipToVillage;
  final List<String> images;
  final List<String> documents;
  final List<String> sources;
  final String approvalStatus;
  final String category;
  final DateTime? createdAt;

  const VillageNotablePerson({
    this.id = '',
    required this.fullName,
    this.photoUrl = '',
    required this.field,
    this.biography = '',
    this.achievements = const [],
    this.relationshipToVillage = '',
    this.images = const [],
    this.documents = const [],
    this.sources = const [],
    this.approvalStatus = 'pending',
    this.category = 'other',
    this.createdAt,
  });

  factory VillageNotablePerson.fromJson(Map<String, dynamic> j, String docId) =>
      VillageNotablePerson(
        id: docId,
        fullName: j['fullName'] as String? ?? '',
        photoUrl: j['photoUrl'] as String? ?? '',
        field: j['field'] as String? ?? '',
        biography: j['biography'] as String? ?? '',
        achievements:
            (j['achievements'] as List<dynamic>?)?.cast<String>() ?? const [],
        relationshipToVillage: j['relationshipToVillage'] as String? ?? '',
        images: (j['images'] as List<dynamic>?)?.cast<String>() ?? const [],
        documents:
            (j['documents'] as List<dynamic>?)?.cast<String>() ?? const [],
        sources: (j['sources'] as List<dynamic>?)?.cast<String>() ?? const [],
        approvalStatus: j['approvalStatus'] as String? ?? 'pending',
        category: j['category'] as String? ?? 'other',
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'photoUrl': photoUrl,
        'field': field,
        'biography': biography,
        'achievements': achievements,
        'relationshipToVillage': relationshipToVillage,
        'images': images,
        'documents': documents,
        'sources': sources,
        'approvalStatus': approvalStatus,
        'category': category,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageNotablePerson copyWith({String? id}) => VillageNotablePerson(
        id: id ?? this.id,
        fullName: fullName,
        photoUrl: photoUrl,
        field: field,
        biography: biography,
        achievements: achievements,
        relationshipToVillage: relationshipToVillage,
        images: images,
        documents: documents,
        sources: sources,
        approvalStatus: approvalStatus,
        category: category,
        createdAt: createdAt,
      );
}

class VillageMemorialPerson {
  final String id;
  final String fullName;
  final String photoUrl;
  final String field;
  final String biography;
  final String relationshipToVillage;
  final DateTime? dateOfDeath;
  final String causeOfDeath;
  final List<String> images;
  final List<String> documents;
  final List<String> sources;
  final String approvalStatus;
  final DateTime? createdAt;

  const VillageMemorialPerson({
    this.id = '',
    required this.fullName,
    this.photoUrl = '',
    required this.field,
    this.biography = '',
    this.relationshipToVillage = '',
    this.dateOfDeath,
    this.causeOfDeath = '',
    this.images = const [],
    this.documents = const [],
    this.sources = const [],
    this.approvalStatus = 'pending',
    this.createdAt,
  });

  factory VillageMemorialPerson.fromJson(
          Map<String, dynamic> j, String docId) =>
      VillageMemorialPerson(
        id: docId,
        fullName: j['fullName'] as String? ?? '',
        photoUrl: j['photoUrl'] as String? ?? '',
        field: j['field'] as String? ?? '',
        biography: j['biography'] as String? ?? '',
        relationshipToVillage: j['relationshipToVillage'] as String? ?? '',
        dateOfDeath: tsToDateTime(j['dateOfDeath']),
        causeOfDeath: j['causeOfDeath'] as String? ?? '',
        images: (j['images'] as List<dynamic>?)?.cast<String>() ?? const [],
        documents:
            (j['documents'] as List<dynamic>?)?.cast<String>() ?? const [],
        sources: (j['sources'] as List<dynamic>?)?.cast<String>() ?? const [],
        approvalStatus: j['approvalStatus'] as String? ?? 'pending',
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'photoUrl': photoUrl,
        'field': field,
        'biography': biography,
        'relationshipToVillage': relationshipToVillage,
        'dateOfDeath':
            dateOfDeath != null ? Timestamp.fromDate(dateOfDeath!) : null,
        'causeOfDeath': causeOfDeath,
        'images': images,
        'documents': documents,
        'sources': sources,
        'approvalStatus': approvalStatus,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageMemorialPerson copyWith({String? id}) => VillageMemorialPerson(
        id: id ?? this.id,
        fullName: fullName,
        photoUrl: photoUrl,
        field: field,
        biography: biography,
        relationshipToVillage: relationshipToVillage,
        dateOfDeath: dateOfDeath,
        causeOfDeath: causeOfDeath,
        images: images,
        documents: documents,
        sources: sources,
        approvalStatus: approvalStatus,
        createdAt: createdAt,
      );
}

class VillageHeritage {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> images;
  final String audioUrl;
  final String videoUrl;
  final String historicalPeriod;
  final String source;
  final String contributor;
  final String approvalStatus;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageHeritage({
    this.id = '',
    required this.title,
    required this.category,
    this.description = '',
    this.images = const [],
    this.audioUrl = '',
    this.videoUrl = '',
    this.historicalPeriod = '',
    this.source = '',
    this.contributor = '',
    this.approvalStatus = 'pending',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageHeritage.fromJson(Map<String, dynamic> j, String docId) =>
      VillageHeritage(
        id: docId,
        title: j['title'] as String? ?? '',
        category: j['category'] as String? ?? '',
        description: j['description'] as String? ?? '',
        images: (j['images'] as List<dynamic>?)?.cast<String>() ?? const [],
        audioUrl: j['audioUrl'] as String? ?? '',
        videoUrl: j['videoUrl'] as String? ?? '',
        historicalPeriod: j['historicalPeriod'] as String? ?? '',
        source: j['source'] as String? ?? '',
        contributor: j['contributor'] as String? ?? '',
        approvalStatus: j['approvalStatus'] as String? ?? 'pending',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'description': description,
        'images': images,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'historicalPeriod': historicalPeriod,
        'source': source,
        'contributor': contributor,
        'approvalStatus': approvalStatus,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageHeritage copyWith({String? id}) => VillageHeritage(
        id: id ?? this.id,
        title: title,
        category: category,
        description: description,
        images: images,
        audioUrl: audioUrl,
        videoUrl: videoUrl,
        historicalPeriod: historicalPeriod,
        source: source,
        contributor: contributor,
        approvalStatus: approvalStatus,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class VillageLandmark {
  final String id;
  final String name;
  final String category;
  final String description;
  final String location;
  final String historicalInfo;
  final String story;
  final List<String> historicalImages;
  final List<String> currentImages;
  final String mapLocation;
  final List<String> relatedPeople;
  final List<String> relatedEvents;
  final List<String> sources;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageLandmark({
    this.id = '',
    required this.name,
    required this.category,
    this.description = '',
    this.location = '',
    this.historicalInfo = '',
    this.story = '',
    this.historicalImages = const [],
    this.currentImages = const [],
    this.mapLocation = '',
    this.relatedPeople = const [],
    this.relatedEvents = const [],
    this.sources = const [],
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageLandmark.fromJson(Map<String, dynamic> j, String docId) =>
      VillageLandmark(
        id: docId,
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? '',
        description: j['description'] as String? ?? '',
        location: j['location'] as String? ?? '',
        historicalInfo: j['historicalInfo'] as String? ?? '',
        story: j['story'] as String? ?? '',
        historicalImages:
            (j['historicalImages'] as List<dynamic>?)?.cast<String>() ??
                const [],
        currentImages:
            (j['currentImages'] as List<dynamic>?)?.cast<String>() ?? const [],
        mapLocation: j['mapLocation'] as String? ?? '',
        relatedPeople:
            (j['relatedPeople'] as List<dynamic>?)?.cast<String>() ?? const [],
        relatedEvents:
            (j['relatedEvents'] as List<dynamic>?)?.cast<String>() ?? const [],
        sources: (j['sources'] as List<dynamic>?)?.cast<String>() ?? const [],
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'location': location,
        'historicalInfo': historicalInfo,
        'story': story,
        'historicalImages': historicalImages,
        'currentImages': currentImages,
        'mapLocation': mapLocation,
        'relatedPeople': relatedPeople,
        'relatedEvents': relatedEvents,
        'sources': sources,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageLandmark copyWith({String? id}) => VillageLandmark(
        id: id ?? this.id,
        name: name,
        category: category,
        description: description,
        location: location,
        historicalInfo: historicalInfo,
        story: story,
        historicalImages: historicalImages,
        currentImages: currentImages,
        mapLocation: mapLocation,
        relatedPeople: relatedPeople,
        relatedEvents: relatedEvents,
        sources: sources,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class VillageBeforeAfter {
  final String id;
  final String historicalImage;
  final String currentImage;
  final String location;
  final String historicalDate;
  final String currentDate;
  final String description;
  final String source;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageBeforeAfter({
    this.id = '',
    required this.historicalImage,
    required this.currentImage,
    this.location = '',
    this.historicalDate = '',
    this.currentDate = '',
    this.description = '',
    this.source = '',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageBeforeAfter.fromJson(Map<String, dynamic> j, String docId) =>
      VillageBeforeAfter(
        id: docId,
        historicalImage: j['historicalImage'] as String? ?? '',
        currentImage: j['currentImage'] as String? ?? '',
        location: j['location'] as String? ?? '',
        historicalDate: j['historicalDate'] as String? ?? '',
        currentDate: j['currentDate'] as String? ?? '',
        description: j['description'] as String? ?? '',
        source: j['source'] as String? ?? '',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'historicalImage': historicalImage,
        'currentImage': currentImage,
        'location': location,
        'historicalDate': historicalDate,
        'currentDate': currentDate,
        'description': description,
        'source': source,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageBeforeAfter copyWith({String? id}) => VillageBeforeAfter(
        id: id ?? this.id,
        historicalImage: historicalImage,
        currentImage: currentImage,
        location: location,
        historicalDate: historicalDate,
        currentDate: currentDate,
        description: description,
        source: source,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class VillageAgricultureHistory {
  final String id;
  final String crop;
  final String agriculturalArea;
  final String traditionalFarming;
  final String historicalTools;
  final String farmerStory;
  final String changesOverTime;
  final List<String> images;
  final List<String> sources;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageAgricultureHistory({
    this.id = '',
    required this.crop,
    this.agriculturalArea = '',
    this.traditionalFarming = '',
    this.historicalTools = '',
    this.farmerStory = '',
    this.changesOverTime = '',
    this.images = const [],
    this.sources = const [],
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageAgricultureHistory.fromJson(
          Map<String, dynamic> j, String docId) =>
      VillageAgricultureHistory(
        id: docId,
        crop: j['crop'] as String? ?? '',
        agriculturalArea: j['agriculturalArea'] as String? ?? '',
        traditionalFarming: j['traditionalFarming'] as String? ?? '',
        historicalTools: j['historicalTools'] as String? ?? '',
        farmerStory: j['farmerStory'] as String? ?? '',
        changesOverTime: j['changesOverTime'] as String? ?? '',
        images: (j['images'] as List<dynamic>?)?.cast<String>() ?? const [],
        sources: (j['sources'] as List<dynamic>?)?.cast<String>() ?? const [],
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'crop': crop,
        'agriculturalArea': agriculturalArea,
        'traditionalFarming': traditionalFarming,
        'historicalTools': historicalTools,
        'farmerStory': farmerStory,
        'changesOverTime': changesOverTime,
        'images': images,
        'sources': sources,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageAgricultureHistory copyWith({String? id}) => VillageAgricultureHistory(
        id: id ?? this.id,
        crop: crop,
        agriculturalArea: agriculturalArea,
        traditionalFarming: traditionalFarming,
        historicalTools: historicalTools,
        farmerStory: farmerStory,
        changesOverTime: changesOverTime,
        images: images,
        sources: sources,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class VillageEducationHistory {
  final String id;
  final String historyOfEducation;
  final List<String> oldSchools;
  final List<String> currentSchools;
  final List<String> formerTeachers;
  final List<String> educationalFigures;
  final List<String> historicalPhotos;
  final List<String> studentMemories;
  final List<String> sources;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageEducationHistory({
    this.id = '',
    this.historyOfEducation = '',
    this.oldSchools = const [],
    this.currentSchools = const [],
    this.formerTeachers = const [],
    this.educationalFigures = const [],
    this.historicalPhotos = const [],
    this.studentMemories = const [],
    this.sources = const [],
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageEducationHistory.fromJson(
          Map<String, dynamic> j, String docId) =>
      VillageEducationHistory(
        id: docId,
        historyOfEducation: j['historyOfEducation'] as String? ?? '',
        oldSchools:
            (j['oldSchools'] as List<dynamic>?)?.cast<String>() ?? const [],
        currentSchools:
            (j['currentSchools'] as List<dynamic>?)?.cast<String>() ?? const [],
        formerTeachers:
            (j['formerTeachers'] as List<dynamic>?)?.cast<String>() ?? const [],
        educationalFigures:
            (j['educationalFigures'] as List<dynamic>?)?.cast<String>() ??
                const [],
        historicalPhotos:
            (j['historicalPhotos'] as List<dynamic>?)?.cast<String>() ??
                const [],
        studentMemories:
            (j['studentMemories'] as List<dynamic>?)?.cast<String>() ??
                const [],
        sources: (j['sources'] as List<dynamic>?)?.cast<String>() ?? const [],
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'historyOfEducation': historyOfEducation,
        'oldSchools': oldSchools,
        'currentSchools': currentSchools,
        'formerTeachers': formerTeachers,
        'educationalFigures': educationalFigures,
        'historicalPhotos': historicalPhotos,
        'studentMemories': studentMemories,
        'sources': sources,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageEducationHistory copyWith({String? id}) => VillageEducationHistory(
        id: id ?? this.id,
        historyOfEducation: historyOfEducation,
        oldSchools: oldSchools,
        currentSchools: currentSchools,
        formerTeachers: formerTeachers,
        educationalFigures: educationalFigures,
        historicalPhotos: historicalPhotos,
        studentMemories: studentMemories,
        sources: sources,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class VillageDevelopmentTimeline {
  final String id;
  final String date;
  final String title;
  final String description;
  final String beforeImage;
  final String afterImage;
  final String relatedProject;
  final String source;
  final String approvalStatus;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageDevelopmentTimeline({
    this.id = '',
    required this.date,
    required this.title,
    this.description = '',
    this.beforeImage = '',
    this.afterImage = '',
    this.relatedProject = '',
    this.source = '',
    this.approvalStatus = 'pending',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageDevelopmentTimeline.fromJson(
          Map<String, dynamic> j, String docId) =>
      VillageDevelopmentTimeline(
        id: docId,
        date: j['date'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        beforeImage: j['beforeImage'] as String? ?? '',
        afterImage: j['afterImage'] as String? ?? '',
        relatedProject: j['relatedProject'] as String? ?? '',
        source: j['source'] as String? ?? '',
        approvalStatus: j['approvalStatus'] as String? ?? 'pending',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'title': title,
        'description': description,
        'beforeImage': beforeImage,
        'afterImage': afterImage,
        'relatedProject': relatedProject,
        'source': source,
        'approvalStatus': approvalStatus,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageDevelopmentTimeline copyWith({String? id}) =>
      VillageDevelopmentTimeline(
        id: id ?? this.id,
        date: date,
        title: title,
        description: description,
        beforeImage: beforeImage,
        afterImage: afterImage,
        relatedProject: relatedProject,
        source: source,
        approvalStatus: approvalStatus,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class VillageAchievement {
  final String id;
  final String date;
  final String title;
  final String description;
  final String image;
  final List<String> relatedPeople;
  final String source;
  final String approvalStatus;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageAchievement({
    this.id = '',
    required this.date,
    required this.title,
    this.description = '',
    this.image = '',
    this.relatedPeople = const [],
    this.source = '',
    this.approvalStatus = 'pending',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageAchievement.fromJson(Map<String, dynamic> j, String docId) =>
      VillageAchievement(
        id: docId,
        date: j['date'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        image: j['image'] as String? ?? '',
        relatedPeople:
            (j['relatedPeople'] as List<dynamic>?)?.cast<String>() ?? const [],
        source: j['source'] as String? ?? '',
        approvalStatus: j['approvalStatus'] as String? ?? 'pending',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'title': title,
        'description': description,
        'image': image,
        'relatedPeople': relatedPeople,
        'source': source,
        'approvalStatus': approvalStatus,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageAchievement copyWith({String? id}) => VillageAchievement(
        id: id ?? this.id,
        date: date,
        title: title,
        description: description,
        image: image,
        relatedPeople: relatedPeople,
        source: source,
        approvalStatus: approvalStatus,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class VillageArchiveItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final String imageUrl;
  final String documentUrl;
  final String videoUrl;
  final String audioUrl;
  final String year;
  final String source;

  /// راوي الحكاية / المساهم بالمادة.
  final String contributor;

  /// موقع الحدث أو مكان التقاط الصورة.
  final String location;

  /// أشخاص مذكورون في المادة.
  final String people;

  /// الفترة الزمنية (مثل: «الخمسينات»، «قبل 1960»).
  final String period;
  final String approvalStatus;
  final int sortOrder;
  final DateTime? createdAt;

  const VillageArchiveItem({
    this.id = '',
    required this.category,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.documentUrl = '',
    this.videoUrl = '',
    this.audioUrl = '',
    this.year = '',
    this.source = '',
    this.contributor = '',
    this.location = '',
    this.people = '',
    this.period = '',
    this.approvalStatus = 'pending',
    this.sortOrder = 0,
    this.createdAt,
  });

  factory VillageArchiveItem.fromJson(Map<String, dynamic> j, String docId) =>
      VillageArchiveItem(
        id: docId,
        category: j['category'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
        documentUrl: j['documentUrl'] as String? ?? '',
        videoUrl: j['videoUrl'] as String? ?? '',
        audioUrl: j['audioUrl'] as String? ?? '',
        year: j['year'] as String? ?? '',
        source: j['source'] as String? ?? '',
        contributor: j['contributor'] as String? ?? '',
        location: j['location'] as String? ?? '',
        people: j['people'] as String? ?? '',
        period: j['period'] as String? ?? '',
        approvalStatus: j['approvalStatus'] as String? ?? 'pending',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: tsToDateTime(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'documentUrl': documentUrl,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'year': year,
        'source': source,
        'contributor': contributor,
        'location': location,
        'people': people,
        'period': period,
        'approvalStatus': approvalStatus,
        'sortOrder': sortOrder,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VillageArchiveItem copyWith({String? id}) => VillageArchiveItem(
        id: id ?? this.id,
        category: category,
        title: title,
        description: description,
        imageUrl: imageUrl,
        documentUrl: documentUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        year: year,
        source: source,
        contributor: contributor,
        location: location,
        people: people,
        period: period,
        approvalStatus: approvalStatus,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

/// فئات الأرشيف الرقمي وذاكرة القرية (village_archive_items.category).
class ArchiveItemCategory {
  ArchiveItemCategory._();
  static const photos = 'photos';
  static const stories = 'stories';
  static const documents = 'documents';
  static const videos = 'videos';
  static const audio = 'audio';
  static const newspapers = 'newspapers';
  static const maps = 'maps';

  static const List<String> all = [
    photos,
    stories,
    documents,
    videos,
    audio,
    newspapers,
    maps,
  ];

  static String label(String c) => switch (c) {
        photos => 'الصور',
        stories => 'الحكايات',
        documents => 'الوثائق',
        videos => 'الفيديوهات',
        audio => 'التسجيلات الصوتية',
        newspapers => 'الصحف القديمة',
        maps => 'الخرائط',
        _ => c,
      };

  static IconData icon(String c) => switch (c) {
        photos => Icons.photo_library_rounded,
        stories => Icons.record_voice_over_rounded,
        documents => Icons.description_rounded,
        videos => Icons.videocam_rounded,
        audio => Icons.graphic_eq_rounded,
        newspapers => Icons.newspaper_rounded,
        maps => Icons.map_rounded,
        _ => Icons.folder_rounded,
      };

  static Color color(String c) => switch (c) {
        photos => const Color(0xFF1565C0),
        stories => const Color(0xFF6A1B9A),
        documents => const Color(0xFF795548),
        videos => const Color(0xFFC62828),
        audio => const Color(0xFF00897B),
        newspapers => const Color(0xFF455A64),
        maps => const Color(0xFFEF6C00),
        _ => Colors.blueGrey,
      };
}

/// فئات عناصر التراث (مصدر واحد للتسمية/الأيقونة/اللون — كان موزعاً في النماذج).
class HeritageCategory {
  HeritageCategory._();
  static const customs = 'customs';
  static const food = 'food';
  static const proverbs = 'proverbs';
  static const games = 'games';
  static const weddings = 'weddings';
  static const funerals = 'funerals';
  static const crafts = 'crafts';
  static const tools = 'tools';

  static const List<String> all = [
    customs,
    food,
    proverbs,
    games,
    weddings,
    funerals,
    crafts,
    tools,
  ];

  static String label(String c) => switch (c) {
        customs => 'العادات والتقاليد',
        food => 'الأكلات الشعبية',
        proverbs => 'الأمثال والحكايات',
        games => 'الألعاب القديمة',
        weddings => 'الأفراح قديماً',
        funerals => 'العزاء والمناسبات',
        crafts => 'الحرف والمهن القديمة',
        tools => 'أدوات الزراعة القديمة',
        _ => c,
      };

  static IconData icon(String c) => switch (c) {
        customs => Icons.diversity_3_rounded,
        food => Icons.restaurant_rounded,
        proverbs => Icons.format_quote_rounded,
        games => Icons.casino_outlined,
        weddings => Icons.celebration_rounded,
        funerals => Icons.volunteer_activism_rounded,
        crafts => Icons.handyman_rounded,
        tools => Icons.agriculture_rounded,
        _ => Icons.folder_rounded,
      };

  static Color color(String c) => switch (c) {
        customs => const Color(0xFF6A1B9A),
        food => const Color(0xFFEF6C00),
        proverbs => const Color(0xFF1565C0),
        games => const Color(0xFF00897B),
        weddings => const Color(0xFFAD1457),
        funerals => const Color(0xFF455A64),
        crafts => const Color(0xFF5D4037),
        tools => const Color(0xFF558B2F),
        _ => Colors.blueGrey,
      };
}

class VillageContribution {
  final String id;
  final String userId;
  final String userName;
  final String type;
  final String title;
  final String description;
  final String imageUrl;
  final String documentUrl;
  final String videoUrl;
  final String audioUrl;
  final String approvalStatus;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  /// تثبيت المساهمة على الصفحة الرئيسية لقسم «عن القرية» (إجراء إداري).
  final bool pinOnHome;

  const VillageContribution({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.documentUrl = '',
    this.videoUrl = '',
    this.audioUrl = '',
    this.approvalStatus = 'pending',
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.pinOnHome = false,
  });

  factory VillageContribution.fromJson(Map<String, dynamic> j, String docId) =>
      VillageContribution(
        id: docId,
        userId: j['userId'] as String? ?? '',
        userName: j['userName'] as String? ?? '',
        type: j['type'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
        documentUrl: j['documentUrl'] as String? ?? '',
        videoUrl: j['videoUrl'] as String? ?? '',
        audioUrl: j['audioUrl'] as String? ?? '',
        approvalStatus: j['approvalStatus'] as String? ?? 'pending',
        createdAt: tsToDateTime(j['createdAt']),
        reviewedAt: tsToDateTime(j['reviewedAt']),
        reviewedBy: j['reviewedBy'] as String?,
        pinOnHome: j['pinOnHome'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'type': type,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'documentUrl': documentUrl,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'approvalStatus': approvalStatus,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'reviewedAt':
            reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'reviewedBy': reviewedBy,
        'pinOnHome': pinOnHome,
      };

  VillageContribution copyWith({String? id}) => VillageContribution(
        id: id ?? this.id,
        userId: userId,
        userName: userName,
        type: type,
        title: title,
        description: description,
        imageUrl: imageUrl,
        documentUrl: documentUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        approvalStatus: approvalStatus,
        createdAt: createdAt,
        reviewedAt: reviewedAt,
        reviewedBy: reviewedBy,
        pinOnHome: pinOnHome,
      );
}

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
    schools,
    azhar,
    agri,
    post,
    health,
    mosque,
    other
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

  factory VillageInstitution.fromJson(Map<String, dynamic> j, String docId) =>
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
