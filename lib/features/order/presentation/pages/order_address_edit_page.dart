import 'package:flutter/material.dart';

class OrderAddressEditPage extends StatelessWidget {
  const OrderAddressEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改地址')),
      body: const Center(child: Text('修改订单地址')),
    );
  }
}
