import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_palette.dart';

class MarketplaceBottomNav extends StatelessWidget {
  const MarketplaceBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _selectTab(BuildContext context, int index) {
    final router = GoRouter.of(context);
    while (router.canPop()) {
      router.pop();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => _selectTab(context, index),
      height: 72,
      backgroundColor: AppPalette.surface,
      indicatorColor: AppPalette.primary.withValues(alpha: 0.12),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.t('home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline),
          selectedIcon: const Icon(Icons.chat_bubble),
          label: l10n.t('inbox'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_border),
          selectedIcon: const Icon(Icons.favorite),
          label: l10n.t('favorites'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.directions_car_outlined),
          selectedIcon: const Icon(Icons.directions_car),
          label: l10n.t('myListings'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.t('profile'),
        ),
      ],
    );
  }
}
