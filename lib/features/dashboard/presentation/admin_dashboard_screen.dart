// lib/features/dashboard/presentation/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const AdminDashboardScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _dashboardService = DashboardService();
  final _notifService = NotificationService();

  Map<String, dynamic> _data = {};
  bool _isLoading = true;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await _dashboardService.getDashboardData(widget.businessId);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
          _lastRefresh = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get _bookings =>
      (_data['bookings'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _revenue =>
      (_data['revenue'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _employees =>
      (_data['employees'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _invoices =>
      (_data['invoices'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _attendance =>
      (_data['attendance'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _payroll =>
      (_data['payroll'] as Map<String, dynamic>?) ?? {};
  List<Map<String, dynamic>> get _recentActivity =>
      ((_data['recentActivity'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList()) ??
          [];
  List<Map<String, dynamic>> get _monthlyRevenue =>
      ((_data['monthlyRevenue'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList()) ??
          [];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: Colors.orange[700],
        child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              actions: [
                StreamBuilder<int>(
                  stream:
                      _notifService.streamUnreadCount(widget.businessId),
                  builder: (_, snap) {
                    final count = snap.data ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('$count',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboard),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[800]!, Colors.orange[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('$greeting 👋',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(widget.businessName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(now),
                            style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.75),
                                fontSize: 13),
                          ),
                          if (!_isLoading)
                            Text(
                              'Updated ${DateFormat('h:mm a').format(_lastRefresh)}',
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _isLoading
                  ? SizedBox(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: Colors.orange[700]),
                            const SizedBox(height: 16),
                            Text('Loading dashboard...',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Revenue Banner ───────────────
                          _revenueBanner(),
                          const SizedBox(height: 20),

                          // ─── Quick Stats Grid ─────────────
                          _sectionTitle('📊 Quick Overview'),
                          const SizedBox(height: 12),
                          _quickStatsGrid(),
                          const SizedBox(height: 20),

                          // ─── Today's Snapshot ─────────────
                          _sectionTitle('📅 Today\'s Snapshot'),
                          const SizedBox(height: 12),
                          _todaySnapshot(),
                          const SizedBox(height: 20),

                          // ─── Revenue Chart ────────────────
                          if (_monthlyRevenue.isNotEmpty) ...[
                            _sectionTitle('📈 Revenue — Last 6 Months'),
                            const SizedBox(height: 12),
                            _revenueChart(),
                            const SizedBox(height: 20),
                          ],

                          // ─── Alerts ───────────────────────
                          _buildAlerts(),

                          // ─── Recent Activity ──────────────
                          if (_recentActivity.isNotEmpty) ...[
                            _sectionTitle('🕐 Recent Activity'),
                            const SizedBox(height: 12),
                            _recentActivityList(),
                            const SizedBox(height: 20),
                          ],

                          // ─── Module Summary Cards ─────────
                          _sectionTitle('🗂 Module Summary'),
                          const SizedBox(height: 12),
                          _moduleSummaryCards(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Revenue Banner ──────────────────────────────────────────
  Widget _revenueBanner() {
    final monthRevenue = (_revenue['month'] as num?)?.toDouble() ?? 0;
    final todayRevenue = (_revenue['today'] as num?)?.toDouble() ?? 0;
    final totalRevenue = (_revenue['total'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Revenue',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          const SizedBox(height: 6),
          Text('\$${totalRevenue.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _bannerStat(
                    'This Month', '\$${monthRevenue.toStringAsFixed(2)}')),
            Container(width: 1, height: 32,
                color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
                child: _bannerStat(
                    'Today', '\$${todayRevenue.toStringAsFixed(2)}')),
            Container(width: 1, height: 32,
                color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
                child: _bannerStat('Bookings',
                    '${_bookings['total'] ?? 0} total')),
          ]),
        ],
      ),
    );
  }

  Widget _bannerStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      ]),
    );
  }

  // ─── Quick Stats Grid ─────────────────────────────────────────
  Widget _quickStatsGrid() {
    final stats = [
      {
        'label': 'Active\nEmployees',
        'value': '${_employees['active'] ?? 0}',
        'sub': 'of ${_employees['total'] ?? 0} total',
        'icon': Icons.people_outline,
        'color': Colors.teal,
      },
      {
        'label': 'Pending\nBookings',
        'value': '${_bookings['pending'] ?? 0}',
        'sub': '${_bookings['confirmed'] ?? 0} confirmed',
        'icon': Icons.calendar_today_outlined,
        'color': Colors.blue,
      },
      {
        'label': 'Overdue\nInvoices',
        'value': '${_invoices['overdue'] ?? 0}',
        'sub': '\$${((_invoices['outstanding'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} outstanding',
        'icon': Icons.warning_amber_outlined,
        'color': Colors.red,
      },
      {
        'label': 'Pending\nPayroll',
        'value': '${_payroll['pending'] ?? 0}',
        'sub': '\$${((_payroll['pendingAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} due',
        'icon': Icons.payments_outlined,
        'color': Colors.purple,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(s['icon'] as IconData, color: color, size: 22),
                  Text(s['value'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: color)),
                ],
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['label'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2)),
                Text(s['sub'] as String,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 10)),
              ]),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Today's Snapshot ─────────────────────────────────────────
  Widget _todaySnapshot() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: _snapshotItem('Today\'s\nBookings',
                '${_bookings['today'] ?? 0}', Colors.blue, Icons.event)),
            _divider(),
            Expanded(child: _snapshotItem('Present\nToday',
                '${_attendance['present'] ?? 0}', Colors.green, Icons.check_circle_outline)),
            _divider(),
            Expanded(child: _snapshotItem('Absent\nToday',
                '${_attendance['absent'] ?? 0}', Colors.red, Icons.cancel_outlined)),
            _divider(),
            Expanded(child: _snapshotItem('Late\nToday',
                '${_attendance['late'] ?? 0}', Colors.orange, Icons.schedule)),
          ]),
        ]),
      ),
    );
  }

  Widget _snapshotItem(String label, String value, Color color, IconData icon) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(color: Colors.grey[500], fontSize: 10, height: 1.2),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _divider() => Container(
      width: 1, height: 50, color: Colors.grey[200]);

  // ─── Revenue Chart ────────────────────────────────────────────
  Widget _revenueChart() {
    if (_monthlyRevenue.isEmpty) return const SizedBox.shrink();

    final maxRevenue = _monthlyRevenue
        .map((m) => (m['revenue'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);
    final safeMax = maxRevenue == 0 ? 1.0 : maxRevenue;
    final currentMonth = DateTime.now().month;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Max: \$${maxRevenue.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                Text(
                    'Total: \$${_monthlyRevenue.fold(0.0, (s, m) => s + ((m['revenue'] as num?)?.toDouble() ?? 0)).toStringAsFixed(0)}',
                    style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _monthlyRevenue.map((m) {
                  final revenue =
                      (m['revenue'] as num?)?.toDouble() ?? 0;
                  final pct = revenue / safeMax;
                  final isCurrent = (m['year'] as int?) == DateTime.now().year &&
                      _monthlyRevenue.last == m;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (revenue > 0)
                            Text('\$${revenue.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: isCurrent
                                        ? Colors.orange[700]
                                        : Colors.grey[500],
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: (pct * 90).clamp(4.0, 90.0),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.orange[700]
                                  : Colors.orange[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(m['month'] as String,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isCurrent
                                      ? Colors.orange[700]
                                      : Colors.grey[500],
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Alerts ───────────────────────────────────────────────────
  Widget _buildAlerts() {
    final alerts = <Map<String, dynamic>>[];

    final overdue = _invoices['overdue'] as int? ?? 0;
    final outstanding =
        (_invoices['outstanding'] as num?)?.toDouble() ?? 0;
    final pendingPayroll = _payroll['pending'] as int? ?? 0;
    final pendingPayrollAmt =
        (_payroll['pendingAmount'] as num?)?.toDouble() ?? 0;
    final pendingBookings = _bookings['pending'] as int? ?? 0;

    if (overdue > 0) {
      alerts.add({
        'icon': '⚠️',
        'text': '$overdue overdue invoice(s) — \$${outstanding.toStringAsFixed(2)} unpaid',
        'color': Colors.red,
      });
    }
    if (pendingPayroll > 0) {
      alerts.add({
        'icon': '💼',
        'text': '$pendingPayroll payroll record(s) pending — \$${pendingPayrollAmt.toStringAsFixed(2)} due',
        'color': Colors.orange,
      });
    }
    if (pendingBookings > 0) {
      alerts.add({
        'icon': '📅',
        'text': '$pendingBookings booking(s) awaiting confirmation',
        'color': Colors.blue,
      });
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('🚨 Action Required'),
        const SizedBox(height: 12),
        ...alerts.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (a['color'] as Color).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (a['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Text(a['icon'] as String,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(a['text'] as String,
                      style: TextStyle(
                          color: a['color'] as Color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            )),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Recent Activity ──────────────────────────────────────────
  Widget _recentActivityList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: _recentActivity.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final colorMap = {
              'blue': Colors.blue,
              'green': Colors.green,
              'orange': Colors.orange,
              'purple': Colors.purple,
            };
            final color = colorMap[item['color']] ?? Colors.grey;
            final isLast = i == _recentActivity.length - 1;

            return Column(children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(item['icon'] as String,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                title: Text(item['title'] as String,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(item['subtitle'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Text(
                  _timeAgo(item['time'] as String),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
                dense: true,
              ),
              if (!isLast)
                Divider(height: 1, indent: 60, color: Colors.grey[100]),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ─── Module Summary Cards ─────────────────────────────────────
  Widget _moduleSummaryCards() {
    final modules = [
      {
        'icon': '📅',
        'label': 'Bookings',
        'stats': [
          '${_bookings['total'] ?? 0} total',
          '${_bookings['completed'] ?? 0} completed',
        ],
        'color': Colors.blue,
      },
      {
        'icon': '🧾',
        'label': 'Invoices',
        'stats': [
          '${_invoices['total'] ?? 0} total',
          '${_invoices['paid'] ?? 0} paid',
        ],
        'color': Colors.orange,
      },
      {
        'icon': '👥',
        'label': 'Employees',
        'stats': [
          '${_employees['total'] ?? 0} total',
          '${_employees['active'] ?? 0} active',
        ],
        'color': Colors.teal,
      },
      {
        'icon': '✅',
        'label': 'Attendance',
        'stats': [
          '${_attendance['present'] ?? 0} present',
          '${_attendance['late'] ?? 0} late today',
        ],
        'color': Colors.green,
      },
      {
        'icon': '💼',
        'label': 'Payroll',
        'stats': [
          '${_payroll['pending'] ?? 0} pending',
          '\$${((_payroll['paidMonth'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} paid this month',
        ],
        'color': Colors.purple,
      },
      {
        'icon': '💰',
        'label': 'Payments',
        'stats': [
          '\$${((_revenue['month'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} this month',
          '\$${((_revenue['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} all time',
        ],
        'color': Colors.green,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < modules.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: _moduleSummaryCard(modules[i])),
                const SizedBox(width: 10),
                Expanded(
                    child: i + 1 < modules.length
                        ? _moduleSummaryCard(modules[i + 1])
                        : const SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _moduleSummaryCard(Map<String, dynamic> module) {
    final color = module['color'] as Color;
    final stats = module['stats'] as List<String>;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(module['icon'] as String,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(module['label'] as String,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        ...stats.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(children: [
                Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(s,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12)),
              ]),
            )),
      ]),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));

  String _timeAgo(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
