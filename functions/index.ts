import * as admin from "firebase-admin";

admin.initializeApp();

// 🔹 Stripe Payments
export { createCheckoutSession } from "./stripe/create_checkout";
export { stripeWebhook } from "./stripe/stripe_webhook";

// 🔹 Invoicing
export { createInvoice } from "./invoices/create_invoice";

// 🔹 Notifications
export { sendEmail } from "./notifications/send_email";
export { bookingReminders } from "./notifications/booking_reminders";
