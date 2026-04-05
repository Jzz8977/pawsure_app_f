import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class ServiceManagePage extends StatelessWidget {
  const ServiceManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.serviceManage)),
      body: const Center(child: Text('服务管理')),
    );
  }
}
