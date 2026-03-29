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
      'appName': 'Cars KG',
      'searchHint': 'Search cars & transport',
      'filters': 'Filter',
      'filtersTitle': 'Filters',
      'filtersApply': 'Apply filters',
      'filtersReset': 'Reset',
      'sort': 'Sort',
      'loadMore': 'Load more',
      'viewAll': 'View all cars',
      'message': 'Message',
      'promote': 'Promote',
      'favorite': 'Favorite',
      'empty': 'No cars match your filters',
      'retry': 'Retry',
      'chatLater': 'Chat will be implemented later',
      'login': 'Login',
      'register': 'Register',
      'forgotPassword': 'Forgot Password',
      'home': 'Home',
      'inbox': 'Chats',
      'favorites': 'Favorites',
      'myListings': 'My listings',
      'profile': 'Profile',
      'createListing': 'Sell car',
      'editListing': 'Edit listing',
      'promotionsPayments': 'Promotions & payments',
      'splashTagline': 'Buy & sell cars in Kyrgyzstan',
      'homePopularBrands': 'Popular brands',
      'homeFoundInCategory': 'Cars in transport',
      'homeSellCar': 'Sell',
      'catAll': 'All',
      'catCarSales': 'Car sales',
      'catAutoParts': 'Auto parts',
      'catAccessories': 'Accessories & tuning',
      'catUsedCars': 'Used cars',
      'filterMakeModels': 'Make & models',
      'filterCity': 'City',
      'filterCityAny': 'All cities',
      'filterPrice': 'Price',
      'filterMinKgs': 'Min (KGS)',
      'filterMaxKgs': 'Max (KGS)',
      'filterMileage': 'Mileage',
      'filterMinKm': 'Min km',
      'filterMaxKm': 'Max km',
      'filterYear': 'Year',
      'filterYearFrom': 'From',
      'filterYearTo': 'To',
      'filterFuelType': 'Fuel type',
      'filterSectionStyle': 'Style',
      'filterBodyType': 'Body type',
      'filterInteriorColors': 'Interior colors',
      'filterExteriorColors': 'Exterior colors',
      'filterSectionOthers': 'Others',
      'filterTransmission': 'Transmission',
      'filterCondition': 'Condition',
      'filterNoAccident': 'Not in an accident',
      'filterDistance': 'Distance from me',
      'filterMaxDistanceKm': 'Max distance (km)',
      'filterDistanceHint': 'Uses your location when available',
      'filterOpenToTrade': 'Open to trade',
      'filterOpenToTradeOnly': 'Only open to trade',
      'filterSellerType': 'Seller type',
      'filterSellerAny': 'Any',
      'filterSellerOwner': 'Private seller',
      'filterSellerDealer': 'Dealer',
      'vip': 'VIP',
      'adsShort': 'ads',
      'profileTitle': 'Profile & settings',
      'profileLoadError': 'Could not load profile',
      'profileRetry': 'Try again',
      'profileEmail': 'Email',
      'languageSheetTitle': 'Language',
      'languageEnglish': 'English',
      'languageRussian': 'Русский',
      'profileBackendHealth': 'Backend health check',
      'profileNotifications': 'Notifications',
      'profilePrivacy': 'Privacy',
      'profileHelp': 'Help center',
      'profileLogout': 'Log out',
    },
    'ru': {
      'appName': 'Cars KG',
      'searchHint': 'Поиск в транспорте',
      'filters': 'Фильтр',
      'filtersTitle': 'Фильтры',
      'filtersApply': 'Применить фильтры',
      'filtersReset': 'Сбросить',
      'sort': 'Сортировка',
      'loadMore': 'Показать еще',
      'viewAll': 'Все авто',
      'message': 'Написать',
      'promote': 'Продвигать',
      'favorite': 'Избранное',
      'empty': 'Нет авто по фильтрам',
      'retry': 'Повторить',
      'chatLater': 'Чат будет добавлен позже',
      'login': 'Вход',
      'register': 'Регистрация',
      'forgotPassword': 'Забыли пароль',
      'home': 'Главная',
      'inbox': 'Чаты',
      'favorites': 'Избранное',
      'myListings': 'Мои объявления',
      'profile': 'Профиль',
      'createListing': 'Продать авто',
      'editListing': 'Редактировать',
      'promotionsPayments': 'Продвижение и платежи',
      'splashTagline': 'Покупайте и продавайте авто в Кыргызстане',
      'homePopularBrands': 'Популярные бренды',
      'homeFoundInCategory': 'Найдено в категории «Транспорт»',
      'homeSellCar': 'Продать',
      'catAll': 'Все',
      'catCarSales': 'Продажа авто',
      'catAutoParts': 'Автозапчасти',
      'catAccessories': 'Аксессуары и тюнинг',
      'catUsedCars': 'Подержанные авто',
      'filterMakeModels': 'Марка и модель',
      'filterCity': 'Город',
      'filterCityAny': 'Все города',
      'filterPrice': 'Цена',
      'filterMinKgs': 'Мин (сом)',
      'filterMaxKgs': 'Макс (сом)',
      'filterMileage': 'Пробег',
      'filterMinKm': 'Мин км',
      'filterMaxKm': 'Макс км',
      'filterYear': 'Год',
      'filterYearFrom': 'От',
      'filterYearTo': 'До',
      'filterFuelType': 'Топливо',
      'filterSectionStyle': 'Стиль',
      'filterBodyType': 'Тип кузова',
      'filterInteriorColors': 'Цвет салона',
      'filterExteriorColors': 'Цвет кузова',
      'filterSectionOthers': 'Другое',
      'filterTransmission': 'Коробка передач',
      'filterCondition': 'Состояние',
      'filterNoAccident': 'Не битый',
      'filterDistance': 'Расстояние от меня',
      'filterMaxDistanceKm': 'Макс расстояние (км)',
      'filterDistanceHint': 'Когда будет доступна геолокация',
      'filterOpenToTrade': 'Обмен',
      'filterOpenToTradeOnly': 'Только с обменом',
      'filterSellerType': 'Тип продавца',
      'filterSellerAny': 'Любой',
      'filterSellerOwner': 'Частник',
      'filterSellerDealer': 'Дилер',
      'vip': 'VIP',
      'adsShort': 'объявл.',
      'profileTitle': 'Профиль и настройки',
      'profileLoadError': 'Не удалось загрузить профиль',
      'profileRetry': 'Повторить',
      'profileEmail': 'Почта',
      'languageSheetTitle': 'Язык',
      'languageEnglish': 'English',
      'languageRussian': 'Русский',
      'profileBackendHealth': 'Проверка сервера',
      'profileNotifications': 'Уведомления',
      'profilePrivacy': 'Конфиденциальность',
      'profileHelp': 'Помощь',
      'profileLogout': 'Выйти',
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
