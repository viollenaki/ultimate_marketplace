import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/marketplace_bottom_nav.dart';
import '../../../shared/widgets/state_views.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.when(
        loading: () => const LoadingStateView(label: 'Loading favorites...'),
        error: (error, stackTrace) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(favoriteListingsProvider),
        ),
        data: (items) {
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
              childAspectRatio: 0.73,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListingCard(
                listing: item,
                onTap: () => context.push('/listing/${item.id}'),
              );
            },
          );
        },
      ),
      bottomNavigationBar: MarketplaceBottomNav(
        currentPath: GoRouterState.of(context).uri.path,
      ),
    );
  }
}
