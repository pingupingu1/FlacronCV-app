// lib/features/payroll/presentation/payroll_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/payroll_model.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/payroll_service.dart';
import '../../../core/services/employee_service.dart';
import 'generate_payroll_screen.dart';
import 'payroll_detail_screen.dart';

class PayrollScreen extends StatefulWidget {
  final String businessId;
  const PayrollScreen({super.key, required this.businessId});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen>
    with SingleTickerProviderStateMixin {
  final _payrollService = PayrollService();
  final _employeeService = EmployeeService();
  late TabController _tabController;

  Map<String, double> _summary = {};
  bool _loadingSummary = false;
  PayrollStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final s = await _payrollService.getPayrollSummary(widget.businessId);
      if (mounted) setState(() { _summary = s; _loadingSummary = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Color _statusColor(PayrollStatus s) {
    switch (s) {
      case PayrollStatus.pending:    return Colors.orange;
      case PayrollStatus.processing: return Colors.blue;
      case PayrollStatus.paid:       return Colors.green;
      case PayrollStatus.failed:     return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payroll'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSummary),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.bar_chart, size: 18)),
            Tab(text: 'Records', icon: Icon(Icons.receipt_long, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GeneratePayrollScreen(businessId: widget.businessId),
          ),
        ).then((_) => _loadSummary()),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Run Payroll', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildRecordsTab()],
      ),
    );
  }

  // ─── Overview Tab ────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(children: [
            Expanded(child: _metricCard('This Month\nGross',
                _summary['monthGross'] ?? 0, Colors.orange, Icons.payments_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('This Month\nNet',
                _summary['monthNet'] ?? 0, Colors.green, Icons.account_balance_wallet_outlined)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _metricCard('Total Paid\nGross',
                _summary['totalGross'] ?? 0, Colors.blue, Icons.paid_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Total\nDeductions',
                _summary['totalDeductions'] ?? 0, Colors.red, Icons.remove_circle_outline)),
          ]),

          const SizedBox(height: 24),
          const Text('Payroll by Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          StreamBuilder<List<PayrollModel>>(
            stream: _payrollService.streamPayroll(businessId: widget.businessId),
            builder: (_, snap) {
              final records = snap.data ?? [];
              final counts = {for (final s in PayrollStatus.values)
                s: records.where((r) => r.status == s).length};
              final pendingTotal = records
                  .where((r) => r.status == PayrollStatus.pending)
                  .fold(0.0, (sum, r) => sum + r.netPay);

              return Column(children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      ...PayrollStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Container(width: 10, height: 10,
                              decoration: BoxDecoration(
                                  color: _statusColor(s), shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Text(s.name[0].toUpperCase() + s.name.substring(1),
                              style: const TextStyle(fontSize: 13)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: _statusColor(s).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('${counts[s] ?? 0}',
                                style: TextStyle(
                                    color: _statusColor(s),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                        ]),
                      )),
                    ]),
                  ),
                ),
                if (pendingTotal > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '\$${pendingTotal.toStringAsFixed(2)} in pending payroll awaiting payment',
                          style: TextStyle(color: Colors.orange[800], fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],
              ]);
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _metricCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 6,
            offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 11, height: 1.3)),
            const SizedBox(height: 4),
            _loadingSummary
                ? Container(height: 16, width: 60,
                    decoration: BoxDecoration(color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4)))
                : Text('\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ]),
        ),
      ]),
    );
  }

  // ─── Records Tab ─────────────────────────────────────────────
  Widget _buildRecordsTab() {
    return Column(
      children: [
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('All', null),
              _filterChip('Pending', PayrollStatus.pending),
              _filterChip('Paid', PayrollStatus.paid),
              _filterChip('Processing', PayrollStatus.processing),
              _filterChip('Failed', PayrollStatus.failed),
            ]),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PayrollModel>>(
            stream: _payrollService.streamPayroll(
              businessId: widget.businessId,
              filterStatus: _filterStatus,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = snap.data ?? [];
              if (records.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.payments_outlined, size: 72, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No payroll records yet',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Run your first payroll to get started',
                        style: TextStyle(color: Colors.grey[500])),
                  ]),
                );
              }

              // Group by period
              final Map<String, List<PayrollModel>> grouped = {};
              for (final r in records) {
                final key = r.periodLabel;
                grouped.putIfAbsent(key, () => []).add(r);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: grouped.keys.length,
                itemBuilder: (_, i) {
                  final period = grouped.keys.elementAt(i);
                  final periodRecords = grouped[period]!;
                  final totalNet = periodRecords.fold(0.0, (s, r) => s + r.netPay);
                  final allPaid = periodRecords.every((r) => r.status == PayrollStatus.paid);
                  final pendingIds = periodRecords
                      .where((r) => r.status == PayrollStatus.pending)
                      .map((r) => r.id)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(period,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Row(children: [
                            Text('\$${totalNet.toStringAsFixed(2)} net',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                            if (!allPaid && pendingIds.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _markAllPaid(pendingIds),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green[300]!),
                                  ),
                                  child: Text('Pay All',
                                      style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...periodRecords.map((r) => _payrollCard(r)),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, PayrollStatus? status) {
    final selected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.orange[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }

  Widget _payrollCard(PayrollModel payroll) {
    final color = _statusColor(payroll.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PayrollDetailScreen(
              payroll: payroll,
              businessId: widget.businessId,
            ),
          ),
        ).then((_) => _loadSummary()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Initials avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: Colors.orange[100], shape: BoxShape.circle),
              child: Center(
                child: Text(
                  payroll.employeeName.split(' ').map((p) => p[0]).take(2).join().toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: Colors.orange[700], fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(payroll.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text('${payroll.formattedHours} • ${payroll.formattedGross} gross',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(payroll.formattedNet,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(payroll.statusLabel,
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _markAllPaid(List<String> ids) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark All as Paid?'),
        content: Text('Mark ${ids.length} payroll record(s) as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Pay All'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _payrollService.markAllPaid(widget.businessId, ids);
    _loadSummary();
  }
}
