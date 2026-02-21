import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable{
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class CodeSent extends AuthState {
  late final String verificationId;

  CodeSent(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

class Authenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}