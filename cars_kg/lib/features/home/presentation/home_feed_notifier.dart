import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/mock/mock_models.dart';
import '../../favorites/presentation/favorites_providers.dart';
import '../../listing/data/listing_from_api.dart';
import '../data/listing_api_query_params.dart';
import 'car_filters_provider.dart';
import 'home_feed_search_providers.dart';

const int kHomeFeedPageSize = 12;

class HomeFeedViewState {
  const HomeFeedViewState({
    this.items = const [],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.total = 0,
    this.error,
  });

  final List<Listing> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int total;
  final String? error;

  HomeFeedViewState copyWith({
    List<Listing>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? total,
    String? error,
    bool clearError = false,
  }) {
    return HomeFeedViewState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HomeFeedNotifier extends Notifier<HomeFeedViewState> {
  bool _loadMoreScheduled = false;

  @override
  HomeFeedViewState build() {
    ref.listen<bool>(mockModeProvider, (prev, next) {
      if (prev != null && prev != next) {
        Future<void>.microtask(refresh);
      }
    });
    ref.listen<String>(homeFeedSearchQueryProvider, (prev, next) {
      if (!ref.read(mockModeProvider) && prev != next) {
        Future<void>.microtask(refresh);
      }
    });
    // Car filter apply/reset calls [HomeFeedNotifier.refresh] explicitly so the
    // feed refetches with new query params (mock mode still skips HTTP in _loadPage).
    Future<void>.microtask(refresh);
    return const HomeFeedViewState();
  }

  Future<void> refresh() async {
    _loadMoreScheduled = false;
    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      items: const [],
      hasMore: true,
    );
    await _loadPage(skip: 0, append: false);
  }

  /// Updates [isFavorite] and public save counter after a successful favorites API call.
  void patchListingFavorite(int listingId, bool isFavorite) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (int.tryParse(item.id) == listingId)
            item.copyWith(
              isFavorite: isFavorite,
              favoriteCount: (item.favoriteCount + (isFavorite ? 1 : -1))
                  .clamp(0, 1 << 30),
            )
          else
            item,
      ],
    );
  }

  /// Called when the user scrolls near the bottom of the home feed.
  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        _loadMoreScheduled) {
      return;
    }
    _loadMoreScheduled = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      await _loadPage(skip: state.items.length, append: true);
    } finally {
      _loadMoreScheduled = false;
    }
  }

  Future<void> _loadPage({required int skip, required bool append}) async {
    final useMock = ref.read(mockModeProvider);
    try {
      late List<Listing> page;
      late final int total;

      if (useMock) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
        total = mockListings.length;
        page = mockListings.skip(skip).take(kHomeFeedPageSize).toList();
      } else {
        final client = ref.read(apiClientProvider);
        final filters = ref.read(carFiltersProvider);
        final searchQ = ref.read(homeFeedSearchQueryProvider);
        final queryParameters = buildPublicListingsQuery(
          skip: skip,
          limit: kHomeFeedPageSize,
          debouncedSearch: searchQ,
          filters: filters,
        );
        final response = await client.get<Map<String, dynamic>>(
          '/listings',
          queryParameters: queryParameters,
        );
        final data = response.data;
        if (data == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            message: 'Empty listings response',
          );
        }
        final rawItems = data['items'] as List<dynamic>? ?? [];
        total = (data['total'] as num?)?.toInt() ?? 0;
        page = rawItems
            .map((e) => listingFromApiJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
        final favAsync = ref.read(favoriteListingIdsProvider);
        final favSet = favAsync.maybeWhen(
          data: (s) => s,
          orElse: () => <int>{},
        );
        page = page
            .map((listing) {
              final nid = int.tryParse(listing.id);
              if (nid == null) return listing;
              return listing.copyWith(isFavorite: favSet.contains(nid));
            })
            .toList();
      }

      final merged = append ? [...state.items, ...page] : page;
      final hasMore = merged.length < total && page.isNotEmpty;

      state = HomeFeedViewState(
        items: merged,
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: hasMore,
        total: total,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.message ?? 'Network error')
          : e.toString();
      if (append) {
        state = state.copyWith(
          isLoadingMore: false,
          error: message,
        );
      } else {
        state = HomeFeedViewState(
          items: const [],
          isInitialLoading: false,
          isLoadingMore: false,
          hasMore: false,
          total: 0,
          error: message,
        );
      }
    }
  }
}

final homeFeedProvider =
    NotifierProvider<HomeFeedNotifier, HomeFeedViewState>(HomeFeedNotifier.new);
