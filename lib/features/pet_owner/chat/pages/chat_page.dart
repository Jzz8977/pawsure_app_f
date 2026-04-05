import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.tabChat)),
      body: const Center(child: Text('消息列表')),
    );
  }
}
