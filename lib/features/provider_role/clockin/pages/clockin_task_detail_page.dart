import 'package:flutter/material.dart';

class ClockinTaskDetailPage extends StatelessWidget {
  final String id;
  const ClockinTaskDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务详情')),
      body: Center(child: Text('任务详情: $id')),
    );
  }
}
