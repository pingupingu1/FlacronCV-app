// lib/features/bookings/presentation/booking_detail_screen.dart

import 'package:flutter/material.dart';
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
      case BookingStatus.confirmed:  return Colors.green;
      case BookingStatus.pending:    return Colors.orange;
      case BookingStatus.completed:  return Colors.blue;
      case BookingStatus.cancelled:  return Colors.red;
    }
  }

  Future<void> _updateStatus(BookingStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _bookingService.updateBookingStatus(
          _booking.businessId, _booking.id, newStatus);
      setState(() => _booking = _booking.copyWith(status: newStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${newStatus.name}'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _markAsPaid() async {
    setState(() => _isUpdating = true);
    try {
      await _bookingService.markAsPaid(
          _booking.businessId, _booking.id);
      setState(() =>
          _booking = _booking.copyWith(paymentStatus: PaymentStatus.paid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marked as paid ✅'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking?'),
        content: const Text(
            'This action cannot be undone. Delete this booking?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _bookingService.deleteBooking(
          _booking.businessId, _booking.id);
      if (mounted) Navigator.pop(context);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteBooking,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ──
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
                  Icon(_statusIcon(_booking.status),
                      color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_booking.statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(
                          _booking.paymentStatus == PaymentStatus.paid
                              ? '✅ Paid'
                              : '⏳ Payment Pending',
                          style: TextStyle(
                              color: _booking.paymentStatus ==
                                      PaymentStatus.paid
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  Text(_booking.formattedPrice,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.orange[700])),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Service & time info ──
            _infoCard('Appointment', [
              _infoRow(Icons.spa_outlined, 'Service', _booking.serviceName),
              _infoRow(Icons.calendar_today_outlined, 'Date',
                  _booking.formattedDate),
              _infoRow(Icons.access_time_outlined, 'Time',
                  _bookingService.formatTo12h(_booking.timeSlot)),
              _infoRow(Icons.timer_outlined, 'Duration',
                  '${_booking.serviceDurationMinutes} min'),
              _infoRow(Icons.attach_money, 'Price', _booking.formattedPrice),
            ]),
            const SizedBox(height: 12),

            // ── Customer info ──
            _infoCard('Customer', [
              _infoRow(Icons.person_outline, 'Name', _booking.customerName),
              _infoRow(Icons.phone_outlined, 'Phone', _booking.customerPhone),
              if (_booking.customerEmail != null)
                _infoRow(Icons.email_outlined, 'Email',
                    _booking.customerEmail!),
              if (_booking.notes != null)
                _infoRow(Icons.notes_outlined, 'Notes', _booking.notes!),
            ]),
            const SizedBox(height: 12),

            // ── Booking meta ──
            _infoCard('Booking Info', [
              _infoRow(Icons.tag, 'Booking ID',
                  _booking.id.substring(0, 8).toUpperCase()),
              _infoRow(Icons.schedule, 'Created',
                  _booking.createdAt.toString().substring(0, 16)),
            ]),
            const SizedBox(height: 20),

            // ── Status Actions ──
            if (_booking.status != BookingStatus.cancelled &&
                _booking.status != BookingStatus.completed) ...[
              const Text('Update Status',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_booking.status == BookingStatus.pending)
                    Expanded(
                      child: _statusButton(
                        'Confirm',
                        Icons.check_circle_outline,
                        Colors.green,
                        () => _updateStatus(BookingStatus.confirmed),
                      ),
                    ),
                  if (_booking.status == BookingStatus.pending)
                    const SizedBox(width: 8),
                  if (_booking.status == BookingStatus.confirmed)
                    Expanded(
                      child: _statusButton(
                        'Complete',
                        Icons.done_all,
                        Colors.blue,
                        () => _updateStatus(BookingStatus.completed),
                      ),
                    ),
                  if (_booking.status == BookingStatus.confirmed)
                    const SizedBox(width: 8),
                  Expanded(
                    child: _statusButton(
                      'Cancel',
                      Icons.cancel_outlined,
                      Colors.red,
                      () => _updateStatus(BookingStatus.cancelled),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Payment action ──
            if (_booking.paymentStatus == PaymentStatus.unpaid &&
                _booking.status != BookingStatus.cancelled)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _markAsPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.payments_outlined),
                  label: Text(
                      _isUpdating ? 'Updating...' : 'Mark as Paid',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:    return Icons.hourglass_empty;
      case BookingStatus.confirmed:  return Icons.check_circle_outline;
      case BookingStatus.completed:  return Icons.done_all;
      case BookingStatus.cancelled:  return Icons.cancel_outlined;
    }
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600])),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange[600]),
          const SizedBox(width: 10),
          Text('$label: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _isUpdating ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}