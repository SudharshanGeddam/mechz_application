import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/data/models/service_model.dart';

class ServiceRepository {
  late final FirebaseFirestore _firestore;

  ServiceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ServiceModel>> fetchServices() async {
    final snapshot = await _firestore
        .collection("service_catalog")
        .where("isActive", isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
