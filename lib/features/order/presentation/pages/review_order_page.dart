import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class ReviewOrderPage extends StatelessWidget {
  final String id;
  const ReviewOrderPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.reviewOrder)),
      body: Center(child: Text('评价订单: $id')),
    );
  }
}
