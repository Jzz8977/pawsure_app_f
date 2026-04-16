import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/network/file_url_resolver.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';
import '../../../pet_owner/home/presentation/widgets/sitter_card.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // sitter
  final List<SitterItem> _sitters = [];
  bool _sitterLoading = false;
  bool _sitterFinished = false;
  int _sitterPage = 1;

  // service
  final List<_ServiceItem> _services = [];
  bool _serviceLoading = false;
  bool _serviceFinished = false;
  int _servicePage = 1;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadSitters(reset: true);
    _tab.addListener(() {
      if (_tab.index == 1 && _services.isEmpty && !_serviceLoading) {
        _loadServices(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadSitters({bool reset = false}) async {
    if (_sitterLoading || (!reset && _sitterFinished)) return;
    if (reset) {
      setState(() {
        _sitters.clear();
        _sitterPage = 1;
        _sitterFinished = false;
      });
    }
    setState(() => _sitterLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        FavoriteApi.page,
        data: {'pageNo': _sitterPage, 'pageSize': 20, 'type': 1},
      );
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      final raw = (content?['records'] as List<dynamic>?) ?? [];
      final total = (content?['total'] as num?)?.toInt() ?? 0;

      // 解析 coverUrl / avatar fileId → URL
      final fileIds = <String>[];
      for (final e in raw) {
        final m = e as Map<String, dynamic>;
        final c = m['coverUrl']?.toString() ?? '';
        final a = m['avatar']?.toString() ?? '';
        if (c.isNotEmpty) fileIds.add(c);
        if (a.isNotEmpty) fileIds.add(a);
      }
      final urlMap = await resolveFileUrls(dio, fileIds);

      final items = raw.map((e) {
        final m = e as Map<String, dynamic>;
        final coverKey = m['coverUrl']?.toString() ?? '';
        final avatarKey = m['avatar']?.toString() ?? '';
        return SitterItem.fromJson({
          ...m,
          if (coverKey.isNotEmpty && urlMap.containsKey(coverKey))
            'thumbnailUrl': urlMap[coverKey],
          if (avatarKey.isNotEmpty && urlMap.containsKey(avatarKey))
            'avatarUrl': urlMap[avatarKey],
        });
      }).toList();

      if (mounted) {
        setState(() {
          _sitters.addAll(items);
          _sitterPage++;
          _sitterFinished = _sitters.length >= total;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sitterLoading = false);
    }
  }

  Future<void> _loadServices({bool reset = false}) async {
    if (_serviceLoading || (!reset && _serviceFinished)) return;
    if (reset) {
      setState(() {
        _services.clear();
        _servicePage = 1;
        _serviceFinished = false;
      });
    }
    setState(() => _serviceLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        FavoriteApi.page,
        data: {'pageNo': _servicePage, 'pageSize': 20, 'type': 2},
      );
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      final raw = (content?['records'] as List<dynamic>?) ?? [];
      final total = (content?['total'] as num?)?.toInt() ?? 0;

      // 解析 coverUrl / thumbnailFileId fileId → URL
      final fileIds = <String>[];
      for (final e in raw) {
        final m = e as Map<String, dynamic>;
        final c = m['coverUrl']?.toString() ?? '';
        final t = m['thumbnailFileId']?.toString() ?? '';
        if (c.isNotEmpty) fileIds.add(c);
        if (t.isNotEmpty) fileIds.add(t);
      }
      final urlMap = await resolveFileUrls(dio, fileIds);

      final items = raw.map((e) {
        final m = e as Map<String, dynamic>;
        final coverKey = m['coverUrl']?.toString() ?? '';
        final thumbKey = m['thumbnailFileId']?.toString() ?? '';
        final resolvedCover = urlMap[coverKey] ?? urlMap[thumbKey];
        return _ServiceItem.fromJson({
          ...m,
          'thumbnailUrl': resolvedCover ?? m['thumbnailUrl'] ?? '',
        });
      }).toList();

      if (mounted) {
        setState(() {
          _services.addAll(items);
          _servicePage++;
          _serviceFinished = _services.length >= total;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _serviceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '我的收藏'),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: const Color(0xFFFF7E51),
              unselectedLabelColor: const Color(0xFF666666),
              indicatorColor: const Color(0xFFFF7E51),
              indicatorWeight: 2.5,
              tabs: const [Tab(text: '看护师'), Tab(text: '服务')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildSitterTab(),
                _buildServiceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSitterTab() {
    if (_sitterLoading && _sitters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sitters.isEmpty) {
      return _buildEmpty('暂无收藏的看护师', '快去发现心仪的看护师吧~');
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 100) {
          _loadSitters();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: _sitters.length,
        itemBuilder: (_, i) => SitterCard(
          item: _sitters[i],
          onTap: () =>
              context.push('/provider-detail/${_sitters[i].id}'),
        ),
      ),
    );
  }

  Widget _buildServiceTab() {
    if (_serviceLoading && _services.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_services.isEmpty) {
      return _buildEmpty('暂无收藏的服务', '快去发现心仪的服务吧~');
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 100) {
          _loadServices();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _services.length,
        itemBuilder: (_, i) => _ServiceCard(
          item: _services[i],
          onTap: () =>
              context.push('/provider-detail/${_services[i].providerId}'),
        ),
      ),
    );
  }

  Widget _buildEmpty(String title, String hint) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 15, color: Color(0xFF666666))),
          const SizedBox(height: 6),
          Text(hint,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }
}

// ── 服务模型 ──────────────────────────────────────────────────────

class _ServiceItem {
  final String id;
  final String title;
  final String cover;
  final String category;
  final String price;
  final String providerId;
  final String providerName;

  const _ServiceItem({
    required this.id,
    required this.title,
    required this.cover,
    required this.category,
    required this.price,
    required this.providerId,
    required this.providerName,
  });

  factory _ServiceItem.fromJson(Map<String, dynamic> json) {
    final priceRaw = (json['basePrice'] as num?)?.toDouble() ?? 0;
    return _ServiceItem(
      id: json['id']?.toString() ?? '',
      title: json['serviceName'] as String? ?? '',
      cover: json['thumbnailUrl'] as String? ?? '',
      category: json['serviceTypeName'] as String? ?? '',
      price: (priceRaw / 100).toStringAsFixed(0),
      providerId: json['merchantId']?.toString() ?? json['providerId']?.toString() ?? '',
      providerName: json['merchantName'] as String? ?? '',
    );
  }
}

// ── 服务卡片 ──────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _ServiceItem item;
  final VoidCallback? onTap;
  const _ServiceCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: item.cover.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.cover,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.category,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF508EF9))),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '¥${item.price}/天',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF7E51)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (item.providerName.isNotEmpty) ...[
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Color(0xFFAAAAAA)),
                    const SizedBox(width: 4),
                    Text(item.providerName,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888888))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 88,
      height: 88,
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.image_outlined,
          size: 32, color: Color(0xFFCCCCCC)),
    );
  }
}
