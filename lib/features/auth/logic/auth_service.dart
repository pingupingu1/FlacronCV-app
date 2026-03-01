import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> login(
      String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  static Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    final user = cred.user;

    if (user != null) {
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        role: role,
        businessId: null,
        createdAt: DateTime.now(),
      );

      await UserService.createUser(userModel);
    }

    return user;
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
