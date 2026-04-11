import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class OrderServiceEditPage extends ConsumerStatefulWidget {
  final String? orderId;
  const OrderServiceEditPage({super.key, this.orderId});

  @override
  ConsumerState<OrderServiceEditPage> createState() => _OrderServiceEditPageState();
}

class _ServiceItem {
  final String key;
  final String name;
  final String unit;
  final int unitPrice; // fen
  int qty;

  _ServiceItem({required this.key, required this.name, required this.unit, required this.unitPrice, int qty = 0}) : qty = qty;
}

class _OrderServiceEditPageState extends ConsumerState<OrderServiceEditPage> {
  final List<_ServiceItem> _items = [
    _ServiceItem(key: 'meal', name: '餐食', unit: '份/天', unitPrice: 2000),
    _ServiceItem(key: 'bath', name: '洗澡', unit: '次', unitPrice: 8000),
    _ServiceItem(key: 'groom', name: '美容', unit: '次', unitPrice: 15000),
  ];
  bool _pickup = false;
  bool _submitting = false;

  int get _total => _items.fold(0, (sum, it) => sum + it.unitPrice * it.qty);

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/order/user/updateService', data: {
        'orderId': widget.orderId,
        'services': _items.map((it) => {'key': it.key, 'qty': it.qty}).toList(),
        'needPickup': _pickup,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('服务修改成功')));
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
      appBar: AppNavBar(title: '修改服务', showDivider: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ..._items.asMap().entries.map((e) {
                  final i = e.key;
                  final it = e.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(it.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Text('¥${(it.unitPrice / 100).toStringAsFixed(0)}/${it.unit}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                          ])),
                          _Stepper(value: it.qty, onChanged: (v) => setState(() => it.qty = v)),
                        ]),
                      ),
                      if (i < _items.length - 1 || true) const Divider(height: 1, indent: 14, endIndent: 14),
                    ],
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('上门接送', style: TextStyle(fontSize: 14)),
                    Switch(value: _pickup, onChanged: (v) => setState(() => _pickup = v), activeThumbColor: _kPrimary),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('附加费用合计', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              Text('¥${(_total / 100).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            ]),
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
                : const Text('确认修改', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: value > 0 ? () => onChanged(value - 1) : null,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: value > 0 ? _kPrimary : const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.remove, size: 16, color: value > 0 ? _kPrimary : const Color(0xFFDDDDDD)),
        ),
      ),
      SizedBox(
        width: 36,
        child: Center(child: Text('$value', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
      ),
      GestureDetector(
        onTap: () => onChanged(value + 1),
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.add, size: 16, color: Colors.white),
        ),
      ),
    ]);
  }
}
