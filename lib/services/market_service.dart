import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/data_models.dart';
import 'cache_service.dart';
import 'content_cleanup_service.dart';
import 'image_upload_service.dart';
import 'notification_inbox_service.dart';
import 'notification_service.dart';
import 'remote_push_service.dart';

class MarketService {
  MarketService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Filter and Sort Options
  static const List<String> sortOptions = [
    'الأحدث',
    'الأعلى تقييماً',
    'أقل سعر',
    'العروض أولاً',
    'الأكثر مبيعاً',
  ];

  Future<List<MarketProduct>> getProductsList({
    bool forceRefresh = false,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    double? minRating,
    String? sellerId,
    String sortBy = 'الأحدث',
    bool? isFeatured,
    bool? isOnOffer,
    String? productStatus,
  }) async {
    if (!forceRefresh) {
      final cached = await CacheService.getProducts();
      if (cached != null) {
        var products = cached
            .map((json) => MarketProduct.fromJson(json, 'cache'))
            .toList();
        products = _applyFiltersAndSort(
          products,
          category: category,
          minPrice: minPrice,
          maxPrice: maxPrice,
          inStockOnly: inStockOnly,
          minRating: minRating,
          sellerId: sellerId,
          sortBy: sortBy,
          isFeatured: isFeatured,
          isOnOffer: isOnOffer,
          productStatus: productStatus,
        );
        return products;
      }
    }

    Query query = _firestore
        .collection('market_products')
        .where('isApproved', isEqualTo: true);
    if (productStatus != null && productStatus.isNotEmpty) {
      query = query.where('productStatus', isEqualTo: productStatus);
    }
    if (category != null && category != 'الكل') {
      query = query.where('category', isEqualTo: category);
    }
    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }
    if (isFeatured != null) {
      query = query.where('isFeatured', isEqualTo: isFeatured);
    }
    if (isOnOffer != null) {
      query = query.where('isOnOffer', isEqualTo: isOnOffer);
    }

    final snapshot = await query.get();
    final fetched = snapshot.docs
        .map((doc) =>
            MarketProduct.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    // الكاش العام لا يخزن إلا الكتالوج غير المفلتر، وإلا ضيّق استعلامٌ واحد
    // بنتيجةٍ جزئية الكاش الذي تقرأ منه بقية الشاشات بلا فلاتر.
    final isGeneralQuery =
        (category == null || category == 'الكل') &&
            sellerId == null &&
            isFeatured == null &&
            isOnOffer == null &&
            (productStatus == null || productStatus.isEmpty);
    if (isGeneralQuery) {
      await CacheService.saveProducts(fetched.map((p) => p.toJson()).toList());
    }

    return _applyFiltersAndSort(
      fetched,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStockOnly: inStockOnly,
      minRating: minRating,
      sellerId: sellerId,
      sortBy: sortBy,
      isFeatured: isFeatured,
      isOnOffer: isOnOffer,
      productStatus: productStatus,
    );
  }

  List<MarketProduct> _applyFiltersAndSort(
    List<MarketProduct> products, {
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    double? minRating,
    String? sellerId,
    String sortBy = 'الأحدث',
    bool? isFeatured,
    bool? isOnOffer,
    String? productStatus,
  }) {
    // كل الفلاتر تُطبّق هنا حتى يتطابق مسار الكاش مع مسار الخادم
    final filtered = products.where((p) {
      if (category != null && category != 'الكل' && p.category != category) {
        return false;
      }
      if (sellerId != null && p.sellerId != sellerId) return false;
      if (isFeatured != null && p.isFeatured != isFeatured) return false;
      if (isOnOffer != null && p.isOnOffer != isOnOffer) return false;
      if (minPrice != null && p.effectivePrice < minPrice) return false;
      if (maxPrice != null && p.effectivePrice > maxPrice) return false;
      if (inStockOnly == true && !p.isInStock) return false;
      if (minRating != null && p.rating < minRating) return false;
      if (productStatus != null &&
          productStatus.isNotEmpty &&
          p.productStatus != productStatus) {
        return false;
      }
      return true;
    }).toList();

    switch (sortBy) {
      case 'الأحدث':
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'الأعلى تقييماً':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'أقل سعر':
        filtered.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'العروض أولاً':
        filtered.sort((a, b) {
          if (a.isOnOffer && !b.isOnOffer) return -1;
          if (!a.isOnOffer && b.isOnOffer) return 1;
          return (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now());
        });
        break;
      case 'الأكثر مبيعاً':
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    return filtered;
  }

  Future<void> addProduct(MarketProduct product) async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // FirebaseAuth not initialized (e.g., in tests)
    }
    await _firestore.collection('market_products').add({
      ...product.toJson(),
      'isApproved': false,
      'sellerId': uid ?? '',
    });
    await CacheService.invalidateProducts();
    unawaited(RemotePushService.notifyAdmins('market_products'));
    await NotificationService.showLocalNotification(
      title: '🛒 منتج جديد',
      body: 'تم إرسال المنتج للمراجعة: ${product.name}',
      payload: '/market',
    );
    if (uid != null) {
      unawaited(NotificationInboxService.instance.push(
        userId: uid,
        title: '🛒 تم إرسال طلبك',
        body: 'تم إرسال المنتج "${product.name}" للمراجعة وسيظهر بعد موافقة الإدارة',
        route: '/market',
        kind: 'info',
      ));
    }
  }

  Future<void> deleteProduct(String productId, List<String> imageUrls) async {
    final uploader = ImageUploadService();
    for (final url in imageUrls) {
      try {
        await uploader.deleteImage(url);
      } catch (_) {}
    }
    await ContentCleanupService.cleanupForDeleted(
        _firestore, 'market_products', productId);
    await _firestore.collection('market_products').doc(productId).delete();
    await CacheService.invalidateProducts();
  }

  Stream<List<MarketProduct>> getProductsStream({int? limit}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('market_products')
        .where('isApproved', isEqualTo: true);
    if (limit != null) {
      query = query.orderBy('createdAt', descending: true).limit(limit);
    }
    return query
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarketProduct.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MarketProduct>> getSellerProductsStream(String sellerId) {
    return _firestore
        .collection('market_products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarketProduct.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<List<MarketProduct>> getProductsBySeller(String sellerId) async {
    final snapshot = await _firestore
        .collection('market_products')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    return snapshot.docs
        .map((doc) => MarketProduct.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<bool> isUserSeller(String userId) async {
    final snapshot = await _firestore
        .collection('market_products')
        .where('sellerId', isEqualTo: userId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<MarketProduct?> getProductById(String productId) async {
    final doc =
        await _firestore.collection('market_products').doc(productId).get();
    if (doc.exists) {
      return MarketProduct.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  // Featured Products
  Future<List<MarketProduct>> getFeaturedProducts({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('market_products')
        .where('isApproved', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => MarketProduct.fromJson(doc.data(), doc.id))
        .toList();
  }

  // Products on Offer
  Future<List<MarketProduct>> getProductsOnOffer({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('market_products')
        .where('isApproved', isEqualTo: true)
        .where('isOnOffer', isEqualTo: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => MarketProduct.fromJson(doc.data(), doc.id))
        .toList();
  }

  // Price Comparison - find similar products by name/category
  Future<List<MarketProduct>> findSimilarProducts(
      String productName, String category,
      {String? excludeSellerId}) async {
    final Query query = _firestore
        .collection('market_products')
        .where('isApproved', isEqualTo: true)
        .where('category', isEqualTo: category);

    final snapshot = await query.get();
    final products = snapshot.docs
        .map((doc) =>
            MarketProduct.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) => p.id != excludeSellerId)
        .where((p) =>
            _calculateSimilarity(
                p.name.toLowerCase(), productName.toLowerCase()) >
            0.3)
        .toList();

    products.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
    return products.take(5).toList();
  }

  double _calculateSimilarity(String a, String b) {
    // Simple Jaccard similarity on words
    final wordsA = a.split(' ').toSet();
    final wordsB = b.split(' ').toSet();
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    return union > 0 ? intersection / union : 0.0;
  }

  // Reviews
  Future<void> addReview(ProductReview review) async {
    await _firestore.collection('product_reviews').add(review.toJson());
    await _updateProductRating(review.productId);
    await CacheService.invalidateProducts();
  }

  Future<List<ProductReview>> getProductReviews(String productId) async {
    final snapshot = await _firestore
        .collection('product_reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ProductReview.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<double> getAverageRating(String productId) async {
    final snapshot = await _firestore
        .collection('product_reviews')
        .where('productId', isEqualTo: productId)
        .get();
    if (snapshot.docs.isEmpty) return 0.0;
    final sum = snapshot.docs.fold<double>(0.0,
        (sum, doc) => sum + (doc.data()['rating'] as num? ?? 0.0).toDouble());
    return sum / snapshot.docs.length;
  }

  Future<void> _updateProductRating(String productId) async {
    // قراءة واحدة للمراجعات (كانت تُقرأ مرتين: للمتوسط ثم للعدد).
    final snapshot = await _firestore
        .collection('product_reviews')
        .where('productId', isEqualTo: productId)
        .get();
    final count = snapshot.docs.length;
    final sum = snapshot.docs.fold<double>(0.0,
        (sum, doc) => sum + (doc.data()['rating'] as num? ?? 0.0).toDouble());
    await _firestore.collection('market_products').doc(productId).update({
      'rating': count == 0 ? 0.0 : sum / count,
      'reviewCount': count,
    });
  }

  // Seller Profile
  Future<SellerProfile?> getSellerProfile(String sellerId) async {
    final doc =
        await _firestore.collection('seller_profiles').doc(sellerId).get();
    if (doc.exists) {
      return SellerProfile.fromJson(doc.data()!, doc.id);
    }
    // Create default profile from user data if not exists
    final userDoc = await _firestore.collection('users').doc(sellerId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final products = await getProductsBySeller(sellerId);
      final categories = products.map((p) => p.category).toSet().toList();
      final profile = SellerProfile(
        id: sellerId,
        userId: sellerId,
        name: userData['name'] ?? 'بائع',
        phone: userData['phone'] ?? '',
        imageUrl: userData['photoUrl'],
        totalProducts: products.length,
        categories: categories,
        createdAt: DateTime.now(),
      );
      await createSellerProfile(profile);
      return profile;
    }
    return null;
  }

  Future<void> createSellerProfile(SellerProfile profile) async {
    await _firestore
        .collection('seller_profiles')
        .doc(profile.id)
        .set(profile.toJson());
  }

  Future<void> updateSellerProfile(SellerProfile profile) async {
    await _firestore
        .collection('seller_profiles')
        .doc(profile.id)
        .update(profile.toJson());
  }

  // Update product fields
  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    await _firestore.collection('market_products').doc(productId).update(data);
    await CacheService.invalidateProducts();
  }

  // Toggle featured status
  Future<void> toggleFeatured(String productId, bool isFeatured) async {
    await _firestore
        .collection('market_products')
        .doc(productId)
        .update({'isFeatured': isFeatured});
    await CacheService.invalidateProducts();
  }

  // Toggle offer status
  Future<void> toggleOffer(
      String productId, bool isOnOffer, double? offerPrice) async {
    await _firestore.collection('market_products').doc(productId).update({
      'isOnOffer': isOnOffer,
      'offerPrice': offerPrice,
    });
    await CacheService.invalidateProducts();
  }

  // Stock notifications - subscribe to back-in-stock alerts
  Future<void> subscribeToStockAlert(String userId, String productId) async {
    await _firestore.collection('stock_alerts').add({
      'userId': userId,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsubscribeFromStockAlert(
      String userId, String productId) async {
    final snapshot = await _firestore
        .collection('stock_alerts')
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> isSubscribedToStockAlert(String userId, String productId) async {
    final snapshot = await _firestore
        .collection('stock_alerts')
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Get price history for comparison
  Future<List<Map<String, dynamic>>> getPriceHistory(String productId) async {
    final snapshot = await _firestore
        .collection('price_history')
        .where('productId', isEqualTo: productId)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> recordPriceChange(
      String productId, double oldPrice, double newPrice) async {
    await _firestore.collection('price_history').add({
      'productId': productId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Store Profiles
  Stream<List<SellerProfile>> getStoreProfilesStream() {
    return _firestore
        .collection('seller_profiles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SellerProfile.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Item Requests
  Stream<List<Map<String, dynamic>>> getRequestsStream() {
    return _firestore
        .collection('item_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> submitRequest(Map<String, dynamic> data) async {
    await _firestore.collection('item_requests').add({
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.showLocalNotification(
      title: '📝 طلب جديد',
      body: 'تم إرسال طلب شراء جديد',
      payload: '/market/tabs',
    );
  }

  Future<void> updateRequestStatus(String docId, String status, {String? adminNotes}) async {
    final updateData = {'status': status, 'updatedAt': FieldValue.serverTimestamp()};
    if (adminNotes != null) {
      updateData['adminNotes'] = adminNotes;
    }
    await _firestore.collection('item_requests').doc(docId).update(updateData);
  }

  // Donations
  Stream<List<Map<String, dynamic>>> getDonationsStream() {
    return _firestore
        .collection('donations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> updateDonationStatus(String docId, String status, {String? claimedBy}) async {
    final updateData = {'status': status, 'updatedAt': FieldValue.serverTimestamp()};
    if (claimedBy != null) {
      updateData['claimedBy'] = claimedBy;
    }
    await _firestore.collection('donations').doc(docId).update(updateData);
  }

  // Seller Requests
  Future<void> submitSellerRequest(SellerRequest request) async {
    await _firestore.collection('seller_requests').add(request.toJson());
    unawaited(RemotePushService.notifyAdmins('seller_requests'));
    await NotificationService.showLocalNotification(
      title: '📝 طلب بائع جديد',
      body: 'تم إرسال طلبك لتصبح بائعاً، سنراجعه قريباً',
      payload: '/profile',
    );
  }

  Future<List<SellerRequest>> getSellerRequests({String? status}) async {
    Query query = _firestore.collection('seller_requests').orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SellerRequest.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<SellerRequest?> getUserSellerRequest(String userId) async {
    final snapshot = await _firestore
        .collection('seller_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return SellerRequest.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id);
    }
    return null;
  }

  Future<void> approveSellerRequest(String requestId, String adminUid, {String? adminNotes}) async {
    final requestDoc = await _firestore.collection('seller_requests').doc(requestId).get();
    if (!requestDoc.exists) return;
    
    final request = SellerRequest.fromJson(requestDoc.data()!, requestDoc.id);
    
    // Update request status
    await _firestore.collection('seller_requests').doc(requestId).update({
      'status': 'approved',
      'adminNotes': adminNotes,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
    });

    // Create seller profile
    final profile = SellerProfile(
      id: request.userId,
      userId: request.userId,
      name: request.shopName,
      bio: request.shopDescription,
      phone: request.userPhone,
      address: request.shopAddress,
      categories: request.categories,
      createdAt: DateTime.now(),
    );
    await createSellerProfile(profile);

    // Notify user
    await NotificationService.showLocalNotification(
      title: '✅ تم قبول طلبك',
      body: 'أصبحت الآن بائعاً معتمداً! يمكنك إضافة منتجاتك',
      payload: '/market',
    );
  }

  Future<void> rejectSellerRequest(String requestId, String adminUid, {String? adminNotes}) async {
    await _firestore.collection('seller_requests').doc(requestId).update({
      'status': 'rejected',
      'adminNotes': adminNotes,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
    });

    // Notify user
    await NotificationService.showLocalNotification(
      title: '❌ تم رفض طلبك',
      body: adminNotes ?? 'لم يتم قبول طلبك لتصبح بائعاً',
      payload: '/profile',
    );
  }

  Future<bool> hasPendingSellerRequest(String userId) async {
    final snapshot = await _firestore
        .collection('seller_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
