import 'package:flutter/material.dart';

class OrderDateEditPage extends StatelessWidget {
  const OrderDateEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改日期')),
      body: const Center(child: Text('修改订单日期')),
    );
  }
}
