import 'package:customer_app/features/cubit/auth_state.dart';
import 'package:customer_app/features/repository/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  void checkAuthStatus() async {
    final user = _authRepository.currentUser;

    if (user == null) {
      emit(AuthInitial());
      return;
    }

    try {
      await _authRepository.ensureCustomerProfile();
      emit(Authenticated());
    } catch (_) {
      await _authRepository.signOut();
      emit(AuthInitial());
    }
  }

  void sendOtp(String phoneNumber) async {
    emit(AuthLoading());

    await _authRepository.verifyPhone(
      phoneNumber: phoneNumber,
      codeSent: (verificationId) {
        emit(CodeSent(verificationId));
      },
      onError: (error) {
        emit(AuthError(error));
      },
    );
  }

  Future<void> verifyOtp(String verificationId, String smsCode) async {
    try {
      emit(AuthLoading());

      await _authRepository.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _authRepository.ensureCustomerProfile();
      emit(Authenticated());
    } catch (e) {
      emit(AuthError("Invalid OTP"));
    }
  }

  void signOut() async {
    await _authRepository.signOut();
    emit(AuthInitial());
  }
}
