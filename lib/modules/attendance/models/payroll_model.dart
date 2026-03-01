class Payroll {
  final String employeeId;
  final int totalDays;
  final double totalSalary;
  final DateTime month;

  Payroll({
    required this.employeeId,
    required this.totalDays,
    required this.totalSalary,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'totalDays': totalDays,
      'totalSalary': totalSalary,
      'month': month,
    };
  }
}
