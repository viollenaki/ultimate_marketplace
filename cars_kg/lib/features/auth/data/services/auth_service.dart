import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/network_helper.dart';
import '../datasources/local/auth_secure_storage.dart';
import '../exceptions/auth_exceptions.dart';
import '../../domain/entities/backend_auth_token.dart';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required ApiClient apiClient,
    required AuthSecureStorage secureStorage,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _api = apiClient,
       _secureStorage = secureStorage;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final ApiClient _api;
  final AuthSecureStorage _secureStorage;
  Future<void>? _googleSignInInitialization;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates the Firebase Auth account on device first; caller should exchange
  /// [UserCredential] for an API JWT via [authenticateWithBackend] (syncs DB).
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    final name = fullName.trim();
    if (user != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }
    return cred;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!await hasInternet()) {
      throw const NoInternetConnectionException();
    }

    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const BackendAuthException(
        'Google Sign-In did not return an ID token. Check Web client ID (serverClientId).',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return _firebaseAuth.signInWithCredential(credential);
  }

  /// `POST /auth/sessions` — exchange Firebase ID token for API JWT.
  /// Falls back to `POST /auth/login/firebase` on 404 (legacy backends).
  Future<BackendAuthToken> authenticateWithBackend(String idToken) async {
    if (!await hasInternet()) {
      throw const NoInternetConnectionException();
    }

    try {
      return await _postForTokens(
        '/auth/sessions',
        data: {'id_token': idToken},
      );
    } on BackendAuthException catch (e) {
      if (e.httpStatus == 404) {
        return _postForTokens(
          '/auth/login/firebase',
          data: {'id_token': idToken},
        );
      }
      rethrow;
    }
  }

  /// `POST /users` — server creates Firebase user + DB row (optional).
  Future<BackendAuthToken> registerWithBackend({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!await hasInternet()) {
      throw const NoInternetConnectionException();
    }

    return _postForTokens(
      '/users',
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
      },
    );
  }

  Future<BackendAuthToken> _postForTokens(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    Response<Map<String, dynamic>> response;
    try {
      response = await _api.postJson(path, data: data);
    } on DioException catch (e) {
      throw BackendAuthException(
        _backendErrorMessage(e),
        httpStatus: e.response?.statusCode,
      );
    }

    return _parseTokenResponse(response);
  }

  BackendAuthToken _parseTokenResponse(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data;
    if (data == null) {
      throw const BackendAuthException('Backend auth response is empty');
    }

    final tokenValue = data['token'] ?? data['jwt'] ?? data['access_token'];
    if (tokenValue is! String || tokenValue.isEmpty) {
      throw const BackendAuthException('Backend did not return a JWT token');
    }

    final expiresAt = _resolveExpiry(data, tokenValue);
    return BackendAuthToken.fromJwt(jwt: tokenValue, expiresAt: expiresAt);
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

  /// Clears Firebase + Google session only (keeps stored API JWT). Used when
  /// Firebase sign-in succeeded but exchanging for an API token failed.
  Future<void> discardFirebaseSession() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> _ensureGoogleSignInInitialized() {
    final existing = _googleSignInInitialization;
    if (existing != null) {
      return existing;
    }

    // Must be the Web OAuth client (client_type 3 in google-services.json), not
    // the Android client — otherwise Android returns "Developer console is not
    // set up correctly" when requesting an ID token for Firebase.
    final rawClientId = Env.googleOAuthClientId.trim();
    final serverClientId = rawClientId.isNotEmpty
        ? rawClientId
        : '700456212189-qrr31phd4ih8of5ujq1vp0akeo6q26qj.apps.googleusercontent.com';

    final initFuture = _googleSignIn.initialize(
      serverClientId: serverClientId,
    );
    _googleSignInInitialization = initFuture;
    return initFuture;
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

  /// Parses FastAPI JSON body `{ "success": false, "error": "..." }`.
  String _backendErrorMessage(DioException e) {
    if (_isUnreachableBackendError(e)) {
      return _unreachableBackendMessage();
    }
    final code = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is String && err.isNotEmpty) {
        return err;
      }
    }
    if (code != null) {
      return 'Backend request failed (HTTP $code)';
    }
    return e.message ?? 'Backend request failed';
  }

  bool _isUnreachableBackendError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    final combined = '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();
    return combined.contains('no route to host') ||
        combined.contains('connection refused') ||
        combined.contains('failed host lookup') ||
        combined.contains('network is unreachable');
  }

  String _unreachableBackendMessage() {
    final base = Env.apiBaseUrl;
    final buf = StringBuffer(
      'Cannot reach the API at $base. ',
    );
    if (base.contains('10.0.2.2')) {
      buf.write(
        '10.0.2.2 only works on an Android emulator. On a real phone set '
        'BACKEND_URL to your computer\'s Wi‑Fi address (e.g. http://192.168.1.5:8000) '
        'and clear BACKEND_USE_ANDROID_EMULATOR_HOST. ',
      );
    } else {
      buf.write(
        'Start the backend, use the same Wi‑Fi as this device, and set BACKEND_URL '
        'in .env if needed. ',
      );
    }
    buf.write('Firewall/VPN can also block the connection.');
    return buf.toString();
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
