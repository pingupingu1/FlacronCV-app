import * as functions from "firebase-functions";
import Stripe from "stripe";
import * as cors from "cors";

const stripe = new Stripe(
  functions.config().stripe.secret,
  { apiVersion: "2023-10-16" }
);

const corsHandler = cors({ origin: true });

export const createCheckoutSession = functions.https.onRequest(
  (req, res) => {
    corsHandler(req, res, async () => {
      const { amount, bookingId, customerEmail } = req.body;

      try {
        const session = await stripe.checkout.sessions.create({
          payment_method_types: ["card"],
          mode: "payment",
          customer_email: customerEmail,
          line_items: [
            {
              price_data: {
                currency: "usd",
                product_data: {
                  name: "FlacronCV Booking Payment",
                },
                unit_amount: amount * 100,
              },
              quantity: 1,
            },
          ],
          metadata: { bookingId },
          success_url:
            "https://flacroncv.web.app/payment-success",
          cancel_url:
            "https://flacroncv.web.app/payment-cancel",
        });

        res.json({ url: session.url });
      } catch (err) {
        res.status(500).send(err);
      }
    });
  }
);
