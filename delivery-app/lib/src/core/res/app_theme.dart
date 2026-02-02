import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryColor,
        primary: AppColors.primaryColor,
      ),
      fontFamily: 'Gilmer',
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryColor,
      ),
      textTheme: ThemeData.light()
          .textTheme
          .apply(
            fontFamily: 'Gilmer',
          )
          .copyWith(
            titleLarge: const TextStyle(
              fontFamily: 'Gilmer',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
      useMaterial3: true,
    );
  }
}
