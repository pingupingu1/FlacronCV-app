// lib/core/services/booking_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Create Booking ──────────────────────────────────────────
  Future<String> createBooking({
    required String businessId,
    required String serviceId,
    required String serviceName,
    required double servicePrice,
    required int serviceDurationMinutes,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required DateTime date,
    required String timeSlot,
    String? notes,
  }) async {
    // Check slot is still available
    final available = await isSlotAvailable(
      businessId: businessId,
      date: date,
      timeSlot: timeSlot,
      durationMinutes: serviceDurationMinutes,
    );
    if (!available) throw Exception('This time slot is no longer available.');

    final docRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('bookings')
        .doc();

    final booking = BookingModel(
      id: docRef.id,
      businessId: businessId,
      serviceId: serviceId,
      serviceName: serviceName,
      servicePrice: servicePrice,
      serviceDurationMinutes: serviceDurationMinutes,
      customerId: _uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      date: date,
      timeSlot: timeSlot,
      notes: notes,
      status: BookingStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
      createdAt: DateTime.now(),
    );

    await docRef.set(booking.toMap());
    return docRef.id;
  }

  // ─── Stream all bookings ─────────────────────────────────────
  Stream<List<BookingModel>> streamBookings({
    required String businessId,
    BookingStatus? filterStatus,
    DateTime? date,
  }) {
    Query query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('bookings')
        .orderBy('date', descending: false);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus.name);
    }
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThan: end.toIso8601String());
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Stream bookings for a specific date ────────────────────
  Stream<List<BookingModel>> streamBookingsForDate({
    required String businessId,
    required DateTime date,
  }) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('bookings')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BookingModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── Get bookings for a month (for calendar dots) ───────────
  Future<List<BookingModel>> getBookingsForMonth({
    required String businessId,
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('bookings')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .get();

    return snap.docs
        .map((d) =>
            BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  // ─── Get available time slots for a date ────────────────────
  Future<List<String>> getAvailableSlots({
    required String businessId,
    required DateTime date,
    required int durationMinutes,
    String? openTime,
    String? closeTime,
  }) async {
    // Default hours
    final open = openTime ?? '09:00';
    final close = closeTime ?? '17:00';

    // Get existing bookings for that day
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('bookings')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .where('status', whereNotIn: ['cancelled'])
        .get();

    final bookedSlots = snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {
        'timeSlot': data['timeSlot'] as String,
        'duration': data['serviceDurationMinutes'] as int? ?? 60,
      };
    }).toList();

    // Generate all possible slots
    final allSlots = _generateTimeSlots(open, close, durationMinutes);

    // Filter out booked ones
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    return allSlots.where((slot) {
      // Skip past times if today
      if (isToday) {
        final parts = slot.split(':');
        final slotTime = DateTime(date.year, date.month, date.day,
            int.parse(parts[0]), int.parse(parts[1]));
        if (slotTime.isBefore(now.add(const Duration(minutes: 30)))) {
          return false;
        }
      }

      // Check if slot conflicts with existing bookings
      final slotMinutes = _timeToMinutes(slot);
      for (final booked in bookedSlots) {
        final bookedStart = _timeToMinutes(booked['timeSlot'] as String);
        final bookedEnd = bookedStart + (booked['duration'] as int);
        final slotEnd = slotMinutes + durationMinutes;

        if (slotMinutes < bookedEnd && slotEnd > bookedStart) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ─── Check if a specific slot is available ──────────────────
  Future<bool> isSlotAvailable({
    required String businessId,
    required DateTime date,
    required String timeSlot,
    required int durationMinutes,
  }) async {
    final slots = await getAvailableSlots(
      businessId: businessId,
      date: date,
      durationMinutes: durationMinutes,
    );
    return slots.contains(timeSlot);
  }

  // ─── Update booking status ───────────────────────────────────
  Future<void> updateBookingStatus({
    required String businessId,
    required String bookingId,
    required BookingStatus status,
  }) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('bookings')
        .doc(bookingId)
        .update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Cancel booking ──────────────────────────────────────────
  Future<void> cancelBooking({
    required String businessId,
    required String bookingId,
  }) =>
      updateBookingStatus(
        businessId: businessId,
        bookingId: bookingId,
        status: BookingStatus.cancelled,
      );

  // ─── Confirm booking ─────────────────────────────────────────
  Future<void> confirmBooking({
    required String businessId,
    required String bookingId,
  }) =>
      updateBookingStatus(
        businessId: businessId,
        bookingId: bookingId,
        status: BookingStatus.confirmed,
      );

  // ─── Get booking stats ───────────────────────────────────────
  Future<Map<String, int>> getBookingStats(String businessId) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('bookings')
        .get();

    int pending = 0, confirmed = 0, completed = 0, cancelled = 0;
    for (final doc in snap.docs) {
      final status = doc.data()['status'] as String? ?? 'pending';
      switch (status) {
        case 'pending': pending++; break;
        case 'confirmed': confirmed++; break;
        case 'completed': completed++; break;
        case 'cancelled': cancelled++; break;
      }
    }
    return {
      'total': snap.docs.length,
      'pending': pending,
      'confirmed': confirmed,
      'completed': completed,
      'cancelled': cancelled,
    };
  }

  // ─── Helpers ─────────────────────────────────────────────────
  List<String> _generateTimeSlots(
      String open, String close, int durationMinutes) {
    final slots = <String>[];
    int current = _timeToMinutes(open);
    final end = _timeToMinutes(close);

    while (current + durationMinutes <= end) {
      final h = current ~/ 60;
      final m = current % 60;
      slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      current += durationMinutes;
    }
    return slots;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String formatTime(String time24) {
    final parts = time24.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }
}
