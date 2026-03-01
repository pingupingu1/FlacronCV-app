import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'localization/app_localizations.dart';

class FlacronCVApp extends StatelessWidget {
  const FlacronCVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlacronCV',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('de'),
        Locale('it'),
        Locale('zh'),
        Locale('ru'),
        Locale('pt'),
        Locale('hi'),
        Locale('ar'),
        Locale('fr'),
        Locale('ko'),
      ],

      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
