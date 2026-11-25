import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'l10n.dart';
import 'ui/features/auth/splash_screen.dart';

void main() => runApp(const HissouApp());

class HissouApp extends StatefulWidget {
  const HissouApp({super.key});

  @override
  State<HissouApp> createState() => _HissouAppState();
}

class _HissouAppState extends State<HissouApp> {
  Locale _locale = const Locale('fr');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: HissouThemeController.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Hissou',
          debugShowCheckedModeBanner: false,
          theme: HissouTheme.lightTheme,
          darkTheme: HissouTheme.darkTheme,
          themeMode: currentMode,
          locale: _locale,
          supportedLocales: [for (final l in supportedLangs) Locale(l)],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SplashScreen(
            onLocaleChanged: (locale) => setState(() => _locale = locale),
          ),
        );
      },
    );
  }
}
