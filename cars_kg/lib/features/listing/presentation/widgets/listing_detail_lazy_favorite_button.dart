import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/mock/mock_models.dart';
import '../../../favorites/presentation/favorite_optimistic_notifier.dart';
import '../../../favorites/presentation/favorites_providers.dart';

/// Favorite toggle for listing detail: waits for [favoriteListingIdsProvider]
/// so the page shell is not tied to favorites fetch latency.
class ListingDetailLazyFavoriteButton extends ConsumerWidget {
  const ListingDetailLazyFavoriteButton({
    super.key,
    required this.listing,
    required this.listingId,
    this.onDemoModeTap,
  });

  final Listing listing;
  final int listingId;
  /// Mock / offline listing: show heart but call this instead of API.
  final VoidCallback? onDemoModeTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (onDemoModeTap != null) {
      return IconButton.outlined(
        onPressed: onDemoModeTap,
        icon: Icon(
          listing.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: listing.isFavorite ? Colors.redAccent : null,
        ),
      );
    }

    final favAsync = ref.watch(favoriteListingIdsProvider);
    final overrides = ref.watch(favoriteOptimisticNotifierProvider);

    return favAsync.when(
      loading: () => const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (err, _) => IconButton.outlined(
        tooltip: 'Retry',
        onPressed: () => ref.invalidate(favoriteListingIdsProvider),
        icon: const Icon(Icons.refresh),
      ),
      data: (ids) {
        final baseline = listing.copyWith(isFavorite: ids.contains(listingId));
        final isFav =
            FavoriteOptimisticNotifier.effectiveFavorite(overrides, baseline);
        return IconButton.outlined(
          onPressed: () => ref
              .read(favoriteOptimisticNotifierProvider.notifier)
              .requestToggle(baseline, context),
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.redAccent : null,
          ),
        );
      },
    );
  }
}
