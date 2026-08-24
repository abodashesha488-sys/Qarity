import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';
import 'cache_service.dart';
import 'image_upload_service.dart';
import 'notification_service.dart';

class MarketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MarketProduct>> getProductsList({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CacheService.getProducts();
      if (cached != null) {
        return cached.map((json) => MarketProduct.fromJson(json, 'cache')).toList();
      }
    }
    final snapshot = await _firestore.collection('market_products').where('isApproved', isEqualTo: true).get();
    final products = snapshot.docs.map((doc) => MarketProduct.fromJson(doc.data(), doc.id)).toList();
    await CacheService.saveProducts(products.map((p) => p.toJson()).toList());
    return products;
  }

  Future<void> addProduct(MarketProduct product) async {
    await _firestore.collection('market_products').add({
      ...product.toJson(),
      'isApproved': false,
    });
    await CacheService.invalidateProducts();
    await NotificationService.showLocalNotification(
      title: '🛒 منتج جديد',
      body: 'تم إرسال المنتج للمراجعة: ${product.name}',
      payload: '/market',
    );
  }

  Future<void> deleteProduct(String productId, List<String> imageUrls) async {
    final uploader = ImageUploadService();
    for (final url in imageUrls) {
      try {
        await uploader.deleteImage(url);
      } catch (_) {}
    }
    await _firestore.collection('market_products').doc(productId).delete();
    await CacheService.invalidateProducts();
  }

  Stream<List<MarketProduct>> getProductsStream() {
    return _firestore
        .collection('market_products')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MarketProduct.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<MarketProduct>> getSellerProductsStream(String sellerId) {
    return _firestore
        .collection('market_products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MarketProduct.fromJson(doc.data(), doc.id)).toList());
  }

  Future<List<MarketProduct>> getProductsBySeller(String sellerId) async {
    final snapshot = await _firestore
        .collection('market_products')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    return snapshot.docs.map((doc) => MarketProduct.fromJson(doc.data(), doc.id)).toList();
  }

  Future<bool> isUserSeller(String userId) async {
    final snapshot = await _firestore.collection('market_products').where('sellerId', isEqualTo: userId).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<MarketProduct?> getProductById(String productId) async {
    final doc = await _firestore.collection('market_products').doc(productId).get();
    if (doc.exists) {
      return MarketProduct.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

}