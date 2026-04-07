import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_nav_bar.dart';

class PhoneChangePage extends StatelessWidget {
  const PhoneChangePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '手机号修改'),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android, size: 64, color: Color(0xFFCCCCCC)),
            SizedBox(height: 16),
            Text(
              '手机号修改功能开发中',
              style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}
