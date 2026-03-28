import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../domain/entities/backend_auth_token.dart';

class AuthSecureStorage {
  AuthSecureStorage(this._storage);

  static const _jwtKey = 'backend_jwt';
  static const _expiryKey = 'backend_jwt_expiry';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(BackendAuthToken token) async {
    await _storage.write(key: _jwtKey, value: token.jwt);
    await _storage.write(
      key: _expiryKey,
      value: token.expiresAt.toUtc().millisecondsSinceEpoch.toString(),
    );
  }

  Future<BackendAuthToken?> readToken() async {
    final jwt = await _storage.read(key: _jwtKey);
    final expiryRaw = await _storage.read(key: _expiryKey);

    if (jwt == null || expiryRaw == null) {
      return null;
    }

    final millis = int.tryParse(expiryRaw);
    if (millis == null) {
      await clear();
      return null;
    }

    final token = BackendAuthToken(
      jwt: jwt,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
    );

    if (token.isExpired) {
      await clear();
      return null;
    }

    return token;
  }

  Future<void> clear() async {
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _expiryKey);
  }
}
