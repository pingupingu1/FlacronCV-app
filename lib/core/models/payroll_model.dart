// lib/core/models/payroll_model.dart

import 'package:intl/intl.dart';

enum PayrollStatus { pending, processing, paid, failed }

class PayrollModel {
  final String id;
  final String businessId;
  final String employeeId;
  final String employeeName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double hourlyRate;
  final int totalWorkedMinutes;
  final double totalHours;
  final double grossPay;
  final double deductions;
  final double netPay;
  final PayrollStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? updatedAt;

  PayrollModel({
    required this.id,
    required this.businessId,
    required this.employeeId,
    required this.employeeName,
    required this.periodStart,
    required this.periodEnd,
    required this.hourlyRate,
    required this.totalWorkedMinutes,
    required this.totalHours,
    required this.grossPay,
    required this.deductions,
    required this.netPay,
    required this.status,
    this.notes,
    required this.createdAt,
    this.paidAt,
    this.updatedAt,
  });

  factory PayrollModel.fromMap(Map<String, dynamic> map, String id) {
    return PayrollModel(
      id: id,
      businessId: map['businessId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      periodStart: DateTime.parse(map['periodStart']),
      periodEnd: DateTime.parse(map['periodEnd']),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0,
      totalWorkedMinutes: map['totalWorkedMinutes'] ?? 0,
      totalHours: (map['totalHours'] as num?)?.toDouble() ?? 0,
      grossPay: (map['grossPay'] as num?)?.toDouble() ?? 0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0,
      netPay: (map['netPay'] as num?)?.toDouble() ?? 0,
      status: PayrollStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PayrollStatus.pending,
      ),
      notes: map['notes'],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'hourlyRate': hourlyRate,
        'totalWorkedMinutes': totalWorkedMinutes,
        'totalHours': totalHours,
        'grossPay': grossPay,
        'deductions': deductions,
        'netPay': netPay,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // ─── Helpers ─────────────────────────────────────────────────
  String get formattedGross => '\$${grossPay.toStringAsFixed(2)}';
  String get formattedNet => '\$${netPay.toStringAsFixed(2)}';
  String get formattedDeductions => '\$${deductions.toStringAsFixed(2)}';
  String get formattedHours => '${totalHours.toStringAsFixed(1)}h';

  String get periodLabel {
    final f = DateFormat('MMM d');
    return '${f.format(periodStart)} – ${f.format(periodEnd)}';
  }

  String get statusLabel {
    switch (status) {
      case PayrollStatus.pending:    return 'Pending';
      case PayrollStatus.processing: return 'Processing';
      case PayrollStatus.paid:       return 'Paid';
      case PayrollStatus.failed:     return 'Failed';
    }
  }

  PayrollModel copyWith({
    PayrollStatus? status,
    DateTime? paidAt,
    String? notes,
  }) {
    return PayrollModel(
      id: id,
      businessId: businessId,
      employeeId: employeeId,
      employeeName: employeeName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      hourlyRate: hourlyRate,
      totalWorkedMinutes: totalWorkedMinutes,
      totalHours: totalHours,
      grossPay: grossPay,
      deductions: deductions,
      netPay: netPay,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
      updatedAt: DateTime.now(),
    );
  }
}
