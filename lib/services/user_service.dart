import '../models/user_model.dart';
import 'firestore_service.dart';

class UserService {
  static const String _collection = 'users';

  static Future<void> createUser(UserModel user) async {
    await FirestoreService.collection(_collection)
        .doc(user.uid)
        .set(user.toMap());
  }

  static Future<UserModel?> getUser(String uid) async {
    final doc =
        await FirestoreService.collection(_collection).doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }
}
