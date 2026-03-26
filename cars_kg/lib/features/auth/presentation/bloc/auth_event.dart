abstract class AuthEvent {
  const AuthEvent();
}

class LoginRequested extends AuthEvent {
  const LoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
