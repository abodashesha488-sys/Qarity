import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../../models/data_models.dart';
import 'cache_service.dart';

class UserService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<firebase_auth.User?> authStateChanges() => _auth.authStateChanges();
  firebase_auth.User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUser(user.uid);
  }

  Future<UserModel?> getUser(String uid) async {
    final cached = await CacheService.getUser(uid);
    if (cached != null) {
      return UserModel.fromJson(cached, uid);
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final user = UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        await CacheService.saveUser(uid, user.toJson());
        return user;
      }
    } on TimeoutException {
      return null;
    }
    return null;
  }

  Future<void> saveUserToFirestore(firebase_auth.User user) async {
    final existingUser = await getUser(user.uid);
    if (existingUser != null) {
      final needsUpdate = existingUser.name != user.displayName || existingUser.photoUrl != user.photoURL;
      if (needsUpdate) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      }
      return;
    }
    final newUser = UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      joinDate: user.metadata.creationTime ?? DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(newUser.toJson()).timeout(const Duration(seconds: 10));
  }

  Future<void> signOut() async => await _auth.signOut();
  Future<bool> isAdmin(String uid) async {
    final user = await getUser(uid);
    return user?.isAdmin ?? false;
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.id);
      final data = user.toJson();
      final existingDoc = await docRef.get();
      if (existingDoc.exists) {
        final existing = existingDoc.data() ?? <String, dynamic>{};
        // Preserve sensitive fields that callers may not supply, so we never
        // accidentally demote an admin or reset account state on a partial update.
        data['role'] = existing['role'] ?? data['role'];
        data['isActive'] = existing['isActive'] ?? data['isActive'];
        data['lastLogin'] = existing['lastLogin'] ?? data['lastLogin'];
      }
      await docRef.set(data, SetOptions(merge: true));
      await CacheService.saveUser(user.id, data);
    } catch (e) {
      debugPrint('updateUser failed: $e');
      rethrow;
    }
  }
}
