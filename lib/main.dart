import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'l10n.dart';
import 'ui/navigation/adaptive_scaffold.dart';

void main() => runApp(const HissouApp());

class HissouApp extends StatefulWidget {
  const HissouApp({super.key});

  @override
  State<HissouApp> createState() => _HissouAppState();
}

class _HissouAppState extends State<HissouApp> {
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hissou',
      debugShowCheckedModeBanner: false,
      theme: HissouTheme.lightTheme,
      darkTheme: HissouTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: _locale,
      supportedLocales: [for (final l in supportedLangs) Locale(l)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AdaptiveScaffold(
        onLocaleChanged: (locale) => setState(() => _locale = locale),
      ),
    );
  }
}
