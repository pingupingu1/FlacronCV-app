import '../models/booking_model.dart';
import 'firestore_service.dart';

class BookingService {
  static const String _collection = 'bookings';

  static Future<void> createBooking(BookingModel booking) async {
    await FirestoreService.collection(_collection)
        .doc(booking.id)
        .set(booking.toMap());
  }

  static Future<List<BookingModel>> getBookings(
      String businessId) async {
    final query = await FirestoreService.collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .orderBy('bookingTime')
        .get();

    return query.docs
        .map((d) => BookingModel.fromMap(d.data(), d.id))
        .toList();
  }
}
