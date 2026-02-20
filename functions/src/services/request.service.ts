import * as admin from "firebase-admin";
import { CreateServiceRequestInput } from "../types/request.types";
import { geohashForLocation } from "geofire-common";

const db = admin.firestore();

export const createServiceRequestHandler = async (
  uid: string,
  data: CreateServiceRequestInput
) => {

  // Validate Dispatch Type
  if (!["AUTO", "MANUAL"].includes(data.dispatchType)) {
    throw new Error("Invalid dispatch type");
  }

  // Validate Required Fields
  if (!data.serviceType || !data.latitude || !data.longitude) {
    throw new Error("Missing required fields");
  }

  // Check User Role
  const userDoc = await db.collection("users").doc(uid).get();

  if (!userDoc.exists) {
    throw new Error("User record not found");
  }

  const userData = userDoc.data();

  if (userData?.role !== "customer") {
    throw new Error("Only customers can create service requests");
  }

  if (userData?.status !== "active") {
    throw new Error("User account is not active");
  }

  // Prevent Multiple Active Requests
  const activeStatuses = [
    "SEARCHING",
    "ACCEPTED",
    "ARRIVING",
    "IN_PROGRESS"
  ];

  const activeRequestSnapshot = await db
    .collection("service_requests")
    .where("customerId", "==", uid)
    .where("status", "in", activeStatuses)
    .limit(1)
    .get();

  if (!activeRequestSnapshot.empty) {
    throw new Error("Customer already has an active service request");
  }

  // Fetch Service Catalog
  const serviceSnapshot = await db
    .collection("service_catalog")
    .where("name", "==", data.serviceType)
    .limit(1)
    .get();

  if (serviceSnapshot.empty) {
    throw new Error("Invalid service selected");
  }

  const serviceData = serviceSnapshot.docs[0].data();

  if (!serviceData.isActive) {
    throw new Error("Selected service is not active");
  }

  const finalPrice = serviceData.basePrice;

  //  Generate Geohash
  const geohash = geohashForLocation([
    data.latitude,
    data.longitude
  ]);

  // Create Request Document
  const requestRef = db.collection("service_requests").doc();

  await requestRef.set({
    customerId: uid,
    mechanicId: null,
    candidateMechanics: [],
    serviceName: serviceData.name,
    finalPrice: finalPrice,
    location: new admin.firestore.GeoPoint(
      data.latitude,
      data.longitude
    ),
    geohash: geohash,
    status: "SEARCHING",
    paymentStatus: "PENDING",
    dispatchType: data.dispatchType,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return {
    requestId: requestRef.id,
    message: "Service request created successfully"
  };
};
