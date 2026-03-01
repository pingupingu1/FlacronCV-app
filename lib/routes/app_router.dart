// D:\FlacronCV\lib\routes\app_router.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/home/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/ai/presentation/ai_assistant_screen.dart';
import '../features/bookings/presentation/booking_calendar_screen.dart';
import '../features/payments/presentation/payments_screen.dart';
import '../features/invoices/presentation/invoice_list_screen.dart';
import '../features/employees/presentation/employees_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/payroll/presentation/payroll_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    // Public routes — no businessId needed
    switch (settings.name) {
      case '/':         return _go(const WelcomeScreen());
      case '/login':    return _go(const LoginScreen());
      case '/register': return _go(const RegisterScreen());
    }

    // Protected routes — resolve businessId + businessName first
    return _go(_BusinessIdResolver(routeName: settings.name ?? '/'));
  }

  static MaterialPageRoute _go(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}

/// Fetches businessId AND businessName from Firestore, then renders the screen.
class _BusinessIdResolver extends StatelessWidget {
  final String routeName;
  const _BusinessIdResolver({required this.routeName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerId', isEqualTo: user.uid)
          .limit(1)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No business found. Please complete setup.')),
          );
        }

        final doc = snap.data!.docs.first;
        final businessId = doc.id;
        final data = doc.data() as Map<String, dynamic>;
        final businessName = (data['name'] ?? data['businessName'] ?? 'My Business') as String;

        return _buildScreen(routeName, businessId, businessName);
      },
    );
  }

  Widget _buildScreen(String route, String businessId, String businessName) {
    switch (route) {
      case '/dashboard':
        return DashboardScreen(businessId: businessId, businessName: businessName);
      case '/ai-assistant':
        return AiAssistantScreen(businessId: businessId);
      case '/bookings':
        return BookingCalendarScreen(businessId: businessId);
      case '/payments':
        return PaymentsScreen(businessId: businessId);
      case '/invoices':
        return InvoiceListScreen(businessId: businessId);
      case '/employees':
        return EmployeesScreen(businessId: businessId);
      case '/attendance':
        return AttendanceScreen(businessId: businessId);
      case '/payroll':
        return PayrollScreen(businessId: businessId);
      case '/notifications':
        return NotificationsScreen(businessId: businessId);
      default:
        return const WelcomeScreen();
    }
  }
}
