import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_palette.dart';
import '../../data/mock/mock_models.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onFavoritePressed,
    this.isCompact = false,
    this.showSellerAvatar = false,
  });

  final Listing listing;
  final VoidCallback onTap;
  /// When null, the heart is display-only.
  final VoidCallback? onFavoritePressed;
  final bool isCompact;
  /// Home feed hides seller photo; detail fetches seller separately.
  final bool showSellerAvatar;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      symbol: '${listing.currency} ',
      decimalDigits: 0,
    );
    final usd = listing.priceUsdApprox != null
        ? NumberFormat.currency(symbol: r'$', decimalDigits: 0)
            .format(listing.priceUsdApprox)
        : null;
    final spec = [
      listing.transmission,
      listing.fuelType,
      listing.bodyType,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: isCompact ? 1.3 : 1.05,
                    child: listing.imageUrls.isEmpty
                        ? ColoredBox(
                            color: AppPalette.surface,
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 48,
                              color: AppPalette.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          )
                        : Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
                if (listing.isVip)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.vipBadge,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'VIP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: onFavoritePressed,
                      icon: Icon(
                        listing.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: listing.isFavorite
                            ? AppPalette.error
                            : AppPalette.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.format(listing.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textPrimary,
                        ),
                  ),
                  if (usd != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      usd,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${listing.brand} ${listing.model}: ${listing.year} г.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.textSecondary,
                          height: 1.25,
                        ),
                  ),
                  if (spec.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      spec,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.textSecondary,
                            fontSize: 12,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (showSellerAvatar &&
                          listing.owner.avatarUrl.isNotEmpty) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundImage:
                              NetworkImage(listing.owner.avatarUrl),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          listing.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: AppPalette.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        listing.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: listing.isFavorite
                            ? AppPalette.error
                            : AppPalette.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
