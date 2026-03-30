import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_models.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/auth_required_dialog.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../chat/data/conversations_api.dart';
import '../../favorites/presentation/favorite_optimistic_notifier.dart';
import 'providers/remote_listing_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _imageIndex = 0;
  bool _openingChat = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final numericId = int.tryParse(widget.listingId);

    if (numericId != null) {
      final asyncListing = ref.watch(remoteListingProvider(numericId));
      final favoriteOverrides = ref.watch(favoriteOptimisticNotifierProvider);
      return asyncListing.when(
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Could not load listing\n$e')),
        ),
        data: (listing) => _buildScaffold(
          context,
          l10n,
          authState,
          listing.title,
          listing.description,
          listing.price,
          listing.currency,
          listing.imageUrls,
          listing.owner,
          listing.latitude,
          listing.longitude,
          listing.locationDisplayName,
          listing.location,
          favoriteListing: listing,
          favoriteApiId: numericId,
          isFavorite: FavoriteOptimisticNotifier.effectiveFavorite(
            favoriteOverrides,
            listing,
          ),
        ),
      );
    }

    final listing = ref.watch(listingByIdProvider(widget.listingId));
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final price = NumberFormat.currency(
      symbol: listing.currency,
      decimalDigits: 0,
    );

    return _buildScaffold(
      context,
      l10n,
      authState,
      listing.title,
      listing.description,
      listing.price,
      listing.currency,
      listing.imageUrls,
      listing.owner,
      listing.latitude,
      listing.longitude,
      listing.locationDisplayName,
      listing.location,
      priceFormatter: price,
      favoriteListing: listing,
      favoriteApiId: null,
      isFavorite: listing.isFavorite,
    );
  }

  Future<void> _openChatWithSeller(
    BuildContext context,
    int listingId,
    MarketplaceUser owner,
    AuthState authState,
  ) async {
    final otherUserId = int.tryParse(owner.id);
    if (otherUserId == null) {
      if (context.mounted) {
        showNotReadySnackBar(context, 'Could not resolve seller account.');
      }
      return;
    }
    if (authState.userId == otherUserId) {
      if (context.mounted) {
        showNotReadySnackBar(context, 'You cannot message yourself.');
      }
      return;
    }
    setState(() => _openingChat = true);
    try {
      final dio = ref.read(authenticatedApiClientProvider).dio;
      final conversationId = await createOrGetConversation(
        dio,
        otherUserId: otherUserId,
        listingId: listingId,
      );
      ref.invalidate(conversationsProvider);
      if (context.mounted) {
        context.push('/chat/$conversationId');
      }
    } on DioException catch (e) {
      if (context.mounted) {
        showNotReadySnackBar(
          context,
          conversationCreateErrorMessage(e),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showNotReadySnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _openingChat = false);
      }
    }
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    AuthState authState,
    String title,
    String description,
    double price,
    String currency,
    List<String> imageUrls,
    MarketplaceUser owner,
    double? latitude,
    double? longitude,
    String? locationDisplayName,
    String cityLabel, {
    NumberFormat? priceFormatter,
    Listing? favoriteListing,
    int? favoriteApiId,
    required bool isFavorite,
  }) {
    final priceFmt = priceFormatter ??
        NumberFormat.currency(symbol: currency, decimalDigits: 0);

    final lat = latitude;
    final lng = longitude;
    final hasCoords = lat != null && lng != null;
    final locationLine = locationDisplayName?.isNotEmpty == true
        ? locationDisplayName!
        : (hasCoords
            ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
            : cityLabel);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            actions: [
              IconButton(
                onPressed: favoriteApiId == null || favoriteListing == null
                    ? () {
                        showNotReadySnackBar(
                          context,
                          'Favorites use the API; turn off demo data.',
                        );
                      }
                    : () => ref
                        .read(favoriteOptimisticNotifierProvider.notifier)
                        .requestToggle(favoriteListing, context),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : null,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  if (imageUrls.isEmpty)
                    ColoredBox(
                      color: AppPalette.surface,
                      child: Center(
                        child: Icon(
                          Icons.directions_car_outlined,
                          size: 72,
                          color: AppPalette.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  else
                    PageView.builder(
                      itemCount: imageUrls.length,
                      onPageChanged: (value) =>
                          setState(() => _imageIndex = value),
                      itemBuilder: (context, index) => Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (imageUrls.isNotEmpty)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_imageIndex + 1}/${imageUrls.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    priceFmt.format(price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppPalette.primaryVariant,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: AppPalette.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locationLine,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (owner.avatarUrl.isNotEmpty)
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(owner.avatarUrl),
                          )
                        else
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppPalette.surface,
                            child: Text(
                              owner.name.isNotEmpty
                                  ? owner.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                owner.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                owner.city,
                                style: const TextStyle(
                                  color: AppPalette.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/my-listings'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(l10n.t('viewAll')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openingChat
                              ? null
                              : () async {
                                  if (!authState.isAuthenticated) {
                                    await showAuthRequiredDialog(context);
                                    return;
                                  }
                                  if (favoriteApiId == null) {
                                    if (context.mounted) {
                                      showNotReadySnackBar(
                                        context,
                                        'Messaging needs a listing from the server.',
                                      );
                                    }
                                    return;
                                  }
                                  await _openChatWithSeller(
                                    context,
                                    favoriteApiId,
                                    owner,
                                    authState,
                                  );
                                },
                          icon: _openingChat
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chat_bubble_outline),
                          label: Text(l10n.t('message')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () async {
                          if (!authState.isAuthenticated) {
                            await showAuthRequiredDialog(context);
                            return;
                          }
                          if (context.mounted) {
                            showNotReadySnackBar(
                              context,
                              'Promotions integration soon',
                            );
                          }
                        },
                        child: Text(l10n.t('promote')),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        onPressed: favoriteApiId == null || favoriteListing == null
                            ? () {
                                showNotReadySnackBar(
                                  context,
                                  'Favorites use the API; turn off demo data.',
                                );
                              }
                            : () => ref
                                .read(favoriteOptimisticNotifierProvider.notifier)
                                .requestToggle(favoriteListing, context),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
