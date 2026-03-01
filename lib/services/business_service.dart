import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_model.dart';
import 'firestore_service.dart';

class BusinessService {
  static const String _collection = 'businesses';

  static Future<void> createBusiness(BusinessModel business) async {
    await FirestoreService.collection(_collection)
        .doc(business.id)
        .set(business.toMap());
  }

  static Future<BusinessModel?> getBusiness(String id) async {
    final doc =
        await FirestoreService.collection(_collection).doc(id).get();

    if (!doc.exists) return null;

    return BusinessModel.fromMap(doc.data()!, doc.id);
  }
}
