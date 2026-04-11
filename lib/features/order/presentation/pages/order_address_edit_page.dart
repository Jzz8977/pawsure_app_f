import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class OrderAddressEditPage extends ConsumerStatefulWidget {
  final String? orderId;
  final String? orderNo;
  const OrderAddressEditPage({super.key, this.orderId, this.orderNo});

  @override
  ConsumerState<OrderAddressEditPage> createState() => _OrderAddressEditPageState();
}

class _OrderAddressEditPageState extends ConsumerState<OrderAddressEditPage> {
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedId;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get(AddressApi.list);
      if (!mounted) return;
      final list = (resp.data['content'] as List?) ?? [];
      setState(() {
        _addresses = list.cast<Map<String, dynamic>>();
        _loading = false;
        // pre-select default
        final def = _addresses.firstWhere((a) => a['isDefault'] == true || a['defaultFlag'] == 1, orElse: () => {});
        if (def.isNotEmpty) _selectedId = def['id']?.toString();
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择地址')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/order/user/updateAddress', data: {
        'orderNo': widget.orderNo,
        'addressId': _selectedId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('地址修改成功')));
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
      appBar: AppNavBar(title: '修改地址', showDivider: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _addresses.isEmpty
              ? const Center(child: Text('暂无保存的地址', style: TextStyle(color: Color(0xFF999999))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  itemBuilder: (ctx, i) {
                    final addr = _addresses[i];
                    final id = addr['id']?.toString() ?? '';
                    final name = addr['contactName']?.toString() ?? addr['name']?.toString() ?? '';
                    final phone = addr['contactPhone']?.toString() ?? addr['phone']?.toString() ?? '';
                    final detail = addr['detailAddress']?.toString() ?? addr['address']?.toString() ?? '';
                    final isDefault = addr['isDefault'] == true || addr['defaultFlag'] == 1;
                    final sel = _selectedId == id;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedId = id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? _kPrimary : Colors.transparent, width: 1.5),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text(phone, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                              if (isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFFFF0E0), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('默认', style: TextStyle(fontSize: 11, color: _kPrimary)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 4),
                            Text(detail, style: const TextStyle(fontSize: 13, color: Color(0xFF999999)), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ])),
                          const SizedBox(width: 10),
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: sel ? _kPrimary : const Color(0xFFDDDDDD)),
                            ),
                            child: Center(child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 12, height: 12,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? _kPrimary : Colors.transparent),
                            )),
                          ),
                        ]),
                      ),
                    );
                  },
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
                : const Text('确认地址', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
