import '../ui/attendance_screen.dart';
import '../ui/payroll_screen.dart';

final attendanceRoutes = {
  '/attendance': (context) => const AttendanceScreen(businessId: ''),
  '/payroll': (context) => const PayrollScreen(),
};
