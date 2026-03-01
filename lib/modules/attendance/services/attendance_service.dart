import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final _db = FirebaseFirestore.instance;

  Future<List<AttendanceModel>> getAttendanceForPeriod({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snap = await _db
        .collection('businesses')
        .doc(businessId)
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();
    return snap.docs
        .map((d) => AttendanceModel.fromMap(d.data(), d.id))
        .toList();
  }
}
