import 'package:equatable/equatable.dart';

abstract class RequestStatusState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RequestStatusLoading extends RequestStatusState {}

class RequestStatusUpdated extends RequestStatusState {
  final String status;
  final String? mechanicId;

  RequestStatusUpdated({required this.status, this.mechanicId});

  @override
  List<Object?> get props => [status, mechanicId];
}

class RequestStatusError extends RequestStatusState {
  final String message;

  RequestStatusError(this.message);

  @override
  List<Object?> get props => [message];
}
