import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const createInvoice = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (
      before.paymentStatus !== "paid" &&
      after.paymentStatus === "paid"
    ) {
      await admin.firestore().collection("invoices").add({
        bookingId: context.params.bookingId,
        businessId: after.businessId,
        amount: after.amount,
        status: "paid",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
