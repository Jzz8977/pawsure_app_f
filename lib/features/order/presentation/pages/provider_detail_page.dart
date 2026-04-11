import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

class ProviderDetailPage extends ConsumerStatefulWidget {
  final String id;
  const ProviderDetailPage({super.key, required this.id});

  @override
  ConsumerState<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends ConsumerState<ProviderDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _provider;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('${ProviderApi.detail}/${widget.id}');
      if (!mounted) return;
      setState(() {
        _provider = resp.data['content'] as Map<String, dynamic>?;
        _loading = false;
      });
      _loadReviews();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final dio = ref.read(dioProvider);
      final url = ProviderApi.reviews.replaceFirst('{id}', widget.id);
      final resp = await dio.get(url);
      if (!mounted) return;
      final list = (resp.data['content']?['records'] as List?) ?? (resp.data['content'] as List?) ?? [];
      setState(() => _reviews = list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = _provider?['name']?.toString() ?? _provider?['serverName']?.toString() ?? '看护师';
    final bio = _provider?['introduction']?.toString() ?? _provider?['bio']?.toString() ?? '';
    final rating = (_provider?['avgScore'] as num?)?.toDouble() ?? 0.0;
    final tags = (_provider?['tags'] as List?)?.cast<String>() ?? [];
    final priceTable = (_provider?['servicePrices'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppNavBar(title: '看护师详情', showDivider: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : Column(children: [
              // Hero card
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.person, size: 30, color: Color(0xFF999999)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.star, size: 16, color: rating > 0 ? _kPrimary : const Color(0xFFDDDDDD)),
                        const SizedBox(width: 4),
                        Text(rating > 0 ? rating.toStringAsFixed(1) : '暂无评分',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                      ]),
                    ])),
                  ]),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFF0E0), borderRadius: BorderRadius.circular(12)),
                      child: Text(t, style: const TextStyle(fontSize: 12, color: _kPrimary)),
                    )).toList()),
                  ],
                ]),
              ),
              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: _kPrimary,
                  unselectedLabelColor: const Color(0xFF666666),
                  indicatorColor: _kPrimary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [Tab(text: '服务价格'), Tab(text: '服务介绍'), Tab(text: '评价')],
                ),
              ),
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  // Prices tab
                  priceTable.isEmpty
                      ? const Center(child: Text('暂无价格信息', style: TextStyle(color: Color(0xFF999999))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: priceTable.length,
                          itemBuilder: (ctx, i) {
                            final item = priceTable[i] as Map<String, dynamic>;
                            final sizeName = item['sizeName']?.toString() ?? item['petSize']?.toString() ?? '';
                            final price = (item['price'] as num?) ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(sizeName, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                                Text('¥${(price / 100).toStringAsFixed(0)}/天',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                              ]),
                            );
                          },
                        ),
                  // Bio tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text(bio.isEmpty ? '暂无介绍' : bio,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.6)),
                      ),
                    ],
                  ),
                  // Reviews tab
                  _reviews.isEmpty
                      ? const Center(child: Text('暂无评价', style: TextStyle(color: Color(0xFF999999))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reviews.length,
                          itemBuilder: (ctx, i) {
                            final r = _reviews[i];
                            final userName = r['userName']?.toString() ?? '用户';
                            final comment = r['comment']?.toString() ?? '';
                            final score = (r['score'] as num?)?.toDouble() ?? 5.0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  CircleAvatar(radius: 16, backgroundColor: const Color(0xFFF0F0F0),
                                      child: Text(userName[0], style: const TextStyle(fontSize: 12))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                  Row(children: List.generate(5, (si) => Icon(
                                    si < score.round() ? Icons.star : Icons.star_border,
                                    size: 14, color: si < score.round() ? _kPrimary : const Color(0xFFDDDDDD),
                                  ))),
                                ]),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(comment, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                                ],
                              ]),
                            );
                          },
                        ),
                ],
              )),
            ]),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: GestureDetector(
          onTap: () => context.push('/select-service?providerId=${widget.id}'),
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Text('立即预约', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
