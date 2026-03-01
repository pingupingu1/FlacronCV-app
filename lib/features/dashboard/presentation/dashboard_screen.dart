// lib/features/dashboard/presentation/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard_screen.dart';
import '../../bookings/presentation/booking_calendar_screen.dart';
import '../../invoices/presentation/invoice_list_screen.dart';
import '../../employees/presentation/employee_list_screen.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../payroll/presentation/payroll_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../../core/services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const DashboardScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _notifService = NotificationService();
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardScreen(
        businessId: widget.businessId,
        businessName: widget.businessName,
      ),
      BookingCalendarScreen(businessId: widget.businessId),
      InvoiceListScreen(businessId: widget.businessId),
      EmployeeListScreen(businessId: widget.businessId),
      _MoreScreen(
        businessId: widget.businessId,
        businessName: widget.businessName,
        onNavigate: (index) => setState(() => _currentIndex = index),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -2))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.orange[700],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Bookings',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Invoices',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Team',
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<int>(
                stream: _notifService
                    .streamUnreadCount(widget.businessId),
                builder: (_, snap) {
                  final count = snap.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.grid_view_outlined),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text('$count',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              activeIcon: const Icon(Icons.grid_view),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── More Screen ──────────────────────────────────────────────────
class _MoreScreen extends StatelessWidget {
  final String businessId;
  final String businessName;
  final void Function(int) onNavigate;

  const _MoreScreen({
    required this.businessId,
    required this.businessName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[700]!, Colors.orange[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      businessName.isNotEmpty
                          ? businessName[0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(businessName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? '',
                          style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.8),
                              fontSize: 13),
                        ),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            _groupTitle('Management'),
            _menuItem(context, Icons.event_available_outlined,
                'Attendance', Colors.green, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AttendanceScreen(businessId: businessId)));
            }),
            _menuItem(context, Icons.payments_outlined,
                'Payroll', Colors.purple, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PayrollScreen(businessId: businessId)));
            }),
            _menuItem(context, Icons.notifications_outlined,
                'Notifications', Colors.orange,
                () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NotificationsScreen(
                          businessId: businessId)));
            },
                badge: StreamBuilder<int>(
                  stream: NotificationService()
                      .streamUnreadCount(businessId),
                  builder: (_, snap) {
                    final count = snap.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    );
                  },
                )),

            const SizedBox(height: 8),
            _groupTitle('Quick Nav'),
            _menuItem(context, Icons.dashboard_outlined,
                'Dashboard', Colors.orange[700]!, () => onNavigate(0)),
            _menuItem(context, Icons.calendar_month_outlined,
                'Bookings', Colors.blue, () => onNavigate(1)),
            _menuItem(context, Icons.receipt_long_outlined,
                'Invoices', Colors.orange, () => onNavigate(2)),
            _menuItem(context, Icons.people_outline,
                'Employees', Colors.teal, () => onNavigate(3)),

            const SizedBox(height: 8),
            _groupTitle('Account'),
            _menuItem(context, Icons.logout_outlined,
                'Sign Out', Colors.red, () => _confirmSignOut(context)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _groupTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    Widget? badge,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (badge != null) ...[badge, const SizedBox(width: 8)],
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ]),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
