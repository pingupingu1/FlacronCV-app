import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const bookingReminders =
  functions.pubsub.schedule("every 60 minutes").onRun(async () => {
    const now = new Date();
    const nextHour = new Date(now.getTime() + 60 * 60 * 1000);

    const snapshot = await admin.firestore()
      .collection("bookings")
      .where("bookingTime", ">=", now)
      .where("bookingTime", "<=", nextHour)
      .get();

    snapshot.forEach(doc => {
      // Email / push trigger placeholder
      console.log("Reminder for booking:", doc.id);
    });
  });
