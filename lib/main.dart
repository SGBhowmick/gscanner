import 'package:flutter/material.dart';
import 'package:gscanner/splash.dart';
import 'package:gscanner/theme_notifier.dart';
import 'package:gscanner/themes.dart';
import 'package:gscanner/watermark_notifier.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialTheme = await ThemeNotifier.loadTheme();
  final watermarkSettings = await WatermarkNotifier.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(initialTheme: initialTheme),
        ),
        ChangeNotifierProvider(
          create: (_) => WatermarkNotifier(
            initialColor: Color(watermarkSettings['initialColor']),
            initialEnabled: watermarkSettings['initialEnabled'],
            initialText: watermarkSettings['initialText'],
            initialFont: watermarkSettings['initialFont'],
            initialFontSize: watermarkSettings['initialFontSize'],
            initialOpacity: watermarkSettings['initialOpacity'],
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      themeMode: themeNotifier.themeMode,

      theme: AppThemes.lightTheme,

      darkTheme: themeNotifier.currentTheme == AppThemeMode.amoled
          ? AppThemes.amoledTheme
          : AppThemes.darkTheme,

      home: const SplashScreen(),
    );
  }
}
