import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/listing/presentation/create_listing_screen.dart';
import '../features/listing/presentation/edit_listing_screen.dart';
import '../features/listing/presentation/listing_detail_screen.dart';
import '../features/my_listings/presentation/my_listings_screen.dart';
import '../features/payments/presentation/promotions_payments_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/inbox', builder: (context, state) => const InboxScreen()),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/promotions',
        builder: (context, state) => const PromotionsPaymentsScreen(),
      ),
      GoRoute(
        path: '/listing/create',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/listing/:listingId',
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['listingId']!),
      ),
      GoRoute(
        path: '/listing/:listingId/edit',
        builder: (context, state) =>
            EditListingScreen(listingId: state.pathParameters['listingId']!),
      ),
    ],
  ),
);
