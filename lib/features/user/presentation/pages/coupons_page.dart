import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

// ── 模型 ──────────────────────────────────────────────────────────

class _Coupon {
  final String id;
  final String title;
  final String tag;
  final double amount;
  final int discountType; // 1=固定金额 2=折扣
  final double? threshold;
  final String? validStart;
  final String? validEnd;
  final String status; // available / expired

  const _Coupon({
    required this.id,
    required this.title,
    required this.tag,
    required this.amount,
    required this.discountType,
    this.threshold,
    this.validStart,
    this.validEnd,
    required this.status,
  });

  factory _Coupon.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final endDate = json['validEnd'] != null
        ? DateTime.tryParse(json['validEnd'] as String)
        : null;
    final status =
        (endDate != null && endDate.isBefore(now)) ? 'expired' : 'available';
    return _Coupon(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '优惠券',
      tag: json['tag'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      discountType: (json['discountType'] as num?)?.toInt() ?? 1,
      threshold: (json['threshold'] as num?)?.toDouble(),
      validStart: json['validStart'] as String?,
      validEnd: json['validEnd'] as String?,
      status: status,
    );
  }

  String get displayAmount =>
      discountType == 2 ? '${amount.toStringAsFixed(1)}折' : amount.toInt().toString();

  String get amountSymbol => discountType == 1 ? '¥' : '';

  String get thresholdText =>
      threshold != null && threshold! > 0 ? '满${threshold!.toInt()}元可用' : '无门槛';

  String get validLabel {
    if (validEnd == null) return '长期有效';
    final d = DateTime.tryParse(validEnd!);
    if (d == null) return '';
    return '有效期至 ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

// ── Page ─────────────────────────────────────────────────────────

class CouponsPage extends ConsumerStatefulWidget {
  const CouponsPage({super.key});

  @override
  ConsumerState<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends ConsumerState<CouponsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<_Coupon> _available = [];
  List<_Coupon> _expired = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(dioProvider).post(CouponApi.getByUser, data: {});
      final data = res.data as Map<String, dynamic>?;
      final raw = (data?['content'] as List<dynamic>?) ?? [];
      final all = raw.map((e) => _Coupon.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _available = all.where((c) => c.status == 'available').toList();
          _expired = all.where((c) => c.status == 'expired').toList();
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
      appBar: const AppNavBar(title: '优惠券'),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: const Color(0xFFFF7E51),
              unselectedLabelColor: const Color(0xFF666666),
              indicatorColor: const Color(0xFFFF7E51),
              indicatorWeight: 2.5,
              tabs: [
                Tab(text: '可用 (${_available.length})'),
                Tab(text: '已过期 (${_expired.length})'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tab,
                    children: [
                      _buildList(_available, isExpired: false),
                      _buildList(_expired, isExpired: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<_Coupon> coupons, {required bool isExpired}) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.discount_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              isExpired ? '暂无过期优惠券' : '暂无可用优惠券',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: coupons.length,
      itemBuilder: (_, i) => _CouponCard(coupon: coupons[i]),
    );
  }
}

// ── 优惠券卡片 ────────────────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final _Coupon coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final isExpired = coupon.status == 'expired';
    final leftColor =
        isExpired ? const Color(0xFFBBBBBB) : const Color(0xFFFF7E51);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // 左侧金额区
          Container(
            width: 90,
            decoration: BoxDecoration(
              color: leftColor,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (coupon.amountSymbol.isNotEmpty)
                      Text(
                        coupon.amountSymbol,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    Text(
                      coupon.displayAmount,
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  coupon.thresholdText,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),

          // 虚线分隔
          _DashedDivider(color: leftColor),

          // 右侧信息区
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        coupon.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isExpired
                                ? const Color(0xFF999999)
                                : const Color(0xFF333333)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (coupon.tag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? const Color(0xFFF0F0F0)
                                : const Color(0xFFFFF0E8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            coupon.tag,
                            style: TextStyle(
                                fontSize: 11,
                                color: isExpired
                                    ? const Color(0xFF999999)
                                    : const Color(0xFFFF7E51)),
                          ),
                        ),
                      Text(
                        coupon.validLabel,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),
                ),
                if (!isExpired)
                  Positioned(
                    right: 12,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7E51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '去使用',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                if (isExpired)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFBBBBBB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '已过期',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFFBBBBBB)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 96,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    const dashH = 5.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
          Offset(size.width / 2, y), Offset(size.width / 2, y + dashH), paint);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
