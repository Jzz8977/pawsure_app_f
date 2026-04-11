import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class RefundDetailPage extends ConsumerStatefulWidget {
  final String id; // refundId
  const RefundDetailPage({super.key, required this.id});

  @override
  ConsumerState<RefundDetailPage> createState() => _RefundDetailPageState();
}

class _RefundDetailPageState extends ConsumerState<RefundDetailPage> {
  Map<String, dynamic>? _refund;
  bool _loading = true;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(RefundApi.detail, data: {'refundId': widget.id});
      if (!mounted) return;
      setState(() {
        _refund = resp.data['content'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelRefund() async {
    setState(() => _cancelling = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(RefundApi.cancel, data: {'refundId': widget.id});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤销退款申请')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PENDING': return '待商家处理';
      case 'APPROVED': return '已同意';
      case 'REJECTED': return '已拒绝';
      case 'COMPLETED': return '退款完成';
      case 'CANCELLED': return '已撤销';
      default: return s ?? '';
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PENDING': return _kPrimary;
      case 'APPROVED': return const Color(0xFF4CAF50);
      case 'REJECTED': return const Color(0xFFFF5722);
      case 'COMPLETED': return const Color(0xFF2196F3);
      default: return const Color(0xFF999999);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _refund?['status']?.toString();
    final refundAmount = (_refund?['refundAmount'] as num?) ?? 0;
    final reason = _refund?['reason']?.toString() ?? '';
    final description = _refund?['description']?.toString() ?? '';
    final createTime = _refund?['createTime']?.toString() ?? '';
    final isPending = status == 'PENDING';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppNavBar(title: '退款详情', showDivider: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _refund == null
              ? const Center(child: Text('退款记录不存在'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Status card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPending ? Icons.access_time : (status == 'COMPLETED' ? Icons.check_circle : Icons.info),
                            color: _statusColor(status),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_statusLabel(status), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _statusColor(status))),
                        const SizedBox(height: 6),
                        Text(
                          isPending ? '请等待商家处理，通常1-3个工作日内完成' : '退款已${_statusLabel(status)}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Progress steps
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('退款进度', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                          const SizedBox(height: 16),
                          _ProgressStep(title: '申请退款', active: true, done: true),
                          _ProgressStep(title: '商家处理', active: status != null && status != 'PENDING', done: status == 'APPROVED' || status == 'COMPLETED'),
                          _ProgressStep(title: '退款结果', active: status == 'COMPLETED' || status == 'REJECTED', done: status == 'COMPLETED', isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Refund info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        _InfoRow(label: '退款金额', value: '¥${(refundAmount / 100).toStringAsFixed(2)}'),
                        _InfoRow(label: '退款原因', value: reason),
                        if (description.isNotEmpty) _InfoRow(label: '问题描述', value: description),
                        _InfoRow(label: '申请时间', value: createTime.length > 16 ? createTime.substring(0, 16) : createTime),
                      ]),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
      bottomNavigationBar: isPending && !_loading
          ? Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              child: GestureDetector(
                onTap: _cancelling ? null : _cancelRefund,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: _cancelling
                      ? const CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)
                      : const Text('撤销退款申请', style: TextStyle(fontSize: 15, color: Color(0xFF666666))),
                ),
              ),
            )
          : null,
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final bool active;
  final bool done;
  final bool isLast;

  const _ProgressStep({required this.title, required this.active, required this.done, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? _kPrimary : (active ? const Color(0xFFFFF0E0) : const Color(0xFFF0F0F0)),
            border: Border.all(color: active ? _kPrimary : const Color(0xFFDDDDDD)),
          ),
          child: done ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        if (!isLast) Container(width: 2, height: 32, color: active ? _kPrimary.withValues(alpha: 0.3) : const Color(0xFFEEEEEE)),
      ]),
      const SizedBox(width: 12),
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(title, style: TextStyle(
          fontSize: 14,
          color: active ? const Color(0xFF333333) : const Color(0xFF999999),
          fontWeight: active ? FontWeight.w500 : FontWeight.normal,
        )),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
    ]),
  );
}
