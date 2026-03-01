import '../models/service_model.dart';
import 'firestore_service.dart';

class ServiceService {
  static const String _collection = 'services';

  static Future<void> createService(ServiceModel service) async {
    await FirestoreService.collection(_collection)
        .doc(service.id)
        .set(service.toMap());
  }

  static Future<List<ServiceModel>> getServices(
      String businessId) async {
    final query = await FirestoreService.collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .get();

    return query.docs
        .map((d) => ServiceModel.fromMap(d.data(), d.id))
        .toList();
  }
}
