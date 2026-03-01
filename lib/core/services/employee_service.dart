// lib/core/services/employee_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/employee_model.dart';

class EmployeeService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─── Stream employees ────────────────────────────────────────
  Stream<List<EmployeeModel>> streamEmployees(String businessId) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EmployeeModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Stream<List<EmployeeModel>> streamActiveEmployees(String businessId) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .where('isActive', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EmployeeModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── Get single employee ─────────────────────────────────────
  Future<EmployeeModel?> getEmployee(
      String businessId, String employeeId) async {
    final doc = await _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .doc(employeeId)
        .get();
    if (!doc.exists) return null;
    return EmployeeModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Create employee ─────────────────────────────────────────
  Future<String> createEmployee({
    required String businessId,
    required String fullName,
    required String email,
    required String phone,
    required String position,
    required EmployeeRole role,
    required EmploymentType employmentType,
    required double hourlyRate,
    required DateTime hireDate,
    String? notes,
  }) async {
    final docRef = _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .doc();

    final employee = EmployeeModel(
      id: docRef.id,
      businessId: businessId,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      employmentType: employmentType,
      position: position,
      hourlyRate: hourlyRate,
      hireDate: hireDate,
      isActive: true,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await docRef.set(employee.toMap());
    return docRef.id;
  }

  // ─── Update employee ─────────────────────────────────────────
  Future<void> updateEmployee(
      String businessId, String employeeId, Map<String, dynamic> data) async {
    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .doc(employeeId)
        .update({...data, 'updatedAt': DateTime.now().toIso8601String()});
  }

  // ─── Deactivate / Activate ───────────────────────────────────
  Future<void> setActiveStatus(
      String businessId, String employeeId, bool isActive) async {
    await updateEmployee(
        businessId, employeeId, {'isActive': isActive});
  }

  // ─── Delete employee ─────────────────────────────────────────
  Future<void> deleteEmployee(
      String businessId, String employeeId) async {
    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .doc(employeeId)
        .delete();
  }

  // ─── Get employee stats ──────────────────────────────────────
  Future<Map<String, int>> getEmployeeStats(String businessId) async {
    final snap = await _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .get();

    int active = 0, inactive = 0, fullTime = 0, partTime = 0;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isActive'] == true) active++; else inactive++;
      if (data['employmentType'] == 'fullTime') fullTime++;
      if (data['employmentType'] == 'partTime') partTime++;
    }
    return {
      'total': snap.docs.length,
      'active': active,
      'inactive': inactive,
      'fullTime': fullTime,
      'partTime': partTime,
    };
  }

  // ─── Search employees ────────────────────────────────────────
  Future<List<EmployeeModel>> searchEmployees(
      String businessId, String query) async {
    final snap = await _db
        .collection('businesses')
        .doc(businessId)
        .collection('employees')
        .get();

    final q = query.toLowerCase();
    return snap.docs
        .map((d) =>
            EmployeeModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .where((e) =>
            e.fullName.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            e.position.toLowerCase().contains(q))
        .toList();
  }
}
