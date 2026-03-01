// lib/features/payments/data/stripe_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  static final String _publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  /// Initialize Stripe with publishable key
  static Future<void> initialize() async {
    try {
      Stripe.publishableKey = _publishableKey;
      await Stripe.instance.applySettings();
      print('Stripe initialized successfully');
    } catch (e) {
      print('Error initializing Stripe: $e');
      throw Exception('Failed to initialize Stripe');
    }
  }

  /// Create a payment intent for booking deposit or full payment
  /// 
  /// [amount] - Amount in cents (e.g., 5000 = $50.00)
  /// [currency] - Currency code (e.g., 'usd')
  /// [bookingId] - Associated booking ID
  /// [customerId] - Stripe customer ID (optional)
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    required String bookingId,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/createPaymentIntent');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'bookingId': bookingId,
          'customerId': customerId,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'clientSecret': data['clientSecret'],
          'paymentIntentId': data['paymentIntentId'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create payment intent: ${response.body}',
        };
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Process payment using Stripe Payment Sheet
  /// 
  /// [clientSecret] - Payment intent client secret from backend
  /// [customerName] - Customer name for payment sheet
  /// [customerEmail] - Customer email
  static Future<Map<String, dynamic>> processPayment({
    required String clientSecret,
    required String customerName,
    required String customerEmail,
  }) async {
    try {
      // Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'FlacronControl',
          customerEphemeralKeySecret: null,
          customerId: null,
          style: ThemeMode.system,
          billingDetails: BillingDetails(
            name: customerName,
            email: customerEmail,
          ),
        ),
      );

      // Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return {
        'success': true,
        'message': 'Payment completed successfully',
      };
    } on StripeException catch (e) {
      print('Stripe error: ${e.error.localizedMessage}');
      return {
        'success': false,
        'error': e.error.localizedMessage ?? 'Payment failed',
        'cancelled': e.error.code == FailureCode.Canceled,
      };
    } catch (e) {
      print('Error processing payment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create checkout session for subscription plans
  /// 
  /// [priceId] - Stripe Price ID for the subscription plan
  /// [customerId] - Customer's Stripe ID (optional)
  /// [businessId] - Business ID for metadata
  static Future<Map<String, dynamic>> createCheckoutSession({
    required String priceId,
    String? customerId,
    required String businessId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/createCheckoutSession');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'priceId': priceId,
          'customerId': customerId,
          'businessId': businessId,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'sessionId': data['sessionId'],
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create checkout session',
        };
      }
    } catch (e) {
      print('Error creating checkout session: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get payment status from backend
  /// 
  /// [paymentIntentId] - Payment Intent ID to check
  static Future<Map<String, dynamic>> getPaymentStatus(String paymentIntentId) async {
    try {
      final url = Uri.parse('$_baseUrl/getPaymentStatus?paymentIntentId=$paymentIntentId');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'amount': data['amount'],
          'paid': data['status'] == 'succeeded',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get payment status',
        };
      }
    } catch (e) {
      print('Error getting payment status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create a refund for a payment
  /// 
  /// [paymentIntentId] - Original payment intent ID
  /// [amount] - Amount to refund in cents (optional, defaults to full refund)
  /// [reason] - Reason for refund
  static Future<Map<String, dynamic>> createRefund({
    required String paymentIntentId,
    int? amount,
    String? reason,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/createRefund');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'amount': amount,
          'reason': reason ?? 'requested_by_customer',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'refundId': data['refundId'],
          'status': data['status'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create refund',
        };
      }
    } catch (e) {
      print('Error creating refund: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Calculate deposit amount (e.g., 20% of total)
  static int calculateDepositAmount(int totalAmount, {double percentage = 0.20}) {
    return (totalAmount * percentage).round();
  }

  /// Format amount for display (cents to dollars)
  static String formatAmount(int amountInCents, String currency) {
    final amount = (amountInCents / 100).toStringAsFixed(2);
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol$amount';
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency.toLowerCase()) {
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      case 'inr':
        return '₹';
      case 'pkr':
        return 'Rs.';
      default:
        return currency.toUpperCase();
    }
  }
}