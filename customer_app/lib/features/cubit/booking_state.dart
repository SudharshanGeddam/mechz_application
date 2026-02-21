import 'package:equatable/equatable.dart';

abstract class BookingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {
  final String bookingRequestId;

  BookingSuccess(this.bookingRequestId);

  @override
  List<Object?> get props => [bookingRequestId];
}

class BookingError extends BookingState {
  final String message;

  BookingError(this.message);

  @override
  List<Object?> get props => [message];
}
