import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock/mock_models.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/listing_report_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'favorite_optimistic_notifier.dart';
import 'favorites_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  void _toggleFavorite(
    WidgetRef ref,
    BuildContext context, {
    required Listing listing,
  }) {
    ref
        .read(favoriteOptimisticNotifierProvider.notifier)
        .requestToggle(listing, context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMock = ref.watch(mockModeProvider);

    if (useMock) {
      final favorites = ref.watch(favoriteListingsProvider);
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: favorites.when(
          loading: () => const LoadingStateView(label: 'Loading favorites...'),
          error: (error, stackTrace) => ErrorStateView(
            message: error.toString(),
            onRetry: () => ref.invalidate(favoriteListingsProvider),
          ),
          data: (items) => _FavoritesGrid(
            items: items,
            favoriteOverrides: const {},
            onFavoritePressed: null,
            onReportPressed: null,
          ),
        ),
      );
    }

    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const EmptyStateView(
          title: 'Sign in to see favorites',
          subtitle:
              'Log in to save listings with the heart icon and view them here.',
        ),
      );
    }

    final favorites = ref.watch(remoteFavoriteListingsProvider);
    final favoriteOverrides = ref.watch(favoriteOptimisticNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.when(
        loading: () => const LoadingStateView(label: 'Loading favorites...'),
        error: (error, stackTrace) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(remoteFavoriteListingsProvider),
        ),
        data: (items) => _FavoritesGrid(
          items: items,
          favoriteOverrides: favoriteOverrides,
          onFavoritePressed: (listing) =>
              _toggleFavorite(ref, context, listing: listing),
          onReportPressed: (listing) async {
            final id = int.tryParse(listing.id);
            if (id == null) return;
            await showListingReportSheet(context, listingId: id);
          },
        ),
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({
    required this.items,
    required this.favoriteOverrides,
    required this.onFavoritePressed,
    required this.onReportPressed,
  });

  final List<Listing> items;
  final Map<int, bool> favoriteOverrides;
  final void Function(Listing listing)? onFavoritePressed;
  final void Function(Listing listing)? onReportPressed;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyStateView(
        title: 'No favorites yet',
        subtitle: 'Tap the heart icon on any listing to save it here.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // ListingCard image + padded text needs more vertical space than 0.73
        // provides at typical phone widths (avoids inner Column overflow).
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final cardListing =
            FavoriteOptimisticNotifier.listingWithEffectiveFavorite(
          favoriteOverrides,
          item,
        );
        return ListingCard(
          listing: cardListing,
          isCompact: true,
          onTap: () => context.push('/listing/${item.id}'),
          onFavoritePressed: onFavoritePressed == null
              ? null
              : () => onFavoritePressed!(item),
          onReportPressed: onReportPressed == null
              ? null
              : () => onReportPressed!(item),
        );
      },
    );
  }
}
