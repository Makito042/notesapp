import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formz/formz.dart';
import 'package:notes_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes_app/features/auth/presentation/cubit/signup/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  SignupCubit(this._authRepository) : super(const SignupState()) {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(state.copyWith(status: FormzSubmissionStatus.success));
      }
    });
  }

  void emailChanged(String value) {
    final email = Email.dirty(value);
    emit(state.copyWith(
      email: email,
      status: FormzSubmissionStatus.initial,
    ));
  }

  void passwordChanged(String value) {
    final password = Password.dirty(value);
    final confirmPassword = state.confirmPassword.isPure 
        ? state.confirmPassword 
        : state.confirmPassword.value == value 
            ? Password.dirty(value) 
            : state.confirmPassword;
    
    final passwordsMatch = value == confirmPassword.value;
    
    emit(state.copyWith(
      password: password,
      confirmPassword: confirmPassword,
      status: FormzSubmissionStatus.initial,
      passwordsMatch: passwordsMatch,
    ));
  }

  void confirmPasswordChanged(String value) {
    final confirmPassword = Password.dirty(value);
    final passwordsMatch = state.password.value == value;
    
    emit(state.copyWith(
      confirmPassword: confirmPassword,
      status: FormzSubmissionStatus.initial,
      passwordsMatch: passwordsMatch,
    ));
  }

  void nameChanged(String value) {
    emit(state.copyWith(
      name: value,
      status: FormzSubmissionStatus.initial,
    ));
  }

  void termsChanged(bool value) {
    emit(state.copyWith(
      termsAccepted: value,
      status: FormzSubmissionStatus.initial,
    ));
  }

  Future<void> signup() async {
    if (!state.isValid || state.status == FormzSubmissionStatus.inProgress) return;

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      await _authRepository.signUpWithEmailAndPassword(
        email: state.email.value,
        password: state.password.value,
        displayName: state.name,
      );
      // State will be updated via the auth state listener
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        error: _mapFirebaseError(e.code),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        error: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
