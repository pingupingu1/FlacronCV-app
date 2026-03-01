import 'package:flutter/foundation.dart'; // optional - for debugPrint if needed

enum AttendanceStatus { present, absent, late, halfDay, leave }

class AttendanceModel {
  final String id;
  final String businessId;
  final String employeeId;
  final String employeeName;
  final DateTime date;               // usually start of day (date only)
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final int? workedMinutes;          // auto-calculated on check-out
  final String? notes;
  final String? leaveReason;         // relevant when status == leave

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
    this.status = AttendanceStatus.present,
    this.workedMinutes,
    this.notes,
    this.leaveReason,
    required this.createdAt,
    this.updatedAt,
  });

  // ────────────────────────────────────────────────
  // Factories
  // ────────────────────────────────────────────────

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      checkInTime: _parseNullableDate(map['checkInTime']),
      checkOutTime: _parseNullableDate(map['checkOutTime']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => AttendanceStatus.present,
      ),
      workedMinutes: map['workedMinutes'] as int?,
      notes: map['notes'] as String?,
      leaveReason: map['leaveReason'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: _parseNullableDate(map['updatedAt']),
    );
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'date': date.toIso8601String().split('T')[0], // store only date part if desired
        'checkInTime': checkInTime?.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'status': status.name,
        'workedMinutes': workedMinutes,
        'notes': notes,
        'leaveReason': leaveReason,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // ────────────────────────────────────────────────
  // Helpers / Getters
  // ────────────────────────────────────────────────

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.leave:
        return 'Leave';
    }
  }

  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get formattedCheckIn => _formatTime(checkInTime);
  String get formattedCheckOut => _formatTime(checkOutTime);

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:$m $period';
  }

  String get formattedWorkedHours {
    if (workedMinutes == null || workedMinutes! <= 0) return '--';
    final hours = workedMinutes! ~/ 60;
    final mins = workedMinutes! % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
  bool get isComplete => isCheckedIn && isCheckedOut;

  // ────────────────────────────────────────────────
  // Copy with (enhanced)
  // ────────────────────────────────────────────────

  AttendanceModel copyWith({
    String? id,
    String? businessId,
    String? employeeId,
    String? employeeName,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceStatus? status,
    int? workedMinutes,
    String? notes,
    String? leaveReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      workedMinutes: workedMinutes ?? this.workedMinutes,
      notes: notes ?? this.notes,
      leaveReason: leaveReason ?? this.leaveReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}