import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class PendingPaymentPage extends ConsumerStatefulWidget {
  final String? orderNo;
  final String? orderId;
  final String? payAmount;

  const PendingPaymentPage({super.key, this.orderNo, this.orderId, this.payAmount});

  @override
  ConsumerState<PendingPaymentPage> createState() => _PendingPaymentPageState();
}

class _PendingPaymentPageState extends ConsumerState<PendingPaymentPage> {
  int _remaining = 30 * 60; // 30 minutes
  Timer? _timer;
  String _payMethod = 'MINI'; // MINI = wechat, WALLET = balance
  bool _submitting = false;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.payAmount == null) _loadOrder();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    if (widget.orderNo == null) return;
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(OrderApi.userDetail, data: {'orderNo': widget.orderNo});
      if (!mounted) return;
      setState(() => _order = resp.data['content'] as Map<String, dynamic>?);
    } catch (_) {}
  }

  String get _countdownText {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _amountFen {
    if (widget.payAmount != null) {
      return int.tryParse(widget.payAmount!) ?? 0;
    }
    return (_order?['payAmount'] as num?)?.toInt() ?? 0;
  }

  Future<void> _pay() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(PaymentApi.createOrder, data: {
        'orderNo': widget.orderNo,
        'paymentMethod': _payMethod,
      });
      if (!mounted) return;
      final yuan = (_amountFen / 100).toStringAsFixed(2);
      context.pushReplacement('/payment-success?orderNo=${widget.orderNo}&amount=$yuan');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('支付失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final yuan = (_amountFen / 100).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppNavBar(title: '确认支付', showDivider: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              const Text('待支付金额', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
              const SizedBox(height: 8),
              Text('¥$yuan', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
              const SizedBox(height: 12),
              if (_remaining > 0) ...[
                const Text('请在以下时间内完成支付', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(height: 6),
                Text(_countdownText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary)),
              ] else
                const Text('支付超时，请重新下单', style: TextStyle(fontSize: 13, color: Color(0xFFFF5722))),
            ]),
          ),
          const SizedBox(height: 16),
          // Order info
          if (widget.orderNo != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('订单号', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  Text(widget.orderNo!, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Payment methods
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _PayMethodTile(
                icon: Icons.payment,
                title: '微信支付',
                subtitle: '推荐使用',
                value: 'MINI',
                selected: _payMethod == 'MINI',
                onTap: () => setState(() => _payMethod = 'MINI'),
              ),
              const Divider(height: 1, indent: 56),
              _PayMethodTile(
                icon: Icons.account_balance_wallet,
                title: '余额支付',
                subtitle: '使用账户余额',
                value: 'WALLET',
                selected: _payMethod == 'WALLET',
                onTap: () => setState(() => _payMethod = 'WALLET'),
              ),
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _remaining > 0 && !_submitting ? _pay : null,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _remaining > 0 ? _kPrimary : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('立即支付', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text('取消订单', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PayMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: selected ? const Color(0xFFFFF0E0) : const Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: selected ? _kPrimary : const Color(0xFF999999)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          ])),
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? _kPrimary : const Color(0xFFD8D8D8)),
            ),
            child: Center(child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 10, height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? _kPrimary : Colors.transparent),
            )),
          ),
        ]),
      ),
    );
  }
}
