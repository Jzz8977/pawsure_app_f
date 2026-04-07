import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/providers/user_provider.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

class MemberCenterPage extends ConsumerWidget {
  const MemberCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userNotifierProvider);
    final isVip = user?.vipExpireTime != null;

    return Scaffold(
      backgroundColor: isVip
          ? const Color(0xFF2D1A0E)
          : const Color(0xFFF7F8FA),
      appBar: AppNavBar(
        title: '会员中心',
        backgroundColor: isVip
            ? const Color(0xFF2D1A0E)
            : Colors.white,
        titleColor: isVip ? const Color(0xFFFFD98A) : const Color(0xFF333333),
        backColor: isVip ? const Color(0xFFFFD98A) : null,
        showDivider: !isVip,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildLevelCard(isVip, user),
            const SizedBox(height: 12),
            _buildPerksSection(isVip),
            const SizedBox(height: 12),
            _buildBenefitsList(isVip),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(bool isVip, UserModel? user) {
    final bgGrad = isVip
        ? const LinearGradient(
            colors: [Color(0xFF4A2800), Color(0xFF8B4513)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF607D8B), Color(0xFF90A4AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final titleColor = isVip ? const Color(0xFFFFD98A) : Colors.white;
    final subColor = isVip
        ? const Color(0xFFFFD98A).withValues(alpha: 0.7)
        : Colors.white70;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: bgGrad,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isVip ? const Color(0xFF8B4513) : Colors.grey)
                .withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVip ? 'VIP 会员' : '普通用户',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: titleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVip
                        ? '到期时间 ${user?.vipExpireTime?.substring(0, 10) ?? ''}'
                        : '开通会员享受更多特权',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVip ? Icons.workspace_premium : Icons.person,
                  size: 30,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 成长进度条
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('成长值', style: TextStyle(fontSize: 12, color: subColor)),
                  Text('0 / 1000', style: TextStyle(fontSize: 12, color: subColor)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(titleColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          if (!isVip) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD98A),
                  foregroundColor: const Color(0xFF4A2800),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '立即开通会员',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerksSection(bool isVip) {
    const perks = [
      (Icons.discount_outlined, '专属折扣'),
      (Icons.priority_high_rounded, '优先接单'),
      (Icons.card_giftcard_outlined, '每月礼券'),
      (Icons.support_agent_outlined, '专属客服'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: perks.map((p) {
          final unlocked = isVip;
          return Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unlocked
                      ? const Color(0xFFFFF0E8)
                      : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  p.$1,
                  size: 22,
                  color: unlocked
                      ? const Color(0xFFFF7E51)
                      : const Color(0xFFCCCCCC),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.$2,
                style: TextStyle(
                    fontSize: 12,
                    color: unlocked
                        ? const Color(0xFF333333)
                        : const Color(0xFFBBBBBB)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBenefitsList(bool isVip) {
    const benefits = [
      (Icons.local_offer_outlined, '专属折扣券', '每月赠送平台专属折扣券'),
      (Icons.star_border_rounded, '积分加速', '消费积分双倍累积'),
      (Icons.access_time_outlined, '优先匹配', '优先匹配优质看护师'),
      (Icons.shield_outlined, '保险权益', '免费享受额外保险保障'),
      (Icons.headset_mic_outlined, '专属客服', '7×24小时VIP专属客服'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '会员权益',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333)),
            ),
          ),
          for (int i = 0; i < benefits.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1, indent: 16, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isVip
                          ? const Color(0xFFFFF0E8)
                          : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(benefits[i].$1,
                        size: 20,
                        color: isVip
                            ? const Color(0xFFFF7E51)
                            : const Color(0xFFCCCCCC)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefits[i].$2,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isVip
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFAAAAAA)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          benefits[i].$3,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                  if (!isVip)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '开通解锁',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF888888)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
