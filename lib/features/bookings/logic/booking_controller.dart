import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/booking_model.dart';
import '../../../services/booking_service.dart';

class BookingController {
  static Future<void> createBooking({
    required String serviceId,
    required String serviceName,
    required DateTime dateTime,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required double amount,
  }) async {
    final booking = BookingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessId: FirebaseAuth.instance.currentUser!.uid,
      serviceId: serviceId,
      serviceName: serviceName,
      bookingTime: dateTime,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      amount: amount,
      status: 'pending',
      paymentStatus: 'unpaid',
      createdAt: DateTime.now(),
    );

    await BookingService.createBooking(booking);
  }
}
