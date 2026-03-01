import 'package:flutter/material.dart';
import '../logic/payment_service.dart';

class PaymentButton extends StatelessWidget {
  final double amount;
  final String bookingId;
  final String email;

  const PaymentButton({
    super.key,
    required this.amount,
    required this.bookingId,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        PaymentService.startCheckout(
          amount: amount,
          bookingId: bookingId,
          email: email,
        );
      },
      child: Text('Pay \$${amount.toStringAsFixed(2)}'),
    );
  }
}
