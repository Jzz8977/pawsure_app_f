import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _remarkCtrl = TextEditingController();
  bool _insurance = true;
  bool _submitting = false;

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(OrderApi.userCreate, data: {
        'remark': _remarkCtrl.text.trim(),
        'needInsurance': _insurance,
      });
      if (!mounted) return;
      final orderNo = resp.data['content']?['orderNo']?.toString() ?? '';
      context.pushReplacement('/pending-payment?orderNo=$orderNo');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下单失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppNavBar(title: '确认订单', showDivider: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider info placeholder
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('看护师信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Color(0xFF999999)),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('专业看护师', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('专业宠物护理服务', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ]),
              ]),
            ],
          )),
          const SizedBox(height: 12),
          // Order summary
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('订单摘要', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(height: 12),
              const _InfoRow(label: '服务类型', value: '宠物寄养'),
              const _InfoRow(label: '服务日期', value: '请在上一步选择'),
              const _InfoRow(label: '宠物', value: '请在上一步选择'),
            ],
          )),
          const SizedBox(height: 12),
          // Insurance toggle
          _Card(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('宠物保险', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('宠物意外保障，保费¥5/天', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
            ]),
            Switch(value: _insurance, onChanged: (v) => setState(() => _insurance = v), activeThumbColor: _kPrimary),
          ])),
          const SizedBox(height: 12),
          // Remark
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('备注', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(height: 10),
              TextField(
                controller: _remarkCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: '有什么需要特别告诉看护师的？（选填）',
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kPrimary)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          )),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: GestureDetector(
          onTap: _submitting ? null : _submit,
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: _submitting
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('提交订单', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
    ]),
  );
}
