import 'dart:async';
import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/network/file_url_resolver.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';
import '../widgets/sitter_card.dart';

// ── 轮播图模型 ────────────────────────────────────────────────────

class _BannerItem {
  final String id;
  final String imageUrl;
  final String link;
  const _BannerItem({required this.id, required this.imageUrl, this.link = ''});
}

// ── 静态数据 ──────────────────────────────────────────────────────

const _kSteps = [
  (icon: 'assets/images/home/caregivers.png', title: '看护师', arrow: true),
  (icon: 'assets/images/home/term.png', title: '选择租期', arrow: true),
  (icon: 'assets/images/home/pay.png', title: '支付租金', arrow: true),
  (icon: 'assets/images/home/return.png', title: '接回/送还', arrow: false),
];

const _kBenefits = [100, 80, 50, 20];

// ── Page ─────────────────────────────────────────────────────────

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollCtrl = ScrollController();
  final _pageCtrl = PageController();
  Timer? _bannerTimer;
  int _bannerPage = 0;

  List<_BannerItem> _banners = [];
  List<SitterItem> _list = [];
  int _pageNo = 1;
  int _pages = 1;
  bool _loadingList = false;

  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadBanners();
    _fetchLocationThenList();
  }

  // 先尝试获取 GPS 位置，再加载看护师列表
  Future<void> _fetchLocationThenList() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission perm = permission;
      developer.log('[Home] 当前定位权限=$perm', name: 'home');
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        developer.log('[Home] 申请后权限=$perm', name: 'home');
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        developer.log('[Home] 拿到坐标 lat=$_userLat lng=$_userLng', name: 'home');
      } else {
        developer.log('[Home] 权限不足，未获取坐标', name: 'home');
      }
    } catch (e, st) {
      developer.log('[Home] 定位失败: $e', name: 'home', error: e, stackTrace: st);
    }
    _loadList(reset: true);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _bannerTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadList(reset: false);
    }
  }

  // ── API ─────────────────────────────────────────────────────────

  Future<void> _loadBanners() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(LibApi.bannerList, data: {});
      final data = res.data as Map<String, dynamic>?;
      final raw = (data?['content'] as List<dynamic>?) ?? [];

      // 解析 fileId → 可访问 URL
      final fileIds = raw
          .map((e) => (e as Map<String, dynamic>)['fileId']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      final urlMap = await resolveFileUrls(dio, fileIds);

      if (mounted) {
        setState(() {
          _banners = raw.map((e) {
            final m = e as Map<String, dynamic>;
            final fileId = m['fileId']?.toString() ?? '';
            final imageUrl = urlMap[fileId] ??
                m['imageUrl'] as String? ??
                m['fileUrl'] as String? ??
                '';
            return _BannerItem(
              id: m['id']?.toString() ?? '',
              imageUrl: imageUrl,
              link: m['linkUrl'] as String? ?? m['link'] as String? ?? '',
            );
          }).toList();
        });
        _startBannerTimer();
      }
    } catch (_) {}
  }

  Future<void> _loadList({required bool reset}) async {
    if (_loadingList) return;
    final nextPage = reset ? 1 : _pageNo + 1;
    if (!reset && nextPage > _pages) return;

    setState(() => _loadingList = true);
    try {
      final reqData = {
        'pageNo': nextPage,
        'pageSize': 8,
        if (_userLat != null) 'latitude': _userLat,
        if (_userLng != null) 'longitude': _userLng,
      };
      developer.log('[Home] 请求发布列表 ${ServicePublishApi.allPublished} body=$reqData',
          name: 'home');
      final res = await ref.read(dioProvider).post(
            ServicePublishApi.allPublished,
            data: reqData,
          );
      final data = res.data as Map<String, dynamic>?;
      developer.log(
          '[Home] 响应 success=${data?['success']} code=${data?['code']} '
          'msg=${data?['message'] ?? data?['msg']} '
          'contentType=${data?['content']?.runtimeType}',
          name: 'home');
      final success = data?['success'] == true || data?['code'] == 200;
      if (!success) {
        developer.log('[Home] 响应未成功，原始 data=$data', name: 'home');
      }
      if (!success || !mounted) return;

      final content = data?['content'];
      List<dynamic> rawList = [];
      int current = nextPage, pages = 1;

      if (content is Map<String, dynamic>) {
        rawList = content['records'] as List<dynamic>? ?? [];
        current = (content['current'] as num?)?.toInt() ?? nextPage;
        pages = (content['pages'] as num?)?.toInt() ?? 1;
      } else if (content is List) {
        rawList = content;
      }

      // 解析 thumbnailFileId / avatarFileId → URL
      final dio = ref.read(dioProvider);
      final fileIds = <String>[];
      for (final e in rawList) {
        final m = e as Map<String, dynamic>;
        final t = m['thumbnailFileId']?.toString() ?? '';
        final a = m['avatarFileId']?.toString() ?? '';
        if (t.isNotEmpty) fileIds.add(t);
        if (a.isNotEmpty) fileIds.add(a);
      }
      final urlMap = await resolveFileUrls(dio, fileIds);

      final items = rawList.map((e) {
        final m = e as Map<String, dynamic>;
        final thumbId = m['thumbnailFileId']?.toString() ?? '';
        final avatarId = m['avatarFileId']?.toString() ?? '';
        return SitterItem.fromJson({
          ...m,
          if (thumbId.isNotEmpty && urlMap.containsKey(thumbId))
            'thumbnailUrl': urlMap[thumbId],
          if (avatarId.isNotEmpty && urlMap.containsKey(avatarId))
            'avatarUrl': urlMap[avatarId],
        });
      }).toList();

      developer.log('[Home] 解析完成 records=${rawList.length} 当前页=$current/$pages',
          name: 'home');

      setState(() {
        _list = reset ? items : [..._list, ...items];
        _pageNo = current;
        _pages = pages;
      });
    } catch (e, st) {
      developer.log('[Home] 拉取发布列表失败: $e',
          name: 'home', error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    final item = _list[index];
    final willCollect = !item.collected;
    try {
      if (willCollect) {
        final res = await ref.read(dioProvider).post(
          FavoriteApi.action,
          data: {'targetType': 1, 'targetId': item.id, 'action': 'COLLECT'},
        );
        final data = res.data as Map<String, dynamic>?;
        final content = data?['content'] as Map<String, dynamic>?;
        if (content != null && mounted) {
          setState(() {
            _list[index] = item.copyWith(
              collected: true,
              collectId: content['id']?.toString(),
            );
          });
        }
      } else {
        if (item.collectId == null) return;
        await ref.read(dioProvider).post(
          FavoriteApi.action,
          data: {'id': item.collectId, 'targetType': 1, 'action': 'CANCEL'},
        );
        if (mounted) {
          setState(() {
            _list[index] = item.copyWith(collected: false, collectId: null);
          });
        }
      }
    } catch (_) {}
  }

  // ── Banner 自动播放 ───────────────────────────────────────────

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_banners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      _bannerPage = (_bannerPage + 1) % _banners.length;
      _pageCtrl.animateToPage(
        _bannerPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFEFF1F4),
      appBar: AppNavBar(
        title: '首页',
        titleAlign: TextAlign.left,
        showBack: false,
        backgroundColor: Colors.transparent,
        showDivider: false,
        titleColor: const Color(0xFF333333),
        enableScrollEffect: true,
        scrollController: _scrollCtrl,
        scrollThreshold: 60,
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/customer-service'),
            child: const SizedBox(
              width: 40,
              height: 44,
              child: Icon(
                Icons.headset_mic_outlined,
                size: 22,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadBanners(), _loadList(reset: true)]);
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFEFF1F4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceSteps(),
                    _buildNewBenefits(),
                    _buildPromotions(),
                    _buildListHeader(),
                  ],
                ),
              ),
            ),
            _buildGrid(),
            SliverToBoxAdapter(child: _buildLoadMore()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Hero（渐变背景 + 搜索栏 + 轮播图）─────────────────────────

  Widget _buildHero() {
    final topPad = MediaQuery.of(context).padding.top + 44.0; // nav bar height
    return Container(
      color: const Color(0xFFEFF1F4),
      child: Stack(
        children: [
          // 渐变背景
          Container(
            height: topPad + 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF1E0), Color(0x24FFF1E0)],
              ),
            ),
          ),
          // 内容
          Padding(
            padding: EdgeInsets.only(top: topPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/home/search.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF999999),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '搜索服务、看护师',
                      style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/customer-service'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headset_mic_outlined,
                size: 20,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    if (_banners.isEmpty) {
      return Container(
        height: 155,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemBuilder: (_, i) {
              final b = _banners[i];
              return GestureDetector(
                onTap: () {
                  if (b.link.isNotEmpty) context.push(b.link);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE8E8E8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: b.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: b.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (_, __, ___) =>
                              const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
        // 指示点
        if (_banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _bannerPage ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _bannerPage
                        ? const Color(0xFFFF9E4A)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── 服务流程步骤 ─────────────────────────────────────────────────

  Widget _buildServiceSteps() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (int i = 0; i < _kSteps.length; i++) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => _onStepTap(i + 1),
                  child: Column(
                    children: [
                      Image.asset(
                        _kSteps[i].icon,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.pets, size: 36, color: Color(0xFFFF9E4A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _kSteps[i].title,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                ),
              ),
              if (_kSteps[i].arrow)
                SvgPicture.asset(
                  'assets/images/home/step-arrow.svg',
                  width: 12,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFCCCCCC),
                    BlendMode.srcIn,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _onStepTap(int step) {
    switch (step) {
      case 1:
        context.push('/services');
        break;
      case 2:
        context.push('/services');
        break;
      case 3:
        context.go('/order');
        break;
      case 4:
        context.go('/services');
        break;
    }
  }

  // ── 新人福利 ──────────────────────────────────────────────────────

  Widget _buildNewBenefits() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDE8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题列
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/home/red_packet.png',
                          width: 14,
                          height: 17,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 14, height: 17),
                        ),
                        const SizedBox(width: 6),
                        const Text.rich(TextSpan(children: [
                          TextSpan(
                            text: '新人',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333)),
                          ),
                          TextSpan(
                            text: '专享福利',
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFFAA5100)),
                          ),
                        ])),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 优惠券格子
                    Row(
                      children: [
                        for (final v in _kBenefits) ...[
                          _benefitItem(v),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // 立即领取按钮（右上角）
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => context.push('/coupons'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9E4A),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '立即领取 >',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitItem(int value) {
    return Container(
      width: 58,
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: const BoxDecoration(
              color: Color(0xFFEED8AF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: const Text(
              '优惠券',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Color(0xFFD79947)),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value元',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAA5100)),
              ),
            ),
          ),
          const Text(
            '立减券',
            style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── 补贴活动 ──────────────────────────────────────────────────────

  Widget _buildPromotions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '补贴优惠',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _promoCard(
                    title: '会员权益',
                    tags: const ['单单立减'],
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD9B5), Color(0xFFFFB07A)],
                    ),
                    onTap: () => context.push('/member-center'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _promoCard(
                    title: '认证补贴',
                    tags: const ['大额券', 'XXXXX'],
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB5D6FF), Color(0xFF85C1FF)],
                    ),
                    onTap: () => context.push('/identity-verification'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoCard({
    required String title,
    required List<String> tags,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333)),
            ),
            Wrap(
              spacing: 4,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [Colors.white, Color(0xFFFFEBE0)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFAA5100))),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── 服务列表 header ──────────────────────────────────────────────

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '服务列表',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333)),
            ),
            Row(
              children: [
                SvgPicture.asset('assets/images/home/layout.svg',
                    width: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF888888), BlendMode.srcIn)),
                const SizedBox(width: 12),
                SvgPicture.asset('assets/images/home/filter.svg',
                    width: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF888888), BlendMode.srcIn)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 服务 2 列格 ───────────────────────────────────────────────────

  Widget _buildGrid() {
    if (_list.isEmpty && _loadingList) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => SitterCard(
            item: _list[i],
            onTap: () => context.push('/provider-detail/${_list[i].id}'),
            onLikeTap: (_) => _toggleLike(i),
          ),
          childCount: _list.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }

  Widget _buildLoadMore() {
    if (!_loadingList || _list.isEmpty) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

