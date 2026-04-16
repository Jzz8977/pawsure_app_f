import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/providers/user_provider.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

// ── 模型 ──────────────────────────────────────────────────────────

class _WalletInfo {
  final double amount;
  final double settledAmount;
  final double settleAmount;
  final double depositAmount;

  const _WalletInfo({
    this.amount = 0,
    this.settledAmount = 0,
    this.settleAmount = 0,
    this.depositAmount = 0,
  });

  factory _WalletInfo.fromJson(Map<String, dynamic> json) => _WalletInfo(
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        settledAmount: (json['settledAmount'] as num?)?.toDouble() ?? 0,
        settleAmount: (json['settleAmount'] as num?)?.toDouble() ?? 0,
        depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
      );

  String fmt(double v) => (v / 100).toStringAsFixed(2);
  String get amountDisplay => fmt(amount);
  String get settledAmountDisplay => fmt(settledAmount);
  String get settleAmountDisplay => fmt(settleAmount);
  String get depositAmountDisplay => fmt(depositAmount);
}

class _Record {
  final String id;
  final String title;
  final String time;
  final String amount;
  final String type; // income / expense
  final String? balanceDisplay;

  const _Record({
    required this.id,
    required this.title,
    required this.time,
    required this.amount,
    required this.type,
    this.balanceDisplay,
  });

  factory _Record.fromJson(Map<String, dynamic> json) {
    final amt = (json['amount'] as num?)?.toDouble() ?? 0;
    final type = amt >= 0 ? 'income' : 'expense';
    final balance = (json['balance'] as num?)?.toDouble();
    return _Record(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? json['remark'] as String? ?? '交易记录',
      time: (json['createTime'] as String?)?.replaceAll('T', ' ').substring(0, 16) ?? '',
      amount: '${amt >= 0 ? '+' : ''}${(amt / 100).toStringAsFixed(2)}',
      type: type,
      balanceDisplay: balance != null ? '余额 ¥${(balance / 100).toStringAsFixed(2)}' : null,
    );
  }

  IconData get icon {
    if (type == 'income') return Icons.arrow_circle_down_outlined;
    return Icons.arrow_circle_up_outlined;
  }

  Color get amountColor =>
      type == 'income' ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
}

// ── Page ─────────────────────────────────────────────────────────

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  _WalletInfo? _wallet;
  bool _walletLoading = true;

  // records
  final List<_Record> _records = [];
  bool _listLoading = false;
  bool _finished = false;
  int _page = 1;
  String _filterKey = 'all';
  final ScrollController _scroll = ScrollController();

  static const _filters = [
    ('all', '全部'),
    ('income', '收入'),
    ('expense', '支出'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _scroll.addListener(_onScroll);
    _loadWallet();
    _loadRecords(reset: true);
  }

  @override
  void dispose() {
    _tab.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 100) {
      _loadRecords();
    }
  }

  Future<void> _loadWallet() async {
    try {
      final res = await ref.read(dioProvider).post(WalletApi.info, data: {});
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      if (mounted && content != null) {
        setState(() => _wallet = _WalletInfo.fromJson(content));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  Future<void> _loadRecords({bool reset = false}) async {
    if (_listLoading || (!reset && _finished)) return;
    if (reset) {
      setState(() {
        _records.clear();
        _page = 1;
        _finished = false;
      });
    }
    setState(() => _listLoading = true);
    try {
      final res = await ref.read(dioProvider).post(
        WalletApi.recordPage,
        data: {'pageNo': _page, 'pageSize': 20, 'type': _filterKey == 'all' ? null : _filterKey},
      );
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      final raw = (content?['records'] as List<dynamic>?) ?? [];
      final current = (content?['current'] as num?)?.toInt() ?? _page;
      final pages = (content?['pages'] as num?)?.toInt() ?? 1;
      final items = raw.map((e) => _Record.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _records.addAll(items);
          _page = current + 1;
          _finished = current >= pages;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _listLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final isProvider = user?.role == UserRole.provider;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF1DD),
      appBar: const AppNavBar(
        title: '我的钱包',
        backgroundColor: Color(0xFFFEF1DD),
        showDivider: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadWallet(), _loadRecords(reset: true)]);
        },
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _buildHero(isProvider)),
            if (isProvider)
              SliverToBoxAdapter(child: _buildDepositEntry()),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildFilterRow(),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i < _records.length) {
                    return _buildRecordItem(_records[i]);
                  }
                  return null;
                },
                childCount: _records.length,
              ),
            ),
            SliverToBoxAdapter(child: _buildListFooter()),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isProvider) {
    final wallet = _wallet ?? const _WalletInfo();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户行
          _buildUserRow(),
          const SizedBox(height: 16),
          // 余额
          const Text('账户余额',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('¥',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333))),
              const SizedBox(width: 2),
              _walletLoading
                  ? const SizedBox(
                      width: 80, height: 36,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  : Text(
                      wallet.amountDisplay,
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333)),
                    ),
            ],
          ),
          if (isProvider) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricItem(label: '已结算收入', value: '¥${wallet.settledAmountDisplay}'),
                _MetricItem(label: '待结算金额', value: '¥${wallet.settleAmountDisplay}'),
                _MetricItem(label: '押金余额', value: '¥${wallet.depositAmountDisplay}'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (!isProvider)
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
                child: const Text('充值'),
              ),
            ),
          if (isProvider)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7E51),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('充值'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/withdraw'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7E51),
                      side: const BorderSide(color: Color(0xFFFF7E51)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('提现'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUserRow() {
    final user = ref.watch(userNotifierProvider);
    return Row(
      children: [
        ClipOval(
          child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: user.avatarUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, err) => _defaultAvatar(),
                )
              : _defaultAvatar(),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? '用户',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '普通用户',
                style: TextStyle(fontSize: 11, color: Color(0xFFFF7E51)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _defaultAvatar() => Container(
        width: 40,
        height: 40,
        color: const Color(0xFFF5F0EA),
        child: const Icon(Icons.person, size: 22, color: Color(0xFFBBBBBB)),
      );

  Widget _buildDepositEntry() {
    return GestureDetector(
      onTap: () => context.push('/deposit'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('押金管理',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333))),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: _filters.map((f) {
          final active = _filterKey == f.$1;
          return GestureDetector(
            onTap: () {
              if (_filterKey == f.$1) return;
              setState(() => _filterKey = f.$1);
              _loadRecords(reset: true);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF7E51)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f.$2,
                style: TextStyle(
                    fontSize: 13,
                    color: active ? Colors.white : const Color(0xFF666666)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordItem(_Record record) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 1),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: record.type == 'income'
                  ? const Color(0xFFE8F8F0)
                  : const Color(0xFFFFF0EE),
              shape: BoxShape.circle,
            ),
            child: Icon(record.icon,
                size: 20,
                color: record.type == 'income'
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE74C3C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF333333))),
                const SizedBox(height: 3),
                Text(record.time,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.amount,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: record.amountColor),
              ),
              if (record.balanceDisplay != null)
                Text(
                  record.balanceDisplay!,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListFooter() {
    if (_listLoading && _records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_listLoading && _records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('暂无交易记录',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          ],
        ),
      );
    }
    if (_finished) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('没有更多了',
              style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
        ),
      );
    }
    if (_listLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return const SizedBox(height: 20);
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333))),
      ],
    );
  }
}
