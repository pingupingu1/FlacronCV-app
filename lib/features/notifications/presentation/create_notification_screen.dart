// lib/features/notifications/presentation/create_notification_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';

class CreateNotificationScreen extends StatefulWidget {
  final String businessId;
  const CreateNotificationScreen({super.key, required this.businessId});

  @override
  State<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState
    extends State<CreateNotificationScreen> {
  final _notifService = NotificationService();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  NotificationType _type = NotificationType.general;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // Quick templates
  final _templates = [
    {'title': '🎉 Special Offer', 'body': 'We\'re running a special promotion this week. Book now to save!', 'type': NotificationType.general},
    {'title': '⏰ Appointment Reminder', 'body': 'Don\'t forget your upcoming appointment. We look forward to seeing you!', 'type': NotificationType.bookingNew},
    {'title': '💳 Payment Due', 'body': 'Your invoice is due for payment. Please complete your payment at your earliest convenience.', 'type': NotificationType.invoiceDue},
    {'title': '✅ Payroll Processed', 'body': 'This month\'s payroll has been processed. Please check your records.', 'type': NotificationType.payrollReady},
    {'title': '👋 Welcome!', 'body': 'Welcome to our team! We\'re excited to have you on board.', 'type': NotificationType.employeeAdded},
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await _notifService.createNotification(
        businessId: widget.businessId,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        type: _type,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification created ✓'),
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
        title: const Text('New Notification'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text('Send',
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔔', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              const Text('Create Notification',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Send an alert or message',
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
                    Expanded(child: Text(_error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13))),
                  ]),
                ),

              // Quick templates
              _label('Quick Templates'),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _templates.length,
                  itemBuilder: (_, i) {
                    final t = _templates[i];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _titleCtrl.text = t['title'] as String;
                        _bodyCtrl.text = t['body'] as String;
                        _type = t['type'] as NotificationType;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Text(
                          (t['title'] as String).split(' ').take(2).join(' '),
                          style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              _label('Notification Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<NotificationType>(
                value: _type,
                decoration: InputDecoration(
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
                items: NotificationType.values.map((t) {
                  final labels = {
                    NotificationType.general: '🔔 General',
                    NotificationType.bookingNew: '📅 New Booking',
                    NotificationType.bookingConfirmed: '✅ Booking Confirmed',
                    NotificationType.bookingCancelled: '❌ Booking Cancelled',
                    NotificationType.paymentReceived: '💰 Payment Received',
                    NotificationType.invoiceDue: '📄 Invoice Due',
                    NotificationType.invoiceOverdue: '⚠️ Invoice Overdue',
                    NotificationType.payrollReady: '💼 Payroll Ready',
                    NotificationType.attendanceAlert: '🕐 Attendance Alert',
                    NotificationType.employeeAdded: '👤 Employee Added',
                  };
                  return DropdownMenuItem(
                    value: t,
                    child: Text(labels[t] ?? t.name),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),

              const SizedBox(height: 16),
              _label('Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: 'Notification title',
                  prefixIcon: Icon(Icons.title, color: Colors.grey[400], size: 20),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),

              const SizedBox(height: 16),
              _label('Message *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your notification message...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.message_outlined,
                        color: Colors.grey[400], size: 20),
                  ),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Message required' : null,
              ),

              const SizedBox(height: 16),

              // Preview
              if (_titleCtrl.text.isNotEmpty || _bodyCtrl.text.isNotEmpty) ...[
                _label('Preview'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            NotificationModel(
                              id: '',
                              businessId: '',
                              title: _titleCtrl.text,
                              body: _bodyCtrl.text,
                              type: _type,
                              createdAt: DateTime.now(),
                            ).typeIcon,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleCtrl.text.isEmpty
                                  ? 'Title...'
                                  : _titleCtrl.text,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _titleCtrl.text.isEmpty
                                      ? Colors.grey
                                      : Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bodyCtrl.text.isEmpty
                                  ? 'Message...'
                                  : _bodyCtrl.text,
                              style: TextStyle(
                                  color: _bodyCtrl.text.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text('Just now',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: Colors.orange[700],
                            shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.send_outlined, size: 20),
                  label: const Text('Send Notification',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)));
}
