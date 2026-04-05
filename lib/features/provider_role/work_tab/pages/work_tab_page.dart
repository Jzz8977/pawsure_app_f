import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class WorkTabPage extends StatelessWidget {
  const WorkTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.tabWorkbench)),
      body: const Center(child: Text('工作台')),
    );
  }
}
