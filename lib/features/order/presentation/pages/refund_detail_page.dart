import 'package:flutter/material.dart';

class RefundDetailPage extends StatelessWidget {
  final String id;
  const RefundDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('退款详情')),
      body: Center(child: Text('退款详情: $id')),
    );
  }
}
