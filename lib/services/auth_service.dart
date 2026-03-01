import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = AppUser(
      uid: result.user!.uid,
      email: email,
      role: role,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());

    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
