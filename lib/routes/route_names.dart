/// Centralized route names for the entire app
/// Keeps navigation clean, consistent, and error-free
///
/// Usage: Navigator.pushNamed(context, RouteNames.dashboard);

class RouteNames {
  // ───────── Core / Startup ─────────
  static const String splash = '/';

  // ───────── Home / Landing Page ─────────
  // This is the main public homepage (rich content + small login button)
  static const String home = '/home';

  // ───────── Authentication ─────────
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ───────── Main App ─────────
  static const String dashboard = '/dashboard';

  // ───────── Business Setup ─────────
  static const String businessSetup = '/business-setup';
  static const String businessProfile = '/business-profile';
  static const String services = '/services';
  static const String businessHours = '/business-hours';

  // ───────── Bookings (Phase 3) ─────────
  static const String bookingCalendar = '/booking';
  static const String createBooking   = '/create-booking';
  static const String bookingDetail   = '/booking-detail';

  // ───────── Payments & Invoices (Phase 4) ─────────
  static const String payments      = '/payments';
  static const String invoiceList   = '/invoices';
  static const String invoiceDetail = '/invoice-detail';

  // ───────── Employees (Phase 5) ─────────
  static const String employees       = '/employees';         // List / overview of all employees
  static const String employeeCreate  = '/employee-create';   // Form to add a new employee
  static const String employeeDetail  = '/employee-detail';   // View / edit single employee
  static const String employeeDashboard = '/employee-dashboard'; // (was already here – kept)

  // ───────── Attendance & Payroll (Phase 5) ─────────
  static const String attendance = '/attendance';
  static const String payroll    = '/payroll';

  // ───────── AI Assistant (Phase 2) ─────────
  static const String aiChat = '/ai-chat';

  // ───────── Admin ─────────
  static const String adminDashboard = '/admin-dashboard';

  // ───────── Profile & Settings ─────────
  static const String profile       = '/profile';
  static const String settings      = '/settings';
  static const String notifications = '/notifications';
}