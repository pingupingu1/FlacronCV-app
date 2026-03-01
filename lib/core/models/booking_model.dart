// lib/core/models/booking_model.dart

enum BookingStatus { pending, confirmed, completed, cancelled }
enum PaymentStatus { unpaid, paid, refunded }

class BookingModel {
  final String id;
  final String businessId;
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDurationMinutes;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final DateTime date;
  final String timeSlot;       // "10:00"
  final String? notes;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? stripePaymentId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.businessId,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDurationMinutes,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.date,
    required this.timeSlot,
    this.notes,
    this.status = BookingStatus.pending,
    this.paymentStatus = PaymentStatus.unpaid,
    this.stripePaymentId,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      businessId: map['businessId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      servicePrice: (map['servicePrice'] ?? 0).toDouble(),
      serviceDurationMinutes: map['serviceDurationMinutes'] ?? 60,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'],
      date: DateTime.parse(map['date']),
      timeSlot: map['timeSlot'] ?? '',
      notes: map['notes'],
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      stripePaymentId: map['stripePaymentId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'serviceDurationMinutes': serviceDurationMinutes,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'notes': notes,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'stripePaymentId': stripePaymentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helpers
  String get formattedPrice => '\$${servicePrice.toStringAsFixed(2)}';

  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:    return 'Pending';
      case BookingStatus.confirmed:  return 'Confirmed';
      case BookingStatus.completed:  return 'Completed';
      case BookingStatus.cancelled:  return 'Cancelled';
    }
  }

  BookingModel copyWith({
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? stripePaymentId,
    String? notes,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id,
      businessId: businessId,
      serviceId: serviceId,
      serviceName: serviceName,
      servicePrice: servicePrice,
      serviceDurationMinutes: serviceDurationMinutes,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      date: date,
      timeSlot: timeSlot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      stripePaymentId: stripePaymentId ?? this.stripePaymentId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}