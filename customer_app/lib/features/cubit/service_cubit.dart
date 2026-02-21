import 'package:customer_app/features/cubit/service_state.dart';
import 'package:customer_app/features/repository/service_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServiceCubit extends Cubit<ServiceState> {
  final ServiceRepository _serviceRepository;

  ServiceCubit(this._serviceRepository) : super(ServiceInitial());

  void loadServices() async {
    emit(ServiceLoading());

    try {
      final services = await _serviceRepository.fetchServices();
      emit(ServiceLoaded(services));
    } catch (e) {
      emit(ServiceError("Failed to load services"));
    }
  }
}
