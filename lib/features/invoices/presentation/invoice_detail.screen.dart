// lib/features/invoices/presentation/invoice_detail_screen.dart
import 'package:flutter/material.dart';

import '../../../core/models/invoice_model.dart';
import '../../../core/services/invoice_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final String businessId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    required this.businessId,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _invoiceService = InvoiceService();
  late InvoiceModel _invoice;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  Color _statusColor(InvoiceStatus status) {
    return switch (status) {
      InvoiceStatus.draft     => Colors.grey,
      InvoiceStatus.sent      => Colors.blue,
      InvoiceStatus.paid      => Colors.green,
      InvoiceStatus.overdue   => Colors.red,
      InvoiceStatus.cancelled => Colors.red,
    };
  }

  Future<void> _updateStatus(InvoiceStatus status) async {
    setState(() => _isUpdating = true);
    try {
      await _invoiceService.updateStatus(
        widget.businessId,
        _invoice.id,
        status,
      );
      setState(() {
        _invoice = _invoice.copyWith(status: status);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice marked as ${status.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _markAsPaid() async {
    setState(() => _isUpdating = true);
    try {
      await _invoiceService.markAsPaid(
        widget.businessId,
        _invoice.id,
      );
      setState(() {
        _invoice = _invoice.copyWith(
          status: InvoiceStatus.paid,
          paidAt: DateTime.now(),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice marked as paid ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteInvoice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _invoiceService.deleteInvoice(
          widget.businessId,
          _invoice.id,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_invoice.status);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_invoice.invoiceNumber),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isUpdating ? null : _deleteInvoice,
            tooltip: 'Delete Invoice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _invoice.invoiceNumber,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _invoice.statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _invoice.formattedTotal,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Colors.orange[700],
                        ),
                      ),
                      Text(
                        _invoice.formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer info
            _buildInfoCard(
              title: 'Customer',
              children: [
                _buildInfoRow(Icons.person_outline, 'Name', _invoice.customerName),
                _buildInfoRow(Icons.phone_outlined, 'Phone', _invoice.customerPhone),
                if (_invoice.customerEmail != null && _invoice.customerEmail!.isNotEmpty)
                  _buildInfoRow(Icons.email_outlined, 'Email', _invoice.customerEmail!),
              ],
            ),
            const SizedBox(height: 16),

            // Line items
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 24),

                    // Table header
                    Row(
                      children: const [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'Qty',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'Price',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'Total',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Items
                    ..._invoice.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                item.description,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                '\$${item.unitPrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 24),

                    _buildTotalLine('Subtotal', _invoice.formattedSubtotal),
                    if (_invoice.taxRate > 0)
                      _buildTotalLine(
                        'Tax (${(_invoice.taxRate * 100).toInt()}%)',
                        _invoice.formattedTax,
                      ),
                    const SizedBox(height: 8),
                    _buildTotalLine(
                      'Total',
                      _invoice.formattedTotal,
                      isBold: true,
                      color: Colors.orange[700]!,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes (if any)
            if (_invoice.notes != null && _invoice.notes!.trim().isNotEmpty)
              _buildInfoCard(
                title: 'Notes',
                children: [
                  _buildInfoRow(Icons.notes_outlined, 'Note', _invoice.notes!),
                ],
              ),

            const SizedBox(height: 24),

            // Actions
            if (_invoice.status != InvoiceStatus.paid &&
                _invoice.status != InvoiceStatus.cancelled) ...[
              const Text(
                'Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (_invoice.status == InvoiceStatus.draft)
                _buildActionButton(
                  label: 'Mark as Sent',
                  icon: Icons.send_outlined,
                  color: Colors.blue,
                  onPressed: () => _updateStatus(InvoiceStatus.sent),
                ),

              if (_invoice.status == InvoiceStatus.sent ||
                  _invoice.status == InvoiceStatus.overdue) ...[
                _buildActionButton(
                  label: 'Mark as Paid',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onPressed: _markAsPaid,
                ),
                const SizedBox(height: 12),
              ],

              _buildActionButton(
                label: 'Cancel Invoice',
                icon: Icons.cancel_outlined,
                color: Colors.red,
                onPressed: () => _updateStatus(InvoiceStatus.cancelled),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalLine(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isUpdating ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}