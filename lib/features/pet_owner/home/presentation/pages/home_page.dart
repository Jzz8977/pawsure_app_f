import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';
import '../../../../../shared/widgets/theme_switcher_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabHome),
        actions: const [ThemeSwitcherWidget()],
      ),
      body: Center(child: Text(s.search)),
    );
  }
}
