// lib/features/payments/presentation/record_payment_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/services/payment_service.dart';

class RecordPaymentScreen extends StatefulWidget {
  final String businessId;
  final String? bookingId;
  final String? invoiceId;
  final double? prefillAmount;
  final String? prefillName;

  const RecordPaymentScreen({
    super.key,
    required this.businessId,
    this.bookingId,
    this.invoiceId,
    this.prefillAmount,
    this.prefillName,
  });

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefillName != null) _nameCtrl.text = widget.prefillName!;
    if (widget.prefillAmount != null) {
      _amountCtrl.text = widget.prefillAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await _paymentService.recordManualPayment(
        businessId: widget.businessId,
        amount: double.parse(_amountCtrl.text),
        customerName: _nameCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        bookingId: widget.bookingId,
        invoiceId: widget.invoiceId,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        method: _method,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment recorded successfully! ✓'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💳', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              const Text('Record a Payment',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Manually log a payment received',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.red[700], fontSize: 13))),
                  ]),
                ),

              // Amount
              _label('Amount *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.attach_money,
                      color: Colors.grey[400], size: 20),
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.orange[700]!, width: 2)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  if (double.parse(v) <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment method
              _label('Payment Method *'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _methodChip(PaymentMethod.cash, '💵', 'Cash'),
                  const SizedBox(width: 8),
                  _methodChip(PaymentMethod.card, '💳', 'Card'),
                  const SizedBox(width: 8),
                  _methodChip(
                      PaymentMethod.bankTransfer, '🏦', 'Bank'),
                  const SizedBox(width: 8),
                  _methodChip(PaymentMethod.other, '📋', 'Other'),
                ],
              ),
              const SizedBox(height: 16),

              // Customer name
              _label('Customer Name *'),
              const SizedBox(height: 6),
              _field(_nameCtrl, 'Full name', Icons.person_outline,
                  required: true),

              // Email
              _label('Customer Email (optional)'),
              const SizedBox(height: 6),
              _field(_emailCtrl, 'email@example.com',
                  Icons.email_outlined,
                  type: TextInputType.emailAddress),

              // Description
              _label('Description / Note (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Haircut + Color, Invoice #123...',
                  prefixIcon:
                      Icon(Icons.notes, color: Colors.grey[400], size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.orange[700]!, width: 2)),
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Record Payment',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodChip(PaymentMethod method, String emoji, String label) {
    final selected = _method == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _method = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.orange[50] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? Colors.orange[700]! : Colors.grey[300]!,
                width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.orange[700] : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2)),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}
