class BookingModel {
  final String id;
  final String businessId;
  final String serviceId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingTime;
  final String status; // pending, confirmed, completed, cancelled

  BookingModel({
    required this.id,
    required this.businessId,
    required this.serviceId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingTime,
    required this.status,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      id: docId,
      businessId: map['businessId'],
      serviceId: map['serviceId'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      bookingTime: map['bookingTime'].toDate(),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'serviceId': serviceId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'bookingTime': bookingTime,
      'status': status,
    };
  }
}
