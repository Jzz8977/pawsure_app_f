import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class WithdrawPage extends StatelessWidget {
  const WithdrawPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.walletWithdraw)),
      body: const Center(child: Text('提现页面')),
    );
  }
}
