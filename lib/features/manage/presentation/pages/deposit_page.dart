import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

// ── Trade type meta ───────────────────────────────────────────────────────────

class _TradeMeta {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  const _TradeMeta({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

const _tradeMeta = <int, _TradeMeta>{
  1: _TradeMeta(title: '缴纳押金', icon: Icons.arrow_downward_rounded, bgColor: Color(0xFFFDECEB), iconColor: Color(0xFFE87A70)),
  2: _TradeMeta(title: '退还押金', icon: Icons.arrow_upward_rounded, bgColor: Color(0xFFFDF1E4), iconColor: Color(0xFFFF7B16)),
  3: _TradeMeta(title: '押金冻结', icon: Icons.ac_unit_rounded, bgColor: Color(0xFFE5FBF8), iconColor: Color(0xFF2BBCAA)),
  4: _TradeMeta(title: '押金解冻', icon: Icons.whatshot_rounded, bgColor: Color(0xFFE4F7F2), iconColor: Color(0xFF2BA07A)),
  5: _TradeMeta(title: '扣除/理赔', icon: Icons.remove_circle_outline, bgColor: Color(0xFFFDECEB), iconColor: Color(0xFFE87A70)),
  6: _TradeMeta(title: '信用免押', icon: Icons.star_outline_rounded, bgColor: Color(0xFFF5E6E2), iconColor: Color(0xFFC0614E)),
  7: _TradeMeta(title: '平台罚款', icon: Icons.gavel_rounded, bgColor: Color(0xFFFAF4B9), iconColor: Color(0xFFB09A10)),
};

// ── Record model ──────────────────────────────────────────────────────────────

class _DepositRecord {
  final String id;
  final String title;
  final String time;
  final String amount;
  final bool isIncome;
  final String balanceDisplay;
  final _TradeMeta meta;

  _DepositRecord({
    required this.id,
    required this.title,
    required this.time,
    required this.amount,
    required this.isIncome,
    required this.balanceDisplay,
    required this.meta,
  });

  factory _DepositRecord.fromJson(Map<String, dynamic> j) {
    final tradeType = j['tradeType'] as int? ?? 0;
    final rawAmount = (j['amount'] as num?)?.toInt() ?? 0;
    final depositAfter = (j['depositAfter'] as num?)?.toInt() ?? 0;
    final payChannel = j['payChannel'];
    final createdAt = j['createdAt']?.toString() ?? '';

    // income: amount >= 0 except type 2,5
    final isIncome = (tradeType == 2 || tradeType == 5) ? false : rawAmount >= 0;
    final absYuan = rawAmount.abs() / 100;
    final amountStr = '${isIncome ? '+' : '-'}¥${absYuan.toStringAsFixed(2)}';

    final meta = _tradeMeta[tradeType] ??
        _TradeMeta(
          title: '押金变动',
          icon: isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          bgColor: isIncome ? const Color(0xFFFDF1E4) : const Color(0xFFEAF5FF),
          iconColor: isIncome ? const Color(0xFFFF7B16) : const Color(0xFF4A90D9),
        );

    final channelMap = {0: '钱包', 1: '小程序', 2: '微信', 3: '支付宝'};
    final channelStr = payChannel != null ? '渠道：${channelMap[payChannel] ?? '其他'}' : '';
    final balanceStr = '押金余额：¥${(depositAfter / 100).toStringAsFixed(2)}${ channelStr.isNotEmpty ? '  $channelStr' : ''}';

    return _DepositRecord(
      id: j['id']?.toString() ?? '${tradeType}_$createdAt',
      title: meta.title,
      time: _formatTime(createdAt),
      amount: amountStr,
      isIncome: isIncome,
      balanceDisplay: balanceStr,
      meta: meta,
    );
  }

  static String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw.replaceAll(' ', 'T'));
      if (dt == null) return raw;
      final y = dt.year;
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$y-$mo-$d $h:$mi';
    } catch (_) {
      return raw;
    }
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DepositPage extends ConsumerStatefulWidget {
  const DepositPage({super.key});

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends ConsumerState<DepositPage> {
  // account info
  bool _needRecharge = true;
  String _displayAmount = '2000.00';
  String _paidTime = '';

  // agreement
  bool _agreed = false;

  // button state
  bool _paying = false;
  bool _refunding = false;

  // records
  final List<_DepositRecord> _records = [];
  int _pageNo = 1;
  bool _hasMore = true;
  bool _loadingRecords = false;


  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadInfo(), _loadRecords(reset: true)]);
  }

  Future<void> _loadInfo() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(ProviderAccountApi.info);
      final content = resp.data['content'] as Map<String, dynamic>? ?? {};
      final depositAmount = (content['depositAmount'] as num?)?.toInt() ?? 200000;
      final updatedAt = content['updatedAt']?.toString() ?? '';
      if (mounted) {
        setState(() {
          _needRecharge = false; // server returns paid info
          _displayAmount = (depositAmount / 100).toStringAsFixed(2);
          _paidTime = _DepositRecord._formatTime(updatedAt);
        });
      }
    } catch (_) {
      // keep default (unpaid)
    }
  }

  Future<void> _loadRecords({bool reset = false}) async {
    if (_loadingRecords) return;
    if (!reset && !_hasMore) return;
    setState(() => _loadingRecords = true);
    final nextPage = reset ? 1 : _pageNo + 1;
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(DepositApi.page, data: {
        'pageNo': nextPage,
        'pageSize': 10,
      });
      final content = resp.data['content'] as Map<String, dynamic>? ?? {};
      final records = (content['records'] as List?) ?? [];
      final current = (content['current'] as num?)?.toInt() ?? nextPage;
      final pages = (content['pages'] as num?)?.toInt() ?? current;
      final list = records.map((e) => _DepositRecord.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          if (reset) _records.clear();
          _records.addAll(list);
          _pageNo = nextPage;
          _hasMore = current < pages;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _loadingRecords = false);
    }
  }

  void _onPay() {
    if (!_agreed || _paying) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('缴纳押金'),
        content: Text('您将缴纳¥$_displayAmount押金，是否继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _doPayDeposit();
            },
            child: const Text('确认缴纳', style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _doPayDeposit() async {
    setState(() => _paying = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(DepositApi.recharge, data: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缴纳成功')));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('缴纳失败: $e')));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _onRefund() {
    if (_refunding) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退还押金'),
        content: const Text('确认申请退还押金吗？审核通过后将原路退回。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _doRefundDeposit();
            },
            child: const Text('确认退还', style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _doRefundDeposit() async {
    setState(() => _refunding = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(DepositApi.refund, data: {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('申请成功')));
      await _refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('申请失败: $e')));
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppNavBar(title: '押金', showDivider: false),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification && n.metrics.extentAfter < 100) {
            _loadRecords();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _kPrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            children: [
              _buildDepositCard(),
              const SizedBox(height: 12),
              _buildDetailCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  // ── Deposit card ────────────────────────────────────────────────────────────

  Widget _buildDepositCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: _needRecharge ? _buildUnpaidCard() : _buildPaidCard(),
    );
  }

  Widget _buildUnpaidCard() {
    return Column(
      children: [
        // Gradient top
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: [0.22, 1.0],
              colors: [Color(0xFFFF9E4A), Color(0xFFEACF37)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请缴纳押金以享受完整服务',
                style: TextStyle(fontSize: 15, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('押金护航，交易无忧，安心每一步',
                style: TextStyle(fontSize: 12, color: Colors.white)),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(children: [
                  const TextSpan(text: '¥', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                  TextSpan(text: _displayAmount,
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w700, height: 1.1)),
                ]),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text('待缴纳', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ],
          ),
        ),
        // Agreement checkbox
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _agreed ? _kPrimary : const Color(0xFFD8D8D8),
                  ),
                  child: _agreed
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: Color(0xFF3D3D3D)),
                      children: [
                        TextSpan(text: '我已阅读并同意宠信用用户'),
                        TextSpan(text: '《押金管理协议》',
                          style: TextStyle(color: Color(0xFF1F7AE0))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaidCard() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: [0.22, 1.0],
              colors: [Color(0xFFFF9E4A), Color(0xFFEACF37)],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('押金金额',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(children: [
                        const TextSpan(text: '¥',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                        TextSpan(text: _displayAmount,
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w700, height: 1.1)),
                      ]),
                    ),
                    if (_paidTime.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(_paidTime,
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: _refunding ? null : _onRefund,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: _refunding
                      ? const SizedBox(width: 40, height: 16,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
                      : const Text('退押金',
                          style: TextStyle(fontSize: 13, color: Color(0xFF333333))),
                ),
              ),
            ],
          ),
        ),
        // "已缴纳" badge top-right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD88A),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check, size: 12, color: Color(0xFF925F30)),
                SizedBox(width: 3),
                Text('已缴纳', style: TextStyle(fontSize: 12, color: Color(0xFF925F30))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Detail card ─────────────────────────────────────────────────────────────

  Widget _buildDetailCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text('押金明细',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          ),
          if (_loadingRecords && _records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)),
            )
          else if (_records.isEmpty)
            _buildEmptyState()
          else ...[
            ..._records.map(_buildRecordItem),
            if (_loadingRecords)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: Text('加载更多...', style: TextStyle(fontSize: 12, color: Color(0xFFA1A6B3)))),
              )
            else if (!_hasMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: Text('没有更多了', style: TextStyle(fontSize: 12, color: Color(0xFFC5C9D3)))),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: const [
          Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFD0D3DC)),
          SizedBox(height: 10),
          Text('暂无押金记录', style: TextStyle(fontSize: 13, color: Color(0xFFA1A6B3))),
        ],
      ),
    );
  }

  Widget _buildRecordItem(_DepositRecord r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F2F6))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: r.meta.bgColor, shape: BoxShape.circle),
            child: Icon(r.meta.icon, size: 20, color: r.meta.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: const TextStyle(fontSize: 14, color: Color(0xFF2F2F2F))),
                const SizedBox(height: 3),
                Text(r.time, style: const TextStyle(fontSize: 12, color: Color(0xFFA1A6B3))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(r.amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: r.isIncome ? const Color(0xFFFF7B16) : const Color(0xFF333D4F),
                )),
              const SizedBox(height: 3),
              Text(r.balanceDisplay,
                style: const TextStyle(fontSize: 11, color: Color(0xFFA1A6B3))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final disabled = _needRecharge ? !_agreed || _paying : false;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      child: GestureDetector(
        onTap: disabled ? null : (_needRecharge ? _onPay : _onRefund),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFDDDDDD) : _kPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: (_paying || _refunding)
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text(
                  _needRecharge ? '缴纳押金' : '申请退押金',
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
