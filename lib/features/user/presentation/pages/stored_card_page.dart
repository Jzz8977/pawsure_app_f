import 'package:flutter/material.dart';

class StoredCardPage extends StatelessWidget {
  const StoredCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('银行卡管理')),
      body: const Center(child: Text('银行卡管理')),
    );
  }
}
