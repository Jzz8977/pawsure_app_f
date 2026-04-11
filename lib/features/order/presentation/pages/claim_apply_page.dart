import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class ClaimApplyPage extends ConsumerStatefulWidget {
  final String? orderId;
  const ClaimApplyPage({super.key, this.orderId});

  @override
  ConsumerState<ClaimApplyPage> createState() => _ClaimApplyPageState();
}

class _ClaimApplyPageState extends ConsumerState<ClaimApplyPage> {
  static const _reasons = ['宠物疾病', '宠物损伤', '宠物丢失', '其他'];
  String? _selectedReason;
  final _descCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  bool _agreed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _idCardCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择理赔原因')));
      return;
    }
    if (_descCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写至少5个字的描述')));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写理赔人姓名')));
      return;
    }
    if (_idCardCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写身份证号')));
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请同意理赔条款')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/id/claim/apply', data: {
        'orderId': widget.orderId,
        'reason': _selectedReason,
        'description': _descCtrl.text.trim(),
        'claimantName': _nameCtrl.text.trim(),
        'idCard': _idCardCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('理赔申请已提交，我们将尽快处理')));
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
      appBar: AppNavBar(title: '理赔申请', showDivider: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Reason
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('理赔原因', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _reasons.map((r) {
                    final sel = _selectedReason == r;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReason = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFFFF0E0) : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? _kPrimary : Colors.transparent),
                        ),
                        child: Text(r, style: TextStyle(fontSize: 13, color: sel ? _kPrimary : const Color(0xFF666666))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Description
          _InputCard(
            title: '情况描述',
            child: TextField(
              controller: _descCtrl,
              maxLines: 4,
              maxLength: 300,
              decoration: _textFieldDecoration('请描述宠物受损情况（至少5个字）'),
            ),
          ),
          const SizedBox(height: 12),
          // Claimant info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('理赔人信息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 14),
                TextField(controller: _nameCtrl, decoration: _textFieldDecoration('真实姓名')),
                const SizedBox(height: 10),
                TextField(controller: _idCardCtrl, decoration: _textFieldDecoration('身份证号')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Agree
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _agreed ? _kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _agreed ? _kPrimary : const Color(0xFFDDDDDD)),
                  ),
                  child: _agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('我已阅读并同意理赔相关条款', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                ),
              ]),
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

  InputDecoration _textFieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kPrimary)),
    contentPadding: const EdgeInsets.all(12),
  );
}

class _InputCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InputCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
      const SizedBox(height: 12),
      child,
    ]),
  );
}
