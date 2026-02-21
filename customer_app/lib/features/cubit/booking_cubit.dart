import 'package:cloud_functions/cloud_functions.dart';
import 'package:customer_app/core/location_service.dart';
import 'package:customer_app/features/cubit/booking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingCubit extends Cubit<BookingState>{
  final LocationService _locationService;
  final FirebaseFunctions _functions;

  BookingCubit({
    LocationService? locationService,
    FirebaseFunctions? functions,
  }) : _locationService = locationService ?? LocationService(),
  _functions = functions ?? FirebaseFunctions.instance,
  super(BookingInitial());

  Future<void> bookService(String serviceType) async {
    emit(BookingLoading());

    try {
      // Get user location
      final position = await _locationService.getCurrentLocation();
      
      final callable =
          _functions.httpsCallable('createServiceRequest');

      final result = await callable.call({
        "serviceType": serviceType,
        "latitude": position.latitude,
        "longitude": position.longitude,
        "dispatchType": "AUTO"
      });

      final requestId = result.data["requestId"];

      emit(BookingSuccess(requestId));
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        emit(BookingError(e.message ?? "Function failed"));
      } else {
        emit(BookingError(e.toString()));
      }
    }
  }
}