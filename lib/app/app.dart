import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/i18n/locale_provider.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeNotifier = ref.watch(themeNotifierProvider.notifier);
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      routerConfig: router,

      // 主题
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeNotifier.flutterThemeMode,

      // 国际化
      locale: locale,
      supportedLocales: LocaleNotifier.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      debugShowCheckedModeBanner: false,
    );
  }
}
