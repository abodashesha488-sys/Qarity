import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/data_models.dart';

class MarketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MarketProduct>> getProductsList() async {
    final snapshot = await _firestore.collection('market_products').where('isApproved', isEqualTo: true).get();
    return snapshot.docs.map((doc) => MarketProduct.fromJson(doc.data(), doc.id)).toList();
  }

  Future<void> addProduct(MarketProduct product) async {
    await _firestore.collection('market_products').add({
      ...product.toJson(),
      'isApproved': true,
    });
  }

  Future<void> deleteProduct(String productId, List<String> imageUrls) async {
    await _deleteImagesFromImgbb(imageUrls);
    await _firestore.collection('market_products').doc(productId).delete();
  }

  Stream<List<MarketProduct>> getSellerProductsStream(String sellerId) {
    return _firestore
        .collection('market_products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MarketProduct.fromJson(doc.data(), doc.id)).toList())
        .handleError((error, stack) => <MarketProduct>[]);
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

  Future<void> _deleteImagesFromImgbb(List<String> imageUrls) async {
    const String apiKey = '5adf17954a21d7d9146824fde7061c6d';
    for (final url in imageUrls) {
      try {
        final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
        final deleteKey = _extractDeleteKey(url);
        if (deleteKey.isNotEmpty) {
          await http.post(uri.replace(path: '/1/delete'), body: {'delete_keys': deleteKey});
        }
      } catch (_) {}
    }
  }

  String _extractDeleteKey(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      return uri.queryParameters['delete_key'] ?? '';
    } catch (_) {
      return '';
    }
  }
}