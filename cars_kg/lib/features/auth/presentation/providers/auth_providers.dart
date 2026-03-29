import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_providers.dart';
import '../../data/datasources/local/auth_secure_storage.dart';
import '../../data/exceptions/auth_exceptions.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../domain/entities/backend_auth_token.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({
    required this.initialized,
    required this.isLoading,
    required this.isAuthenticated,
    this.errorMessage,
    this.jwt,
    this.tokenExpiresAt,
    this.userEmail,
    this.userId,
    this.firebaseUid,
  });

  final bool initialized;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;
  final String? jwt;
  final DateTime? tokenExpiresAt;
  final String? userEmail;
  final int? userId;
  final String? firebaseUid;

  factory AuthState.initial() => const AuthState(
    initialized: false,
    isLoading: false,
    isAuthenticated: false,
  );

  AuthState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? jwt,
    DateTime? tokenExpiresAt,
    String? userEmail,
    int? userId,
    String? firebaseUid,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      jwt: jwt ?? this.jwt,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      userEmail: userEmail ?? this.userEmail,
      userId: userId ?? this.userId,
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn.instance,
);
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);
final authSecureStorageProvider = Provider<AuthSecureStorage>(
  (ref) => AuthSecureStorage(ref.watch(secureStorageProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(authSecureStorageProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authServiceProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// API client that sends `Authorization: Bearer` from [authControllerProvider].
final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(ApiClient.baseOptions());
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final jwt = ref.read(authControllerProvider).jwt;
        if (jwt != null && jwt.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $jwt';
        }
        handler.next(options);
      },
    ),
  );
  return ApiClient.withDio(dio);
});

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    unawaited(_restoreSession());
    return AuthState.initial();
  }

  Future<void> _restoreSession() async {
    final token = await _repository.restoreSession();
    if (token == null) {
      state = state.copyWith(
        initialized: true,
        isAuthenticated: false,
        clearErrorMessage: true,
      );
      return;
    }

    final userEmail = ref.read(firebaseAuthProvider).currentUser?.email;
    state = state.copyWith(
      initialized: true,
      isAuthenticated: true,
      clearErrorMessage: true,
      jwt: token.jwt,
      tokenExpiresAt: token.expiresAt,
      userEmail: userEmail,
      userId: token.userId,
      firebaseUid: token.firebaseUid,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final token = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      _setAuthenticated(token);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final token = await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      _setAuthenticated(token);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final token = await _repository.signInWithGoogle();
      _setAuthenticated(token);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(error));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = AuthState(
      initialized: true,
      isLoading: false,
      isAuthenticated: false,
      userEmail: null,
      jwt: null,
      tokenExpiresAt: null,
      userId: null,
      firebaseUid: null,
    );
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  void _setAuthenticated(BackendAuthToken token) {
    state = state.copyWith(
      initialized: true,
      isLoading: false,
      isAuthenticated: true,
      clearErrorMessage: true,
      jwt: token.jwt,
      tokenExpiresAt: token.expiresAt,
      userEmail: ref.read(firebaseAuthProvider).currentUser?.email,
      userId: token.userId,
      firebaseUid: token.firebaseUid,
    );
  }

  String _mapError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Invalid email format';
        case 'invalid-credential':
          return 'Wrong email or password';
        case 'user-not-found':
          return 'User not found';
        case 'wrong-password':
          return 'Wrong password';
        case 'email-already-in-use':
          return 'Email is already in use';
        case 'weak-password':
          return 'Password should be at least 8 characters';
        case 'network-request-failed':
          return 'Network error; check your connection and try again.';
      }
      // e.g. [firebase_auth/unknown] ... Connection reset — TLS/TCP to Google dropped
      final hint = (error.message ?? '').toLowerCase();
      if (error.code == 'unknown' &&
          (hint.contains('connection reset') ||
              hint.contains('connection refused') ||
              hint.contains('broken pipe') ||
              hint.contains('timed out') ||
              hint.contains('failed to connect') ||
              hint.contains('unable to resolve host'))) {
        return 'Could not reach Google sign-in (connection was reset). '
            'Try another Wi-Fi or mobile data, disable VPN, and ensure '
            'google.com is reachable.';
      }
    }
    if (error is BackendAuthException) {
      return error.message;
    }
    return error.toString();
  }
}
