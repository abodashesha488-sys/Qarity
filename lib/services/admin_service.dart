import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  bool get isAdmin => _auth.currentUser?.uid != null;

  Future<bool> isAdminUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (e) {
      debugPrint('isAdminUser error: $e');
      return false;
    }
  }

  Future<Map<String, int>> fetchPendingCounts() async {
    final results = await Future.wait([
      _pendingCount('news').first,
      _pendingCount('market_products').first,
      _pendingCount('obituaries').first,
      _pendingCount('occasions').first,
      _pendingCount('forum_posts').first,
    ]);
    return {
      'news': results[0],
      'market_products': results[1],
      'obituaries': results[2],
      'occasions': results[3],
      'forum_posts': results[4],
    };
  }

  Stream<int> getPendingNewsCount() => _pendingCount('news');
  Stream<int> getPendingProductsCount() => _pendingCount('market_products');
  Stream<int> getPendingObituariesCount() => _pendingCount('obituaries');
  Stream<int> getPendingOccasionsCount() => _pendingCount('occasions');
  Stream<int> getPendingForumPostsCount() => _pendingCount('forum_posts');

  Stream<int> _pendingCount(String collection) {
    return _firestore
        .collection(collection)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<List<Map<String, dynamic>>> getPendingNewsStream() => _pendingStream('news');
  Stream<List<Map<String, dynamic>>> getApprovedNewsStream() => _approvedStream('news');
  Stream<List<Map<String, dynamic>>> getAllNewsStream() => _allStream('news');
  Stream<List<Map<String, dynamic>>> getPendingProductsStream() => _pendingStream('market_products');
  Stream<List<Map<String, dynamic>>> getApprovedProductsStream() => _approvedStream('market_products');
  Stream<List<Map<String, dynamic>>> getAllProductsStream() => _allStream('market_products');
  Stream<List<Map<String, dynamic>>> getPendingObituariesStream() => _pendingStream('obituaries');
  Stream<List<Map<String, dynamic>>> getPendingOccasionsStream() => _pendingStream('occasions');
  Stream<List<Map<String, dynamic>>> getPendingForumPostsStream() => _pendingStream('forum_posts');

  Stream<List<Map<String, dynamic>>> getPendingStream(String collection) => _pendingStream(collection);
  Stream<List<Map<String, dynamic>>> getApprovedStream(String collection) => _approvedStream(collection);
  Stream<List<Map<String, dynamic>>> getAllStream(String collection) => _allStream(collection);

  Future<void> approveNews(String docId) => _approve('news', docId);
  Future<void> rejectNews(String docId) => _reject('news', docId);
  Future<void> deleteNews(String docId) => _delete('news', docId);

  Future<void> approveProduct(String docId) => _approve('market_products', docId);
  Future<void> rejectProduct(String docId) => _reject('market_products', docId);
  Future<void> deleteProduct(String docId) => _delete('market_products', docId);

  Future<void> approveObituary(String docId) => _approve('obituaries', docId);
  Future<void> rejectObituary(String docId) => _reject('obituaries', docId);
  Future<void> deleteObituary(String docId) => _delete('obituaries', docId);

  Future<void> approveOccasion(String docId) => _approve('occasions', docId);
  Future<void> rejectOccasion(String docId) => _reject('occasions', docId);
  Future<void> deleteOccasion(String docId) => _delete('occasions', docId);

  Future<void> approveForumPost(String docId) => _approve('forum_posts', docId);
  Future<void> rejectForumPost(String docId) => _reject('forum_posts', docId);
  Future<void> deleteForumPost(String docId) => _delete('forum_posts', docId);

  Stream<List<Map<String, dynamic>>> getActivityLogStream({int limit = 100}) {
    return _firestore
        .collection('activity_log')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<Map<String, int>> getStatistics() async {
    final counts = <String, int>{};
    final collections = [
      'users',
      'news',
      'market_products',
      'obituaries',
      'occasions',
      'forum_posts',
      'activity_log',
    ];
    for (final collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).count().get();
        counts[collection] = snapshot.count ?? 0;
      } catch (e) {
        counts[collection] = 0;
      }
    }
    return counts;
  }

  Future<List<Map<String, dynamic>>> getAdmins() async {
    final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'admin').get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  Future<void> setUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
    await _logActivity(action: 'set_role', targetCollection: 'users', targetDocId: uid, targetTitle: role);
  }

  Future<void> removeAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).set({'role': 'user'}, SetOptions(merge: true));
    await _logActivity(action: 'remove_admin', targetCollection: 'users', targetDocId: uid);
  }

  Future<void> updateItem(String collection, String docId, Map<String, dynamic> data) => _update(collection, docId, data);
  Future<void> updateNews(String docId, Map<String, dynamic> data) => _update('news', docId, data);
  Future<void> updateProduct(String docId, Map<String, dynamic> data) => _update('market_products', docId, data);
  Future<void> updateObituary(String docId, Map<String, dynamic> data) => _update('obituaries', docId, data);
  Future<void> updateOccasion(String docId, Map<String, dynamic> data) => _update('occasions', docId, data);
  Future<void> updateForumPost(String docId, Map<String, dynamic> data) => _update('forum_posts', docId, data);

  Future<void> _update(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Stream<List<Map<String, dynamic>>> _allStream(String collection) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> _pendingStream(String collection) {
    return _firestore
        .collection(collection)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> _approvedStream(String collection) {
    return _firestore
        .collection(collection)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> approveItem(String collection, String docId) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    final title = doc.data()?['title'] as String? ??
        doc.data()?['name'] as String? ??
        doc.data()?['content'] as String? ??
        doc.id;
    await _firestore.collection(collection).doc(docId).update({
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
    });
    await _logActivity(
      action: 'approve',
      targetCollection: collection,
      targetDocId: docId,
      targetTitle: title,
    );
  }

  Future<void> rejectItem(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).update({
      'isApproved': false,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': _auth.currentUser?.uid,
    });
    await _logActivity(
      action: 'reject',
      targetCollection: collection,
      targetDocId: docId,
    );
  }

  Future<void> deleteItem(String collection, String docId) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    final title = doc.data()?['title'] as String? ??
        doc.data()?['name'] as String? ??
        doc.data()?['content'] as String? ??
        doc.id;
    await _firestore.collection(collection).doc(docId).delete();
    await _logActivity(
      action: 'delete',
      targetCollection: collection,
      targetDocId: docId,
      targetTitle: title,
    );
  }

  Future<void> _approve(String collection, String docId) async {
    await approveItem(collection, docId);
  }

  Future<void> _reject(String collection, String docId) async {
    await rejectItem(collection, docId);
  }

  Future<void> _delete(String collection, String docId) async {
    await deleteItem(collection, docId);
  }

  Future<void> _logActivity({
    required String action,
    required String targetCollection,
    required String targetDocId,
    String? targetTitle,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'unknown';
    await _firestore.collection('activity_log').add({
      'adminId': uid,
      'action': action,
      'targetCollection': targetCollection,
      'targetDocId': targetDocId,
      if (targetTitle != null) 'targetTitle': targetTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
