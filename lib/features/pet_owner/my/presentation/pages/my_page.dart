import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsure_app/core/i18n/l10n/app_localizations.dart';
import '../../../../../shared/providers/user_provider.dart';
import '../../../../../shared/widgets/theme_switcher_widget.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final user = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tabMy),
        actions: const [ThemeSwitcherWidget()],
      ),
      body: ListView(
        children: [
          // 用户信息
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? '未登录',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(user?.phone ?? '',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          _buildItem(context, Icons.receipt_long, s.orderTitle, '/order'),
          _buildItem(context, Icons.account_balance_wallet, s.walletTitle, '/wallet'),
          _buildItem(context, Icons.favorite_border, s.coupons, '/coupons'),
          _buildItem(context, Icons.star_border, '我的收藏', '/favorites'),
          const Divider(),
          _buildItem(context, Icons.person_outline, '个人资料', '/user-profile'),
          _buildItem(context, Icons.verified_user_outlined, s.identityVerify, '/identity-verification'),
          _buildItem(context, Icons.headset_mic_outlined, s.customerService, '/customer-service'),
          _buildItem(context, Icons.info_outline, s.about, '/about'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(userNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
