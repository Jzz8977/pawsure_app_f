import 'package:flutter/material.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.orderTitle),
          bottom: TabBar(tabs: [
            Tab(text: s.orderPending),
            Tab(text: s.orderInProgress),
            Tab(text: s.orderCompleted),
            Tab(text: s.orderCancelled),
          ]),
        ),
        body: const TabBarView(children: [
          Center(child: Text('待付款')),
          Center(child: Text('进行中')),
          Center(child: Text('已完成')),
          Center(child: Text('已取消')),
        ]),
      ),
    );
  }
}
