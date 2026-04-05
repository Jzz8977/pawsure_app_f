import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../providers/user_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _petOwnerTabs = [
    _TabItem('/home',          'assets/images/tabbar/home.svg',    'assets/images/tabbar/home_active.svg'),
    _TabItem('/pets',          'assets/images/tabbar/pets.svg',    'assets/images/tabbar/pets_active.svg'),
    _TabItem('/chat',          'assets/images/tabbar/chat.svg',    'assets/images/tabbar/chat_active.svg'),
    _TabItem('/my',            'assets/images/tabbar/my.svg',      'assets/images/tabbar/my_active.svg'),
  ];

  static const _providerTabs = [
    _TabItem('/provider-home', 'assets/images/tabbar/service.svg', 'assets/images/tabbar/service_active.svg'),
    _TabItem('/work-tab',      'assets/images/tabbar/data.svg',    'assets/images/tabbar/data_active.svg'),
    _TabItem('/chat',          'assets/images/tabbar/chat.svg',    'assets/images/tabbar/chat_active.svg'),
    _TabItem('/my',            'assets/images/tabbar/my.svg',      'assets/images/tabbar/my_active.svg'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userNotifierProvider);
    final tabs = user?.role == UserRole.provider ? _providerTabs : _petOwnerTabs;
    final location = GoRouterState.of(context).uri.toString();
    final idx = tabs.indexWhere((t) => location.startsWith(t.path));
    final activeIndex = idx == -1 ? 0 : idx;

    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingTabBar(
              tabs: tabs,
              activeIndex: activeIndex,
              onTap: (i) => context.go(tabs[i].path),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 浮动 Tab Bar ────────────────────────────────────────────────

class _FloatingTabBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: 5 + bottomInset),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF535353).withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(tabs.length, (i) {
                    final isActive = i == activeIndex;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            isActive ? tabs[i].activeIcon : tabs[i].icon,
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab 配置 ────────────────────────────────────────────────────

class _TabItem {
  final String path;
  final String icon;
  final String activeIcon;
  const _TabItem(this.path, this.icon, this.activeIcon);
}
