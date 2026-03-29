import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// Server origin only, e.g. `http://192.168.0.173:8000` — no `/api/v1`.
  /// Set `BACKEND_URL` in `.env` (with or without `/api/v1`; it is normalized away).
  static String get backendOrigin {
    final raw = dotenv.env['BACKEND_URL']?.trim();
    late String url;
    if (raw == null || raw.isEmpty) {
      url = 'http://localhost:8000';
    } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
      url = raw;
    } else {
      url = 'http://$raw';
    }
    final mapToEmulatorHost =
        dotenv.env['BACKEND_USE_ANDROID_EMULATOR_HOST']?.toLowerCase() == 'true';
    if (mapToEmulatorHost &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      url = url.replaceFirst('localhost', '10.0.2.2');
      url = url.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final lower = url.toLowerCase();
    const suffix = '/api/v1';
    if (lower.endsWith(suffix)) {
      url = url.substring(0, url.length - suffix.length);
      while (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
    }
    return url;
  }

  /// REST API base: `{backendOrigin}/api/v1`. Use with [ApiClient] (relative paths).
  static String get apiBaseUrl => '$backendOrigin/api/v1';

  /// Same as [backendOrigin] (legacy name).
  static String get backendUrl => backendOrigin;

  /// `GET` liveness: `{apiBaseUrl}/health`.
  static String get backendHealthUrl => '$apiBaseUrl/health';

  /// Optional full URL for a dedicated LAN ping; defaults to [backendHealthUrl].
  static String get lanHealthCheckUrl {
    final raw = dotenv.env['LAN_HEALTH_CHECK_URL']?.trim();
    if (raw != null && raw.isNotEmpty) {
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return raw.replaceAll(RegExp(r'/+$'), '');
      }
      return 'http://${raw.replaceAll(RegExp(r'^/+'), '')}';
    }
    return backendHealthUrl;
  }

  static String get googleOAuthClientId =>
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ?? '';

  const Env._();
}
