import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/features/cubit/request_status_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestStatusCubit extends Cubit<RequestStatusState> {
  final FirebaseFirestore _firestore;
  final String requestId;

  RequestStatusCubit(this.requestId)
    : _firestore = FirebaseFirestore.instance,
      super(RequestStatusLoading()) {
    listenToRequest();
  }

  void listenToRequest() {
    _firestore
        .collection("service_requests")
        .doc(requestId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              emit(RequestStatusError("Request not found"));
              return;
            }

            final data = snapshot.data();
            final geo = data?["location"] as GeoPoint;
            emit(
              RequestStatusUpdated(
                status: data?["status"] ?? "UNKNOWN",
                mechanicId: data?["mechanicId"],
                customerLat: geo.latitude,
                customerLng: geo.longitude,
              ),
            );
          },
          onError: (error) {
            emit(RequestStatusError(error.toString()));
          },
        );
  }
}
