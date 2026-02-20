import * as admin from "firebase-admin";
import { geohashQueryBounds, distanceBetween } from "geofire-common";

const db = admin.firestore();
const RADIUS_IN_KM = 5;
const MAX_CANDIDATES = 5;

export const dispatchServiceRequestHandler = async (
  requestId: string
) => {

  const requestRef = db.collection("service_requests").doc(requestId);
  const requestDoc = await requestRef.get();

  if (!requestDoc.exists) {
    throw new Error("Service request not found");
  }

  const requestData = requestDoc.data();

  if (requestData?.status !== "SEARCHING") {
    return;
  }

  const center: [number, number] = [
    requestData.location.latitude,
    requestData.location.longitude
  ];

  //  Get Geohash Bounds
  const bounds = geohashQueryBounds(center, RADIUS_IN_KM);

  const mechanicMatches: any[] = [];

  // Query Each Bound
  for (const b of bounds) {

    const snapshot = await db
      .collection("mechanic_profiles")
      .orderBy("geohash")
      .startAt(b[0])
      .endAt(b[1])
      .get();

    snapshot.docs.forEach(doc => {
      const data = doc.data();

      if (!data.isOnline || data.status !== "active") return;

      const mechanicLocation: [number, number] = [
        data.currentLocation.latitude,
        data.currentLocation.longitude
      ];

      const distanceInKm = distanceBetween(center, mechanicLocation);

      if (distanceInKm <= RADIUS_IN_KM) {
        mechanicMatches.push({
          id: doc.id,
          distance: distanceInKm
        });
      }
    });
  }

  // Sort by Distance
  mechanicMatches.sort((a, b) => a.distance - b.distance);

  // Take Top N
  const selectedMechanics = mechanicMatches
    .slice(0, MAX_CANDIDATES)
    .map(m => m.id);

  // Update Request with Candidates
  await requestRef.update({
    candidateMechanics: selectedMechanics,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

};
