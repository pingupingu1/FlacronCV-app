import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static Future<void> startCheckout({
    required double amount,
    required String bookingId,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://us-central1-YOUR_PROJECT.cloudfunctions.net/createCheckoutSession',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'bookingId': bookingId,
        'customerEmail': email,
      }),
    );

    final url = jsonDecode(response.body)['url'];
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
