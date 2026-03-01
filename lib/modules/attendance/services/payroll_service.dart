import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/attendance_model.dart';
import '../../../core/models/payroll_model.dart';
import 'attendance_service.dart';

class PayrollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceService _attendanceService = AttendanceService();

  Future<Map<String, double>> getPayrollSummary(String businessId) async {
    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payroll')
        .get();

    double totalGross = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (final doc in snapshot.docs) {
      final p = PayrollModel.fromMap(doc.data(), doc.id);
      totalGross += p.grossPay;
      if (p.status == PayrollStatus.paid) totalPaid += p.netPay;
      if (p.status == PayrollStatus.pending) totalPending += p.netPay;
    }

    return {
      'totalGross': totalGross,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
    };
  }

  Stream<List<PayrollModel>> streamPayroll({
    required String businessId,
    String? employeeId,
  }) {
    var ref = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payroll')
        .orderBy('periodStart', descending: true);

    if (employeeId != null) {
      return _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('payroll')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('periodStart', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => PayrollModel.fromMap(d.data(), d.id)).toList());
    }

    return ref.snapshots().map((snap) =>
        snap.docs.map((d) => PayrollModel.fromMap(d.data(), d.id)).toList());
  }

  Future<double> calculateGrossSalary({
    required String businessId,
    required String employeeId,
    required double hourlyRate,
    required DateTime month,
  }) async {
    try {
      final start = _startOfMonth(month);
      final end = _endOfMonth(month);

      final attendanceRecords = await _attendanceService.getAttendanceForPeriod(
        businessId: businessId,
        startDate: start,
        endDate: end,
      );

      final employeeAttendance =
          attendanceRecords.where((att) => att.employeeId == employeeId).toList();

      if (employeeAttendance.isEmpty) {
        final workingDays = _calculateWorkingDaysInMonth(month);
        return hourlyRate * workingDays * 8.0;
      }

      num totalMinutes = 0;
      for (final att in employeeAttendance) {
        if (att.workedMinutes != null && att.workedMinutes! > 0) {
          totalMinutes += att.workedMinutes!;
        }
      }

      final totalHours = totalMinutes / 60.0;
      return hourlyRate * totalHours;
    } catch (e) {
      rethrow;
    }
  }

  Future<PayrollModel> generateAndSavePayroll({
    required String businessId,
    required String employeeId,
    required String employeeName,
    required double hourlyRate,
    required DateTime month,
    double deductions = 0.0,
    String? notes,
    String? paymentMethod,
  }) async {
    final grossPay = await calculateGrossSalary(
      businessId: businessId,
      employeeId: employeeId,
      hourlyRate: hourlyRate,
      month: month,
    );

    final netPay = grossPay - deductions;
    final periodStart = _startOfMonth(month);
    final periodEnd = _endOfMonth(month);

    final docRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payroll')
        .doc();

    final payroll = PayrollModel(
      id: docRef.id,
      businessId: businessId,
      employeeId: employeeId,
      employeeName: employeeName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      hourlyRate: hourlyRate,
      totalWorkedMinutes: 0,
      totalHours: hourlyRate > 0 ? (grossPay / hourlyRate) : 0,
      grossPay: grossPay,
      deductions: deductions,
      netPay: netPay,
      status: PayrollStatus.pending,
      paymentMethod: paymentMethod,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(payroll.toMap());
    return payroll;
  }

  Future<void> updatePayrollStatus({
    required String businessId,
    required String payrollId,
    required PayrollStatus newStatus,
    DateTime? paidAt,
  }) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payroll')
        .doc(payrollId)
        .update({
      'status': newStatus.name,
      'paidAt': paidAt?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<PayrollModel>> getEmployeePayrollHistory({
    required String businessId,
    required String employeeId,
    int limit = 12,
  }) async {
    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payroll')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('periodStart', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => PayrollModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<PayrollModel?> getLatestPayroll({
    required String businessId,
    required String employeeId,
  }) async {
    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payroll')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('periodStart', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PayrollModel.fromMap(
        snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  int _calculateWorkingDaysInMonth(DateTime month) {
    final start = _startOfMonth(month);
    final end = _endOfMonth(month);
    int count = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);
  DateTime _endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);
}
