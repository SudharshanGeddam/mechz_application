import * as admin from "firebase-admin";

const db = admin.firestore();

const allowedTransitions: Record<string, string> = {
  ACCEPTED: "ARRIVING",
  ARRIVING: "IN_PROGRESS",
  IN_PROGRESS: "COMPLETED"
};

export const updateServiceStatusHandler = async (
  mechanicId: string,
  requestId: string,
  nextStatus: string
) => {

  const requestRef = db.collection("service_requests").doc(requestId);
  const mechanicRef = db.collection("mechanic_profiles").doc(mechanicId);

  return await db.runTransaction(async (transaction) => {

    const requestDoc = await transaction.get(requestRef);
    const mechanicDoc = await transaction.get(mechanicRef);

    if (!requestDoc.exists) {
      throw new Error("Request not found");
    }

    if (!mechanicDoc.exists) {
      throw new Error("Mechanic not found");
    }

    const requestData = requestDoc.data();

    // Ownership check
    if (requestData?.mechanicId !== mechanicId) {
      throw new Error("Not authorized for this request");
    }

    // Prevent updating after payment
    if (requestData?.paymentStatus === "PAID") {
      throw new Error("Request already completed");
    }

    const currentStatus = requestData?.status;

    // Validate transition
    if (allowedTransitions[currentStatus] !== nextStatus) {
      throw new Error("Invalid status transition");
    }

    transaction.update(requestRef, {
      status: nextStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      message: `Status updated to ${nextStatus}`
    };

  });
};