import 'package:flutter/widgets.dart';

import '../features/auth/presentation/pages/login_page.dart';

class AppRoutes {
  static const String login = '/login';

  static final Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginPage(),
  };
}
