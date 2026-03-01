import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/business_model.dart';
import '../../../models/service_model.dart';
import '../../../services/business_service.dart';
import '../../../services/service_service.dart';

class BusinessController {
  static Future<void> createBusiness({
    required String name,
    required String category,
    required String phone,
    required String address,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final business = BusinessModel(
      id: uid,
      name: name,
      category: category,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );

    await BusinessService.createBusiness(business);
  }

  static Future<void> addService({
    required String name,
    required double price,
    required int duration,
  }) async {
    final businessId = FirebaseAuth.instance.currentUser!.uid;

    final service = ServiceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: businessId,
      name: name,
      price: price,
      duration: duration,
      createdAt: DateTime.now(),
    );

    await ServiceService.createService(service);
  }
}
