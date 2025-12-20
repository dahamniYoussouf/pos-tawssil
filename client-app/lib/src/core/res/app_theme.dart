import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      fontFamily: 'Gilmer',
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
    );
  }
}
