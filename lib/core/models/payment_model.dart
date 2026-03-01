// lib/core/models/payment_model.dart

enum PaymentMethod { card, cash, bankTransfer, other }
enum PaymentState { pending, processing, succeeded, failed, refunded }

class PaymentModel {
  final String id;
  final String businessId;
  final String? bookingId;
  final String? invoiceId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentState state;
  final String? stripePaymentIntentId;
  final String? stripeChargeId;
  final String customerName;
  final String? customerEmail;
  final String? description;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.businessId,
    this.bookingId,
    this.invoiceId,
    required this.amount,
    this.currency = 'usd',
    required this.method,
    required this.state,
    this.stripePaymentIntentId,
    this.stripeChargeId,
    required this.customerName,
    this.customerEmail,
    this.description,
    this.failureReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      businessId: map['businessId'] ?? '',
      bookingId: map['bookingId'],
      invoiceId: map['invoiceId'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'usd',
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethod.card,
      ),
      state: PaymentState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => PaymentState.pending,
      ),
      stripePaymentIntentId: map['stripePaymentIntentId'],
      stripeChargeId: map['stripeChargeId'],
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'],
      description: map['description'],
      failureReason: map['failureReason'],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'bookingId': bookingId,
        'invoiceId': invoiceId,
        'amount': amount,
        'currency': currency,
        'method': method.name,
        'state': state.name,
        'stripePaymentIntentId': stripePaymentIntentId,
        'stripeChargeId': stripeChargeId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'description': description,
        'failureReason': failureReason,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String get formattedAmount =>
      '\$${amount.toStringAsFixed(2)}';

  String get stateLabel {
    switch (state) {
      case PaymentState.pending:    return 'Pending';
      case PaymentState.processing: return 'Processing';
      case PaymentState.succeeded:  return 'Paid';
      case PaymentState.failed:     return 'Failed';
      case PaymentState.refunded:   return 'Refunded';
    }
  }

  String get methodLabel {
    switch (method) {
      case PaymentMethod.card:         return 'Card';
      case PaymentMethod.cash:         return 'Cash';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.other:        return 'Other';
    }
  }
}
