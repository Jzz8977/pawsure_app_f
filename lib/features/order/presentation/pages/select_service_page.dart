import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class SelectServicePage extends ConsumerStatefulWidget {
  final String? providerId;
  const SelectServicePage({super.key, this.providerId});

  @override
  ConsumerState<SelectServicePage> createState() => _SelectServicePageState();
}

class _SelectServicePageState extends ConsumerState<SelectServicePage> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _pets = [];
  List<String> _selectedPetIds = [];
  bool _mealAddon = false;
  bool _bathAddon = false;
  bool _groomAddon = false;
  bool _loadingPets = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(PetApi.pageQuery, data: {'pageNo': 1, 'pageSize': 50});
      if (!mounted) return;
      final records = (resp.data['content']?['records'] as List?) ?? [];
      setState(() {
        _pets = records.cast<Map<String, dynamic>>();
        _loadingPets = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPets = false);
    }
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
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)),
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

  void _goCheckout() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择服务日期')));
      return;
    }
    if (_selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择宠物')));
      return;
    }
    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppNavBar(title: '选择服务', showDivider: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date selection
          _SectionCard(
            title: '服务日期',
            child: Row(children: [
              Expanded(child: _DateBox(
                label: '开始日期',
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              )),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF999999)),
              ),
              Expanded(child: _DateBox(
                label: '结束日期',
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
                enabled: _startDate != null,
              )),
            ]),
          ),
          const SizedBox(height: 12),
          // Pet selection
          _SectionCard(
            title: '选择宠物',
            child: _loadingPets
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : _pets.isEmpty
                    ? const Text('暂无宠物，请先添加', style: TextStyle(color: Color(0xFF999999)))
                    : Wrap(
                        spacing: 10, runSpacing: 10,
                        children: _pets.map((p) {
                          final id = p['id']?.toString() ?? '';
                          final name = p['petName']?.toString() ?? '宠物';
                          final sel = _selectedPetIds.contains(id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (sel) _selectedPetIds.remove(id);
                              else _selectedPetIds.add(id);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFFFF0E0) : const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? _kPrimary : Colors.transparent),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.pets, size: 14, color: sel ? _kPrimary : const Color(0xFF999999)),
                                const SizedBox(width: 4),
                                Text(name, style: TextStyle(fontSize: 13, color: sel ? _kPrimary : const Color(0xFF666666))),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 12),
          // Add-ons
          _SectionCard(
            title: '附加服务',
            child: Column(children: [
              _ToggleRow(label: '餐食服务', price: '¥20/天', value: _mealAddon, onChanged: (v) => setState(() => _mealAddon = v)),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _ToggleRow(label: '洗澡护理', price: '¥80/次', value: _bathAddon, onChanged: (v) => setState(() => _bathAddon = v)),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _ToggleRow(label: '专业美容', price: '¥150/次', value: _groomAddon, onChanged: (v) => setState(() => _groomAddon = v)),
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: GestureDetector(
          onTap: _goCheckout,
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Text('下一步', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool enabled;
  const _DateBox({required this.label, required this.date, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: date != null ? const Color(0xFF333333) : const Color(0xFFBBBBBB)),
        ),
      ]),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String price;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.price, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      Text(price, style: const TextStyle(fontSize: 12, color: _kPrimary)),
    ])),
    Switch(value: value, onChanged: onChanged, activeThumbColor: _kPrimary),
  ]);
}
