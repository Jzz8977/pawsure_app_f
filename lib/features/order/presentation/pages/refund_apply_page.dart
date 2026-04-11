import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class RefundApplyPage extends ConsumerStatefulWidget {
  final String? orderId;
  final String? orderNo;

  const RefundApplyPage({super.key, this.orderId, this.orderNo});

  @override
  ConsumerState<RefundApplyPage> createState() => _RefundApplyPageState();
}

class _RefundApplyPageState extends ConsumerState<RefundApplyPage> {
  List<Map<String, dynamic>> _reasons = [];
  String? _selectedReasonKey;
  String? _selectedReasonValue;
  final _descCtrl = TextEditingController();
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReasons() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(LibApi.dictBatchList, data: ['refund_reason']);
      if (!mounted) return;
      final list = (resp.data['content']?['refund_reason'] as List?) ?? [];
      setState(() {
        _reasons = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedReasonKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择退款原因')));
      return;
    }
    if (_descCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写至少5个字的描述')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(RefundApi.apply, data: {
        'orderId': widget.orderId,
        'orderNo': widget.orderNo,
        'reason': _selectedReasonValue,
        'description': _descCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('退款申请已提交')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppNavBar(title: '申请退款', showDivider: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Order info
                if (widget.orderNo != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('订单号', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                      Text(widget.orderNo!, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
                    ]),
                  ),
                // Reason selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('退款原因', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                      const SizedBox(height: 14),
                      if (_reasons.isEmpty)
                        const Text('暂无可选原因', style: TextStyle(color: Color(0xFF999999)))
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _reasons.map((r) {
                            final key = r['key']?.toString() ?? '';
                            final value = r['value']?.toString() ?? '';
                            final sel = _selectedReasonKey == key;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedReasonKey = key;
                                _selectedReasonValue = value;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? const Color(0xFFFFF0E0) : const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: sel ? _kPrimary : Colors.transparent),
                                ),
                                child: Text(value, style: TextStyle(fontSize: 13, color: sel ? _kPrimary : const Color(0xFF666666))),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('退款说明', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 5,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText: '请描述退款原因（至少5个字）',
                          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kPrimary)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
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
                : const Text('提交申请', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
