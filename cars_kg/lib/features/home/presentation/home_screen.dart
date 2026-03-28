import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/marketplace_bottom_nav.dart';
import '../../../shared/widgets/state_views.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listingState = ref.watch(homeListingsProvider);
    final isGrid = ref.watch(homeFeedIsGridProvider);
    final mode = ref.watch(homeFeedStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            onPressed: () => context.push('/listing/create'),
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.t('searchHint'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All'),
                ...mockCategories.map(_buildCategoryChip),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.tune),
                    label: Text(l10n.t('filters')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.swap_vert),
                    label: Text(l10n.t('sort')),
                  ),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  isSelected: [isGrid, !isGrid],
                  onPressed: (index) =>
                      ref.read(homeFeedIsGridProvider.notifier).state =
                          index == 0,
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: AppPalette.primary,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.grid_view_rounded, size: 18),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.view_list_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                SegmentedButton<DemoLoadState>(
                  segments: const [
                    ButtonSegment(
                      value: DemoLoadState.data,
                      label: Text('Data'),
                    ),
                    ButtonSegment(
                      value: DemoLoadState.empty,
                      label: Text('Empty'),
                    ),
                    ButtonSegment(
                      value: DemoLoadState.error,
                      label: Text('Error'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) {
                    ref.read(homeFeedPageProvider.notifier).state = 1;
                    ref.read(homeFeedStateProvider.notifier).state =
                        selection.first;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: listingState.when(
              loading: () =>
                  const LoadingStateView(label: 'Loading listings...'),
              error: (error, stackTrace) => ErrorStateView(
                message: error.toString(),
                onRetry: () => ref.invalidate(homeListingsProvider),
              ),
              data: (listings) {
                final filtered = _selectedCategory == 'All'
                    ? listings
                    : listings
                          .where((l) => l.category == _selectedCategory)
                          .toList();

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    title: l10n.t('empty'),
                    subtitle: 'Try another category or reset filters.',
                    actionLabel: 'Reset',
                    onAction: () => setState(() => _selectedCategory = 'All'),
                  );
                }

                Widget itemBuilder(BuildContext context, int index) {
                  final item = filtered[index];
                  return ListingCard(
                    listing: item,
                    isCompact: !isGrid,
                    onTap: () => context.push('/listing/${item.id}'),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: isGrid
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              itemCount: filtered.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.73,
                                  ),
                              itemBuilder: itemBuilder,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: itemBuilder,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.read(homeFeedPageProvider.notifier).state += 1,
                        child: Text(l10n.t('loadMore')),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MarketplaceBottomNav(
        currentPath: GoRouterState.of(context).uri.path,
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final selected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        label: Text(category),
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }
}
