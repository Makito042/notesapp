import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

class Email extends FormzInput<String, String> {
  const Email.pure() : super.pure('');
  const Email.dirty([String value = '']) : super.dirty(value);

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  @override
  String? validator(String? value) {
    return _emailRegExp.hasMatch(value ?? '') ? null : 'Please enter a valid email';
  }

  bool get invalid => !isValid;
}

class Password extends FormzInput<String, String> {
  const Password.pure() : super.pure('');
  const Password.dirty([String value = '']) : super.dirty(value);

  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$',
  );

  @override
  String? validator(String? value) {
    return _passwordRegExp.hasMatch(value ?? '') ? null : 'Password must be at least 6 characters and contain at least one letter and one number';
  }

  bool get invalid => !isValid;
}

class SignupState extends Equatable {
  final Email email;
  final Password password;
  final Password confirmPassword;
  final String name;
  final bool termsAccepted;
  final FormzSubmissionStatus status;
  final String? error;
  final bool passwordsMatch;

  const SignupState({
    Email? email,
    Password? password,
    Password? confirmPassword,
    this.name = '',
    this.termsAccepted = false,
    this.status = FormzSubmissionStatus.initial,
    this.error,
    bool? passwordsMatch,
  }) : email = email ?? const Email.pure(),
       password = password ?? const Password.pure(),
       confirmPassword = confirmPassword ?? const Password.pure(),
       passwordsMatch = passwordsMatch ?? true;

  bool get isValid => 
      email.isValid && 
      password.isValid && 
      confirmPassword.isValid &&
      name.isNotEmpty && 
      termsAccepted &&
      passwordsMatch;

  SignupState copyWith({
    Email? email,
    Password? password,
    Password? confirmPassword,
    String? name,
    bool? termsAccepted,
    FormzSubmissionStatus? status,
    String? error,
    bool? passwordsMatch,
  }) {
    final newState = SignupState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      name: name ?? this.name,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      status: status ?? this.status,
      error: error,
      passwordsMatch: passwordsMatch ?? this.passwordsMatch,
    );

    // Check if passwords match when either password or confirmPassword changes
    if ((password != null || confirmPassword != null) && 
        newState.password.value.isNotEmpty && 
        newState.confirmPassword.value.isNotEmpty) {
      return newState.copyWith(
        passwordsMatch: newState.password.value == newState.confirmPassword.value,
      );
    }

    return newState;
  }

  @override
  List<Object?> get props => [
        email.value,
        password.value,
        confirmPassword.value,
        name,
        termsAccepted,
        status,
        error,
      ];
}
