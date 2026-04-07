import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_nav_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '关于宠信'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          children: [
            // Logo 区域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7E51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.pets, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '宠信',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '专业的宠物服务平台',
                    style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '版本 1.0.0',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 介绍卡片
            _InfoCard(
              title: '关于我们',
              child: const Text(
                '宠信是一个专业的宠物服务平台，致力于为宠物主人和服务提供者搭建一个安全、可靠、便捷的服务桥梁。我们提供宠物寄养、宠物护理、宠物保险等全方位服务，让每一只宠物都能享受到专业的照顾和关爱。',
                style: TextStyle(
                    fontSize: 14, color: Color(0xFF666666), height: 1.7),
              ),
            ),

            const SizedBox(height: 12),

            _InfoCard(
              title: '我们的使命',
              child: const Text(
                '让每一只宠物都能得到最好的照顾，让每一位宠物主人都能安心放心。我们通过严格的服务提供者审核机制、完善的保险保障体系、透明的服务评价系统，为用户提供最优质的宠物服务体验。',
                style: TextStyle(
                    fontSize: 14, color: Color(0xFF666666), height: 1.7),
              ),
            ),

            const SizedBox(height: 12),

            _InfoCard(
              title: '核心价值观',
              child: Column(
                children: const [
                  _ValueItem(icon: '💙', name: '专业', desc: '严格的服务提供者认证'),
                  _ValueItem(icon: '🛡️', name: '安全', desc: '完善的保险保障体系'),
                  _ValueItem(icon: '⭐', name: '信任', desc: '透明的服务评价系统'),
                  _ValueItem(icon: '❤️', name: '用心', desc: '贴心的客户服务支持'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 联系方式
            _InfoCard(
              title: '联系我们',
              child: Column(
                children: const [
                  _ContactRow(label: '客服电话', value: '400-123-4567'),
                  _ContactRow(label: '客服邮箱', value: 'service@pawsure.com'),
                  _ContactRow(label: '工作时间', value: '周一至周日 9:00-21:00'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '© 2025 宠信 Pawsure\n保留所有权利',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Color(0xFFBBBBBB), height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;
  const _ValueItem(
      {required this.icon, required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333))),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String label;
  final String value;
  const _ContactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF888888))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF333333))),
        ],
      ),
    );
  }
}
