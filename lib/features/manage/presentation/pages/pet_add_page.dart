import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class PetAddPage extends StatelessWidget {
  const PetAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.petAdd)),
      body: const Center(child: Text('添加宠物')),
    );
  }
}
