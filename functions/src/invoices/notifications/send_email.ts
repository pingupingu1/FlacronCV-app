import * as functions from "firebase-functions";
import * as sgMail from "@sendgrid/mail";

sgMail.setApiKey(functions.config().sendgrid.key);

export const sendEmail = functions.https.onCall(
  async ({ to, subject, text }) => {
    await sgMail.send({
      to,
      from: "no-reply@flacroncv.com",
      subject,
      text,
    });
  }
);
