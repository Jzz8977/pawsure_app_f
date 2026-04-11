import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);
const _kBg = Color(0xFFF5F5F5);

const _tabs = ['全部', '待付款', '待开始', '服务中', '已完成', '已取消'];
const _statusKeys = ['', 'PENDING_PAY', 'PENDING_START', 'IN_SERVICE', 'COMPLETED', 'CANCELLED'];

class OrderPage extends ConsumerStatefulWidget {
  final String? tab;
  const OrderPage({super.key, this.tab});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<List<Map<String, dynamic>>> _lists = List.generate(6, (_) => []);
  final List<bool> _loading = List.generate(6, (_) => false);

  @override
  void initState() {
    super.initState();
    int initial = 0;
    if (widget.tab != null) {
      final idx = _statusKeys.indexOf(widget.tab!);
      if (idx >= 0) initial = idx;
    }
    _tabController = TabController(length: 6, vsync: this, initialIndex: initial);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load(_tabController.index);
    });
    for (int i = 0; i < 6; i++) {
      _load(i);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load(int idx) async {
    if (_loading[idx]) return;
    setState(() => _loading[idx] = true);
    try {
      final dio = ref.read(dioProvider);
      final data = <String, dynamic>{'pageNo': 1, 'pageSize': 100};
      if (_statusKeys[idx].isNotEmpty) data['status'] = _statusKeys[idx];
      final resp = await dio.post(OrderApi.userList, data: data);
      if (!mounted) return;
      final records = (resp.data['content']?['records'] as List?) ?? [];
      setState(() {
        _lists[idx] = records.cast<Map<String, dynamic>>();
        _loading[idx] = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading[idx] = false);
    }
  }

  Future<void> _cancelOrder(String orderNo, String reason) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(OrderApi.userCancel, data: {'orderNo': orderNo, 'cancelReason': reason});
      if (!mounted) return;
      for (int i = 0; i < 6; i++) {
        _load(i);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppNavBar(title: '我的订单', showDivider: false),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _kPrimary,
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              indicatorColor: _kPrimary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(6, (i) => _OrderList(
                orders: _lists[i],
                loading: _loading[i],
                onRefresh: () => _load(i),
                onCancel: _cancelOrder,
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool loading;
  final VoidCallback onRefresh;
  final Future<void> Function(String orderNo, String reason) onCancel;

  const _OrderList({
    required this.orders,
    required this.loading,
    required this.onRefresh,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('暂无订单', style: TextStyle(color: Color(0xFF999999)))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => _OrderCard(order: orders[i], onCancel: onCancel),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(String orderNo, String reason) onCancel;

  const _OrderCard({required this.order, required this.onCancel});

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
      case 'PENDING_PAY': return const Color(0xFFFF9E4A);
      case 'IN_SERVICE': return const Color(0xFF4CAF50);
      case 'COMPLETED': return const Color(0xFF2196F3);
      case 'CANCELLED': return const Color(0xFF999999);
      default: return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNo = order['orderNo']?.toString() ?? '';
    final orderId = order['id']?.toString() ?? order['orderId']?.toString() ?? '';
    final status = order['status']?.toString();
    final providerName = order['providerName']?.toString() ?? order['serverName']?.toString() ?? '看护师';
    final serviceName = order['serviceType']?.toString() ?? order['serviceName']?.toString() ?? '服务';
    final createTime = order['createTime']?.toString() ?? '';
    final totalAmount = (order['totalAmount'] as num?) ?? 0;
    final yuan = (totalAmount / 100).toStringAsFixed(2);

    return GestureDetector(
      onTap: () => context.push('/order-detail/$orderNo'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFF0F0F0),
                    child: Icon(Icons.person, size: 18, color: Color(0xFF999999)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(providerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(serviceName, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      ],
                    ),
                  ),
                  Text(_statusLabel(status), style: TextStyle(fontSize: 13, color: _statusColor(status), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(createTime.length > 16 ? createTime.substring(0, 16) : createTime,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  Text('¥$yuan', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                ],
              ),
            ),
            _buildActions(context, orderNo, orderId, status),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext ctx, String orderNo, String orderId, String? status) {
    switch (status) {
      case 'PENDING_PAY':
        return _ActionsRow(children: [
          _ActionBtn(text: '取消订单', outline: true, onTap: () => _showCancelSheet(ctx, orderNo)),
          _ActionBtn(text: '立即付款', onTap: () => ctx.push('/pending-payment?orderNo=$orderNo')),
        ]);
      case 'PENDING_START':
        return _ActionsRow(children: [
          _ActionBtn(text: '取消订单', outline: true, onTap: () => _showCancelSheet(ctx, orderNo)),
        ]);
      case 'IN_SERVICE':
        return _ActionsRow(children: [
          _ActionBtn(text: '申请售后', outline: true, onTap: () => _showAfterSaleSheet(ctx, orderId, orderNo)),
        ]);
      case 'COMPLETED':
      case 'PENDING_REVIEW':
        return _ActionsRow(children: [
          _ActionBtn(text: '立即评价', onTap: () => ctx.push('/review-order/$orderId')),
        ]);
      case 'CANCELLED':
        return _ActionsRow(children: [
          _ActionBtn(
            text: '再来一单',
            outline: true,
            onTap: () => ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('功能开发中'))),
          ),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCancelSheet(BuildContext ctx, String orderNo) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(onConfirm: (reason) async {
        await onCancel(orderNo, reason);
      }),
    );
  }

  void _showAfterSaleSheet(BuildContext ctx, String orderId, String orderNo) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _AfterSaleSheet(orderId: orderId, orderNo: orderNo),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final List<Widget> children;
  const _ActionsRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String text;
  final bool outline;
  final VoidCallback onTap;

  const _ActionBtn({required this.text, this.outline = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: outline ? Colors.white : _kPrimary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kPrimary),
        ),
        child: Text(text, style: TextStyle(fontSize: 13, color: outline ? _kPrimary : Colors.white)),
      ),
    );
  }
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('取消订单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
              ),
            ],
          ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$2, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? _kPrimary : const Color(0xFFD8D8D8)),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? _kPrimary : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: _kPrimary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('再想想', style: TextStyle(color: _kPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selected == null || _submitting ? null : () async {
                    setState(() => _submitting = true);
                    final nav = Navigator.of(context);
                    await widget.onConfirm(_selected!);
                    nav.pop();
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _selected == null ? const Color(0xFFE5E5E5) : _kPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '仍要取消',
                      style: TextStyle(color: _selected == null ? const Color(0xFF999999) : Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('申请售后', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _SheetItem(
            icon: Icons.undo,
            title: '退款申请',
            subtitle: '申请退款',
            onTap: () {
              Navigator.pop(context);
              context.push('/refund-apply?orderId=$orderId&orderNo=$orderNo');
            },
          ),
          const SizedBox(height: 12),
          _SheetItem(
            icon: Icons.shield_outlined,
            title: '理赔申请',
            subtitle: '宠物意外理赔申请',
            onTap: () {
              Navigator.pop(context);
              context.push('/claim-apply?orderId=$orderId');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Color(0xFFFFF0E0), shape: BoxShape.circle),
              child: Icon(icon, color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
