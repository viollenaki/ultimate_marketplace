import '../entities/backend_auth_token.dart';

abstract class AuthRepository {
  Future<BackendAuthToken?> restoreSession();
  Future<BackendAuthToken> signInWithEmail({
    required String email,
    required String password,
  });
  Future<BackendAuthToken> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<BackendAuthToken> signInWithGoogle();
  Future<void> signOut();
}
