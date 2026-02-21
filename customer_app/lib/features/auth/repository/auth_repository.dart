import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  AuthRepository ({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
  _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      }, verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "Verification failed");
      }, codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      }, codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    await _auth.signInWithCredential(credential);
  }

  Future<void> ensureCustomerProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final userRef = _firestore.collection("users").doc(user.uid);
    final userDoc = await userRef.get();

    // Case 1: User document exists
    if (userDoc.exists) {
      final role = userDoc.data()?["role"];

      if (role != "customer") {
        throw Exception("Access denied: Not a customer");
      }

      return; // Valid customer
    }

    // Case 2: No user document yet
    // Check if mechanic profile exists
    final mechanicDoc = await _firestore
        .collection("mechanic_profiles")
        .doc(user.uid)
        .get();

    if (mechanicDoc.exists) {
      throw Exception("Access denied: Registered as mechanic");
    }

    // Safe to create as customer
    await userRef.set({
      "role": "customer",
      "status": "active",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
   Future<void> signOut() async {
      await _auth.signOut();
  }
}