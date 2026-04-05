import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class SelectServicePage extends StatelessWidget {
  const SelectServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.serviceSelect)),
      body: const Center(child: Text('选择服务')),
    );
  }
}
