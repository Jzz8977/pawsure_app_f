import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PetOwnerShell extends StatelessWidget {
  final Widget child;
  const PetOwnerShell({super.key, required this.child});

  static const _tabs = [
    ('/home', Icons.home_outlined, Icons.home, '首页'),
    ('/pets', Icons.pets_outlined, Icons.pets, '宠物'),
    ('/chat', Icons.chat_bubble_outline, Icons.chat_bubble, '聊天'),
    ('/my', Icons.person_outline, Icons.person, '我的'),
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
