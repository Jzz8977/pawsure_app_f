import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

/// 陪伴师主页（用户视角查看服务者）
class CompanionHomePage extends ConsumerStatefulWidget {
  final String providerId;
  const CompanionHomePage({super.key, required this.providerId});

  @override
  ConsumerState<CompanionHomePage> createState() => _CompanionHomePageState();
}

class _CompanionHomePageState extends ConsumerState<CompanionHomePage>
    with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  late TabController _tabCtrl;

  bool _loading = true;

  // ── Provider info ─────────────────────────────────────────────
  String _name = '';
  String _avatar = '';
  List<String> _coverImages = [];
  String _gender = '';
  int _age = 0;
  bool _isCertified = false;
  String _wechat = '';
  String _address = '';
  int _favoriteCount = 0;
  bool _isFavorite = false;
  String? _favoriteId;
  String _intro = '';
  double _avgScore = 0;

  // ── FAQ / 服务 / 评价 ──────────────────────────────────────────
  final List<({String question, String answer})> _faqList = [];
  List<Map<String, dynamic>> _serviceList = [];
  List<Map<String, dynamic>> _reviewList = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── 数据加载 ──────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('${ProviderApi.detail}/${widget.providerId}');
      final c = resp.data['content'];
      if (c is Map) {
        _applyProvider(c);
      }
    } catch (_) {
      // ignore - 继续显示占位
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    _loadReviews();
    _loadAvgScore();
  }

  void _applyProvider(Map data) {
    final coverRaw = data['coverImages'] ?? data['gallery'] ?? data['images'];
    final covers = coverRaw is List
        ? coverRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final faqRaw = data['faqList'] ?? data['faqs'];
    _faqList.clear();
    if (faqRaw is List) {
      for (final e in faqRaw) {
        if (e is Map) {
          _faqList.add((
            question: e['question']?.toString() ?? '',
            answer: e['answer']?.toString() ?? '',
          ));
        }
      }
    }

    final serviceRaw = data['serviceList'] ?? data['services'] ?? data['servicePrices'];
    if (serviceRaw is List) {
      _serviceList = serviceRaw.cast<Map<String, dynamic>>();
    }

    setState(() {
      _name = data['name']?.toString() ?? data['serverName']?.toString() ?? '陪伴师';
      _avatar = data['avatar']?.toString() ?? data['avatarUrl']?.toString() ?? '';
      _coverImages = covers;
      _gender = data['gender']?.toString() ?? '';
      _age = (data['age'] as num?)?.toInt() ?? 0;
      _isCertified = data['isCertified'] == true || data['certified'] == true;
      _wechat = data['wechat']?.toString() ?? data['wechatId']?.toString() ?? '';
      _address = data['address']?.toString() ?? data['serviceAddress']?.toString() ?? '';
      _favoriteCount = (data['favoriteCount'] as num?)?.toInt() ?? 0;
      _isFavorite = data['isFavorite'] == true || data['collected'] == true;
      _favoriteId = data['collectId']?.toString();
      _intro = data['intro']?.toString() ??
          data['introduction']?.toString() ??
          data['description']?.toString() ??
          '';
    });
  }

  Future<void> _loadAvgScore() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(
        CommentApi.avgScoreByServer,
        data: {'serverId': widget.providerId},
      );
      final v = resp.data['content'];
      if (mounted) {
        setState(() => _avgScore = (v is num) ? v.toDouble() : 0);
      }
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(
        CommentApi.listByServerId,
        data: {'serverId': widget.providerId},
      );
      final raw = resp.data['content'];
      final list = raw is List
          ? raw.cast<Map<String, dynamic>>()
          : (raw is Map && raw['records'] is List
              ? (raw['records'] as List).cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[]);
      if (mounted) setState(() => _reviewList = list);
    } catch (_) {}
  }

  // ─── 收藏 ─────────────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    final wasFav = _isFavorite;
    setState(() {
      _isFavorite = !wasFav;
      _favoriteCount = wasFav
          ? (_favoriteCount > 0 ? _favoriteCount - 1 : 0)
          : _favoriteCount + 1;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post(FavoriteApi.action, data: {
        'targetId': widget.providerId,
        'type': 'provider',
        'action': wasFav ? 'cancel' : 'collect',
        if (wasFav && _favoriteId != null) 'collectId': _favoriteId,
      });
    } catch (_) {
      // 失败回滚
      if (mounted) {
        setState(() {
          _isFavorite = wasFav;
          _favoriteCount = wasFav
              ? _favoriteCount + 1
              : (_favoriteCount > 0 ? _favoriteCount - 1 : 0);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      extendBodyBehindAppBar: true,
      appBar: AppNavBar(
        title: '陪伴师主页',
        showDivider: false,
        backgroundColor: Colors.transparent,
        titleColor: Colors.white,
        backColor: Colors.white,
        enableScrollEffect: true,
        scrollController: _scrollCtrl,
        scrollThreshold: 200,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCover(),
                  _buildProfileCard(),
                  _buildTabBar(),
                  _buildTabContent(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: FooterBar(
        buttonText: '预约联系',
        hasService: true,
        hasShare: true,
        onServiceTap: () {
          // 跳客服页：保持与已注册路由对齐
          Navigator.of(context).pushNamed('/customer-service');
        },
        onShareTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('分享功能开发中')),
          );
        },
        onButtonTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('预约功能开发中')),
          );
        },
      ),
    );
  }

  // ── 封面区 ────────────────────────────────────────────────────

  Widget _buildCover() {
    final mediaWidth = MediaQuery.of(context).size.width;
    final coverHeight = mediaWidth * 0.72;
    return SizedBox(
      width: double.infinity,
      height: coverHeight + 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 轮播
          SizedBox(
            width: double.infinity,
            height: coverHeight,
            child: _coverImages.isEmpty
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFB87A), Color(0xFFFF7A4A)],
                      ),
                    ),
                  )
                : PageView.builder(
                    itemCount: _coverImages.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: _coverImages[i],
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0xFFEFEFEF)),
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFEFEFEF)),
                    ),
                  ),
          ),
          // 头像（向下突出）
          Positioned(
            left: 16,
            bottom: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: _avatar.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFFAAAAAA), size: 32)
                  : CachedNetworkImage(
                      imageUrl: _avatar,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, color: Color(0xFFAAAAAA)),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 个人信息卡片 ──────────────────────────────────────────────

  Widget _buildProfileCard() {
    final certText = _isCertified ? '已认证' : '未认证';
    final ageText = _age > 0 ? '$_age岁' : '';
    final metaParts = [
      if (_gender.isNotEmpty) _gender,
      if (ageText.isNotEmpty) ageText,
      certText,
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_avgScore > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 14, color: _kPrimary),
                      const SizedBox(width: 2),
                      Text(
                        _avgScore.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleFavorite,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: _isFavorite
                          ? const Color(0xFFFF7E51)
                          : const Color(0xFF999999),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_favoriteCount+',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (metaParts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              metaParts.join(' · '),
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ],
          if (_wechat.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('VX：',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF666666))),
                Text(_wechat,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF333333))),
              ],
            ),
          ],
          if (_address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.place_outlined,
                      size: 14, color: Color(0xFF999999)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(_address,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.4)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 栏 ────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: const Color(0xFF333333),
        unselectedLabelColor: const Color(0xFF999999),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        indicatorColor: _kPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: '个人简介'),
          Tab(text: '服务'),
          Tab(text: '评价'),
        ],
      ),
    );
  }

  // ── Tab 内容（不滚，内嵌于外层滚动）─────────────────────────────

  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (_, __) {
        switch (_tabCtrl.index) {
          case 0:
            return _buildIntroTab();
          case 1:
            return _buildServiceTab();
          case 2:
          default:
            return _buildReviewTab();
        }
      },
    );
  }

  // ── 个人简介 + FAQ ────────────────────────────────────────────

  Widget _buildIntroTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '关于我',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          Text(
            _intro.isEmpty ? '暂无介绍' : _intro,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF666666), height: 1.6),
          ),
          if (_faqList.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '常见问题',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            ..._faqList.map(_faqItem),
          ],
        ],
      ),
    );
  }

  Widget _faqItem(({String question, String answer}) item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FaqBadge(text: 'Q', color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.question,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                      height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FaqBadge(text: 'A', color: Color(0xFF89A8FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.answer,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 服务 ──────────────────────────────────────────────────────

  Widget _buildServiceTab() {
    if (_serviceList.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
        child: const Text('暂无服务信息',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
      );
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _serviceList.map((s) {
          final name = s['serviceName']?.toString() ??
              s['name']?.toString() ??
              s['serviceTypeName']?.toString() ??
              '服务';
          final price = (s['price'] ?? s['basePrice']) as num? ?? 0;
          final priceYuan = (price / 100);
          final priceText = priceYuan == priceYuan.truncateToDouble()
              ? priceYuan.toInt().toString()
              : priceYuan.toStringAsFixed(2);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF333333))),
                ),
                Text(
                  '¥$priceText 起',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 评价 ──────────────────────────────────────────────────────

  Widget _buildReviewTab() {
    if (_reviewList.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
        child: const Text('暂无评价',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _reviewList.map((r) {
          final rawTail = (r['customerId']?.toString() ?? '');
          final tail = rawTail.length >= 4
              ? rawTail.substring(rawTail.length - 4)
              : rawTail;
          final userName = r['anonymous'] == true
              ? '匿名用户'
              : (tail.isNotEmpty ? '用户$tail' : '匿名用户');
          final score = (r['overallScore'] as num?)?.toDouble() ?? 0;
          final content = r['content']?.toString() ?? '';
          final commentTime = r['commentTime']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFEEEEEE),
                      child: Text(
                        userName.isNotEmpty ? userName[0] : '?',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(userName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < score.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 13,
                          color: i < score.round()
                              ? _kPrimary
                              : const Color(0xFFDDDDDD),
                        ),
                      ),
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(content,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.5)),
                ],
                if (commentTime.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(commentTime,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF999999))),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FaqBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _FaqBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1),
      ),
    );
  }
}
