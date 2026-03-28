import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/marketplace_bottom_nav.dart';
import '../../../shared/widgets/state_views.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            onPressed: () => context.push('/listing/create'),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyStateView(
              title: 'No listings yet',
              subtitle: 'Create your first listing and it will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Stack(
                  children: [
                    ListingCard(
                      listing: item,
                      isCompact: true,
                      onTap: () => context.push('/listing/${item.id}'),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            context.push('/listing/${item.id}/edit'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: MarketplaceBottomNav(
        currentPath: GoRouterState.of(context).uri.path,
      ),
    );
  }
}
