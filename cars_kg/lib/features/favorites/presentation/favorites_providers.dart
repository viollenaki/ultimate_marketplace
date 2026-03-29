import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_models.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../listing/data/listing_from_api.dart';
import '../../listing/presentation/providers/listing_api_providers.dart';

/// Numeric listing ids the signed-in user has favorited (empty when logged out).
final favoriteListingIdsProvider = FutureProvider<Set<int>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return {};
  }
  final api = ref.watch(listingApiServiceProvider);
  final ids = await api.fetchFavoriteListingIds();
  return ids.toSet();
});

/// Full favorited listings from the API (empty when logged out).
final remoteFavoriteListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return [];
  }
  final api = ref.watch(listingApiServiceProvider);
  final raw = await api.fetchFavoriteListings();
  return raw
      .map((e) => listingFromApiJson(e, isFavorite: true))
      .toList();
});
