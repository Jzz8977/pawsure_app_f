import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';
import '../../../../shared/widgets/theme_switcher_widget.dart';

class ProviderHomePage extends StatelessWidget {
  const ProviderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabProviderHome),
        actions: const [ThemeSwitcherWidget()],
      ),
      body: const Center(child: Text('看护师首页')),
    );
  }
}
