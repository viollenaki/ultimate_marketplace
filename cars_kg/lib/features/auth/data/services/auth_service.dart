import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/env.dart';
import '../../../../core/utils/network_helper.dart';
import '../datasources/local/auth_secure_storage.dart';
import '../exceptions/auth_exceptions.dart';
import '../../domain/entities/backend_auth_token.dart';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required Dio dio,
    required AuthSecureStorage secureStorage,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _dio = dio,
       _secureStorage = secureStorage;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final Dio _dio;
  final AuthSecureStorage _secureStorage;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!await hasInternet()) {
      throw const NoInternetConnectionException();
    }

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<BackendAuthToken> authenticateWithBackend(String idToken) async {
    if (!await hasInternet()) {
      throw const NoInternetConnectionException();
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '${Env.backendUrl}/auth/login/firebase',
      data: {'idToken': idToken},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = response.data;
    if (data == null) {
      throw const BackendAuthException('Backend auth response is empty');
    }

    final tokenValue = data['token'] ?? data['jwt'] ?? data['access_token'];
    if (tokenValue is! String || tokenValue.isEmpty) {
      throw const BackendAuthException('Backend did not return a JWT token');
    }

    final expiresAt = _resolveExpiry(data, tokenValue);
    return BackendAuthToken(jwt: tokenValue, expiresAt: expiresAt);
  }

  Future<void> persistBackendToken(BackendAuthToken token) {
    return _secureStorage.saveToken(token);
  }

  Future<BackendAuthToken?> readStoredBackendToken() {
    return _secureStorage.readToken();
  }

  Future<void> clearStoredBackendToken() {
    return _secureStorage.clear();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await clearStoredBackendToken();
  }

  DateTime _resolveExpiry(Map<String, dynamic> data, String tokenValue) {
    final expiresAtRaw = data['expires_at'] ?? data['expiresAt'];

    if (expiresAtRaw is String) {
      final parsedIso = DateTime.tryParse(expiresAtRaw);
      if (parsedIso != null) {
        return parsedIso.toUtc();
      }

      final parsedInt = int.tryParse(expiresAtRaw);
      if (parsedInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt, isUtc: true);
      }
    }

    if (expiresAtRaw is int) {
      return DateTime.fromMillisecondsSinceEpoch(expiresAtRaw, isUtc: true);
    }

    final expiresInRaw = data['expires_in'] ?? data['expiresIn'];
    if (expiresInRaw is int) {
      return DateTime.now().toUtc().add(Duration(seconds: expiresInRaw));
    }
    if (expiresInRaw is String) {
      final seconds = int.tryParse(expiresInRaw);
      if (seconds != null) {
        return DateTime.now().toUtc().add(Duration(seconds: seconds));
      }
    }

    try {
      final payload = _decodeJwtPayload(tokenValue);
      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
    } catch (_) {
      // Keep fallback below if payload parsing fails.
    }

    return DateTime.now().toUtc().add(const Duration(days: 1));
  }

  Map<String, dynamic> _decodeJwtPayload(String jwt) {
    final segments = jwt.split('.');
    if (segments.length != 3) {
      throw const FormatException('Invalid JWT format');
    }

    final normalized = base64Url.normalize(segments[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(payload) as Map<String, dynamic>;
  }
}
