import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale/app_locale_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/current_user_profile.dart';
import 'providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _initials(String name, String email) {
    final t = name.trim();
    if (t.isNotEmpty) {
      final parts = t.split(RegExp(r'\s+'));
      if (parts.length >= 2 &&
          parts[0].isNotEmpty &&
          parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return t[0].toUpperCase();
    }
    final e = email.trim();
    if (e.isNotEmpty) {
      return e[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final firebaseUser = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('profileTitle'))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(currentUserProfileProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            profileAsync.when(
              data: (api) => _ProfileHeader(
                api: api,
                firebaseUser: firebaseUser,
                initialsBuilder: _initials,
              ),
              loading: () => _ProfileHeader(
                api: null,
                firebaseUser: firebaseUser,
                initialsBuilder: _initials,
                loading: true,
              ),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    api: null,
                    firebaseUser: firebaseUser,
                    initialsBuilder: _initials,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('profileLoadError'),
                    style: const TextStyle(color: AppPalette.error),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(currentUserProfileProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.t('profileRetry')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _settingTile(
              context,
              Icons.language_outlined,
              l10n.t('languageSheetTitle'),
              () => _openLanguageSheet(context, ref),
            ),
            _settingTile(
              context,
              Icons.cloud_sync_outlined,
              l10n.t('profileBackendHealth'),
              () => context.push('/backend-health'),
            ),
            _settingTile(
              context,
              Icons.notifications_none,
              l10n.t('profileNotifications'),
              () {},
            ),
            _settingTile(
              context,
              Icons.shield_outlined,
              l10n.t('profilePrivacy'),
              () {},
            ),
            _settingTile(
              context,
              Icons.help_outline,
              l10n.t('profileHelp'),
              () {},
            ),
            _settingTile(
              context,
              Icons.logout,
              l10n.t('profileLogout'),
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
      ),
    );
  }

  void _openLanguageSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  l10n.t('languageSheetTitle'),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ListTile(
                title: Text(l10n.t('languageEnglish')),
                onTap: () async {
                  await ref
                      .read(appLocaleProvider.notifier)
                      .setLocale(const Locale('en'));
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              ListTile(
                title: Text(l10n.t('languageRussian')),
                onTap: () async {
                  await ref
                      .read(appLocaleProvider.notifier)
                      .setLocale(const Locale('ru'));
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _settingTile(
    BuildContext context,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.api,
    required this.firebaseUser,
    required this.initialsBuilder,
    this.loading = false,
  });

  final CurrentUserProfile? api;
  final User? firebaseUser;
  final String Function(String name, String email) initialsBuilder;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = profileDisplayName(api, firebaseUser);
    final email = api?.email ?? firebaseUser?.email ?? '';
    final displayName = name.isNotEmpty ? name : email;
    final photo = profilePhotoUrl(api, firebaseUser);
    final initials = initialsBuilder(displayName, email);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Avatar(radius: 30, photoUrl: photo, initials: initials, busy: loading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : '—',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (email.isEmpty && displayName.isEmpty)
                  Text(
                    l10n.t('profileEmail'),
                    style: const TextStyle(color: AppPalette.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.radius,
    required this.photoUrl,
    required this.initials,
    this.busy = false,
  });

  final double radius;
  final String? photoUrl;
  final String initials;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    if (busy && photoUrl == null) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppPalette.secondary.withValues(alpha: 0.15),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => SizedBox(
              width: size,
              height: size,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, _, _) => _InitialsCircle(
              radius: radius,
              initials: initials,
            ),
          ),
        ),
      );
    }
    return _InitialsCircle(radius: radius, initials: initials);
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.radius, required this.initials});

  final double radius;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppPalette.primary.withValues(alpha: 0.12),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w700,
          color: AppPalette.primary,
        ),
      ),
    );
  }
}
