import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

class _Record {
  final String id;
  final String title;
  final String time;
  final String amount;
  final String type;
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
      time: (json['createTime'] as String?)
              ?.replaceAll('T', ' ')
              .substring(0, 16) ??
          '',
      amount: '${amt >= 0 ? '+' : ''}${(amt / 100).toStringAsFixed(2)}',
      type: type,
      balanceDisplay: balance != null
          ? '余额 ¥${(balance / 100).toStringAsFixed(2)}'
          : null,
    );
  }

  IconData get icon => type == 'income'
      ? Icons.arrow_circle_down_outlined
      : Icons.arrow_circle_up_outlined;

  Color get amountColor =>
      type == 'income' ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
}

class WalletDetailPage extends ConsumerStatefulWidget {
  const WalletDetailPage({super.key});

  @override
  ConsumerState<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends ConsumerState<WalletDetailPage> {
  final List<_Record> _records = [];
  bool _loading = false;
  bool _finished = false;
  int _page = 1;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 100) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading || _finished) return;
    setState(() => _loading = true);
    try {
      final res = await ref.read(dioProvider).post(
        WalletApi.transactionList,
        data: {'pageNo': _page, 'pageSize': 20},
      );
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      final raw = (content?['records'] as List<dynamic>?) ?? [];
      final total = (content?['total'] as num?)?.toInt() ?? 0;
      final items =
          raw.map((e) => _Record.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _records.addAll(items);
          _page++;
          _finished = _records.length >= total;
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
      appBar: const AppNavBar(title: '账单明细'),
      body: _loading && _records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  controller: _scroll,
                  itemCount: _records.length + 1,
                  itemBuilder: (_, i) {
                    if (i < _records.length) return _buildItem(_records[i]);
                    return _buildFooter();
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('暂无账单记录',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildItem(_Record record) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _buildFooter() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_finished) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('没有更多了',
              style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
        ),
      );
    }
    return const SizedBox(height: 20);
  }
}
