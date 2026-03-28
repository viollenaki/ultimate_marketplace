import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/auth_required_dialog.dart';
import '../../auth/presentation/providers/auth_providers.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listing = ref.watch(listingByIdProvider(widget.listingId));
    final authState = ref.watch(authControllerProvider);

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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: listing.imageUrls.length,
                    onPageChanged: (value) =>
                        setState(() => _imageIndex = value),
                    itemBuilder: (context, index) => Image.network(
                      listing.imageUrls[index],
                      fit: BoxFit.cover,
                    ),
                  ),
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
                        '${_imageIndex + 1}/${listing.imageUrls.length}',
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
                    listing.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    price.format(listing.price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppPalette.primaryVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    listing.description,
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
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            listing.owner.avatarUrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.owner.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                listing.owner.city,
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
                          onPressed: () async {
                            if (!authState.isAuthenticated) {
                              await showAuthRequiredDialog(context);
                              return;
                            }
                            if (context.mounted) {
                              showNotReadySnackBar(
                                context,
                                l10n.t('chatLater'),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
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
                        onPressed: () async {
                          if (!authState.isAuthenticated) {
                            await showAuthRequiredDialog(context);
                            return;
                          }
                          if (context.mounted) {
                            showNotReadySnackBar(
                              context,
                              'Favorites sync is next',
                            );
                          }
                        },
                        icon: const Icon(Icons.favorite_border),
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
