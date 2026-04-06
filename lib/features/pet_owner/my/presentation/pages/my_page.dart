import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsure_app/shared/providers/user_provider.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

// ─── Data model ──────────────────────────────────────────────────

class _GridItem {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final int count;
  const _GridItem(this.icon, this.label, this.onTap, {this.count = 0});
}

// ─── Page ────────────────────────────────────────────────────────

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  bool _showBalance = true;

  static const _gradientHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD8B0), Color(0xFFFFB78A), Color(0xFFF5A37A)],
    stops: [0.0, 0.45, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final isProvider = user?.role == UserRole.provider;

    return Scaffold(
      appBar: AppNavBar(title: '我的', showBack: false),
      backgroundColor: const Color(0xFFEFF1F4),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, user, isProvider),
            _buildMemberSection(context, user, isProvider),
            const SizedBox(height: 16),
            _buildOrderCard(context, isProvider),
            if (!isProvider) ...[
              const SizedBox(height: 16),
              _buildAccountCard(context),
            ],
            const SizedBox(height: 16),
            _buildAboutCard(context, isProvider),
            if (user != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildRoleSwitchCard(context, isProvider),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildLogoutButton(context),
              ),
            ],
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, UserModel? user, bool isProvider) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/user-profile'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: const BoxDecoration(
          gradient: _gradientHeader,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 12),
            Expanded(child: _buildNameCol(user)),
            const SizedBox(width: 12),
            _buildServiceBtn(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel? user) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: user?.avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: user!.avatarUrl!,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, err) =>
                    _avatarFallback(user.sex),
              )
            : _avatarFallback(user?.sex ?? 0),
      ),
    );
  }

  Widget _avatarFallback(int sex) => Container(
        color: Colors.white.withValues(alpha: 0.3),
        child: Icon(
          sex == 2 ? Icons.face_2_outlined : Icons.face_outlined,
          size: 30,
          color: const Color(0xFFF5A37A),
        ),
      );

  Widget _buildNameCol(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                user != null
                    ? (user.name.isNotEmpty ? user.name : '极速小鱼')
                    : '点击登录',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down,
                  size: 12, color: Color(0xFF2B2B2B)),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLevelChip(),
            const SizedBox(width: 8),
            Text(
              user?.isIdCertified == true ? '已认证' : '未认证',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFFA7A2A2)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelChip() {
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.only(
                left: 18, right: 8, top: 2, bottom: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9)),
            ),
            child: const Text(
              '普通',
              style:
                  TextStyle(fontSize: 11, color: Color(0xFFD48713)),
            ),
          ),
          Positioned(
            left: -7,
            top: -4,
            child: Image.asset(
              'assets/images/my/vip.png',
              width: 26,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/customer-service'),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          'assets/icons/service.svg',
          colorFilter: const ColorFilter.mode(
              Color(0xFF2B2B2B), BlendMode.srcIn),
        ),
      ),
    );
  }

  // ─── Member strip + quick grid / provider wallet ─────────────

  Widget _buildMemberSection(
      BuildContext context, UserModel? user, bool isProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x69FFFFFF), Color(0x00FFFFFF)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          _buildMemberStrip(context, isProvider),
          const SizedBox(height: 12),
          if (!isProvider) _buildQuickGrid(context),
          if (isProvider) _buildProviderWallet(context),
        ],
      ),
    );
  }

  Widget _buildMemberStrip(BuildContext context, bool isProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              isProvider ? '宠物看护师' : '普通会员',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFFCC9933),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: List.generate(
                5,
                (i) => Text(
                  '★',
                  style: TextStyle(
                    fontSize: 12,
                    color: i == 0
                        ? const Color(0xFFFF8C3D)
                        : const Color(0xFFD8D8D8),
                  ),
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/member-center'),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFCDEA2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isProvider ? '等级中心' : '会员中心',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF333333)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    size: 14, color: Color(0xFF333333)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickGrid(BuildContext context) {
    final items = [
      _GridItem('assets/images/my/coupon.png', '优惠券',
          () => context.push('/coupons')),
      _GridItem('assets/images/my/collect.png', '收藏',
          () => context.push('/favorites')),
      _GridItem('assets/images/my/address.png', '地址',
          () => context.push('/address-list')),
      _GridItem('assets/images/my/caregivers.png', '成为看护师',
          _onBecomePetsitter),
    ];
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children:
            items.map((item) => Expanded(child: _buildQuickItem(item))).toList(),
      ),
    );
  }

  Widget _buildQuickItem(_GridItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(item.icon,
              width: 36, height: 36, fit: BoxFit.contain),
          const SizedBox(height: 4),
          Text(item.label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF333333))),
        ],
      ),
    );
  }

  void _onBecomePetsitter() {
    final user = ref.read(userNotifierProvider);
    if (user == null) return;
    if (!user.isIdCertified) {
      _showConfirmDialog(
        title: '需要身份认证',
        content: '成为看护师需要先完成身份认证，是否前往认证？',
        confirmText: '去认证',
        onConfirm: () => context.push('/identity-verification'),
      );
      return;
    }
    context.push('/petsitter-list');
  }

  Widget _buildProviderWallet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/wallet'),
            child: Row(
              children: [
                const Text(
                  '我的钱包',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333)),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () =>
                      setState(() => _showBalance = !_showBalance),
                  child: Icon(
                    _showBalance
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 16,
                    color: const Color(0xFF999999),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 16, color: Color(0xFF999999)),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFF5F5F5)),
          Row(
            children: [
              _walletStat('100.00', '余额'),
              _walletStat('100.00', '本月收入'),
              _walletStat('100.00', '待结算'),
              _walletDepositStat(true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (_showBalance)
                const Text('¥',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF333333))),
              Text(
                _showBalance ? value : '****',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF333333)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _walletDepositStat(bool depositPaid) {
    return Expanded(
      child: Column(
        children: [
          Text(
            depositPaid ? '已缴纳' : '未缴纳',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 4),
          const Text('押金',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  // ─── Order card ──────────────────────────────────────────────

  Widget _buildOrderCard(BuildContext context, bool isProvider) {
    final items = isProvider
        ? [
            _GridItem('assets/images/my/pre_payment.png', '待接单',
                () => context.push('/order')),
            _GridItem('assets/images/my/pre_start.png', '进行中',
                () => context.push('/order')),
            _GridItem('assets/images/my/pre_evaluate.png', '已完成',
                () => context.push('/order')),
            _GridItem('assets/images/my/refund.png', '退款/售后',
                () => context.push('/order')),
            _GridItem('assets/images/my/check_in.png', '打卡',
                () => context.push('/clockin')),
          ]
        : [
            _GridItem('assets/images/my/pre_payment.png', '全部',
                () => context.push('/order')),
            _GridItem('assets/images/my/pre_start.png', '待开始',
                () => context.push('/order')),
            _GridItem('assets/images/my/pre_evaluate.png', '待评价',
                () => context.push('/order')),
            _GridItem('assets/images/my/refund.png', '退款/售后',
                () => context.push('/order')),
            _GridItem('assets/images/my/check_in.png', '打卡',
                () => context.push('/order')),
          ];
    return _sectionCard(
      title: '我的订单',
      onMoreTap: () => context.push('/order'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: items
              .map((item) => Expanded(child: _buildOrderItem(item)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildOrderItem(_GridItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(item.icon,
                    width: 23, height: 23, fit: BoxFit.contain),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF333333)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (item.count > 0)
              Positioned(
                top: 0,
                right: 8,
                child: _buildBadge(item.count),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      constraints:
          const BoxConstraints(minWidth: 16, maxHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
            fontSize: 10, color: Colors.white, height: 1.6),
      ),
    );
  }

  // ─── Account card ─────────────────────────────────────────────

  Widget _buildAccountCard(BuildContext context) {
    final items = [
      _GridItem('assets/images/my/account.png', '钱包',
          () => context.push('/wallet')),
      _GridItem('assets/images/my/insurance.png', '保险',
          () => context.push('/insurance')),
      _GridItem('assets/images/my/agreement.png', '协议',
          () => context.push('/agreement')),
    ];
    return _sectionCard(
      title: '账户',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: [
            ...items
                .map((item) => Expanded(child: _buildOrderItem(item))),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  // ─── About card ───────────────────────────────────────────────

  Widget _buildAboutCard(BuildContext context, bool isProvider) {
    final items = isProvider
        ? [
            _GridItem('assets/images/my/rules.png', '平台规则',
                () => context.push('/platform-rules')),
            _GridItem('assets/images/my/about.png', '关于宠信',
                () => context.push('/about')),
            _GridItem('assets/images/my/insurance.png', '保险',
                () => context.push('/insurance')),
            _GridItem('assets/images/my/agreement.png', '协议',
                () => context.push('/agreement')),
          ]
        : [
            _GridItem('assets/images/my/rules.png', '平台规则',
                () => context.push('/platform-rules')),
            _GridItem('assets/images/my/about.png', '关于宠信',
                () => context.push('/about')),
          ];
    return _sectionCard(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9, top: 9),
        child: Row(
          children: items
              .map((item) => Expanded(child: _buildOrderItem(item)))
              .toList(),
        ),
      ),
    );
  }

  // ─── Shared section card wrapper ──────────────────────────────

  Widget _sectionCard({
    String? title,
    VoidCallback? onMoreTap,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    if (onMoreTap != null)
                      GestureDetector(
                        onTap: onMoreTap,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('全部',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999))),
                            Icon(Icons.chevron_right,
                                size: 14,
                                color: Color(0xFF999999)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }

  // ─── Role switch card ─────────────────────────────────────────

  Widget _buildRoleSwitchCard(BuildContext context, bool isProvider) {
    return GestureDetector(
      onTap: () => _onRoleSwitchTap(context, isProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProvider ? '看护师模式' : '客户模式',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isProvider ? '提供专业宠物服务' : '预订宠物服务',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('切换',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  SizedBox(width: 2),
                  Text('›',
                      style:
                          TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRoleSwitchTap(BuildContext context, bool isProvider) {
    final targetMode = isProvider ? '客户' : '看护师';
    _showConfirmDialog(
      title: '切换角色',
      content: '确定要切换到$targetMode模式吗？',
      confirmText: '确定切换',
      onConfirm: () async {
        await ref.read(userNotifierProvider.notifier).switchRole();
        if (!context.mounted) return;
        context.go(isProvider ? '/home' : '/provider-home');
      },
    );
  }

  // ─── Logout button ────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _onLogoutTap(context),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        alignment: Alignment.center,
        child: const Text(
          '退出登录',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF6A00),
          ),
        ),
      ),
    );
  }

  void _onLogoutTap(BuildContext context) {
    _showConfirmDialog(
      title: '退出登录',
      content: '确定要退出登录吗？',
      confirmText: '确定退出',
      onConfirm: () async {
        await ref.read(userNotifierProvider.notifier).logout();
        if (!context.mounted) return;
        context.go('/welcome');
      },
    );
  }

  // ─── Shared dialog helper ─────────────────────────────────────

  void _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: Text(
              confirmText,
              style: const TextStyle(color: Color(0xFFFF6A00)),
            ),
          ),
        ],
      ),
    );
  }
}
