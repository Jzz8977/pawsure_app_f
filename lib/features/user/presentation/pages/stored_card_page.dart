import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';
import '../../../../../shared/widgets/footer_bar.dart';

class _CardOption {
  final String id;
  final String name;
  final double faceValue;
  final int bonusPoints;
  final int bonusCoupons;
  final String priceDisplay;

  const _CardOption({
    required this.id,
    required this.name,
    required this.faceValue,
    required this.bonusPoints,
    required this.bonusCoupons,
    required this.priceDisplay,
  });

  factory _CardOption.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final faceValue = (json['faceValue'] as num?)?.toDouble() ?? price;
    return _CardOption(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '储值卡',
      faceValue: faceValue / 100,
      bonusPoints: (json['bonusPoints'] as num?)?.toInt() ?? 0,
      bonusCoupons: (json['bonusCoupons'] as num?)?.toInt() ?? 0,
      priceDisplay: '¥${(price / 100).toStringAsFixed(0)}',
    );
  }
}

class StoredCardPage extends ConsumerStatefulWidget {
  const StoredCardPage({super.key});

  @override
  ConsumerState<StoredCardPage> createState() => _StoredCardPageState();
}

class _StoredCardPageState extends ConsumerState<StoredCardPage> {
  List<_CardOption> _options = [];
  bool _loading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await ref.read(dioProvider).post(StoredCardApi.list, data: {});
      final data = res.data as Map<String, dynamic>?;
      final raw = (data?['content'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _options = raw
              .map((e) => _CardOption.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // show defaults on error
      if (mounted) {
        setState(() {
          _options = const [
            _CardOption(id: '100', name: '¥100 储值卡', faceValue: 100, bonusPoints: 100, bonusCoupons: 1, priceDisplay: '¥100'),
            _CardOption(id: '200', name: '¥200 储值卡', faceValue: 200, bonusPoints: 220, bonusCoupons: 2, priceDisplay: '¥200'),
            _CardOption(id: '500', name: '¥500 储值卡', faceValue: 500, bonusPoints: 600, bonusCoupons: 5, priceDisplay: '¥500'),
          ];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy() async {
    if (_selectedId == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('正在跳转支付...')));
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        _options.where((o) => o.id == _selectedId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '储值卡'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: _options.length,
              itemBuilder: (_, i) => _CardTile(
                option: _options[i],
                selected: _options[i].id == _selectedId,
                onTap: () =>
                    setState(() => _selectedId = _options[i].id),
              ),
            ),
      bottomNavigationBar: FooterBar(
        buttonText: '立即购买',
        buttonDisabled: _selectedId == null,
        amountLabel: selected != null ? '合计' : null,
        totalAmount: selected?.priceDisplay.replaceAll('¥', '') ?? '0',
        onButtonTap: _buy,
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final _CardOption option;
  final bool selected;
  final VoidCallback onTap;

  const _CardTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF7E51)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // 面值展示
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7E51), Color(0xFFFFB347)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¥',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                  Text(
                    option.faceValue.toStringAsFixed(0),
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (option.bonusPoints > 0)
                        _Tag('赠${option.bonusPoints}积分'),
                      if (option.bonusCoupons > 0)
                        _Tag('赠${option.bonusCoupons}张券'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.priceDisplay,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF7E51)),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF7E51)
                      : const Color(0xFFDDDDDD),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 7,
                        backgroundColor: Color(0xFFFF7E51),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, color: Color(0xFFFF7E51))),
    );
  }
}
