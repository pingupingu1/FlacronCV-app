// lib/features/bookings/presentation/booking_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import 'create_booking_screen.dart';
import 'booking_detail_screen.dart';

class BookingCalendarScreen extends StatefulWidget {
  final String businessId;
  const BookingCalendarScreen({super.key, required this.businessId});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final _bookingService = BookingService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<BookingModel> _selectedDayBookings = [];
  Map<DateTime, List<BookingModel>> _monthEvents = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _bookingService.getBookingsForMonth(
          widget.businessId, month);
      final events = <DateTime, List<BookingModel>>{};
      for (final b in bookings) {
        final key = DateTime(b.date.year, b.date.month, b.date.day);
        events[key] = [...(events[key] ?? []), b];
      }
      setState(() {
        _monthEvents = events;
        _updateSelectedDay(_selectedDay);
      });
    } catch (e) {
      debugPrint('Error loading month: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateSelectedDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    setState(() {
      _selectedDay = day;
      _selectedDayBookings = _monthEvents[key] ?? [];
    });
  }

  List<BookingModel> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _monthEvents[key] ?? [];
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed: return Colors.green;
      case BookingStatus.pending:   return Colors.orange;
      case BookingStatus.completed: return Colors.blue;
      case BookingStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMonth(_focusedDay),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateBookingScreen(
                businessId: widget.businessId,
                initialDate: _selectedDay,
              ),
            ),
          );
          _loadMonth(_focusedDay);
        },
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
      ),
      body: Column(
        children: [
          // ── Calendar ──
          Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            shape: const RoundedRectangleBorder(),
            child: TableCalendar<BookingModel>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.orange[700],
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange[200],
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.orange[800],
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: Colors.orange[700]),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: Colors.orange[700]),
              ),
              onDaySelected: (selected, focused) {
                setState(() => _focusedDay = focused);
                _updateSelectedDay(selected);
              },
              onPageChanged: (focused) {
                _focusedDay = focused;
                _loadMonth(focused);
              },
            ),
          ),

          // ── Selected day header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.orange[50],
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  _formatSelectedDay(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800]),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.orange)),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedDayBookings.length} booking${_selectedDayBookings.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bookings list for selected day ──
          Expanded(
            child: _selectedDayBookings.isEmpty
                ? _buildEmptyDay()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _selectedDayBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _buildBookingCard(_selectedDayBookings[i]),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDay() {
    const months = ['January','February','March','April','May','June',
                    'July','August','September','October','November','December'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[_selectedDay.weekday - 1]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No bookings on this day',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Tap "New Booking" to schedule one',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final color = _statusColor(booking.status);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          ),
        );
        _loadMonth(_focusedDay);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Time
            Column(
              children: [
                Text(
                  _bookingService.formatTo12h(booking.timeSlot),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13),
                ),
                Text(
                  '${booking.serviceDurationMinutes} min',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const VerticalDivider(width: 1),
            const SizedBox(width: 12),
            // Customer & service info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(booking.serviceName,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(booking.customerPhone,
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            // Price & status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(booking.formattedPrice,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        fontSize: 15)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(booking.statusLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}