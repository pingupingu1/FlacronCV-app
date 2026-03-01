// lib/core/services/dashboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_service.dart';

class DashboardService {
  final _db = FirebaseFirestore.instance;
  final _attendanceService = AttendanceService();

  // ─── Full dashboard snapshot ─────────────────────────────────
  Future<Map<String, dynamic>> getDashboardData(String businessId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final results = await Future.wait([
      _getBookingStats(businessId, monthStart, monthEnd),
      _getRevenueStats(businessId, monthStart, monthEnd),
      _getEmployeeStats(businessId),
      _getInvoiceStats(businessId, monthStart, monthEnd),
      _getAttendanceStats(businessId, now),
      _getPayrollStats(businessId, monthStart, monthEnd),
      _getRecentActivity(businessId),
      _getMonthlyRevenue(businessId),
    ]);

    return {
      'bookings': results[0],
      'revenue': results[1],
      'employees': results[2],
      'invoices': results[3],
      'attendance': results[4],
      'payroll': results[5],
      'recentActivity': results[6],
      'monthlyRevenue': results[7],
      'generatedAt': now.toIso8601String(),
    };
  }

  // ─── Booking stats ───────────────────────────────────────────
  Future<Map<String, dynamic>> _getBookingStats(
      String businessId, DateTime from, DateTime to) async {
    try {
      final snap = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('bookings')
          .get();

      int total = 0, pending = 0, confirmed = 0, completed = 0, today = 0;
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final dateStr = (data['appointmentDate'] ?? '').toString().substring(0, 10);
        total++;
        if (status == 'pending') pending++;
        if (status == 'confirmed') confirmed++;
        if (status == 'completed') completed++;
        if (dateStr == todayStr) today++;
      }

      return {
        'total': total,
        'pending': pending,
        'confirmed': confirmed,
        'completed': completed,
        'today': today,
      };
    } catch (_) {
      return {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'today': 0};
    }
  }

  // ─── Revenue stats ───────────────────────────────────────────
  Future<Map<String, dynamic>> _getRevenueStats(
      String businessId, DateTime from, DateTime to) async {
    try {
      final snap = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('payments')
          .where('state', isEqualTo: 'succeeded')
          .get();

      double total = 0, month = 0, today = 0;
      final now = DateTime.now();

      for (final doc in snap.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final createdAt = data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : null;

        total += amount;
        if (createdAt != null) {
          if (createdAt.year == now.year && createdAt.month == now.month) {
            month += amount;
          }
          if (createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day) {
            today += amount;
          }
        }
      }

      return {'total': total, 'month': month, 'today': today};
    } catch (_) {
      return {'total': 0.0, 'month': 0.0, 'today': 0.0};
    }
  }

  // ─── Employee stats ──────────────────────────────────────────
  Future<Map<String, dynamic>> _getEmployeeStats(String businessId) async {
    try {
      final snap = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('employees')
          .get();

      int active = 0, total = snap.docs.length;
      for (final doc in snap.docs) {
        if ((doc.data())['isActive'] == true) active++;
      }
      return {'total': total, 'active': active};
    } catch (_) {
      return {'total': 0, 'active': 0};
    }
  }

  // ─── Invoice stats ───────────────────────────────────────────
  Future<Map<String, dynamic>> _getInvoiceStats(
      String businessId, DateTime from, DateTime to) async {
    try {
      final snap = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('invoices')
          .get();

      int total = 0, paid = 0, overdue = 0, draft = 0;
      double outstanding = 0, monthRevenue = 0;
      final now = DateTime.now();

      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final invoiceTotal = (data['total'] as num?)?.toDouble() ?? 0;
        total++;

        if (status == 'paid') {
          paid++;
          final paidAt = data['paidAt'] != null
              ? DateTime.parse(data['paidAt'])
              : null;
          if (paidAt != null &&
              paidAt.year == now.year &&
              paidAt.month == now.month) {
            monthRevenue += invoiceTotal;
          }
        }
        if (status == 'overdue') {
          overdue++;
          outstanding += invoiceTotal;
        }
        if (status == 'sent') outstanding += invoiceTotal;
        if (status == 'draft') draft++;
      }

      return {
        'total': total,
        'paid': paid,
        'overdue': overdue,
        'draft': draft,
        'outstanding': outstanding,
        'monthRevenue': monthRevenue,
      };
    } catch (_) {
      return {
        'total': 0, 'paid': 0, 'overdue': 0, 'draft': 0,
        'outstanding': 0.0, 'monthRevenue': 0.0
      };
    }
  }

  // ─── Today's attendance ──────────────────────────────────────
  Future<Map<String, dynamic>> _getAttendanceStats(
      String businessId, DateTime date) async {
    try {
      final summary = await _attendanceService.getAttendanceSummary(
        businessId: businessId,
        from: date,
        to: date,
      );
      return summary;
    } catch (_) {
      return {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
    }
  }

  // ─── Payroll stats ───────────────────────────────────────────
  Future<Map<String, dynamic>> _getPayrollStats(
      String businessId, DateTime from, DateTime to) async {
    try {
      final snap = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('payroll')
          .get();

      int pending = 0;
      double pendingAmount = 0, paidMonth = 0;
      final now = DateTime.now();

      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final net = (data['netPay'] as num?)?.toDouble() ?? 0;

        if (status == 'pending') {
          pending++;
          pendingAmount += net;
        }
        if (status == 'paid') {
          final paidAt = data['paidAt'] != null
              ? DateTime.parse(data['paidAt'])
              : null;
          if (paidAt != null &&
              paidAt.year == now.year &&
              paidAt.month == now.month) {
            paidMonth += net;
          }
        }
      }

      return {
        'pending': pending,
        'pendingAmount': pendingAmount,
        'paidMonth': paidMonth,
      };
    } catch (_) {
      return {'pending': 0, 'pendingAmount': 0.0, 'paidMonth': 0.0};
    }
  }

  // ─── Recent activity (last 10 items across all collections) ──
  Future<List<Map<String, dynamic>>> _getRecentActivity(
      String businessId) async {
    final activity = <Map<String, dynamic>>[];

    try {
      // Recent bookings
      final bookings = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();
      for (final doc in bookings.docs) {
        final data = doc.data();
        activity.add({
          'type': 'booking',
          'icon': '📅',
          'title': 'New booking — ${data['customerName'] ?? 'Customer'}',
          'subtitle': data['serviceName'] ?? '',
          'time': data['createdAt'] ?? '',
          'color': 'blue',
        });
      }

      // Recent payments
      final payments = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();
      for (final doc in payments.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        activity.add({
          'type': 'payment',
          'icon': '💰',
          'title': 'Payment received — \$${amount.toStringAsFixed(2)}',
          'subtitle': data['customerName'] ?? '',
          'time': data['createdAt'] ?? '',
          'color': 'green',
        });
      }

      // Recent invoices
      final invoices = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('invoices')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();
      for (final doc in invoices.docs) {
        final data = doc.data();
        activity.add({
          'type': 'invoice',
          'icon': '📄',
          'title': 'Invoice ${data['invoiceNumber'] ?? ''} — ${data['customerName'] ?? ''}',
          'subtitle': data['status'] ?? '',
          'time': data['createdAt'] ?? '',
          'color': 'orange',
        });
      }

      // Sort by time descending
      activity.sort((a, b) => (b['time'] as String)
          .compareTo(a['time'] as String));

      return activity.take(8).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Monthly revenue (last 6 months) ─────────────────────────
  Future<List<Map<String, dynamic>>> _getMonthlyRevenue(
      String businessId) async {
    try {
      final now = DateTime.now();
      final months = <Map<String, dynamic>>[];

      final snap = await _db
          .collection('businesses')
          .doc(businessId)
          .collection('payments')
          .where('state', isEqualTo: 'succeeded')
          .get();

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        double revenue = 0;

        for (final doc in snap.docs) {
          final data = doc.data();
          final createdAt = data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : null;
          if (createdAt != null &&
              createdAt.year == month.year &&
              createdAt.month == month.month) {
            revenue += (data['amount'] as num?)?.toDouble() ?? 0;
          }
        }

        months.add({
          'month': _monthAbbr(month.month),
          'revenue': revenue,
          'year': month.year,
        });
      }

      return months;
    } catch (_) {
      return [];
    }
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}
