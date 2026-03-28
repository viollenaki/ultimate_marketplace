import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale) : _languageCode = locale.languageCode {
    Intl.defaultLocale = locale.languageCode;
  }

  final Locale locale;
  final String _languageCode;

  static const supportedLocales = [Locale('en'), Locale('ru')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(instance != null, 'AppLocalizations is not found in widget tree');
    return instance!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Ultimate Marketplace',
      'searchHint': 'Search listings',
      'filters': 'Filters',
      'sort': 'Sort',
      'loadMore': 'Load more',
      'viewAll': 'View all listings',
      'message': 'Message',
      'promote': 'Promote',
      'favorite': 'Favorite',
      'empty': 'Nothing here yet',
      'retry': 'Retry',
      'chatLater': 'Chat will be implemented later',
      'login': 'Login',
      'register': 'Register',
      'forgotPassword': 'Forgot Password',
      'home': 'Home',
      'inbox': 'Inbox',
      'favorites': 'Favorites',
      'myListings': 'My Listings',
      'profile': 'Profile',
      'createListing': 'Create Listing',
      'editListing': 'Edit Listing',
      'promotionsPayments': 'Promotions & Payments',
    },
    'ru': {
      'appName': 'Ultimate Marketplace',
      'searchHint': 'Поиск объявлений',
      'filters': 'Фильтры',
      'sort': 'Сортировка',
      'loadMore': 'Показать еще',
      'viewAll': 'Все объявления',
      'message': 'Написать',
      'promote': 'Продвигать',
      'favorite': 'Избранное',
      'empty': 'Пока пусто',
      'retry': 'Повторить',
      'chatLater': 'Чат будет добавлен позже',
      'login': 'Вход',
      'register': 'Регистрация',
      'forgotPassword': 'Забыли пароль',
      'home': 'Главная',
      'inbox': 'Сообщения',
      'favorites': 'Избранное',
      'myListings': 'Мои объявления',
      'profile': 'Профиль',
      'createListing': 'Создать объявление',
      'editListing': 'Редактировать объявление',
      'promotionsPayments': 'Продвижение и платежи',
    },
  };

  String t(String key) =>
      _localizedValues[_languageCode]?[key] ??
      _localizedValues['en']![key] ??
      key;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
