class AttendanceModel {
  final String id;
  final String employeeId;
  final num? workedMinutes;

  AttendanceModel({required this.id, required this.employeeId, this.workedMinutes});

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      employeeId: map['employeeId'] ?? '',
      workedMinutes: map['workedMinutes'],
    );
  }
}