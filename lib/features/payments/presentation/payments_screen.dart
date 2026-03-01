// lib/features/payments/presentation/payments_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/services/payment_service.dart';
import 'record_payment_screen.dart';
import 'payment_detail_screen.dart';

class PaymentsScreen extends StatefulWidget {
  final String businessId;
  const PaymentsScreen({super.key, required this.businessId});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  final _paymentService = PaymentService();
  late TabController _tabController;

  Map<String, double> _revenue = {
    'total': 0, 'month': 0, 'year': 0, 'today': 0
  };
  List<Map<String, dynamic>> _monthlyData = [];
  bool _loadingRevenue = true;
  PaymentState? _filterState;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRevenue();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRevenue() async {
    setState(() => _loadingRevenue = true);
    try {
      final r = await _paymentService.getRevenueSummary(widget.businessId);
      final m = await _paymentService.getMonthlyRevenue(widget.businessId);
      if (mounted) setState(() { _revenue = r; _monthlyData = m; _loadingRevenue = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRevenue = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRevenue),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.bar_chart, size: 18)),
            Tab(text: 'Transactions', icon: Icon(Icons.receipt_long, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordPaymentScreen(businessId: widget.businessId),
          ),
        ).then((_) => _loadRevenue()),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  // ─── Overview Tab ────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadRevenue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue cards
            Row(children: [
              Expanded(
                child: _revenueCard('Today', _revenue['today'] ?? 0,
                    Icons.today, Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _revenueCard('This Month', _revenue['month'] ?? 0,
                    Icons.calendar_month, Colors.green),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _revenueCard('This Year', _revenue['year'] ?? 0,
                    Icons.calendar_today, Colors.purple),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _revenueCard('All Time', _revenue['total'] ?? 0,
                    Icons.all_inclusive, Colors.orange),
              ),
            ]),

            const SizedBox(height: 24),

            // Mini bar chart
            const Text('Last 6 Months',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildBarChart(),

            const SizedBox(height: 24),

            // Quick stats
            const Text('Quick Stats',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            StreamBuilder<List<PaymentModel>>(
              stream: _paymentService.streamPayments(
                  businessId: widget.businessId),
              builder: (_, snap) {
                final payments = snap.data ?? [];
                final succeeded =
                    payments.where((p) => p.state == PaymentState.succeeded).length;
                final failed =
                    payments.where((p) => p.state == PaymentState.failed).length;
                final refunded =
                    payments.where((p) => p.state == PaymentState.refunded).length;
                final cardPay = payments
                    .where((p) =>
                        p.method == PaymentMethod.card &&
                        p.state == PaymentState.succeeded)
                    .length;
                final cashPay = payments
                    .where((p) =>
                        p.method == PaymentMethod.cash &&
                        p.state == PaymentState.succeeded)
                    .length;
                return Column(children: [
                  _statRow('Total Transactions', '${payments.length}'),
                  _statRow('Successful Payments', '$succeeded',
                      color: Colors.green),
                  _statRow('Failed Payments', '$failed',
                      color: failed > 0 ? Colors.red : null),
                  _statRow('Refunds', '$refunded'),
                  const Divider(),
                  _statRow('Card Payments', '$cardPay'),
                  _statRow('Cash Payments', '$cashPay'),
                ]);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _revenueCard(
      String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
          ]),
          const SizedBox(height: 10),
          _loadingRevenue
              ? Container(
                  height: 20,
                  width: 80,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4)))
              : Text('\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color)),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_monthlyData.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text('No payment data yet',
              style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    final maxAmount =
        _monthlyData.map((m) => m['amount'] as double).reduce((a, b) => a > b ? a : b);
    final barMax = maxAmount == 0 ? 1.0 : maxAmount;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyData.map((m) {
                final amount = m['amount'] as double;
                final ratio = amount / barMax;
                final isLast = m == _monthlyData.last;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (amount > 0)
                          Text(
                            '\$${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}k' : amount.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: ratio * 80,
                          decoration: BoxDecoration(
                            color: isLast
                                ? Colors.orange[700]
                                : Colors.orange[200],
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _monthlyData.map((m) {
              return Expanded(
                child: Text(m['month'] as String,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey[500]),
                    textAlign: TextAlign.center),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  // ─── Transactions Tab ────────────────────────────────────────
  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                _filterChip('Paid', PaymentState.succeeded),
                _filterChip('Pending', PaymentState.pending),
                _filterChip('Failed', PaymentState.failed),
                _filterChip('Refunded', PaymentState.refunded),
              ],
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<PaymentModel>>(
            stream: _paymentService.streamPayments(
              businessId: widget.businessId,
              filterState: _filterState,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final payments = snapshot.data ?? [];

              if (payments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No payments found',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Record your first payment',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: payments.length,
                itemBuilder: (_, i) => _paymentCard(payments[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, PaymentState? state) {
    final selected = _filterState == state;
    return GestureDetector(
      onTap: () => setState(() => _filterState = state),
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
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }

  Widget _paymentCard(PaymentModel payment) {
    Color stateColor;
    switch (payment.state) {
      case PaymentState.succeeded:  stateColor = Colors.green; break;
      case PaymentState.failed:     stateColor = Colors.red; break;
      case PaymentState.refunded:   stateColor = Colors.purple; break;
      case PaymentState.processing: stateColor = Colors.blue; break;
      default:                      stateColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentDetailScreen(
              payment: payment,
              businessId: widget.businessId,
            ),
          ),
        ).then((_) => _loadRevenue()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Method icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                payment.method == PaymentMethod.card
                    ? Icons.credit_card
                    : payment.method == PaymentMethod.cash
                        ? Icons.payments_outlined
                        : Icons.account_balance,
                color: stateColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    payment.description ?? payment.methodLabel,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, y • h:mm a')
                        .format(payment.createdAt),
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            // Amount + status
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(payment.formattedAmount,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: payment.state == PaymentState.refunded
                          ? Colors.purple
                          : Colors.black87)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(payment.stateLabel,
                    style: TextStyle(
                        color: stateColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
