import 'package:flutter/material.dart';

class PetDetailPage extends StatelessWidget {
  final String id;
  const PetDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宠物详情')),
      body: Center(child: Text('宠物: $id')),
    );
  }
}
