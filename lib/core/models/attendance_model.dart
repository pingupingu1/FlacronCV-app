// lib/core/models/attendance_model.dart

enum AttendanceStatus { present, absent, late, halfDay, leave }

class AttendanceModel {
  final String id;
  final String businessId;
  final String employeeId;
  final String employeeName;
  final String date;           // Stored as YYYY-MM-DD string
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final int? workedMinutes;    // Calculated from check-in/out
  final String? notes;
  final String? leaveReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceModel({
    required this.id,
    required this.businessId,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.workedMinutes,
    this.notes,
    this.leaveReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      businessId: map['businessId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      date: map['date'] ?? '',
      checkInTime: map['checkInTime'] != null
          ? DateTime.parse(map['checkInTime'])
          : null,
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'])
          : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      workedMinutes: map['workedMinutes'],
      notes: map['notes'],
      leaveReason: map['leaveReason'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'date': date,
        'checkInTime': checkInTime?.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'status': status.name,
        'workedMinutes': workedMinutes,
        'notes': notes,
        'leaveReason': leaveReason,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // ─── Helpers ─────────────────────────────────────────────────
  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent:  return 'Absent';
      case AttendanceStatus.late:    return 'Late';
      case AttendanceStatus.halfDay: return 'Half Day';
      case AttendanceStatus.leave:   return 'Leave';
    }
  }

  String get formattedCheckIn {
    if (checkInTime == null) return '--';
    final h = checkInTime!.hour;
    final m = checkInTime!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String get formattedCheckOut {
    if (checkOutTime == null) return '--';
    final h = checkOutTime!.hour;
    final m = checkOutTime!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String get formattedWorkedHours {
    if (workedMinutes == null) return '--';
    final h = workedMinutes! ~/ 60;
    final m = workedMinutes! % 60;
    return '${h}h ${m}m';
  }

  bool get isClockedIn => checkInTime != null && checkOutTime == null;

  AttendanceModel copyWith({
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceStatus? status,
    int? workedMinutes,
    String? notes,
  }) {
    return AttendanceModel(
      id: id,
      businessId: businessId,
      employeeId: employeeId,
      employeeName: employeeName,
      date: date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      workedMinutes: workedMinutes ?? this.workedMinutes,
      notes: notes ?? this.notes,
      leaveReason: leaveReason,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
