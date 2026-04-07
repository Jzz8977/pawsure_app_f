import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  double _balance = 0;
  bool _balanceLoading = true;
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final res = await ref.read(dioProvider).post(WalletApi.info, data: {});
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      final amt = (content?['amount'] as num?)?.toDouble() ?? 0;
      if (mounted) setState(() => _balance = amt / 100);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _balanceLoading = false);
    }
  }

  void _fillAll() {
    _ctrl.text = _balance.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入有效的提现金额')));
      return;
    }
    if (amount < 10) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('最低提现金额为10元')));
      return;
    }
    if (amount > _balance) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('提现金额不能超过可用余额')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(dioProvider).post(
        WalletApi.withdraw,
        data: {'amount': (amount * 100).round()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('提现申请已提交')));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('提现失败，请稍后重试')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFEF1DD),
      appBar: const AppNavBar(
        title: '提现',
        backgroundColor: Color(0xFFFEF1DD),
        showDivider: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero 余额卡
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    color: const Color(0xFFFEF1DD),
                    child: Column(
                      children: [
                        const Text(
                          '可提现余额（元）',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF888888)),
                        ),
                        const SizedBox(height: 8),
                        _balanceLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                _balance.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF333333)),
                              ),
                      ],
                    ),
                  ),

                  // 输入区
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '提现金额',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF888888)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '¥',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333)),
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                      color: Color(0xFFCCCCCC),
                                      fontSize: 24),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _fillAll,
                              child: const Text(
                                '全部提现',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFFF7E51)),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 4),
                        const Text(
                          '最低提现金额 ¥10.00',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),

                  // 提示
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '提现说明',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333)),
                        ),
                        SizedBox(height: 10),
                        _TipItem(text: '提现到账时间为1-3个工作日，节假日顺延'),
                        _TipItem(text: '提现手续费由平台承担，用户无需支付'),
                        _TipItem(text: '如遇问题请联系客服，我们将尽快为您处理'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部按钮
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7E51),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E5E5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('申请提现',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: Color(0xFFBBBBBB),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF888888), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
