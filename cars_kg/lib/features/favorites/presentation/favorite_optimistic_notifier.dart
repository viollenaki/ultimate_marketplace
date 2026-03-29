import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_models.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/auth_required_dialog.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../home/presentation/home_feed_notifier.dart';
import '../../listing/data/listing_api_service.dart';
import '../../listing/presentation/providers/listing_api_providers.dart';
import '../../listing/presentation/providers/remote_listing_provider.dart';
import 'favorites_providers.dart';

/// Optimistic favorite toggles: UI updates immediately; API runs in the background
/// without blocking on a full home-feed refetch.
class FavoriteOptimisticNotifier extends Notifier<Map<int, bool>> {
  final Set<int> _inFlight = {};

  @override
  Map<int, bool> build() => {};

  /// Effective favorite for UI: [overrides] win over [listing.isFavorite].
  static bool effectiveFavorite(Map<int, bool> overrides, Listing listing) {
    final id = int.tryParse(listing.id);
    if (id == null) return listing.isFavorite;
    return overrides[id] ?? listing.isFavorite;
  }

  /// Applies optimistic [isFavorite] for display (e.g. merged listing for cards).
  static Listing listingWithEffectiveFavorite(
    Map<int, bool> overrides,
    Listing listing,
  ) {
    final id = int.tryParse(listing.id);
    if (id == null) return listing;
    final v = overrides[id];
    if (v == null) return listing;
    return listing.copyWith(isFavorite: v);
  }

  Future<void> requestToggle(Listing listing, BuildContext context) async {
    final id = int.tryParse(listing.id);
    if (id == null) return;
    if (_inFlight.contains(id)) return;

    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      await showAuthRequiredDialog(context);
      return;
    }

    _inFlight.add(id);
    final baseline = listing.isFavorite;
    final current = state[id] ?? baseline;
    final next = !current;
    state = {...state, id: next};

    final api = ref.read(listingApiServiceProvider);
    try {
      if (next) {
        await api.addFavorite(id);
      } else {
        await api.removeFavorite(id);
      }
      try {
        ref.read(homeFeedProvider.notifier).patchListingFavorite(id, next);
        state = Map<int, bool>.from(state)..remove(id);
        ref.invalidate(favoriteListingIdsProvider);
        ref.invalidate(remoteListingProvider(id));
        ref.invalidate(remoteFavoriteListingsProvider);
      } catch (_) {
        // Provider graph may be torn down (e.g. navigated away).
      }
    } on ListingApiException catch (e) {
      try {
        state = Map<int, bool>.from(state)..remove(id);
      } catch (_) {}
      if (context.mounted) {
        showNotReadySnackBar(context, e.message);
      }
    } finally {
      _inFlight.remove(id);
    }
  }
}

final favoriteOptimisticNotifierProvider =
    NotifierProvider<FavoriteOptimisticNotifier, Map<int, bool>>(
  FavoriteOptimisticNotifier.new,
);
