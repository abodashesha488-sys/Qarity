import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/data_models.dart';
import '../../models/medical_models.dart';
import '../../models/service_provider_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/qurity_logo.dart';

/// ممرّيف إشعار → العنصر نفسه: يفتح `/open` بمعرّف المجموعة والوثيقة،
/// يجلب النموذج من Firestore ويعيد التوجيه لشاشة تفاصيله.
/// أي فشل (حذف/صلاحيات/مجموعة بلا تفاصيل) يرجع لمسار القائمة المرفق،
/// فلا ينكسر شيء عند قدوم إشعار قديم بلا معرّف.
class NotificationOpenScreen extends StatefulWidget {
  const NotificationOpenScreen({super.key, this.firestore});

  /// قابل للحقن لاختبار الموجّه دون Firebase حقيقي.
  final FirebaseFirestore? firestore;

  @override
  State<NotificationOpenScreen> createState() => _NotificationOpenScreenState();
}

class _NotificationOpenScreenState extends State<NotificationOpenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
    final fallback = (args['route'] ?? '').toString();
    final collection = (args['collection'] ?? '').toString();
    final id = (args['id'] ?? '').toString();
    try {
      if (collection.isNotEmpty && id.isNotEmpty) {
        final db = widget.firestore ?? FirebaseFirestore.instance;
        final snap = await db
            .collection(collection)
            .doc(id)
            .get()
            .timeout(const Duration(seconds: 10));
        if (snap.exists && mounted) {
          final data = snap.data()!;
          Object? model;
          String? route;
          switch (collection) {
            case 'news':
              model = NewsItem.fromJson(data, id);
              route = AppRoutes.newsView;
              break;
            case 'market_products':
              model = MarketProduct.fromJson(data, id);
              route = AppRoutes.marketProductDetail;
              break;
            case 'obituaries':
              model = Obituary.fromJson(data, id);
              route = AppRoutes.obituariesDetail;
              break;
            case 'occasions':
              model = Occasion.fromJson(data, id);
              route = AppRoutes.occasionsDetail;
              break;
            case 'forum_posts':
              model = ForumPost.fromJson(data, id);
              route = AppRoutes.forumPostDetail;
              break;
            case 'service_providers':
              model = ServiceProvider.fromJson(data, id);
              route = AppRoutes.serviceProviderDetail;
              break;
            case 'village_clinics':
              model = VillageClinic.fromJson(data, id);
              route = AppRoutes.medicalClinicDetail;
              break;
            case 'pharmacies':
              model = Pharmacy.fromJson(data, id);
              route = AppRoutes.medicalPharmacyDetail;
              break;
            case 'medical_labs':
              model = MedicalLab.fromJson(data, id);
              route = AppRoutes.medicalLabDetail;
              break;
          }
          if (route != null && mounted) {
            Navigator.pushReplacementNamed(context, route, arguments: model);
            return;
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    if (fallback.isNotEmpty) {
      Navigator.pushReplacementNamed(context, fallback);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QurityLogo(size: 64),
            SizedBox(height: 18),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
