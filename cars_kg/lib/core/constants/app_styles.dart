import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppStyles {
  static const TextTheme textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
  );

  const AppStyles._();
}
