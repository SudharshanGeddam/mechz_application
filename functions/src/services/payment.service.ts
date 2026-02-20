import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Processes successful Razorpay payment webhook.
 * This function is:
 * - Idempotent
 * - Financially atomic
 * - Compatible with 24-hour settlement delay
 */
export const processSuccessfulPayment = async (payload: any) => {

  //  Defensive payload validation
  if (!payload?.payload?.payment?.entity) {
    throw new Error("Invalid webhook payload structure");
  }

  const paymentEntity = payload.payload.payment.entity;

  const razorpayOrderId: string = paymentEntity.order_id;
  const razorpayPaymentId: string = paymentEntity.id;
  const amountPaidInPaise: number = paymentEntity.amount;

  if (!razorpayOrderId || !razorpayPaymentId) {
    throw new Error("Missing Razorpay identifiers");
  }

  //  Locate payment record
  const paymentQuery = await db
    .collection("payments")
    .where("razorpayOrderId", "==", razorpayOrderId)
    .limit(1)
    .get();

  if (paymentQuery.empty) {
    throw new Error("Payment record not found");
  }

  const paymentDoc = paymentQuery.docs[0];
  const paymentRef = paymentDoc.ref;
  const paymentData = paymentDoc.data();

  const requestRef = db.collection("service_requests").doc(paymentData.requestId);
  const walletRef = db.collection("wallets").doc(paymentData.mechanicId);
  const mechanicRef = db.collection("mechanic_profiles").doc(paymentData.mechanicId);

  await db.runTransaction(async (transaction) => {

    const freshPaymentDoc = await transaction.get(paymentRef);

    if (!freshPaymentDoc.exists) {
      throw new Error("Payment record missing");
    }

    const freshPaymentData = freshPaymentDoc.data();

    //  Idempotency guard
    if (freshPaymentData?.status === "VERIFIED") {
      return;
    }

    const requestDoc = await transaction.get(requestRef);
    const mechanicDoc = await transaction.get(mechanicRef);

    if (!requestDoc.exists || !mechanicDoc.exists) {
      throw new Error("Related records missing");
    }

    const requestData = requestDoc.data();

    if (!requestData) {
      throw new Error("Request data missing");
    }

    // Lifecycle validation
    if (requestData.status !== "COMPLETED") {
      throw new Error("Request not completed. Cannot verify payment.");
    }

    if (requestData.paymentStatus === "PAID") {
      return; // Double safety
    }

    if (typeof requestData.finalPrice !== "number") {
      throw new Error("Invalid final price");
    }

    // Amount validation (integer math)
    const expectedAmountInPaise = Math.round(requestData.finalPrice * 100);

    if (expectedAmountInPaise !== amountPaidInPaise) {
      throw new Error("Payment amount mismatch");
    }

    //  Commission calculation (5%)
    const commissionInPaise = Math.round(amountPaidInPaise * 5 / 100);
    const mechanicEarningInPaise = amountPaidInPaise - commissionInPaise;

    const commission = commissionInPaise / 100;
    const mechanicEarning = mechanicEarningInPaise / 100;

    // Update payment record
    transaction.update(paymentRef, {
      status: "VERIFIED",
      settlementStatus: "PENDING",
      razorpayPaymentId: razorpayPaymentId,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update service request (DO NOT modify lifecycle state here)
    transaction.update(requestRef, {
      paymentStatus: "PAID",
      commissionAmount: commission,
      mechanicEarning: mechanicEarning,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Wallet update (Settlement model)
    const walletDoc = await transaction.get(walletRef);

    if (!walletDoc.exists) {
      transaction.set(walletRef, {
        totalEarned: mechanicEarning,
        totalWithdrawn: 0,
        pendingSettlement: mechanicEarning,
        availableBalance: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } else {
      const walletData = walletDoc.data();

      transaction.update(walletRef, {
        totalEarned: (walletData?.totalEarned || 0) + mechanicEarning,
        pendingSettlement:
          (walletData?.pendingSettlement || 0) + mechanicEarning,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Release mechanic after verified payment
    transaction.update(mechanicRef, {
      activeRequestId: null
    });

  });

};