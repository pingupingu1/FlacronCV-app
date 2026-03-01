// lib/core/services/payment_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';

class PaymentService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─── IMPORTANT: Set your backend URL here ──────────────────
  // You need a small backend (Firebase Cloud Function or Node server)
  // to create Stripe PaymentIntents securely.
  // See SETUP.md for instructions.
  static const String _backendUrl = 'YOUR_BACKEND_URL';

  String? get _uid => _auth.currentUser?.uid;

  // ─── Create a Stripe PaymentIntent via backend ──────────────
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerName,
    String? customerEmail,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': (amount * 100).round(), // Stripe uses cents
        'currency': currency,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'description': description,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create payment intent: ${response.body}');
  }

  // ─── Record a manual/cash payment ───────────────────────────
  Future<String> recordManualPayment({
    required String businessId,
    required double amount,
    required String customerName,
    String? customerEmail,
    String? bookingId,
    String? invoiceId,
    String? description,
    PaymentMethod method = PaymentMethod.cash,
  }) async {
    final docRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments')
        .doc();

    final payment = PaymentModel(
      id: docRef.id,
      businessId: businessId,
      bookingId: bookingId,
      invoiceId: invoiceId,
      amount: amount,
      currency: 'usd',
      method: method,
      state: PaymentState.succeeded,
      customerName: customerName,
      customerEmail: customerEmail,
      description: description,
      createdAt: DateTime.now(),
    );

    await docRef.set(payment.toMap());
    return docRef.id;
  }

  // ─── Record a Stripe payment after success ──────────────────
  Future<String> recordStripePayment({
    required String businessId,
    required double amount,
    required String customerName,
    required String paymentIntentId,
    String? customerEmail,
    String? bookingId,
    String? invoiceId,
    String? description,
  }) async {
    final docRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments')
        .doc();

    final payment = PaymentModel(
      id: docRef.id,
      businessId: businessId,
      bookingId: bookingId,
      invoiceId: invoiceId,
      amount: amount,
      currency: 'usd',
      method: PaymentMethod.card,
      state: PaymentState.succeeded,
      stripePaymentIntentId: paymentIntentId,
      customerName: customerName,
      customerEmail: customerEmail,
      description: description,
      createdAt: DateTime.now(),
    );

    await docRef.set(payment.toMap());
    return docRef.id;
  }

  // ─── Stream all payments ─────────────────────────────────────
  Stream<List<PaymentModel>> streamPayments({
    required String businessId,
    PaymentState? filterState,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (filterState != null) {
      query = query.where('state', isEqualTo: filterState.name);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            PaymentModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Get revenue summary ─────────────────────────────────────
  Future<Map<String, double>> getRevenueSummary(String businessId) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments')
        .where('state', isEqualTo: PaymentState.succeeded.name)
        .get();

    double total = 0;
    double thisMonth = 0;
    double thisYear = 0;
    double today = 0;

    final now = DateTime.now();
    for (final doc in snap.docs) {
      final p = PaymentModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
      total += p.amount;
      if (p.createdAt.year == now.year) {
        thisYear += p.amount;
        if (p.createdAt.month == now.month) {
          thisMonth += p.amount;
          if (p.createdAt.day == now.day) {
            today += p.amount;
          }
        }
      }
    }

    return {
      'total': total,
      'year': thisYear,
      'month': thisMonth,
      'today': today,
    };
  }

  // ─── Get payment by booking ──────────────────────────────────
  Future<PaymentModel?> getPaymentForBooking({
    required String businessId,
    required String bookingId,
  }) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .where('state', isEqualTo: PaymentState.succeeded.name)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return PaymentModel.fromMap(
        snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  // ─── Get monthly breakdown for chart ────────────────────────
  Future<List<Map<String, dynamic>>> getMonthlyRevenue(
      String businessId) async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments')
        .where('state', isEqualTo: PaymentState.succeeded.name)
        .where('createdAt',
            isGreaterThanOrEqualTo: sixMonthsAgo.toIso8601String())
        .get();

    // Group by month
    final Map<String, double> monthly = {};
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    for (final doc in snap.docs) {
      final p = PaymentModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
      final key = '${months[p.createdAt.month - 1]} ${p.createdAt.year}';
      monthly[key] = (monthly[key] ?? 0) + p.amount;
    }

    // Return last 6 months in order
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${months[month.month - 1]} ${month.year}';
      result.add({'month': months[month.month - 1], 'amount': monthly[key] ?? 0});
    }
    return result;
  }

  // ─── Refund (marks as refunded in Firestore) ────────────────
  Future<void> markRefunded(String businessId, String paymentId) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments')
        .doc(paymentId)
        .update({
      'state': PaymentState.refunded.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
