import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_data.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../../shared/widgets/marketplace_bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(currentUser.avatarUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        currentUser.city,
                        style: const TextStyle(color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _settingTile(
            Icons.sell_outlined,
            'My promotions & payments',
            () => context.push('/promotions'),
          ),
          _settingTile(Icons.language_outlined, 'Language (EN / RU)', () {}),
          _settingTile(Icons.notifications_none, 'Notifications', () {}),
          _settingTile(Icons.shield_outlined, 'Privacy', () {}),
          _settingTile(Icons.help_outline, 'Help Center', () {}),
          _settingTile(
            Icons.logout,
            'Log out',
            () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/home');
              }
            },
            color: AppPalette.error,
          ),
        ],
      ),
      bottomNavigationBar: MarketplaceBottomNav(
        currentPath: GoRouterState.of(context).uri.path,
      ),
    );
  }

  Widget _settingTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    final tileColor = color ?? AppPalette.textPrimary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: tileColor),
        title: Text(title, style: TextStyle(color: tileColor)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
