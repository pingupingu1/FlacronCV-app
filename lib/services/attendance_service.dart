import '../models/attendance_model.dart';
import 'firestore_service.dart';

class AttendanceService {
  static const String _collection = 'attendance';

  static Future<void> checkIn(AttendanceModel attendance) async {
    await FirestoreService.collection(_collection)
        .doc(attendance.id)
        .set(attendance.toMap());
  }

  static Future<void> checkOut(
      String attendanceId, DateTime time) async {
    await FirestoreService.collection(_collection)
        .doc(attendanceId)
        .update({'checkOut': time});
  }
}
