// lib/core/services/invoice_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Generate invoice number ─────────────────────────────────
  Future<String> _generateInvoiceNumber(String businessId) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return 'INV-001';
    final last = snap.docs.first.data()['invoiceNumber'] as String? ?? 'INV-000';
    final num = int.tryParse(last.split('-').last) ?? 0;
    return 'INV-${(num + 1).toString().padLeft(3, '0')}';
  }

  // ─── Create invoice ──────────────────────────────────────────
  Future<String> createInvoice({
    required String businessId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? bookingId,
    required List<InvoiceItemModel> items,
    required double taxRate,
    String? notes,
    DateTime? dueDate,
  }) async {
    final invoiceNumber = await _generateInvoiceNumber(businessId);
    final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    final taxAmount = subtotal * taxRate;
    final total = subtotal + taxAmount;

    final docRef = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .doc();

    final invoice = InvoiceModel(
      id: docRef.id,
      businessId: businessId,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      bookingId: bookingId,
      items: items,
      subtotal: subtotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      total: total,
      status: InvoiceStatus.draft,
      notes: notes,
      date: DateTime.now(),
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    await docRef.set(invoice.toMap());
    return docRef.id;
  }

  // ─── Stream all invoices ─────────────────────────────────────
  Stream<List<InvoiceModel>> streamInvoices({
    required String businessId,
    InvoiceStatus? filterStatus,
  }) {
    Query query = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .orderBy('createdAt', descending: true);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus.name);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            InvoiceModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Get single invoice ──────────────────────────────────────
  Future<InvoiceModel?> getInvoice(
      String businessId, String invoiceId) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .doc(invoiceId)
        .get();
    if (!doc.exists) return null;
    return InvoiceModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Update status ───────────────────────────────────────────
  Future<void> updateStatus({
    required String businessId,
    required String invoiceId,
    required InvoiceStatus status,
    String? stripePaymentId,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (status == InvoiceStatus.paid) {
      updates['paidAt'] = DateTime.now().toIso8601String();
    }
    if (stripePaymentId != null) {
      updates['stripePaymentId'] = stripePaymentId;
    }
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .doc(invoiceId)
        .update(updates);
  }

  // ─── Mark as sent ────────────────────────────────────────────
  Future<void> markSent(String businessId, String invoiceId) =>
      updateStatus(
          businessId: businessId,
          invoiceId: invoiceId,
          status: InvoiceStatus.sent);

  // ─── Mark as paid ────────────────────────────────────────────
  Future<void> markPaid(String businessId, String invoiceId,
          {String? stripePaymentId}) =>
      updateStatus(
          businessId: businessId,
          invoiceId: invoiceId,
          status: InvoiceStatus.paid,
          stripePaymentId: stripePaymentId);

  // ─── Cancel invoice ──────────────────────────────────────────
  Future<void> cancelInvoice(String businessId, String invoiceId) =>
      updateStatus(
          businessId: businessId,
          invoiceId: invoiceId,
          status: InvoiceStatus.cancelled);

  // ─── Delete invoice ──────────────────────────────────────────
  Future<void> deleteInvoice(String businessId, String invoiceId) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .doc(invoiceId)
        .delete();
  }

  // ─── Revenue summary ─────────────────────────────────────────
  Future<Map<String, double>> getRevenueSummary(String businessId) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .where('status', isEqualTo: InvoiceStatus.paid.name)
        .get();

    double total = 0, month = 0, year = 0;
    final now = DateTime.now();
    for (final doc in snap.docs) {
      final inv = InvoiceModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
      total += inv.total;
      if (inv.paidAt != null && inv.paidAt!.year == now.year) {
        year += inv.total;
        if (inv.paidAt!.month == now.month) month += inv.total;
      }
    }
    return {'total': total, 'month': month, 'year': year};
  }

  // ─── Check & mark overdue invoices ───────────────────────────
  Future<void> checkOverdue(String businessId) async {
    final now = DateTime.now();
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('invoices')
        .where('status', isEqualTo: InvoiceStatus.sent.name)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dueDate = data['dueDate'] != null
          ? DateTime.parse(data['dueDate'])
          : null;
      if (dueDate != null && dueDate.isBefore(now)) {
        await doc.reference.update({
          'status': InvoiceStatus.overdue.name,
          'updatedAt': now.toIso8601String(),
        });
      }
    }
  }
}
