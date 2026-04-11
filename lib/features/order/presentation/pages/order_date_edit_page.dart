import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class OrderDateEditPage extends ConsumerStatefulWidget {
  final String? orderId;
  const OrderDateEditPage({super.key, this.orderId});

  @override
  ConsumerState<OrderDateEditPage> createState() => _OrderDateEditPageState();
}

class _OrderDateEditPageState extends ConsumerState<OrderDateEditPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  int get _days {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now));
    final first = isStart ? now : (_startDate ?? now);
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (result == null) return;
    setState(() {
      if (isStart) {
        _startDate = result;
        if (_endDate != null && _endDate!.isBefore(result)) _endDate = null;
      } else {
        _endDate = result;
      }
    });
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择开始和结束日期')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/order/user/updateDate', data: {
        'orderId': widget.orderId,
        'startDate': _startDate!.toIso8601String().substring(0, 10),
        'endDate': _endDate!.toIso8601String().substring(0, 10),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日期修改成功')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppNavBar(title: '修改服务日期', showDivider: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择服务日期', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _DatePicker(
                    label: '开始日期',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  )),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF999999)),
                  ),
                  Expanded(child: _DatePicker(
                    label: '结束日期',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                    enabled: _startDate != null,
                  )),
                ]),
                if (_days > 0) ...[
                  const SizedBox(height: 16),
                  Text('共 $_days 天', style: const TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _SummaryRow(label: '开始日期', value: _startDate!.toIso8601String().substring(0, 10)),
                _SummaryRow(label: '结束日期', value: _endDate!.toIso8601String().substring(0, 10)),
                _SummaryRow(label: '服务天数', value: '$_days 天'),
              ]),
            ),
          ],
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
                : const Text('确认修改', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool enabled;

  const _DatePicker({required this.label, required this.date, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF7F8FA) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: date != null ? _kPrimary : Colors.transparent),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
          const SizedBox(height: 4),
          Text(
            date != null ? date!.toIso8601String().substring(0, 10) : '请选择',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: date != null ? const Color(0xFF333333) : const Color(0xFFBBBBBB),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
      Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
    ]),
  );
}
