// lib/features/invoices/presentation/create_invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/services/invoice_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String businessId;
  final String? prefillCustomerName;
  final String? prefillCustomerPhone;
  final String? prefillCustomerEmail;
  final String? bookingId;

  const CreateInvoiceScreen({
    super.key,
    required this.businessId,
    this.prefillCustomerName,
    this.prefillCustomerPhone,
    this.prefillCustomerEmail,
    this.bookingId,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _invoiceService = InvoiceService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<_LineItem> _items = [_LineItem()];
  double _taxRate = 0.0;
  DateTime? _dueDate;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefillCustomerName != null)
      _nameCtrl.text = widget.prefillCustomerName!;
    if (widget.prefillCustomerPhone != null)
      _phoneCtrl.text = widget.prefillCustomerPhone!;
    if (widget.prefillCustomerEmail != null)
      _emailCtrl.text = widget.prefillCustomerEmail!;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);
  double get _taxAmount => _subtotal * _taxRate;
  double get _total => _subtotal + _taxAmount;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty || _items.every((i) => i.description.isEmpty)) {
      setState(() => _error = 'Add at least one line item');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = _items
          .where((i) => i.description.isNotEmpty)
          .map((i) => InvoiceItemModel(
                description: i.description,
                quantity: i.qty,
                unitPrice: i.price,
              ))
          .toList();

      await _invoiceService.createInvoice(
        businessId: widget.businessId,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        bookingId: widget.bookingId,
        items: items,
        taxRate: _taxRate,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        dueDate: _dueDate,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invoice created successfully! ✓'),
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.orange[700]!),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('New Invoice'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text('Create',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline,
                        color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 13))),
                  ]),
                ),

              // Customer section
              _sectionTitle('👤 Customer'),
              _field(_nameCtrl, 'Customer Name *', Icons.person_outline,
                  required: true),
              _field(_phoneCtrl, 'Phone *', Icons.phone_outlined,
                  required: true, type: TextInputType.phone),
              _field(_emailCtrl, 'Email (optional)',
                  Icons.email_outlined,
                  type: TextInputType.emailAddress),

              const SizedBox(height: 8),
              _sectionTitle('📋 Line Items'),
              const SizedBox(height: 8),

              // Line items
              ..._items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return _buildLineItem(i, item);
              }),

              TextButton.icon(
                onPressed: () =>
                    setState(() => _items.add(_LineItem())),
                icon: Icon(Icons.add, color: Colors.orange[700]),
                label: Text('Add Line Item',
                    style: TextStyle(color: Colors.orange[700])),
              ),

              const SizedBox(height: 8),
              _sectionTitle('🧾 Totals & Tax'),
              const SizedBox(height: 12),

              // Tax rate
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax Rate',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text('${(_taxRate * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ]),
                    Slider(
                      value: _taxRate,
                      min: 0,
                      max: 0.25,
                      divisions: 25,
                      activeColor: Colors.orange[700],
                      onChanged: (v) =>
                          setState(() => _taxRate = v),
                    ),
                    const Divider(),
                    _totalRow('Subtotal', _subtotal),
                    _totalRow(
                        'Tax (${(_taxRate * 100).toStringAsFixed(0)}%)',
                        _taxAmount),
                    const Divider(),
                    _totalRow('Total', _total, bold: true, large: true),
                  ]),
                ),
              ),

              const SizedBox(height: 16),
              _sectionTitle('📅 Due Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDueDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today,
                        color: Colors.grey[400], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? DateFormat('MMMM d, y').format(_dueDate!)
                          : 'No due date (optional)',
                      style: TextStyle(
                          color: _dueDate != null
                              ? Colors.black87
                              : Colors.grey[500]),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _dueDate = null),
                        child: Icon(Icons.close,
                            size: 16, color: Colors.grey[400]),
                      ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),
              _sectionTitle('📝 Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any additional notes for the customer...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.orange[700]!, width: 2)),
                ),
              ),

              const SizedBox(height: 24),
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
                      : const Text('Create Invoice',
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

  Widget _buildLineItem(int index, _LineItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                initialValue: item.description,
                decoration: InputDecoration(
                  hintText: 'Description',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.orange[700]!, width: 1.5)),
                ),
                onChanged: (v) => item.description = v,
              ),
            ),
            if (_items.length > 1) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _items.removeAt(index)),
                child: Icon(Icons.delete_outline,
                    color: Colors.red[400], size: 20),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Row(children: [
            // Qty
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: item.qty.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Qty',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.orange[700]!, width: 1.5)),
                ),
                onChanged: (v) =>
                    setState(() => item.qty = int.tryParse(v) ?? 1),
              ),
            ),
            const SizedBox(width: 8),
            // Price
            Expanded(
              child: TextFormField(
                initialValue: item.price > 0
                    ? item.price.toStringAsFixed(2)
                    : '',
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: 'Unit Price (\$)',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.orange[700]!, width: 1.5)),
                ),
                onChanged: (v) => setState(
                    () => item.price = double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            // Line total
            Container(
              width: 80,
              alignment: Alignment.centerRight,
              child: Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    fontSize: 14),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text,
      bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
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
              borderSide:
                  BorderSide(color: Colors.orange[700]!, width: 2)),
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _totalRow(String label, double amount,
      {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: large ? 15 : 13,
                    color: bold ? Colors.black : Colors.grey[700])),
            Text('\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: bold
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: large ? 18 : 13,
                    color: bold ? Colors.orange[700] : Colors.black87)),
          ]),
    );
  }
}

// Simple mutable line item for form state
class _LineItem {
  String description = '';
  int qty = 1;
  double price = 0;
  double get total => qty * price;
}
