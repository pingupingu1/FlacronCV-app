import * as functions from "firebase-functions";
import Stripe from "stripe";
import * as admin from "firebase-admin";

const stripe = new Stripe(
  functions.config().stripe.secret,
  { apiVersion: "2023-10-16" }
);

export const stripeWebhook = functions.https.onRequest(
  async (req, res) => {
    const sig = req.headers["stripe-signature"] as string;

    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        functions.config().stripe.webhook
      );
    } catch (err) {
      return res.status(400).send("Webhook error");
    }

    if (event.type === "checkout.session.completed") {
      const session = event.data.object as any;
      const bookingId = session.metadata.bookingId;

      await admin.firestore()
        .collection("bookings")
        .doc(bookingId)
        .update({ paymentStatus: "paid" });
    }

    res.json({ received: true });
  }
);
