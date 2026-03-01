// lib/features/bookings/presentation/booking_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../routes/route_names.dart';

class BookingCalendarScreen extends StatefulWidget {
  final String businessId;
  const BookingCalendarScreen({super.key, required this.businessId});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen>
    with SingleTickerProviderStateMixin {
  final _bookingService = BookingService();
  late TabController _tabController;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<BookingModel>> _bookingsByDay = {};
  bool _loadingMonth = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMonth(_focusedDay);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() => _loadingMonth = true);
    final bookings = await _bookingService.getBookingsForMonth(
      businessId: widget.businessId,
      month: month,
    );
    final map = <DateTime, List<BookingModel>>{};
    for (final b in bookings) {
      final key = DateTime(b.date.year, b.date.month, b.date.day);
      map.putIfAbsent(key, () => []).add(b);
    }
    if (mounted) setState(() { _bookingsByDay = map; _loadingMonth = false; });
  }

  List<BookingModel> _getBookingsForDay(DateTime day) {
    return _bookingsByDay[DateTime(day.year, day.month, day.day)] ?? [];
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
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_month, size: 18)),
            Tab(text: 'All Bookings', icon: Icon(Icons.list, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          RouteNames.createBooking,
          arguments: {'businessId': widget.businessId},
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Booking', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildAllBookingsTab(),
        ],
      ),
    );
  }

  // ─── Calendar Tab ────────────────────────────────────────────
  Widget _buildCalendarTab() {
    final dayBookings = _getBookingsForDay(_selectedDay);
    return Column(
      children: [
        // Calendar
        Container(
          color: Colors.white,
          child: TableCalendar<BookingModel>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: _getBookingsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange[200],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange[700],
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.orange[700],
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: Colors.orange[700]),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: Colors.orange[700]),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
              _loadMonth(focused);
            },
          ),
        ),

        // Selected day header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(_selectedDay),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dayBookings.length} booking${dayBookings.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Day bookings list
        Expanded(
          child: dayBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available,
                          size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No bookings for this day',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 15)),
                    ],
                  ),
                )
              : StreamBuilder<List<BookingModel>>(
                  stream: _bookingService.streamBookingsForDate(
                    businessId: widget.businessId,
                    date: _selectedDay,
                  ),
                  builder: (context, snapshot) {
                    final list = snapshot.data ?? dayBookings;
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _bookingCard(list[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── All Bookings Tab ────────────────────────────────────────
  Widget _buildAllBookingsTab() {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.streamBookings(
          businessId: widget.businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 72, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No bookings yet',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Create your first booking',
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        // Group by status
        final pending =
            bookings.where((b) => b.status == BookingStatus.pending).toList();
        final confirmed =
            bookings.where((b) => b.status == BookingStatus.confirmed).toList();
        final others = bookings
            .where((b) =>
                b.status != BookingStatus.pending &&
                b.status != BookingStatus.confirmed)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (pending.isNotEmpty) ...[
              _sectionHeader('Pending', pending.length, Colors.orange),
              ...pending.map(_bookingCard),
              const SizedBox(height: 8),
            ],
            if (confirmed.isNotEmpty) ...[
              _sectionHeader('Confirmed', confirmed.length, Colors.blue),
              ...confirmed.map(_bookingCard),
              const SizedBox(height: 8),
            ],
            if (others.isNotEmpty) ...[
              _sectionHeader('Other', others.length, Colors.grey),
              ...others.map(_bookingCard),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _bookingCard(BookingModel booking) {
    final color = _statusColor(booking.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(
          context,
          RouteNames.bookingDetail,
          arguments: {'booking': booking},
        ).then((_) => _loadMonth(_focusedDay)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Time column
              Container(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _bookingService.formatTime(booking.timeSlot),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.orange[700]),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${booking.serviceDurationMinutes}min',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                  width: 1,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.grey[200]),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(booking.serviceName,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                    if (booking.customerPhone.isNotEmpty)
                      Text(booking.customerPhone,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              // Status + price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_statusIcon(booking.status),
                          size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(booking.statusLabel,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Text(booking.formattedPrice,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
