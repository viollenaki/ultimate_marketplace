import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get backendUrl {
    final raw = dotenv.env['BACKEND_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      return 'http://localhost:8000';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return 'http://$raw';
  }

  const Env._();
}
