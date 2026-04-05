import 'package:flutter/material.dart';

class ProviderOrderDetailPage extends StatelessWidget {
  const ProviderOrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('看护订单详情')),
      body: const Center(child: Text('看护师订单详情')),
    );
  }
}
