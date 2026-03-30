import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/mock/mock_models.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/auth_required_dialog.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/listing_report_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../favorites/presentation/favorite_optimistic_notifier.dart';
import '../domain/car_filters_state.dart';
import 'car_filters_provider.dart';
import 'home_feed_notifier.dart';
import 'home_feed_search_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(homeFeedSearchQueryProvider.notifier).setQuery(value.trim());
    });
  }

  void _onScroll() {
    final pos = _scroll.position;
    if (!pos.hasViewportDimension) return;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(homeFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _openReportListing(BuildContext context, Listing listing) async {
    final id = int.tryParse(listing.id);
    if (id == null) return;
    if (!ref.read(authControllerProvider).isAuthenticated) {
      await showAuthRequiredDialog(context);
      return;
    }
    await showListingReportSheet(context, listingId: id);
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
      if (!_matchesSearch(listing, q)) return false;
      return true;
    }).toList();
  }

  void _toggleFavorite(Listing listing) {
    ref
        .read(favoriteOptimisticNotifierProvider.notifier)
        .requestToggle(listing, context);
  }

  /// Fields not yet supported by `GET /listings` (seller / distance / interior).
  List<Listing> _apiExtraClientFilters(
    List<Listing> listings,
    CarFiltersState filters,
  ) {
    return listings.where((listing) {
      if (filters.openToTradeOnly && !listing.openToTrade) return false;
      if (filters.sellerType == SellerFilterType.owner &&
          listing.sellerIsDealer) {
        return false;
      }
      if (filters.sellerType == SellerFilterType.dealer &&
          !listing.sellerIsDealer) {
        return false;
      }
      if (filters.maxDistanceKm != null) return false;
      if (filters.interiorColors.isNotEmpty) {
        final c = listing.interiorColor;
        if (c == null || !filters.interiorColors.contains(c)) return false;
      }
      return true;
    }).toList();
  }

  int _listingCount(HomeFeedViewState feed, bool useMock) {
    if (feed.total > 0) return feed.total;
    if (useMock) return mockListings.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(homeFeedProvider);
    final filters = ref.watch(carFiltersProvider);
    final useMock = ref.watch(mockModeProvider);
    final favoriteOverrides = ref.watch(favoriteOptimisticNotifierProvider);
    final List<Listing> filtered;
    if (feed.isInitialLoading && feed.items.isEmpty) {
      filtered = <Listing>[];
    } else if (useMock) {
      filtered = _filterList(feed.items, filters);
    } else {
      filtered = _apiExtraClientFilters(feed.items, filters);
    }

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
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeFeedProvider.notifier).refresh(),
          edgeOffset: 0,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: _onSearchChanged,
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
              ),
              if (filters.hasAnyFilter)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        label: Text(l10n.t('filtersReset')),
                        onPressed: () {
                          ref.read(carFiltersProvider.notifier).reset();
                          ref
                              .read(homeFeedSearchQueryProvider.notifier)
                              .setQuery('');
                          _search.clear();
                          ref.read(homeFeedProvider.notifier).refresh();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800&q=80',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  l10n.t('splashTagline'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_listingCount(feed, useMock)} ${l10n.t('adsShort')}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    l10n.t('homePopularBrands'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemCount: mockPopularBrands.length,
                    itemBuilder: (context, i) {
                      final b = mockPopularBrands[i];
                      final letter = b.name.isNotEmpty ? b.name[0] : '?';
                      final asset = b.logoAsset;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E4F0),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              clipBehavior: Clip.antiAlias,
                              padding: const EdgeInsets.all(6),
                              child: asset != null
                                  ? Image.asset(
                                      asset,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, _, _) => Center(
                                        child: Text(
                                          letter,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppPalette.textPrimary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        letter,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppPalette.textPrimary,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 80,
                              child: Text(
                                b.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.t('homeFoundInCategory'),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
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
              ),
              if (feed.isInitialLoading && feed.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingStateView(label: 'Loading cars...'),
                )
              else if (feed.error != null && feed.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateView(
                    message: feed.error!,
                    onRetry: () => ref.read(homeFeedProvider.notifier).refresh(),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    title: l10n.t('empty'),
                    subtitle: 'Try clearing filters or search.',
                    actionLabel: l10n.t('filtersReset'),
                    onAction: () {
                      ref.read(carFiltersProvider.notifier).reset();
                      ref
                          .read(homeFeedSearchQueryProvider.notifier)
                          .setQuery('');
                      _search.clear();
                      ref.read(homeFeedProvider.notifier).refresh();
                      setState(() {});
                    },
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < filtered.length) {
                          final item = filtered[index];
                          final cardListing = useMock
                              ? item
                              : FavoriteOptimisticNotifier
                                  .listingWithEffectiveFavorite(
                                  favoriteOverrides,
                                  item,
                                );
                          return ListingCard(
                            listing: cardListing,
                            onTap: () =>
                                context.push('/listing/${item.id}'),
                            onFavoritePressed: useMock
                                ? null
                                : () => _toggleFavorite(item),
                            onReportPressed: useMock
                                ? null
                                : () => _openReportListing(context, item),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      childCount:
                          filtered.length + (feed.isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
