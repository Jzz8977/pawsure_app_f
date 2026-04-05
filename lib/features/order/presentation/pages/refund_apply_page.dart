import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class RefundApplyPage extends StatelessWidget {
  const RefundApplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.refundApply)),
      body: const Center(child: Text('申请退款')),
    );
  }
}
