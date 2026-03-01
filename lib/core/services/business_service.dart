// lib/core/services/business_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business_model.dart';
import '../models/service_model.dart';
import '../models/business_hours_model.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Business CRUD ────────────────────────────────────────────

  Future<String> createBusiness({
    required String name,
    required String category,
    String? description,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? website,
    String? logoUrl,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final docRef = _firestore.collection('businesses').doc();
    final business = BusinessModel(
      id: docRef.id,
      ownerId: uid,
      name: name,
      category: category,
      description: description,
      phone: phone,
      email: email,
      address: address,
      city: city,
      state: state,
      zip: zip,
      website: website,
      logoUrl: logoUrl,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await docRef.set(business.toMap());

    // Link business to user
    await _firestore.collection('users').doc(uid).update({
      'businessId': docRef.id,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return docRef.id;
  }

  Future<BusinessModel?> getBusiness(String businessId) async {
    final doc =
        await _firestore.collection('businesses').doc(businessId).get();
    if (!doc.exists) return null;
    return BusinessModel.fromMap(doc.data()!, doc.id);
  }

  Future<BusinessModel?> getMyBusiness() async {
    final uid = _uid;
    if (uid == null) return null;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final businessId = userDoc.data()?['businessId'] as String?;
    if (businessId == null) return null;
    return getBusiness(businessId);
  }

  Stream<BusinessModel?> streamBusiness(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .snapshots()
        .map((doc) =>
            doc.exists ? BusinessModel.fromMap(doc.data()!, doc.id) : null);
  }

  Future<void> updateBusiness(
      String businessId, Map<String, dynamic> data) async {
    await _firestore.collection('businesses').doc(businessId).update({
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Services CRUD ───────────────────────────────────────────

  Stream<List<ServiceModel>> streamServices(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ServiceModel.fromMap(d.data(), d.id)).toList());
  }

  Future<List<ServiceModel>> getServices(String businessId) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((d) => ServiceModel.fromMap(d.data(), d.id)).toList();
  }

  Future<String> addService({
    required String businessId,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? category,
    String? color,
  }) async {
    final docRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .doc();

    final service = ServiceModel(
      id: docRef.id,
      businessId: businessId,
      name: name,
      price: price,
      durationMinutes: durationMinutes,
      description: description,
      category: category,
      color: color ?? '#FF6B00',
      isActive: true,
      createdAt: DateTime.now(),
    );

    await docRef.set(service.toMap());
    return docRef.id;
  }

  Future<void> updateService(
      String businessId, String serviceId, Map<String, dynamic> data) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .doc(serviceId)
        .update({...data, 'updatedAt': DateTime.now().toIso8601String()});
  }

  Future<void> deleteService(String businessId, String serviceId) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  // ─── Business Hours ──────────────────────────────────────────

  Future<BusinessHoursModel?> getBusinessHours(String businessId) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('hours')
        .get();
    if (!doc.exists) return BusinessHoursModel.defaultHours(businessId);
    return BusinessHoursModel.fromMap(doc.data()!, businessId);
  }

  Stream<BusinessHoursModel?> streamBusinessHours(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('hours')
        .snapshots()
        .map((doc) => doc.exists
            ? BusinessHoursModel.fromMap(doc.data()!, businessId)
            : BusinessHoursModel.defaultHours(businessId));
  }

  Future<void> saveBusinessHours(
      String businessId, BusinessHoursModel hours) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('hours')
        .set(hours.toMap());
  }
}
