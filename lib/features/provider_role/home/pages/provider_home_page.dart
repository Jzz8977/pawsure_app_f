import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

class ProviderHomePage extends ConsumerStatefulWidget {
  const ProviderHomePage({super.key});

  @override
  ConsumerState<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends ConsumerState<ProviderHomePage> {
  static const _tabs = [
    {'key': 'waiting', 'label': '待操作'},
    {'key': 'doing',   'label': '进行中'},
    {'key': 'done',    'label': '已完成'},
  ];

  static const _actions = [
    {'id': 'clockin',  'title': '正常打卡',  'icon': Icons.access_time},
    {'id': 'report',   'title': '异常上报',  'icon': Icons.report_problem_outlined},
    {'id': 'service',  'title': '服务配置',  'icon': Icons.settings_outlined},
  ];

  String _activeTab = 'doing';
  bool _loading = false;
  bool _hasMore = true;
  int _pageNo = 1;
  List<Map<String, dynamic>> _orders = [];

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadOrders(refresh: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loading && _hasMore) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (_loading) return;
    if (!refresh && !_hasMore) return;
    setState(() => _loading = true);
    final pageNo = refresh ? 1 : _pageNo;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(OrderApi.serverList, data: {
        'tabKey': _activeTab,
        'pageNo': pageNo,
        'pageSize': 10,
      });
      final content = res.data['content'];
      final records = (content is Map ? content['records'] : null) as List? ?? [];
      final total = (content is Map ? content['total'] : 0) as int? ?? 0;
      final items = records.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _orders = refresh ? items : [..._orders, ...items];
        _pageNo = pageNo + 1;
        _hasMore = _orders.length < total;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchTab(String key) {
    if (key == _activeTab) return;
    setState(() {
      _activeTab = key;
      _orders = [];
      _pageNo = 1;
      _hasMore = true;
    });
    _loadOrders(refresh: true);
  }

  void _onActionTap(String id) {
    switch (id) {
      case 'clockin':
        context.push('/clockin');
        break;
      case 'report':
        context.push('/report-issue');
        break;
      case 'service':
        context.push('/service-manage');
        break;
    }
  }

  Future<void> _onOrderAction(String action, Map<String, dynamic> order) async {
    final orderNo = order['orderNo']?.toString() ?? '';
    final orderBody = {'orderNo': orderNo};
    try {
      switch (action) {
        case 'accept':
          await ref.read(dioProvider).post(OrderApi.serverAccept, data: orderBody);
          break;
        case 'reject':
          await ref.read(dioProvider).post(OrderApi.serverReject, data: orderBody);
          break;
        case 'startService':
          await ref.read(dioProvider).post(OrderApi.serverStartService, data: orderBody);
          break;
        case 'finishService':
          await ref.read(dioProvider).post(OrderApi.serverFinishService, data: orderBody);
          break;
        case 'approveCancel':
          await ref.read(dioProvider).post(OrderApi.serverConfirmCancel, data: orderBody);
          break;
        case 'rejectCancel':
          await ref.read(dioProvider).post(OrderApi.serverRejectCancel, data: orderBody);
          break;
        case 'clockin':
          if (mounted) context.push('/clockin');
          return;
        case 'clockinTasks':
          if (mounted) context.push('/clockin-tasks');
          return;
        case 'clockinRecord':
          if (mounted) context.push('/clockin-record');
          return;
        case 'report':
          if (mounted) context.push('/report-issue');
          return;
        default:
          return;
      }
      if (mounted) _loadOrders(refresh: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '首页', showDivider: false, backgroundColor: Color(0xFFFFEBBB)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadOrders(refresh: true),
              child: ListView(
                controller: _scroll,
                children: [
                  _buildActionGrid(),
                  _buildTabs(),
                  _buildOrderList(),
                  if (_loading) const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  if (!_loading && !_hasMore && _orders.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('没有更多了', style: TextStyle(fontSize: 13, color: Color(0xFF999999)))),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Container(
      color: const Color(0xFFFFEBBB),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: _actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _onActionTap(a['id'] as String),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(a['icon'] as IconData, color: const Color(0xFFFF9E4A), size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(a['title'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: _tabs.map((t) {
          final key = t['key']!;
          final isActive = key == _activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? const Color(0xFFFF9E4A) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  t['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? const Color(0xFFFF9E4A) : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderList() {
    if (!_loading && _orders.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('暂无任务', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ),
      );
    }
    return Column(
      children: _orders.map((o) => _buildOrderCard(o)).toList(),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderNo = order['orderNo']?.toString() ?? '';
    final customerName = order['customerName']?.toString() ?? '--';
    final createTime = _formatTime(order['createTime']);
    final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final amountYuan = (totalAmount / 100).toStringAsFixed(2);
    final statusText = order['orderStatusText']?.toString() ?? order['orderStatus']?.toString() ?? '--';
    final serviceType = order['serviceType']?.toString() ?? '';
    final petName = order['petName']?.toString() ?? '';

    final List<dynamic> leftActions = order['leftActions'] as List? ?? [];
    final List<dynamic> rightActions = order['rightActions'] as List? ?? [];

    return GestureDetector(
      onTap: () => context.push('/provider-order-detail'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                        const SizedBox(height: 4),
                        Text('下单时间 $createTime', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('订单金额', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      Text('¥$amountYuan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(serviceType, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9E4A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusText, style: const TextStyle(fontSize: 12, color: Color(0xFFFF9E4A))),
                  ),
                ],
              ),
            ),
            if (petName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('宠物：$petName', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
              ),
            if (leftActions.isNotEmpty || rightActions.isNotEmpty) ...[
              const Divider(height: 24, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: leftActions.map<Widget>((btn) {
                        final m = btn as Map;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _actionBtn(m['label']?.toString() ?? '', m['action']?.toString() ?? '', order, outline: true),
                        );
                      }).toList(),
                    ),
                    Row(
                      children: rightActions.map<Widget>((btn) {
                        final m = btn as Map;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _actionBtn(m['label']?.toString() ?? '', m['action']?.toString() ?? '', order),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 12),
            if (orderNo.isNotEmpty && leftActions.isEmpty && rightActions.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _actionBtn('打卡记录', 'clockinRecord', order, outline: true),
                    const SizedBox(width: 8),
                    _actionBtn('打卡任务', 'clockinTasks', order, outline: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, String action, Map<String, dynamic> order, {bool outline = false}) {
    return GestureDetector(
      onTap: () => _onOrderAction(action, order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: outline ? Colors.white : const Color(0xFFFF9E4A),
          border: Border.all(color: const Color(0xFFFF9E4A)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: outline ? const Color(0xFFFF9E4A) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--';
    final d = DateTime.tryParse(value.toString().replaceAll('-', '/'));
    if (d == null) return value.toString();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
