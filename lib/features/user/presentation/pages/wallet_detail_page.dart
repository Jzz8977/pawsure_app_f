import 'package:flutter/material.dart';

class WalletDetailPage extends StatelessWidget {
  const WalletDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账单明细')),
      body: const Center(child: Text('账单明细')),
    );
  }
}
