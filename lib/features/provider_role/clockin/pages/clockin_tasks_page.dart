import 'package:flutter/material.dart';

class ClockinTasksPage extends StatelessWidget {
  const ClockinTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打卡任务')),
      body: const Center(child: Text('打卡任务列表')),
    );
  }
}
