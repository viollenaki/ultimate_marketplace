import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale/app_locale_provider.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class UltimateMarketplaceApp extends ConsumerWidget {
  const UltimateMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final localeAsync = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cars KG',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: localeAsync.when(
        data: (locale) => locale,
        loading: () => const Locale('en'),
        error: (_, _) => const Locale('en'),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
