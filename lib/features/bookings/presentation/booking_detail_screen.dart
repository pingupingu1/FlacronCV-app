// lib/features/bookings/presentation/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _bookingService = BookingService();
  late BookingModel _booking;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:   return Colors.orange;
      case BookingStatus.confirmed: return Colors.blue;
      case BookingStatus.completed: return Colors.green;
      case BookingStatus.cancelled: return Colors.red;
    }
  }

  IconData _statusIcon(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:   return Icons.schedule;
      case BookingStatus.confirmed: return Icons.check_circle_outline;
      case BookingStatus.completed: return Icons.done_all;
      case BookingStatus.cancelled: return Icons.cancel_outlined;
    }
  }

  Future<void> _updateStatus(BookingStatus newStatus) async {
    final action = newStatus.name;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Booking?'),
        content: Text(
            'Are you sure you want to mark this booking as ${newStatus.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _statusColor(newStatus),
              foregroundColor: Colors.white,
            ),
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isUpdating = true);
    try {
      await _bookingService.updateBookingStatus(
        businessId: _booking.businessId,
        bookingId: _booking.id,
        status: newStatus,
      );
      setState(() {
        _booking = _booking.copyWith(
            status: newStatus, updatedAt: DateTime.now());
        _isUpdating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking marked as ${newStatus.name}'),
            backgroundColor: _statusColor(newStatus),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_booking.status);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
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
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(_statusIcon(_booking.status),
                    color: statusColor, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_booking.statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text(
                    'Created ${DateFormat('MMM d, y').format(_booking.createdAt)}',
                    style:
                        TextStyle(color: statusColor.withValues(alpha: 0.75), fontSize: 12),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Appointment info
            _card('Appointment', [
              _row(Icons.content_cut, 'Service', _booking.serviceName),
              _row(Icons.attach_money, 'Price', _booking.formattedPrice),
              _row(Icons.access_time, 'Duration',
                  '${_booking.serviceDurationMinutes} minutes'),
              _row(Icons.calendar_today, 'Date',
                  DateFormat('EEEE, MMMM d, y').format(_booking.date)),
              _row(Icons.schedule, 'Time',
                  _bookingService.formatTime(_booking.timeSlot)),
            ]),
            const SizedBox(height: 12),

            // Customer info
            _card('Customer', [
              _row(Icons.person, 'Name', _booking.customerName),
              _row(Icons.phone, 'Phone', _booking.customerPhone),
              if (_booking.customerEmail != null)
                _row(Icons.email, 'Email', _booking.customerEmail!),
              if (_booking.notes != null)
                _row(Icons.notes, 'Notes', _booking.notes!),
            ]),
            const SizedBox(height: 12),

            // Payment info
            _card('Payment', [
              _row(Icons.payment, 'Status',
                  _booking.paymentStatus.name.toUpperCase(),
                  valueColor: _booking.paymentStatus == PaymentStatus.paid
                      ? Colors.green
                      : Colors.orange),
              _row(Icons.attach_money, 'Amount', _booking.formattedPrice),
              if (_booking.stripePaymentId != null)
                _row(Icons.receipt, 'Payment ID', _booking.stripePaymentId!),
            ]),
            const SizedBox(height: 20),

            // Action buttons
            if (_booking.status != BookingStatus.cancelled &&
                _booking.status != BookingStatus.completed) ...[
              const Text('Actions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              if (_booking.status == BookingStatus.pending)
                _actionButton(
                  'Confirm Booking',
                  Icons.check_circle_outline,
                  Colors.blue,
                  () => _updateStatus(BookingStatus.confirmed),
                ),
              if (_booking.status == BookingStatus.confirmed)
                _actionButton(
                  'Mark as Completed',
                  Icons.done_all,
                  Colors.green,
                  () => _updateStatus(BookingStatus.completed),
                ),
              const SizedBox(height: 8),
              _actionButton(
                'Cancel Booking',
                Icons.cancel_outlined,
                Colors.red,
                () => _updateStatus(BookingStatus.cancelled),
              ),
            ],

            if (_isUpdating)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 32),
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
      {Color? valueColor}) {
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
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: valueColor ?? Colors.black87),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _isUpdating ? null : onTap,
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
      ),
    );
  }
}
