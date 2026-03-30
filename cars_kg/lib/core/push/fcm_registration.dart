import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../firebase_options.dart';

/// Must be a top-level function for background isolate (see [main.dart]).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('FCM background: ${message.messageId}');
  }
}

String _fcmPlatformLabel() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    default:
      return 'other';
  }
}

/// Retrieves the FCM registration token ([FirebaseMessaging.getToken]) and
/// registers it with the API (`POST /devices/fcm-token`).
class FcmRegistration {
  FcmRegistration._();

  static final FcmRegistration instance = FcmRegistration._();

  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> cancelTokenRefreshListener() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  /// Call when the user has a valid backend JWT (after login or session restore).
  Future<void> syncWithBackend(WidgetRef ref) async {
    final jwt = ref.read(authControllerProvider).jwt;
    if (jwt == null || jwt.isEmpty) return;

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.setAutoInitEnabled(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM setAutoInitEnabled: $e');
      }
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen(
      (newToken) {
        if (kDebugMode) {
          debugPrint('FCM token (refreshed): $newToken');
        }
        unawaited(_postToken(ref, newToken));
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('FCM onTokenRefresh error: $e');
        }
      },
    );

    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('FCM token: $token');
        }
        await _postToken(ref, token);
      } else if (kDebugMode) {
        debugPrint('FCM getToken returned null (emulator/web/no Google Play?)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM getToken failed: $e');
      }
    }
  }

  Future<void> _postToken(WidgetRef ref, String token) async {
    final t = token.trim();
    if (t.length < 10) return;

    try {
      final client = ref.read(authenticatedApiClientProvider);
      await client.postJson(
        '/devices/fcm-token',
        data: {
          'token': t,
          'platform': _fcmPlatformLabel(),
        },
      );
      if (kDebugMode) {
        debugPrint('FCM token registered with backend');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM register with backend failed: $e');
      }
    }
  }
}
