import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollService {
  final _db = FirebaseFirestore.instance;

  Future<double> calculateSalary({
    required String employeeId,
    required double dailyRate,
    required DateTime month,
  }) async {
    final snapshot = await _db
        .collection('attendance')
        .where('employeeId', isEqualTo: employeeId)
        .get();

    int totalDays = snapshot.docs.length;
    return totalDays * dailyRate;
  }
}
