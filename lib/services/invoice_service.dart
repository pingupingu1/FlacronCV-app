import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceService {
  static Future<QuerySnapshot> getInvoices(String businessId) {
    return FirebaseFirestore.instance
        .collection('invoices')
        .where('businessId', isEqualTo: businessId)
        .get();
  }
}
