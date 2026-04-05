import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class FaceVerifyPage extends StatelessWidget {
  const FaceVerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.faceVerify)),
      body: const Center(child: Text('人脸识别页面')),
    );
  }
}
