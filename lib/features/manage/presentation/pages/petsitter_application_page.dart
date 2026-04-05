import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class PetsitterApplicationPage extends StatelessWidget {
  const PetsitterApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.petsitterApply)),
      body: const Center(child: Text('申请成为看护师')),
    );
  }
}
