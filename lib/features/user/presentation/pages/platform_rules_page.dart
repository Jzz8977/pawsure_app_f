import 'package:flutter/material.dart';

class PlatformRulesPage extends StatelessWidget {
  const PlatformRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('平台规则')),
      body: const Center(child: Text('平台规则内容')),
    );
  }
}
