import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class ClockinPage extends StatelessWidget {
  const ClockinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.clockinTitle)),
      body: const Center(child: Text('打卡页面')),
    );
  }
}
