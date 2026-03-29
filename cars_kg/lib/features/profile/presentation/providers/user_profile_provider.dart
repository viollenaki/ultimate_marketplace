import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/current_user_profile.dart';

final currentUserProfileProvider =
    FutureProvider.autoDispose<CurrentUserProfile?>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return null;
  }
  if (auth.jwt == null || auth.jwt!.isEmpty) {
    return null;
  }

  final client = ref.watch(authenticatedApiClientProvider);
  try {
    final response = await client.dio.get<Map<String, dynamic>>('/users/me');
    final data = response.data;
    if (data == null) {
      return null;
    }
    return CurrentUserProfile.fromJson(data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      return null;
    }
    throw Exception(e.message ?? 'Profile request failed');
  }
});

/// Resolved display name: API → Firebase displayName → email.
String profileDisplayName(CurrentUserProfile? api, User? firebaseUser) {
  final fromApi = api?.fullName.trim();
  if (fromApi != null && fromApi.isNotEmpty) {
    return fromApi;
  }
  final dn = firebaseUser?.displayName?.trim();
  if (dn != null && dn.isNotEmpty) {
    return dn;
  }
  return firebaseUser?.email?.trim() ?? '';
}

/// Resolved photo: API profile image → Firebase photo URL.
String? profilePhotoUrl(CurrentUserProfile? api, User? firebaseUser) {
  final u = api?.profileImageUrl?.trim();
  if (u != null && u.isNotEmpty) {
    return u;
  }
  final p = firebaseUser?.photoURL?.trim();
  if (p != null && p.isNotEmpty) {
    return p;
  }
  return null;
}
