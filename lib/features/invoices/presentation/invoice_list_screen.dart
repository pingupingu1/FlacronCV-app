// lib/features/invoices/presentation/invoice_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/services/invoice_service.dart';
import 'invoice_detail_screen.dart';
import 'create_invoice_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  final String businessId;
  const InvoiceListScreen({super.key, required this.businessId});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  final _invoiceService = InvoiceService();
  late TabController _tabController;
  InvoiceStatus? _filterStatus;

  Map<String, double> _revenue = {'total': 0, 'month': 0, 'year': 0};
  bool _loadingRevenue = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRevenue();
    _invoiceService.checkOverdue(widget.businessId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRevenue() async {
    setState(() => _loadingRevenue = true);
    try {
      final r = await _invoiceService.getRevenueSummary(widget.businessId);
      if (mounted) setState(() { _revenue = r; _loadingRevenue = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRevenue = false);
    }
  }

  Color _statusColor(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:     return Colors.grey;
      case InvoiceStatus.sent:      return Colors.blue;
      case InvoiceStatus.paid:      return Colors.green;
      case InvoiceStatus.overdue:   return Colors.red;
      case InvoiceStatus.cancelled: return Colors.orange;
    }
  }

  IconData _statusIcon(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:     return Icons.edit_outlined;
      case InvoiceStatus.sent:      return Icons.send_outlined;
      case InvoiceStatus.paid:      return Icons.check_circle_outline;
      case InvoiceStatus.overdue:   return Icons.warning_amber_outlined;
      case InvoiceStatus.cancelled: return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadRevenue),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.bar_chart, size: 18)),
            Tab(text: 'Invoices', icon: Icon(Icons.receipt_long, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CreateInvoiceScreen(businessId: widget.businessId),
          ),
        ).then((_) => _loadRevenue()),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildInvoicesTab(),
        ],
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
          // Revenue cards
          Row(children: [
            Expanded(
                child: _revenueCard('This Month',
                    _revenue['month'] ?? 0, Icons.calendar_month, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(
                child: _revenueCard('This Year',
                    _revenue['year'] ?? 0, Icons.calendar_today, Colors.purple)),
          ]),
          const SizedBox(height: 10),
          _revenueCard('Total Revenue', _revenue['total'] ?? 0,
              Icons.account_balance_wallet, Colors.orange,
              wide: true),

          const SizedBox(height: 24),
          const Text('Invoice Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          // Status breakdown
          StreamBuilder<List<InvoiceModel>>(
            stream: _invoiceService.streamInvoices(
                businessId: widget.businessId),
            builder: (_, snap) {
              final invoices = snap.data ?? [];
              final counts = {
                for (final s in InvoiceStatus.values)
                  s: invoices.where((i) => i.status == s).length
              };
              final overdueAmount = invoices
                  .where((i) => i.status == InvoiceStatus.overdue)
                  .fold(0.0, (sum, i) => sum + i.total);
              final unpaidAmount = invoices
                  .where((i) =>
                      i.status == InvoiceStatus.sent ||
                      i.status == InvoiceStatus.overdue)
                  .fold(0.0, (sum, i) => sum + i.total);

              return Column(children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      ...InvoiceStatus.values.map((s) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Icon(_statusIcon(s),
                                  color: _statusColor(s), size: 18),
                              const SizedBox(width: 10),
                              Text(s.name[0].toUpperCase() +
                                      s.name.substring(1),
                                  style: const TextStyle(fontSize: 13)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(s)
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
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
                const SizedBox(height: 12),
                // Alerts
                if (overdueAmount > 0)
                  _alertBanner(
                    icon: Icons.warning_amber,
                    color: Colors.red,
                    text:
                        '\$${overdueAmount.toStringAsFixed(2)} overdue — ${counts[InvoiceStatus.overdue]} invoice(s) past due date',
                  ),
                if (unpaidAmount > 0)
                  _alertBanner(
                    icon: Icons.info_outline,
                    color: Colors.blue,
                    text:
                        '\$${unpaidAmount.toStringAsFixed(2)} outstanding — awaiting payment',
                  ),
              ]);
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _revenueCard(String label, double amount, IconData icon, Color color,
      {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style:
                    TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
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
          ]),
        ],
      ),
    );
  }

  Widget _alertBanner(
      {required IconData icon,
      required Color color,
      required String text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ─── Invoices Tab ────────────────────────────────────────────
  Widget _buildInvoicesTab() {
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
                _filterChip('Draft', InvoiceStatus.draft),
                _filterChip('Sent', InvoiceStatus.sent),
                _filterChip('Paid', InvoiceStatus.paid),
                _filterChip('Overdue', InvoiceStatus.overdue),
                _filterChip('Cancelled', InvoiceStatus.cancelled),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<InvoiceModel>>(
            stream: _invoiceService.streamInvoices(
              businessId: widget.businessId,
              filterStatus: _filterStatus,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final invoices = snap.data ?? [];
              if (invoices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No invoices yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Create your first invoice',
                          style:
                              TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: invoices.length,
                itemBuilder: (_, i) => _invoiceCard(invoices[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, InvoiceStatus? status) {
    final selected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

  Widget _invoiceCard(InvoiceModel invoice) {
    final color = _statusColor(invoice.status);
    final isOverdue = invoice.status == InvoiceStatus.overdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: isOverdue ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(
              invoice: invoice,
              businessId: widget.businessId,
            ),
          ),
        ).then((_) => _loadRevenue()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Number badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(_statusIcon(invoice.status),
                    color: color, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(invoice.invoiceNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(invoice.statusLabel,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(invoice.customerName,
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 13)),
                  Text(
                    invoice.dueDate != null
                        ? 'Due ${DateFormat('MMM d').format(invoice.dueDate!)}'
                        : invoice.formattedDate,
                    style: TextStyle(
                        color: isOverdue
                            ? Colors.red
                            : Colors.grey[500],
                        fontSize: 12,
                        fontWeight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal),
                  ),
                ],
              ),
            ),
            // Amount
            Text(invoice.formattedTotal,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: invoice.status == InvoiceStatus.paid
                        ? Colors.green
                        : Colors.black87)),
          ]),
        ),
      ),
    );
  }
}
