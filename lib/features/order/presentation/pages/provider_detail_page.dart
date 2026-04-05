import 'package:flutter/material.dart';

class ProviderDetailPage extends StatelessWidget {
  final String id;
  const ProviderDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('看护师详情')),
      body: Center(child: Text('看护师: $id')),
    );
  }
}
