// lib/core/services/attendance_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore;

  AttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── Helpers ─────────────────────────────────────────────────
  String _toDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  CollectionReference _attendanceColl(String businessId) => _firestore
      .collection('businesses')
      .doc(businessId)
      .collection('attendance');

  // ─── Clock In ────────────────────────────────────────────────
  Future<String> clockIn({
    required String businessId,
    required String employeeId,
    required String employeeName,
    String? notes,
  }) async {
    final now = DateTime.now();
    final dateKey = _toDateKey(now);

    // Check if already clocked in today
    final existing = await getAttendanceForEmployee(
        businessId: businessId,
        employeeId: employeeId,
        date: now);

    if (existing != null) {
      if (existing.isClockedIn) throw Exception('Already clocked in today');
      if (existing.checkOutTime != null) throw Exception('Already completed for today');
    }

    final docRef = _attendanceColl(businessId).doc();

    // Determine status: late if after 9:30 AM
    final isLate = now.hour > 9 || (now.hour == 9 && now.minute > 30);

    final record = AttendanceModel(
      id: docRef.id,
      businessId: businessId,
      employeeId: employeeId,
      employeeName: employeeName,
      date: dateKey,
      checkInTime: now,
      status: isLate ? AttendanceStatus.late : AttendanceStatus.present,
      notes: notes,
      createdAt: now,
    );

    await docRef.set(record.toMap());
    return docRef.id;
  }

  // ─── Clock Out ───────────────────────────────────────────────
  Future<void> clockOut({
    required String businessId,
    required String employeeId,
    String? notes,
  }) async {
    final now = DateTime.now();
    final record = await getAttendanceForEmployee(
        businessId: businessId,
        employeeId: employeeId,
        date: now);

    if (record == null) throw Exception('No check-in found for today');
    if (!record.isClockedIn) throw Exception('Already clocked out');

    final workedMinutes =
        now.difference(record.checkInTime!).inMinutes;

    // Half day if less than 4 hours
    final status = workedMinutes < 240
        ? AttendanceStatus.halfDay
        : record.status;

    await _attendanceColl(businessId).doc(record.id).update({
      'checkOutTime': now.toIso8601String(),
      'workedMinutes': workedMinutes,
      'status': status.name,
      'updatedAt': now.toIso8601String(),
      if (notes != null) 'notes': notes,
    });
  }

  // ─── Get attendance for employee on a date ───────────────────
  Future<AttendanceModel?> getAttendanceForEmployee({
    required String businessId,
    required String employeeId,
    required DateTime date,
  }) async {
    final dateKey = _toDateKey(date);
    final snap = await _attendanceColl(businessId)
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isEqualTo: dateKey)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return AttendanceModel.fromMap(
        snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  // ─── Stream attendance for a date (all employees) ────────────
  Stream<List<AttendanceModel>> streamAttendanceForDate({
    required String businessId,
    required DateTime date,
  }) {
    final dateKey = _toDateKey(date);
    return _attendanceColl(businessId)
        .where('date', isEqualTo: dateKey)
        .orderBy('checkInTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AttendanceModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── Stream attendance for an employee (last 30 days) ────────
  Stream<List<AttendanceModel>> streamEmployeeAttendance({
    required String businessId,
    required String employeeId,
    int days = 30,
  }) {
    final from = DateTime.now().subtract(Duration(days: days));
    final fromKey = _toDateKey(from);

    return _attendanceColl(businessId)
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: fromKey)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AttendanceModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── Mark manual attendance ──────────────────────────────────
  Future<void> markAttendance({
    required String businessId,
    required String employeeId,
    required String employeeName,
    required DateTime date,
    required AttendanceStatus status,
    String? leaveReason,
    String? notes,
  }) async {
    final dateKey = _toDateKey(date);

    // Check if exists
    final existing = await getAttendanceForEmployee(
        businessId: businessId, employeeId: employeeId, date: date);

    if (existing != null) {
      await _attendanceColl(businessId).doc(existing.id).update({
        'status': status.name,
        'leaveReason': leaveReason,
        'notes': notes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      final docRef = _attendanceColl(businessId).doc();
      final record = AttendanceModel(
        id: docRef.id,
        businessId: businessId,
        employeeId: employeeId,
        employeeName: employeeName,
        date: dateKey,
        status: status,
        leaveReason: leaveReason,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await docRef.set(record.toMap());
    }
  }

  // ─── Get attendance summary for a date range ─────────────────
  Future<Map<String, dynamic>> getAttendanceSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
    String? employeeId,
  }) async {
    Query query = _attendanceColl(businessId)
        .where('date', isGreaterThanOrEqualTo: _toDateKey(from))
        .where('date', isLessThanOrEqualTo: _toDateKey(to));

    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    final snap = await query.get();
    final records = snap.docs
        .map((d) => AttendanceModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList();

    int present = 0, absent = 0, late = 0, halfDay = 0, leave = 0;
    int totalMinutes = 0;

    for (final r in records) {
      switch (r.status) {
        case AttendanceStatus.present: present++; break;
        case AttendanceStatus.absent:  absent++; break;
        case AttendanceStatus.late:    late++; break;
        case AttendanceStatus.halfDay: halfDay++; break;
        case AttendanceStatus.leave:   leave++; break;
      }
      totalMinutes += r.workedMinutes ?? 0;
    }

    return {
      'total': records.length,
      'present': present,
      'absent': absent,
      'late': late,
      'halfDay': halfDay,
      'leave': leave,
      'totalMinutes': totalMinutes,
      'avgMinutes': records.isEmpty ? 0 : totalMinutes ~/ records.length,
    };
  }

  // ─── Get monthly attendance for an employee ──────────────────
  Future<List<AttendanceModel>> getMonthlyAttendance({
    required String businessId,
    required String employeeId,
    required DateTime month,
  }) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);

    final snap = await _attendanceColl(businessId)
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: _toDateKey(from))
        .where('date', isLessThanOrEqualTo: _toDateKey(to))
        .get();

    return snap.docs
        .map((d) => AttendanceModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList();
  }
}
