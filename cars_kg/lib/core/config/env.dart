import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get backendUrl {
    final raw = dotenv.env['BACKEND_URL']?.trim();
    late String url;
    if (raw == null || raw.isEmpty) {
      url = 'http://localhost:8000';
    } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
      url = raw;
    } else {
      url = 'http://$raw';
    }
    // Android emulator: localhost is the emulator, not the dev machine. 10.0.2.2
    // is the host loopback. Physical device: set BACKEND_URL to your PC's LAN IP.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url.replaceFirst('localhost', '10.0.2.2');
      url = url.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  static String get googleOAuthClientId =>
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ?? '';

  const Env._();
}
