import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProviderShell extends StatelessWidget {
  final Widget child;
  const ProviderShell({super.key, required this.child});

  static const _tabs = [
    ('/provider-home', Icons.dashboard_outlined, Icons.dashboard, '首页'),
    ('/work-tab', Icons.work_outline, Icons.work, '工作台'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i].$1),
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.$2),
                  activeIcon: Icon(t.$3),
                  label: t.$4,
                ))
            .toList(),
      ),
    );
  }
}
