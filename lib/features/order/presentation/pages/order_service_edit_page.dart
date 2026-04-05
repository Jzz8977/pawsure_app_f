import 'package:flutter/material.dart';

class OrderServiceEditPage extends StatelessWidget {
  const OrderServiceEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改服务')),
      body: const Center(child: Text('修改订单服务')),
    );
  }
}
