import 'dart:convert';

class BackendAuthToken {
  const BackendAuthToken({
    required this.jwt,
    required this.expiresAt,
    this.userId,
    this.firebaseUid,
  });

  final String jwt;
  final DateTime expiresAt;
  final int? userId;
  final String? firebaseUid;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Fills [userId] / [firebaseUid] from the API JWT payload (`sub`, `firebase_uid`).
  factory BackendAuthToken.fromJwt({
    required String jwt,
    required DateTime expiresAt,
    int? userId,
    String? firebaseUid,
  }) {
    final fromClaims = _claimsFromJwt(jwt);
    final sub = fromClaims?['sub'];
    int? uid = userId;
    if (uid == null && sub is String) {
      uid = int.tryParse(sub);
    }
    if (uid == null && sub is int) {
      uid = sub;
    }
    String? fu = firebaseUid;
    final claimFu = fromClaims?['firebase_uid'];
    if (fu == null && claimFu is String && claimFu.isNotEmpty) {
      fu = claimFu;
    }
    return BackendAuthToken(
      jwt: jwt,
      expiresAt: expiresAt,
      userId: uid,
      firebaseUid: fu,
    );
  }

  static Map<String, dynamic>? _claimsFromJwt(String jwt) {
    try {
      final segments = jwt.split('.');
      if (segments.length != 3) {
        return null;
      }
      final normalized = base64Url.normalize(segments[1]);
      final json = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
