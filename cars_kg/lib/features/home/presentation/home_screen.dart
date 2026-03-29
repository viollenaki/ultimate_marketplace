import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/mock/mock_models.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/car_filters_state.dart';
import 'car_filters_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  String? _selectedBrowseId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesBrowse(Listing listing, String? browseId) {
    if (browseId == null || browseId == 'all') return true;
    switch (browseId) {
      case 'parts':
      case 'tuning':
        return listing.category == 'Parts';
      case 'used':
        return listing.category == 'Used';
      case 'sales':
        return listing.category != 'Parts';
      default:
        return true;
    }
  }

  bool _matchesSearch(Listing listing, String q) {
    if (q.isEmpty) return true;
    final s = q.toLowerCase();
    return listing.title.toLowerCase().contains(s) ||
        listing.brand.toLowerCase().contains(s) ||
        listing.model.toLowerCase().contains(s);
  }

  List<Listing> _filterList(
    List<Listing> listings,
    CarFiltersState filters,
  ) {
    final q = _search.text.trim();
    return listings.where((listing) {
      if (!listingMatchesFilters(listing, filters)) return false;
      if (!_matchesBrowse(listing, _selectedBrowseId)) return false;
      if (!_matchesSearch(listing, q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listingState = ref.watch(homeListingsProvider);
    final filters = ref.watch(carFiltersProvider);

    return Scaffold(
      backgroundColor: AppPalette.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listing/create'),
        backgroundColor: AppPalette.accentGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('homeSellCar')),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l10n.t('searchHint'),
                        prefixIcon: const Icon(Icons.search, size: 22),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/filters'),
                    child: Text(
                      l10n.t('filters'),
                      style: const TextStyle(
                        color: AppPalette.accentGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (filters.hasAnyFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    label: Text(l10n.t('filtersReset')),
                    onPressed: () {
                      ref.read(carFiltersProvider.notifier).reset();
                      setState(() {});
                    },
                  ),
                ),
              ),
            SizedBox(
              height: 132,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: [
                  _BrowseCategoryCard(
                    l10n: l10n,
                    title: l10n.t('catAll'),
                    count: mockListings.length,
                    imageUrl:
                        'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=400&q=80',
                    selected: _selectedBrowseId == null || _selectedBrowseId == 'all',
                    onTap: () => setState(() => _selectedBrowseId = 'all'),
                  ),
                  ...mockCarBrowseCategories.map(
                    (c) => _BrowseCategoryCard(
                      l10n: l10n,
                      title: l10n.t(c.titleKey),
                      count: c.listingCount,
                      imageUrl: c.imageUrl,
                      selected: _selectedBrowseId == c.id,
                      onTap: () => setState(() => _selectedBrowseId = c.id),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                l10n.t('homePopularBrands'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            SizedBox(
              height: 84,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemCount: mockPopularBrands.length,
                itemBuilder: (context, i) {
                  final b = mockPopularBrands[i];
                  final letter = b.name.isNotEmpty ? b.name[0] : '?';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFE8E4F0),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 72,
                        child: Text(
                          b.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.t('homeFoundInCategory'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sort — coming soon')),
                      );
                    },
                    icon: const Icon(Icons.swap_vert, size: 22),
                    color: AppPalette.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: listingState.when(
                loading: () =>
                    const LoadingStateView(label: 'Loading cars...'),
                error: (error, stackTrace) => ErrorStateView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(homeListingsProvider),
                ),
                data: (listings) {
                  final filtered = _filterList(listings, filters);

                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      title: l10n.t('empty'),
                      subtitle: 'Try clearing filters or search.',
                      actionLabel: l10n.t('filtersReset'),
                      onAction: () {
                        ref.read(carFiltersProvider.notifier).reset();
                        _search.clear();
                        setState(() {
                          _selectedBrowseId = 'all';
                        });
                      },
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.58,
                          ),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ListingCard(
                              listing: item,
                              onTap: () => context.push('/listing/${item.id}'),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
      ),
    );
  }
}

class _BrowseCategoryCard extends StatelessWidget {
  const _BrowseCategoryCard({
    required this.l10n,
    required this.title,
    required this.count,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final String title;
  final int count;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppPalette.accentGreen : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imageUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatCount(count)} ${l10n.t('adsShort')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
    }
    return '$n';
  }
}
