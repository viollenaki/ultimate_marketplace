import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../domain/entities/backend_auth_token.dart';

class AuthSecureStorage {
  AuthSecureStorage(this._storage);

  static const _jwtKey = 'backend_jwt';
  static const _expiryKey = 'backend_jwt_expiry';
  static const _userIdKey = 'backend_user_id';
  static const _firebaseUidKey = 'backend_firebase_uid';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(BackendAuthToken token) async {
    await _storage.write(key: _jwtKey, value: token.jwt);
    await _storage.write(
      key: _expiryKey,
      value: token.expiresAt.toUtc().millisecondsSinceEpoch.toString(),
    );
    if (token.userId != null) {
      await _storage.write(key: _userIdKey, value: token.userId.toString());
    } else {
      await _storage.delete(key: _userIdKey);
    }
    if (token.firebaseUid != null && token.firebaseUid!.isNotEmpty) {
      await _storage.write(key: _firebaseUidKey, value: token.firebaseUid);
    } else {
      await _storage.delete(key: _firebaseUidKey);
    }
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

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    final storedUserIdRaw = await _storage.read(key: _userIdKey);
    final storedFirebaseUid = await _storage.read(key: _firebaseUidKey);
    int? storedUserId = int.tryParse(storedUserIdRaw ?? '');

    final token = BackendAuthToken.fromJwt(
      jwt: jwt,
      expiresAt: expiresAt,
      userId: storedUserId,
      firebaseUid: storedFirebaseUid,
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
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _firebaseUidKey);
  }
}
