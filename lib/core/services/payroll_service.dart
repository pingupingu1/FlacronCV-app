// lib/core/services/payroll_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payroll_model.dart';
import '../models/employee_model.dart';
import 'attendance_service.dart';

class PayrollService {
  final _db = FirebaseFirestore.instance;
  final _attendanceService = AttendanceService();

  CollectionReference _payrollColl(String businessId) => _db
      .collection('businesses')
      .doc(businessId)
      .collection('payroll');

  // ─── Generate payroll for an employee ───────────────────────
  Future<String> generatePayroll({
    required String businessId,
    required EmployeeModel employee,
    required DateTime periodStart,
    required DateTime periodEnd,
    double deductionRate = 0.15, // 15% default tax/deductions
    String? notes,
  }) async {
    // Fetch attendance for the period
    final summary = await _attendanceService.getAttendanceSummary(
      businessId: businessId,
      from: periodStart,
      to: periodEnd,
      employeeId: employee.id,
    );

    final totalMinutes = summary['totalMinutes'] as int? ?? 0;
    final totalHours = totalMinutes / 60.0;
    final grossPay = totalHours * employee.hourlyRate;
    final deductions = grossPay * deductionRate;
    final netPay = grossPay - deductions;

    final docRef = _payrollColl(businessId).doc();

    final payroll = PayrollModel(
      id: docRef.id,
      businessId: businessId,
      employeeId: employee.id,
      employeeName: employee.fullName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      hourlyRate: employee.hourlyRate,
      totalWorkedMinutes: totalMinutes,
      totalHours: totalHours,
      grossPay: grossPay,
      deductions: deductions,
      netPay: netPay,
      status: PayrollStatus.pending,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await docRef.set(payroll.toMap());
    return docRef.id;
  }

  // ─── Generate payroll for ALL employees ─────────────────────
  Future<List<String>> generatePayrollForAll({
    required String businessId,
    required List<EmployeeModel> employees,
    required DateTime periodStart,
    required DateTime periodEnd,
    double deductionRate = 0.15,
  }) async {
    final ids = <String>[];
    for (final emp in employees) {
      try {
        final id = await generatePayroll(
          businessId: businessId,
          employee: emp,
          periodStart: periodStart,
          periodEnd: periodEnd,
          deductionRate: deductionRate,
        );
        ids.add(id);
      } catch (_) {}
    }
    return ids;
  }

  // ─── Stream payroll records ──────────────────────────────────
  Stream<List<PayrollModel>> streamPayroll({
    required String businessId,
    PayrollStatus? filterStatus,
    String? employeeId,
  }) {
    Query query = _payrollColl(businessId)
        .orderBy('periodStart', descending: true);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus.name);
    }
    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            PayrollModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Get payroll by period ───────────────────────────────────
  Future<List<PayrollModel>> getPayrollForPeriod({
    required String businessId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final snap = await _payrollColl(businessId)
        .where('periodStart',
            isEqualTo: periodStart.toIso8601String())
        .where('periodEnd', isEqualTo: periodEnd.toIso8601String())
        .get();

    return snap.docs
        .map((d) =>
            PayrollModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  // ─── Mark as paid ────────────────────────────────────────────
  Future<void> markPaid(String businessId, String payrollId) async {
    await _payrollColl(businessId).doc(payrollId).update({
      'status': PayrollStatus.paid.name,
      'paidAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Mark all pending as paid ────────────────────────────────
  Future<void> markAllPaid(
      String businessId, List<String> payrollIds) async {
    final batch = _db.batch();
    final now = DateTime.now().toIso8601String();
    for (final id in payrollIds) {
      batch.update(_payrollColl(businessId).doc(id), {
        'status': PayrollStatus.paid.name,
        'paidAt': now,
        'updatedAt': now,
      });
    }
    await batch.commit();
  }

  // ─── Delete payroll record ───────────────────────────────────
  Future<void> deletePayroll(String businessId, String payrollId) async {
    await _payrollColl(businessId).doc(payrollId).delete();
  }

  // ─── Get payroll summary ─────────────────────────────────────
  Future<Map<String, double>> getPayrollSummary(String businessId) async {
    final snap = await _payrollColl(businessId).get();
    double totalGross = 0, totalNet = 0, totalDeductions = 0;
    double monthGross = 0, monthNet = 0;

    final now = DateTime.now();
    for (final doc in snap.docs) {
      final p = PayrollModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
      if (p.status == PayrollStatus.paid) {
        totalGross += p.grossPay;
        totalNet += p.netPay;
        totalDeductions += p.deductions;
        if (p.paidAt != null &&
            p.paidAt!.year == now.year &&
            p.paidAt!.month == now.month) {
          monthGross += p.grossPay;
          monthNet += p.netPay;
        }
      }
    }

    return {
      'totalGross': totalGross,
      'totalNet': totalNet,
      'totalDeductions': totalDeductions,
      'monthGross': monthGross,
      'monthNet': monthNet,
    };
  }
}
