import 'package:flutter/material.dart';

class AppThemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  );

  static final amoledTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: Colors.black,
    dialogBackgroundColor: Colors.black,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.black),

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,

      background: Colors.black,
      surface: Colors.black,
      surfaceContainerHighest: Colors.black,

      primary: Colors.white,
      onPrimary: Colors.black,

      secondary: Colors.grey,
      onSecondary: Colors.white,

      tertiary: Colors.grey,
      onTertiary: Colors.white,

      onBackground: Colors.white,
      onSurface: Colors.white,

      error: Colors.redAccent,
      onError: Colors.black,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white54),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
