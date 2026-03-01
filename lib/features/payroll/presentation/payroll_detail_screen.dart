// lib/features/payroll/presentation/payroll_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/payroll_model.dart';
import '../../../core/services/payroll_service.dart';

class PayrollDetailScreen extends StatefulWidget {
  final PayrollModel payroll;
  final String businessId;
  const PayrollDetailScreen(
      {super.key, required this.payroll, required this.businessId});

  @override
  State<PayrollDetailScreen> createState() => _PayrollDetailScreenState();
}

class _PayrollDetailScreenState extends State<PayrollDetailScreen> {
  final _payrollService = PayrollService();
  late PayrollModel _payroll;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _payroll = widget.payroll;
  }

  Color get _statusColor {
    switch (_payroll.status) {
      case PayrollStatus.paid:       return Colors.green;
      case PayrollStatus.pending:    return Colors.orange;
      case PayrollStatus.processing: return Colors.blue;
      case PayrollStatus.failed:     return Colors.red;
    }
  }

  Future<void> _markPaid() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Paid?'),
        content: Text(
            'Mark ${_payroll.employeeName}\'s payroll of ${_payroll.formattedNet} as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _payrollService.markPaid(widget.businessId, _payroll.id);
      setState(() {
        _payroll = _payroll.copyWith(
            status: PayrollStatus.paid, paidAt: DateTime.now());
        _isUpdating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Payroll marked as paid ✓'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record?'),
        content: const Text('Delete this payroll record? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _payrollService.deletePayroll(widget.businessId, _payroll.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_payroll.employeeName),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_payroll.status == PayrollStatus.pending)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[700]!, Colors.orange[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Text(_payroll.formattedNet,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 42,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Net Pay', style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text(_payroll.statusLabel,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 8),
                Text(_payroll.periodLabel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),

            // Breakdown card
            _card('Pay Breakdown', [
              _row(Icons.access_time, 'Hours Worked', _payroll.formattedHours),
              _row(Icons.attach_money, 'Hourly Rate',
                  '\$${_payroll.hourlyRate.toStringAsFixed(2)}/hr'),
              const Divider(height: 16),
              _row(Icons.payments_outlined, 'Gross Pay',
                  _payroll.formattedGross),
              _row(Icons.remove_circle_outline, 'Deductions',
                  '- ${_payroll.formattedDeductions}',
                  valueColor: Colors.red[600]),
              const Divider(height: 8),
              _row(Icons.account_balance_wallet_outlined, 'Net Pay',
                  _payroll.formattedNet,
                  valueColor: Colors.green[600], bold: true),
            ]),
            const SizedBox(height: 12),

            // Period card
            _card('Pay Period', [
              _row(Icons.calendar_today, 'Period',
                  '${fmt.format(_payroll.periodStart)} – ${fmt.format(_payroll.periodEnd)}'),
              _row(Icons.person, 'Employee', _payroll.employeeName),
              _row(Icons.schedule, 'Generated', fmt.format(_payroll.createdAt)),
              if (_payroll.paidAt != null)
                _row(Icons.check_circle_outline, 'Paid On',
                    fmt.format(_payroll.paidAt!), valueColor: Colors.green[600]),
              if (_payroll.notes != null && _payroll.notes!.isNotEmpty)
                _row(Icons.notes, 'Notes', _payroll.notes!),
            ]),

            const SizedBox(height: 20),

            if (!_isUpdating) ...[
              if (_payroll.status == PayrollStatus.pending ||
                  _payroll.status == PayrollStatus.processing)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _markPaid,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Mark as Paid',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
            ] else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.orange[700], letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.orange[300]),
        const SizedBox(width: 10),
        Text('$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  fontSize: bold ? 15 : 13,
                  color: valueColor ?? Colors.black87),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }
}
