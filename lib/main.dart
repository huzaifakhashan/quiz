import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'services/stats_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  final stats = await StatsService.create();
  runApp(QuizApp(stats: stats));
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key, required this.stats});

  final StatsService stats;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      stats: stats,
      child: ListenableBuilder(
        listenable: stats,
        builder: (context, _) => MaterialApp(
          title: 'كويز',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: switch (stats.themeMode) {
            ThemeModeSetting.system => ThemeMode.system,
            ThemeModeSetting.light => ThemeMode.light,
            ThemeModeSetting.dark => ThemeMode.dark,
          },
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
