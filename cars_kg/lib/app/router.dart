import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/home/presentation/car_filters_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/listing/presentation/create_listing_screen.dart';
import '../features/listing/presentation/edit_listing_screen.dart';
import '../features/listing/presentation/listing_detail_screen.dart';
import '../features/listing/presentation/map_picker_screen.dart';
import '../features/my_listings/presentation/my_listings_screen.dart';
import '../features/payments/presentation/promotions_payments_screen.dart';
import '../features/diagnostics/presentation/backend_health_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/widgets/marketplace_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

bool _isProtectedPath(String path) {
  if (path.startsWith('/inbox') || path.startsWith('/chat')) {
    return true;
  }
  if (path.startsWith('/favorites')) {
    return true;
  }
  if (path.startsWith('/my-listings')) {
    return true;
  }
  if (path.startsWith('/profile') || path.startsWith('/promotions')) {
    return true;
  }
  if (path == '/listing/create') {
    return true;
  }
  if (path == '/listing/map-picker') {
    return true;
  }
  if (path.contains('/listing/') && path.endsWith('/edit')) {
    return true;
  }
  return false;
}

class _MarketplaceShell extends StatelessWidget {
  const _MarketplaceShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MarketplaceBottomNav(
        navigationShell: navigationShell,
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;

      if (!authState.initialized &&
          path != '/splash' &&
          path != '/backend-health') {
        return '/splash';
      }

      if (_isProtectedPath(path) && !authState.isAuthenticated) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      final isAuthPage = path == '/login' || path == '/register';
      if (isAuthPage && authState.isAuthenticated) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return Uri.decodeComponent(from);
        }
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MarketplaceShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-listings',
                builder: (context, state) => const MyListingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/backend-health',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BackendHealthScreen(),
      ),
      GoRoute(
        path: '/listing/map-picker',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          double? lat;
          double? lng;
          final extra = state.extra;
          if (extra is Map) {
            final m = Map<String, dynamic>.from(extra);
            final la = m['lat'];
            final ln = m['lng'];
            if (la is num) {
              lat = la.toDouble();
            }
            if (ln is num) {
              lng = ln.toDouble();
            }
          }
          return MapPickerScreen(
            initialLatitude: lat,
            initialLongitude: lng,
          );
        },
      ),
      GoRoute(
        path: '/listing/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/listing/:listingId/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EditListingScreen(listingId: state.pathParameters['listingId']!),
      ),
      GoRoute(
        path: '/listing/:listingId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['listingId']!),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(
        path: '/promotions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PromotionsPaymentsScreen(),
      ),
      GoRoute(
        path: '/filters',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CarFiltersScreen(),
      ),
    ],
  );
});
