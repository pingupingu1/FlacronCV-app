// lib/features/payments/presentation/payment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/services/payment_service.dart';

class PaymentDetailScreen extends StatefulWidget {
  final PaymentModel payment;
  final String businessId;
  const PaymentDetailScreen(
      {super.key, required this.payment, required this.businessId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _paymentService = PaymentService();
  late PaymentModel _payment;
  bool _isRefunding = false;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
  }

  Color get _stateColor {
    switch (_payment.state) {
      case PaymentState.succeeded:  return Colors.green;
      case PaymentState.failed:     return Colors.red;
      case PaymentState.refunded:   return Colors.purple;
      case PaymentState.processing: return Colors.blue;
      default:                      return Colors.orange;
    }
  }

  Future<void> _markRefunded() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Refunded?'),
        content: Text(
            'Mark this ${_payment.formattedAmount} payment as refunded?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white),
            child: const Text('Mark Refunded'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isRefunding = true);
    try {
      await _paymentService.markRefunded(
          widget.businessId, _payment.id);
      setState(() {
        _payment = PaymentModel(
          id: _payment.id,
          businessId: _payment.businessId,
          bookingId: _payment.bookingId,
          invoiceId: _payment.invoiceId,
          amount: _payment.amount,
          currency: _payment.currency,
          method: _payment.method,
          state: PaymentState.refunded,
          stripePaymentIntentId: _payment.stripePaymentIntentId,
          customerName: _payment.customerName,
          customerEmail: _payment.customerEmail,
          description: _payment.description,
          createdAt: _payment.createdAt,
          updatedAt: DateTime.now(),
        );
        _isRefunding = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment marked as refunded'),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isRefunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Amount hero
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
                Text(_payment.formattedAmount,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _stateColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(_payment.stateLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMMM d, y • h:mm a')
                      .format(_payment.createdAt),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Payment info
            _card('Payment Info', [
              _row(Icons.payments_outlined, 'Method',
                  _payment.methodLabel),
              _row(Icons.currency_exchange, 'Currency',
                  _payment.currency.toUpperCase()),
              if (_payment.description != null)
                _row(Icons.notes, 'Description', _payment.description!),
              if (_payment.stripePaymentIntentId != null)
                _row(Icons.receipt, 'Stripe ID',
                    _payment.stripePaymentIntentId!,
                    copyable: true),
            ]),
            const SizedBox(height: 12),

            // Customer info
            _card('Customer', [
              _row(Icons.person, 'Name', _payment.customerName),
              if (_payment.customerEmail != null)
                _row(Icons.email, 'Email', _payment.customerEmail!),
            ]),
            const SizedBox(height: 12),

            // References
            if (_payment.bookingId != null || _payment.invoiceId != null)
              _card('Linked To', [
                if (_payment.bookingId != null)
                  _row(Icons.calendar_today, 'Booking',
                      _payment.bookingId!,
                      copyable: true),
                if (_payment.invoiceId != null)
                  _row(Icons.receipt_long, 'Invoice',
                      _payment.invoiceId!,
                      copyable: true),
              ]),

            const SizedBox(height: 20),

            // Refund action
            if (_payment.state == PaymentState.succeeded) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isRefunding ? null : _markRefunded,
                  icon: _isRefunding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.purple))
                      : const Icon(Icons.undo, color: Colors.purple, size: 18),
                  label: const Text('Mark as Refunded',
                      style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.purple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> rows) {
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
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.orange[300]),
        const SizedBox(width: 10),
        Text('$label:',
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis),
              ),
              if (copyable) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  child: Icon(Icons.copy,
                      size: 14, color: Colors.grey[400]),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}
