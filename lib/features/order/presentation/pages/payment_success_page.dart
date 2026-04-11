import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kPrimary = Color(0xFFFF9E4A);

class PaymentSuccessPage extends StatefulWidget {
  final String? orderNo;
  final String? amount;

  const PaymentSuccessPage({super.key, this.orderNo, this.amount});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        if (mounted) context.go('/order?tab=IN_SERVICE');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.amount ?? '0.00';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text('支付成功', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                    const SizedBox(height: 10),
                    Text('¥$amount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 30),
                    Text('$_countdown 秒后自动跳转到订单页', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/order?tab=IN_SERVICE'),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('查看订单', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text('返回首页', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
