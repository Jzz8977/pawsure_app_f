import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);
const _kBg = Color(0xFFF5F5F5);

class OrderDetailPage extends ConsumerStatefulWidget {
  final String id; // orderNo
  const OrderDetailPage({super.key, required this.id});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(OrderApi.userDetail, data: {'orderNo': widget.id});
      if (!mounted) return;
      setState(() {
        _order = resp.data['content'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PENDING_PAY': return '待付款';
      case 'PENDING_START': return '待开始';
      case 'IN_SERVICE': return '服务中';
      case 'COMPLETED': return '已完成';
      case 'CANCELLED': return '已取消';
      case 'REFUNDING': return '退款中';
      default: return s ?? '';
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PENDING_PAY': return _kPrimary;
      case 'IN_SERVICE': return const Color(0xFF4CAF50);
      case 'COMPLETED': return const Color(0xFF2196F3);
      case 'CANCELLED': return const Color(0xFF999999);
      case 'REFUNDING': return const Color(0xFFFF5722);
      default: return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status']?.toString();
    final orderId = _order?['id']?.toString() ?? _order?['orderId']?.toString() ?? '';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppNavBar(
        title: '订单详情',
        showDivider: false,
        actions: status != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(fontSize: 14, color: _statusColor(status), fontWeight: FontWeight.w500),
                  ),
                )
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _order == null
              ? const Center(child: Text('订单不存在'))
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: _kPrimary,
                        unselectedLabelColor: const Color(0xFF666666),
                        indicatorColor: _kPrimary,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [Tab(text: '订单详情'), Tab(text: '服务进度')],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _DetailTab(order: _order!),
                          const _ProgressTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _order == null ? null : _buildFooter(status, orderId),
    );
  }

  Widget? _buildFooter(String? status, String orderId) {
    switch (status) {
      case 'PENDING_PAY':
        return FooterBar(
          outlineText: '取消',
          buttonText: '立即付款',
          onOutlineTap: _showCancelSheet,
          onButtonTap: () => context.push('/pending-payment?orderNo=${widget.id}'),
        );
      case 'PENDING_START':
        return FooterBar(
          buttonText: '取消订单',
          onButtonTap: _showCancelSheet,
        );
      case 'IN_SERVICE':
        return FooterBar(
          buttonText: '申请售后',
          onButtonTap: () => _showAfterSaleSheet(orderId),
        );
      case 'COMPLETED':
        return FooterBar(
          buttonText: '立即评价',
          onButtonTap: () => context.push('/review-order/$orderId'),
        );
      case 'CANCELLED':
        return FooterBar(
          buttonText: '再来一单',
          onButtonTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('功能开发中')),
          ),
        );
      default:
        return null;
    }
  }

  void _showCancelSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(onConfirm: (reason) async {
        try {
          final dio = ref.read(dioProvider);
          await dio.post(OrderApi.userCancel, data: {'orderNo': widget.id, 'cancelReason': reason});
          if (!mounted) return;
          _load();
        } catch (_) {}
      }),
    );
  }

  void _showAfterSaleSheet(String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AfterSaleSheet(orderId: orderId, orderNo: widget.id),
    );
  }
}

class _DetailTab extends StatelessWidget {
  final Map<String, dynamic> order;
  const _DetailTab({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderNo = order['orderNo']?.toString() ?? '';
    final createTime = order['createTime']?.toString() ?? '';
    final remark = order['remark']?.toString() ?? '';
    final providerName = order['providerName']?.toString() ?? order['serverName']?.toString() ?? '';
    final providerPhone = order['providerPhone']?.toString() ?? '';
    final serviceName = order['serviceType']?.toString() ?? order['serviceName']?.toString() ?? '';
    final startDate = order['startDate']?.toString() ?? order['startTime']?.toString() ?? '';
    final endDate = order['endDate']?.toString() ?? order['endTime']?.toString() ?? '';
    final totalAmount = (order['totalAmount'] as num?) ?? 0;
    final couponDiscount = (order['couponDiscount'] as num?) ?? 0;
    final payAmount = (order['payAmount'] as num?) ?? totalAmount;
    final pets = (order['pets'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _Card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('看护师信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            _InfoRow(label: '姓名', value: providerName),
            if (providerPhone.isNotEmpty) _InfoRow(label: '电话', value: providerPhone),
            _InfoRow(label: '服务类型', value: serviceName),
          ],
        )),
        const SizedBox(height: 10),
        _Card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('服务时间', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DateBox(label: '开始', date: startDate)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF999999)),
              ),
              Expanded(child: _DateBox(label: '结束', date: endDate)),
            ]),
          ],
        )),
        const SizedBox(height: 10),
        if (pets.isNotEmpty) ...[
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('宠物信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(height: 12),
              ...pets.map((p) => _PetItem(pet: p as Map<String, dynamic>)),
            ],
          )),
          const SizedBox(height: 10),
        ],
        _Card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('费用明细', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            _PriceRow(label: '订单金额', value: '¥${(totalAmount / 100).toStringAsFixed(2)}'),
            if (couponDiscount > 0)
              _PriceRow(label: '优惠券', value: '-¥${(couponDiscount / 100).toStringAsFixed(2)}', isDiscount: true),
            const Divider(height: 20, color: Color(0xFFF0F0F0)),
            _PriceRow(label: '实付金额', value: '¥${(payAmount / 100).toStringAsFixed(2)}', isTotal: true),
          ],
        )),
        const SizedBox(height: 10),
        _Card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('订单信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: orderNo));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制订单号')));
              },
              child: _InfoRow(label: '订单号', value: orderNo, trailing: const Icon(Icons.copy, size: 14, color: Color(0xFF999999))),
            ),
            _InfoRow(label: '下单时间', value: createTime.length > 16 ? createTime.substring(0, 16) : createTime),
            if (remark.isNotEmpty) _InfoRow(label: '备注', value: remark),
          ],
        )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('暂无服务进度', style: TextStyle(color: Color(0xFF999999))),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  const _InfoRow({required this.label, required this.value, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
      if (trailing != null) trailing!,
    ]),
  );
}

class _DateBox extends StatelessWidget {
  final String label;
  final String date;
  const _DateBox({required this.label, required this.date});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
      const SizedBox(height: 4),
      Text(date.length > 10 ? date.substring(0, 10) : date,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
    ]),
  );
}

class _PetItem extends StatelessWidget {
  final Map<String, dynamic> pet;
  const _PetItem({required this.pet});
  @override
  Widget build(BuildContext context) {
    final name = pet['petName']?.toString() ?? pet['name']?.toString() ?? '宠物';
    final breed = pet['breed']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
          child: const Icon(Icons.pets, size: 18, color: Color(0xFF999999)),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (breed.isNotEmpty)
            Text(breed, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ]),
      ]),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;
  final bool isTotal;
  const _PriceRow({required this.label, required this.value, this.isDiscount = false, this.isTotal = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(
        fontSize: isTotal ? 14 : 13,
        fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
        color: isTotal ? const Color(0xFF333333) : const Color(0xFF666666),
      )),
      Text(value, style: TextStyle(
        fontSize: isTotal ? 15 : 13,
        fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
        color: isDiscount ? const Color(0xFF4CAF50) : (isTotal ? _kPrimary : const Color(0xFF333333)),
      )),
    ]),
  );
}

class _CancelSheet extends StatefulWidget {
  final Future<void> Function(String reason) onConfirm;
  const _CancelSheet({required this.onConfirm});
  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  static const _reasons = [
    ('change_time', '行程有变，需要改期'),
    ('found_better', '找到了更合适的服务'),
    ('price_high', '价格太贵'),
    ('no_need', '暂时不需要了'),
    ('other', '其他原因'),
  ];
  String? _selected;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('取消订单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, size: 20, color: Color(0xFF999999))),
          ]),
          const SizedBox(height: 16),
          const Text('请选择取消原因', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
          const SizedBox(height: 10),
          ...List.generate(_reasons.length, (i) {
            final r = _reasons[i];
            final sel = _selected == r.$1;
            return GestureDetector(
              onTap: () => setState(() => _selected = r.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFFFF8F0) : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? _kPrimary : Colors.transparent),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(r.$2, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? _kPrimary : const Color(0xFFD8D8D8))),
                    child: Center(child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 10, height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? _kPrimary : Colors.transparent),
                    )),
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 44,
                decoration: BoxDecoration(border: Border.all(color: _kPrimary), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Text('再想想', style: TextStyle(color: _kPrimary)),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: _selected == null || _submitting ? null : () async {
                setState(() => _submitting = true);
                final nav = Navigator.of(context);
                await widget.onConfirm(_selected!);
                nav.pop();
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(color: _selected == null ? const Color(0xFFE5E5E5) : _kPrimary, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text('仍要取消', style: TextStyle(color: _selected == null ? const Color(0xFF999999) : Colors.white)),
              ),
            )),
          ]),
        ],
      ),
    );
  }
}

class _AfterSaleSheet extends StatelessWidget {
  final String orderId;
  final String orderNo;
  const _AfterSaleSheet({required this.orderId, required this.orderNo});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('申请售后', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _SheetOption(icon: Icons.undo, title: '退款申请', subtitle: '申请退款', onTap: () {
            Navigator.pop(context);
            context.push('/refund-apply?orderId=$orderId&orderNo=$orderNo');
          }),
          const SizedBox(height: 12),
          _SheetOption(icon: Icons.shield_outlined, title: '理赔申请', subtitle: '宠物意外理赔申请', onTap: () {
            Navigator.pop(context);
            context.push('/claim-apply?orderId=$orderId');
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: Color(0xFFFFF0E0), shape: BoxShape.circle),
          child: Icon(icon, color: _kPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ])),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF999999)),
      ]),
    ),
  );
}
