import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/backend_auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../exceptions/auth_exceptions.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final AuthService _service;

  @override
  Future<BackendAuthToken?> restoreSession() {
    return _service.readStoredBackendToken();
  }

  @override
  Future<BackendAuthToken> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _service.signInWithEmail(
      email: email,
      password: password,
    );

    return _exchangeFirebaseToken(credential);
  }

  @override
  Future<BackendAuthToken> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _service.signUpWithEmail(
      email: email,
      password: password,
    );

    return _exchangeFirebaseToken(credential);
  }

  @override
  Future<BackendAuthToken> signInWithGoogle() async {
    final credential = await _service.signInWithGoogle();
    return _exchangeFirebaseToken(credential);
  }

  @override
  Future<void> signOut() {
    return _service.signOut();
  }

  Future<BackendAuthToken> _exchangeFirebaseToken(
    UserCredential credential,
  ) async {
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw const BackendAuthException('Firebase authentication failed');
    }

    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw const BackendAuthException('Unable to retrieve Firebase ID token');
    }

    final backendToken = await _service.authenticateWithBackend(idToken);
    await _service.persistBackendToken(backendToken);
    return backendToken;
  }
}
