import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

class _Plan {
  final String id;
  final String name;
  final String price;
  final List<String> features;
  final String coverageAmount;

  const _Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    required this.coverageAmount,
  });

  factory _Plan.fromJson(Map<String, dynamic> json) {
    final priceVal = (json['price'] as num?)?.toDouble() ?? 0;
    return _Plan(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '保险套餐',
      price: (priceVal / 100).toStringAsFixed(0),
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coverageAmount: json['coverageAmount'] as String? ?? '',
    );
  }
}

class InsurancePage extends ConsumerStatefulWidget {
  const InsurancePage({super.key});

  @override
  ConsumerState<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends ConsumerState<InsurancePage> {
  List<_Plan> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await ref.read(dioProvider).post(InsuranceApi.listAll, data: {});
      final data = res.data as Map<String, dynamic>?;
      final raw = (data?['content'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _plans = raw
              .map((e) => _Plan.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '宠物保险'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部横幅
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7E51), Color(0xFFFF9E4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.shield, size: 28, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              '宠信宠物保险',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '全方位保障您的爱宠健康与安全',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    '保险套餐',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 10),

                  if (_plans.isEmpty)
                    _buildDefaultPlans()
                  else
                    ...(_plans.map((p) => _PlanCard(plan: p))),
                ],
              ),
            ),
    );
  }

  Widget _buildDefaultPlans() {
    const defaults = [
      ('基础保障', '99', ['意外伤亡保障', '医疗费用补偿', '第三方责任险'], '最高¥5000'),
      ('标准保障', '199', ['意外伤亡保障', '医疗费用补偿', '第三方责任险', '寄养意外险'], '最高¥15000'),
      ('高级保障', '399', ['意外伤亡保障', '医疗费用补偿', '第三方责任险', '寄养意外险', '住院津贴', '手术费用'], '最高¥50000'),
    ];
    return Column(
      children: defaults
          .map((d) => _PlanCard(
                plan: _Plan(
                  id: d.$1,
                  name: d.$1,
                  price: d.$2,
                  features: d.$3,
                  coverageAmount: d.$4,
                ),
              ))
          .toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('¥',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFFFF7E51))),
                  Text(
                    plan.price,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF7E51)),
                  ),
                  const Text('/年',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF888888))),
                ],
              ),
            ],
          ),
          if (plan.coverageAmount.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('保额 ${plan.coverageAmount}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF888888))),
          ],
          const SizedBox(height: 12),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 15, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    Text(f,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF555555))),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E51),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('立即购买'),
            ),
          ),
        ],
      ),
    );
  }
}
