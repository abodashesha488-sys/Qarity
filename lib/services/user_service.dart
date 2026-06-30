import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/data_models.dart';

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
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    return null;
  }
  Future<void> saveUserToFirestore(firebase_auth.User user) async {
    final existingUser = await getUser(user.uid);
    if (existingUser != null) {
      final needsUpdate = existingUser.name != user.displayName || existingUser.photoUrl != user.photoURL;
      if (needsUpdate) {
        await updateUser(existingUser.copyWith(name: user.displayName ?? '', photoUrl: user.photoURL));
      } else {
        await updateUser(existingUser.copyWith(lastLogin: DateTime.now()));
      }
      return;
    }
    final newUser = UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      phone: null,
      photoUrl: user.photoURL,
      joinDate: user.metadata.creationTime ?? DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
  }
  Future<void> signOut() async => await _auth.signOut();
  Future<bool> isAdmin(String uid) async { final user = await getUser(uid); return user?.isAdmin ?? false; }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }
}