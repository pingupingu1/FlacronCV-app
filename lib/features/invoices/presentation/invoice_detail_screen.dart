// lib/features/invoices/presentation/invoice_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/services/invoice_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final dynamic invoice;
  final String? invoiceId;
  final String? businessId;

  const InvoiceDetailScreen({
    super.key,
    this.invoice,
    this.invoiceId,
    this.businessId,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _invoiceService = InvoiceService();
  InvoiceModel? _invoice;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice is InvoiceModel) {
      _invoice = widget.invoice as InvoiceModel;
      _isLoading = false;
    } else {
      _loadInvoice();
    }
  }

  Future<void> _loadInvoice() async {
    if (widget.businessId == null || widget.invoiceId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final inv = await _invoiceService.getInvoice(
        widget.businessId!, widget.invoiceId!);
    if (mounted) setState(() { _invoice = inv; _isLoading = false; });
  }

  String get _businessId =>
      _invoice?.businessId ?? widget.businessId ?? '';

  Color _statusColor(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:     return Colors.grey;
      case InvoiceStatus.sent:      return Colors.blue;
      case InvoiceStatus.paid:      return Colors.green;
      case InvoiceStatus.overdue:   return Colors.red;
      case InvoiceStatus.cancelled: return Colors.orange;
    }
  }

  Future<void> _updateStatus(InvoiceStatus newStatus) async {
    if (_invoice == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Mark as ${newStatus.name[0].toUpperCase()}${newStatus.name.substring(1)}?'),
        content: Text(
            'Update invoice ${_invoice!.invoiceNumber} to ${newStatus.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _statusColor(newStatus),
                foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _invoiceService.updateStatus(
        businessId: _businessId,
        invoiceId: _invoice!.id,
        status: newStatus,
      );
      setState(() {
        _invoice = _invoice!.copyWith(
            status: newStatus, updatedAt: DateTime.now());
        _isUpdating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Invoice marked as ${newStatus.name}'),
          backgroundColor: _statusColor(newStatus),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteInvoice() async {
    if (_invoice == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Invoice?'),
        content: Text(
            'Delete ${_invoice!.invoiceNumber}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _invoiceService.deleteInvoice(_businessId, _invoice!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Invoice not found')),
      );
    }

    final inv = _invoice!;
    final statusColor = _statusColor(inv.status);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(inv.invoiceNumber),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (inv.status == InvoiceStatus.draft)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteInvoice,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header card
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(inv.invoiceNumber,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Text(inv.statusLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(inv.formattedTotal,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Issued ${DateFormat('MMMM d, y').format(inv.date)}${inv.dueDate != null ? ' · Due ${DateFormat('MMM d').format(inv.dueDate!)}' : ''}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer
            _card('Bill To', [
              _row(Icons.person, 'Name', inv.customerName),
              _row(Icons.phone, 'Phone', inv.customerPhone),
              if (inv.customerEmail != null)
                _row(Icons.email, 'Email', inv.customerEmail!),
            ]),
            const SizedBox(height: 12),

            // Line items
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[700],
                            letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    // Header
                    Row(children: [
                      const Expanded(
                          flex: 3,
                          child: Text('Description',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600))),
                      const Text('Qty',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      const Text('Price',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const Divider(height: 16),
                    // Items
                    ...inv.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Expanded(
                                flex: 3,
                                child: Text(item.description,
                                    style: const TextStyle(
                                        fontSize: 13))),
                            Text('${item.quantity}',
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 16),
                            Text(
                                '\$${item.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 16),
                            Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ]),
                        )),
                    const Divider(height: 16),
                    // Totals
                    _totalRow('Subtotal', inv.formattedSubtotal),
                    _totalRow(
                        'Tax (${(inv.taxRate * 100).toStringAsFixed(0)}%)',
                        inv.formattedTax),
                    const Divider(height: 8),
                    _totalRow('Total', inv.formattedTotal,
                        bold: true, large: true),
                    if (inv.status == InvoiceStatus.paid &&
                        inv.paidAt != null) ...[
                      const Divider(height: 8),
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paid On',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                                DateFormat('MMM d, y')
                                    .format(inv.paidAt!),
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ]),
                    ],
                  ],
                ),
              ),
            ),

            if (inv.notes != null && inv.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _card('Notes', [
                Text(inv.notes!,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.5)),
              ]),
            ],

            const SizedBox(height: 20),

            // Action buttons
            if (!_isUpdating) ...[
              if (inv.status == InvoiceStatus.draft) ...[
                _actionBtn('Mark as Sent', Icons.send_outlined,
                    Colors.blue,
                    () => _updateStatus(InvoiceStatus.sent)),
                const SizedBox(height: 8),
              ],
              if (inv.status == InvoiceStatus.sent ||
                  inv.status == InvoiceStatus.overdue) ...[
                _actionBtn('Mark as Paid', Icons.check_circle_outline,
                    Colors.green,
                    () => _updateStatus(InvoiceStatus.paid)),
                const SizedBox(height: 8),
              ],
              if (inv.status != InvoiceStatus.paid &&
                  inv.status != InvoiceStatus.cancelled)
                _actionBtn('Cancel Invoice', Icons.cancel_outlined,
                    Colors.red,
                    () => _updateStatus(InvoiceStatus.cancelled)),
            ] else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange[700],
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.orange[300]),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _totalRow(String label, String value,
      {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: large ? 15 : 13,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal,
                    color: bold ? Colors.black : Colors.grey[700])),
            Text(value,
                style: TextStyle(
                    fontSize: large ? 18 : 13,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.w500,
                    color: bold
                        ? Colors.orange[700]
                        : Colors.black87)),
          ]),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
