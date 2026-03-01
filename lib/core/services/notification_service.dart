// lib/core/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference _notifColl(String businessId) => _db
      .collection('businesses')
      .doc(businessId)
      .collection('notifications');

  // ─── Create a notification ───────────────────────────────────
  Future<String> createNotification({
    required String businessId,
    required String title,
    required String body,
    required NotificationType type,
    String? referenceId,
    String? referenceType,
  }) async {
    final docRef = _notifColl(businessId).doc();
    final notif = NotificationModel(
      id: docRef.id,
      businessId: businessId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      referenceType: referenceType,
      createdAt: DateTime.now(),
    );
    await docRef.set(notif.toMap());
    return docRef.id;
  }

  // ─── Convenience creators ────────────────────────────────────
  Future<void> notifyNewBooking({
    required String businessId,
    required String customerName,
    required String serviceName,
    required String bookingId,
    required String dateTime,
  }) => createNotification(
        businessId: businessId,
        title: 'New Booking',
        body: '$customerName booked $serviceName for $dateTime',
        type: NotificationType.bookingNew,
        referenceId: bookingId,
        referenceType: 'booking',
      );

  Future<void> notifyPaymentReceived({
    required String businessId,
    required String customerName,
    required String amount,
    required String paymentId,
  }) => createNotification(
        businessId: businessId,
        title: 'Payment Received',
        body: '$customerName paid $amount',
        type: NotificationType.paymentReceived,
        referenceId: paymentId,
        referenceType: 'payment',
      );

  Future<void> notifyInvoiceDue({
    required String businessId,
    required String customerName,
    required String amount,
    required String invoiceId,
    required String dueDate,
  }) => createNotification(
        businessId: businessId,
        title: 'Invoice Due Soon',
        body: 'Invoice for $customerName ($amount) is due $dueDate',
        type: NotificationType.invoiceDue,
        referenceId: invoiceId,
        referenceType: 'invoice',
      );

  Future<void> notifyInvoiceOverdue({
    required String businessId,
    required String customerName,
    required String amount,
    required String invoiceId,
  }) => createNotification(
        businessId: businessId,
        title: 'Invoice Overdue',
        body: 'Invoice for $customerName ($amount) is overdue!',
        type: NotificationType.invoiceOverdue,
        referenceId: invoiceId,
        referenceType: 'invoice',
      );

  Future<void> notifyPayrollReady({
    required String businessId,
    required int employeeCount,
    required String period,
  }) => createNotification(
        businessId: businessId,
        title: 'Payroll Ready',
        body: 'Payroll generated for $employeeCount employees — $period',
        type: NotificationType.payrollReady,
      );

  Future<void> notifyEmployeeAdded({
    required String businessId,
    required String employeeName,
    required String position,
    required String employeeId,
  }) => createNotification(
        businessId: businessId,
        title: 'New Employee Added',
        body: '$employeeName joined as $position',
        type: NotificationType.employeeAdded,
        referenceId: employeeId,
        referenceType: 'employee',
      );

  Future<void> notifyGeneral({
    required String businessId,
    required String title,
    required String body,
  }) => createNotification(
        businessId: businessId,
        title: title,
        body: body,
        type: NotificationType.general,
      );

  // ─── Stream notifications ────────────────────────────────────
  Stream<List<NotificationModel>> streamNotifications({
    required String businessId,
    bool unreadOnly = false,
    int limit = 50,
  }) {
    Query query = _notifColl(businessId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => NotificationModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Get unread count ────────────────────────────────────────
  Stream<int> streamUnreadCount(String businessId) {
    return _notifColl(businessId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Mark as read ────────────────────────────────────────────
  Future<void> markAsRead(String businessId, String notifId) async {
    await _notifColl(businessId).doc(notifId).update({
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Mark all as read ────────────────────────────────────────
  Future<void> markAllAsRead(String businessId) async {
    final snap = await _notifColl(businessId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    final now = DateTime.now().toIso8601String();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true, 'readAt': now});
    }
    await batch.commit();
  }

  // ─── Delete notification ─────────────────────────────────────
  Future<void> deleteNotification(
      String businessId, String notifId) async {
    await _notifColl(businessId).doc(notifId).delete();
  }

  // ─── Clear all notifications ─────────────────────────────────
  Future<void> clearAll(String businessId) async {
    final snap = await _notifColl(businessId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
