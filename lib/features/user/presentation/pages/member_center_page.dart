import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class MemberCenterPage extends StatelessWidget {
  const MemberCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.memberCenter)),
      body: const Center(child: Text('会员中心')),
    );
  }
}
