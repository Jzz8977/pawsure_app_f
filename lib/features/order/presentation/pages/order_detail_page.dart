import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final String id;
  const OrderDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: Center(child: Text('订单: $id')),
    );
  }
}
