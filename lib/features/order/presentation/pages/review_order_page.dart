import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class ReviewOrderPage extends ConsumerStatefulWidget {
  final String id; // orderId
  const ReviewOrderPage({super.key, required this.id});

  @override
  ConsumerState<ReviewOrderPage> createState() => _ReviewOrderPageState();
}

class _ReviewOrderPageState extends ConsumerState<ReviewOrderPage> {
  int _serviceRating = 5;
  int _envRating = 5;
  int _patienceRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/order/user/review', data: {
        'orderId': widget.id,
        'serviceRating': _serviceRating,
        'envRating': _envRating,
        'patienceRating': _patienceRating,
        'comment': _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评价成功')));
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
      appBar: AppNavBar(title: '评价订单', showDivider: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('服务评分', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 16),
                _RatingRow(label: '服务质量', rating: _serviceRating, onChanged: (v) => setState(() => _serviceRating = v)),
                const SizedBox(height: 12),
                _RatingRow(label: '环境卫生', rating: _envRating, onChanged: (v) => setState(() => _envRating = v)),
                const SizedBox(height: 12),
                _RatingRow(label: '耐心程度', rating: _patienceRating, onChanged: (v) => setState(() => _patienceRating = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('文字评价', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 5,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: '分享您的服务体验（选填）',
                    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
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
                : const Text('提交评价', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int rating;
  final ValueChanged<int> onChanged;

  const _RatingRow({required this.label, required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF666666)))),
      ...List.generate(5, (i) => GestureDetector(
        onTap: () => onChanged(i + 1),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            i < rating ? Icons.star : Icons.star_border,
            color: i < rating ? _kPrimary : const Color(0xFFDDDDDD),
            size: 28,
          ),
        ),
      )),
    ]);
  }
}
