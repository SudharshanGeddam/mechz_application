import * as admin from "firebase-admin";
admin.initializeApp();

import { onCall, HttpsError, onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as crypto from "crypto";

// Service imports
import { createServiceRequestHandler } from "./services/request.service";
import { dispatchServiceRequestHandler } from "./services/dispatch.service";
import { acceptServiceRequestHandler } from "./services/accept.service";
import { processSuccessfulPayment } from "./services/payment.service";

import { onSchedule } from "firebase-functions/v2/scheduler";


/* -------------------------------------------------------------------------- */
/*                            CREATE SERVICE REQUEST                          */
/* -------------------------------------------------------------------------- */

export const createServiceRequest = onCall(
  async (request) => {

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = request.auth.uid;

    return await createServiceRequestHandler(uid, request.data);
  }
);


/* -------------------------------------------------------------------------- */
/*                         DISPATCH ON DOCUMENT CREATE                        */
/* -------------------------------------------------------------------------- */

export const onServiceRequestCreated = onDocumentCreated(
  "service_requests/{requestId}",
  async (event) => {

    const requestId = event.params.requestId;

    if (!requestId) return;

    await dispatchServiceRequestHandler(requestId);
  }
);


/* -------------------------------------------------------------------------- */
/*                           ACCEPT SERVICE REQUEST                           */
/* -------------------------------------------------------------------------- */

export const acceptServiceRequest = onCall(
  async (request) => {

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    const mechanicId = request.auth.uid;
    const requestId = request.data?.requestId;

    if (!requestId) {
      throw new HttpsError(
        "invalid-argument",
        "Request ID is required"
      );
    }

    return await acceptServiceRequestHandler(mechanicId, requestId);
  }
);


/* -------------------------------------------------------------------------- */
/*                            RAZORPAY WEBHOOK (v2)                           */
/* -------------------------------------------------------------------------- */

export const razorpayWebhook = onRequest(
  async (req, res) => {

    try {

      const secret = process.env.RAZORPAY_KEY_SECRET;

      if (!secret) {
        res.status(500).send("Missing RAZORPAY_KEY_SECRET");
        return;
      }

      const signature = req.headers["x-razorpay-signature"] as string;

      if (!signature) {
        res.status(400).send("Missing signature");
        return;
      }

      // IMPORTANT: rawBody is required for signature validation
      const rawBody = (req as any).rawBody;

      if (!rawBody) {
        res.status(400).send("Missing raw body");
        return;
      }

      const expectedSignature = crypto
        .createHmac("sha256", secret)
        .update(rawBody)
        .digest("hex");

      if (signature !== expectedSignature) {
        res.status(400).send("Invalid signature");
        return;
      }

      const event = req.body?.event;

      if (event === "payment.captured") {
        await processSuccessfulPayment(req.body);
      }

      // Always respond 200 for valid signature
      res.status(200).send("Webhook processed");

    } catch (error) {
      console.error("Webhook error:", error);
      res.status(500).send("Internal Server Error");
    }

  }
);

export const settlementScheduler = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Asia/Kolkata",
  },
  async () => {

    const db = admin.firestore();

    const now = admin.firestore.Timestamp.now();
    const twentyFourHoursAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 24 * 60 * 60 * 1000
    );

    const eligiblePayments = await db
      .collection("payments")
      .where("status", "==", "VERIFIED")
      .where("settlementStatus", "==", "PENDING")
      .where("verifiedAt", "<=", twentyFourHoursAgo)
      .limit(50) // batch limit for safety
      .get();

    if (eligiblePayments.empty) {
      console.log("No payments eligible for settlement");
      return;
    }

    for (const doc of eligiblePayments.docs) {

      const paymentData = doc.data();
      const paymentRef = doc.ref;

      const walletRef = db.collection("wallets").doc(paymentData.mechanicId);

      await db.runTransaction(async (transaction) => {

        const freshPaymentDoc = await transaction.get(paymentRef);

        if (!freshPaymentDoc.exists) return;

        const freshPaymentData = freshPaymentDoc.data();

        // Double safety
        if (
          freshPaymentData?.settlementStatus !== "PENDING" ||
          freshPaymentData?.status !== "VERIFIED"
        ) {
          return;
        }

        const walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw new Error("Wallet not found during settlement");
        }

        const walletData = walletDoc.data();

        const earning = freshPaymentData.mechanicEarning;

        transaction.update(walletRef, {
          pendingSettlement: (walletData?.pendingSettlement || 0) - earning,
          availableBalance: (walletData?.availableBalance || 0) + earning,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        transaction.update(paymentRef, {
          settlementStatus: "SETTLED",
          settledAt: admin.firestore.FieldValue.serverTimestamp()
        });

      });

    }

    console.log("Settlement cycle completed");

  }
);