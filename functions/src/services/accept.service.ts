import * as admin from "firebase-admin";

const db = admin.firestore();

export const acceptServiceRequestHandler = async (
  mechanicId: string,
  requestId: string
) => {

  const requestRef = db.collection("service_requests").doc(requestId);
  const mechanicRef = db.collection("mechanic_profiles").doc(mechanicId);
  const userRef = db.collection("users").doc(mechanicId);

  return await db.runTransaction(async (transaction) => {

    const requestDoc = await transaction.get(requestRef);
    const mechanicDoc = await transaction.get(mechanicRef);
    const userDoc = await transaction.get(userRef);

    if (!requestDoc.exists) {
      throw new Error("Service request not found");
    }

    if (!mechanicDoc.exists || !userDoc.exists) {
      throw new Error("Mechanic not found");
    }

    const requestData = requestDoc.data();
    const mechanicData = mechanicDoc.data();
    const userData = userDoc.data();

    //  Role validation
    if (userData?.role !== "mechanic") {
      throw new Error("Only mechanics can accept requests");
    }

    if (userData?.status !== "active") {
      throw new Error("Mechanic account not active");
    }

    // Mechanic availability
    if (!mechanicData?.isOnline) {
      throw new Error("Mechanic is offline");
    }

    if (mechanicData?.activeRequestId) {
      throw new Error("Mechanic already has an active job");
    }

    //  Request validation
    if (requestData?.status !== "SEARCHING") {
      throw new Error("Request no longer available");
    }

    if (requestData?.mechanicId !== null) {
      throw new Error("Request already assigned");
    }

    //  Candidate validation
    const candidates: string[] = requestData?.candidateMechanics || [];

    if (!candidates.includes(mechanicId)) {
      throw new Error("Mechanic not eligible for this request");
    }

    // Assign mechanic atomically
    transaction.update(requestRef, {
      mechanicId: mechanicId,
      status: "ACCEPTED",
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    transaction.update(mechanicRef, {
      activeRequestId: requestId
    });

    return {
      message: "Request accepted successfully"
    };

  });
};