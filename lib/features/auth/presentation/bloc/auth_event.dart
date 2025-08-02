abstract class AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested(this.email, this.password);
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final String name;
  final String country;

  SignUpRequested(
    this.email,
    this.password,
    this.role,
    this.name,
    this.country,
  );
}

class SignOutRequested extends AuthEvent {}

class GoogleSignInRequested extends AuthEvent {}
