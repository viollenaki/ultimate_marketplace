import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';

class MarketplaceBottomNav extends StatelessWidget {
  const MarketplaceBottomNav({super.key, required this.currentPath});

  final String currentPath;

  int get _index {
    if (currentPath.startsWith('/inbox') || currentPath.startsWith('/chat')) {
      return 1;
    }
    if (currentPath.startsWith('/favorites')) {
      return 2;
    }
    if (currentPath.startsWith('/my-listings') ||
        currentPath.startsWith('/listing/create')) {
      return 3;
    }
    if (currentPath.startsWith('/profile') ||
        currentPath.startsWith('/promotions')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/inbox');
            break;
          case 2:
            context.go('/favorites');
            break;
          case 3:
            context.go('/my-listings');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      height: 72,
      backgroundColor: AppPalette.surface,
      indicatorColor: AppPalette.secondary.withValues(alpha: 0.16),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'Inbox',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'My Listings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
