import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../home/presentation/widgets/sitter_card.dart';

// ── 常量 ──────────────────────────────────────────────────────────

const _kHistoryKey = 'search_history';
const _kMaxHistory = 20;
const _kDebounceMs  = 300;

// ── Page ─────────────────────────────────────────────────────────

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl    = TextEditingController();
  final _focus   = FocusNode();
  final _scroll  = ScrollController();
  Timer? _debounce;

  List<String> _history = [];
  bool _editingHistory = false;

  List<SitterItem> _results = [];
  bool _hasSearched = false;
  bool _isSearching = false;
  int  _pageNo   = 1;
  int  _pages    = 1;
  bool _loadingMore = false;
  String _lastKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scroll.addListener(_onScroll);
    // 自动弹出键盘
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  // ── 历史记录 ─────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kHistoryKey) ?? [];
    if (mounted) setState(() => _history = list.take(10).toList());
  }

  Future<void> _saveToHistory(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(_kHistoryKey) ?? [])
      ..remove(kw);
    list.insert(0, kw);
    final next = list.take(_kMaxHistory).toList();
    await prefs.setStringList(_kHistoryKey, next);
    if (mounted) setState(() => _history = next.take(10).toList());
  }

  Future<void> _deleteHistoryItem(String kw) async {
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(_kHistoryKey) ?? [])..remove(kw);
    await prefs.setStringList(_kHistoryKey, list);
    if (mounted) setState(() => _history = list.take(10).toList());
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHistoryKey, []);
    if (mounted) setState(() { _history = []; _editingHistory = false; });
  }

  // ── 搜索 ─────────────────────────────────────────────────────────

  void _onInput(String value) {
    setState(() {});
    final kw = value.trim();
    if (kw.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _hasSearched = false;
        _results = [];
        _lastKeyword = '';
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _kDebounceMs), () {
      _performSearch(kw, reset: true, saveHistory: true);
    });
  }

  void _onSubmit(String value) {
    final kw = value.trim();
    if (kw.isEmpty) return;
    _debounce?.cancel();
    _performSearch(kw, reset: true, saveHistory: true);
  }

  void _onHistoryTap(String kw) {
    if (_editingHistory) return;
    _ctrl.text = kw;
    _ctrl.selection = TextSelection.collapsed(offset: kw.length);
    setState(() {});
    _performSearch(kw, reset: true, saveHistory: true);
  }

  void _onClear() {
    _debounce?.cancel();
    _ctrl.clear();
    setState(() {
      _hasSearched = false;
      _results = [];
      _lastKeyword = '';
      _editingHistory = false;
    });
    _focus.requestFocus();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      if (_hasSearched && !_isSearching && !_loadingMore && _pageNo < _pages) {
        _performSearch(_lastKeyword, reset: false);
      }
    }
  }

  Future<void> _performSearch(
    String keyword, {
    required bool reset,
    bool saveHistory = false,
  }) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    if (_isSearching || _loadingMore) return;

    final nextPage = reset ? 1 : _pageNo + 1;
    if (!reset && nextPage > _pages) return;

    if (reset) {
      setState(() {
        _isSearching  = true;
        _results      = [];
        _hasSearched  = false;
        _lastKeyword  = kw;
        _pageNo = 1;
        _pages  = 1;
      });
    } else {
      setState(() { _loadingMore = true; _lastKeyword = kw; });
    }

    try {
      final res = await ref.read(dioProvider).post(
        ServicePublishApi.allPublished,
        data: {'pageNo': nextPage, 'pageSize': 10, 'serviceName': kw},
      );
      final data    = res.data as Map<String, dynamic>?;
      final content = data?['content'];

      List<dynamic> rawList = [];
      int current = nextPage, pages = 1;

      if (content is Map<String, dynamic>) {
        rawList = content['records'] as List<dynamic>? ?? [];
        current = (content['current'] as num?)?.toInt() ?? nextPage;
        pages   = (content['pages']   as num?)?.toInt() ?? 1;
      } else if (content is List) {
        rawList = content;
      }

      final items = rawList
          .map((e) => SitterItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (saveHistory) _saveToHistory(kw);

      if (mounted) {
        setState(() {
          _results    = reset ? items : [..._results, ...items];
          _pageNo     = current;
          _pages      = pages;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasSearched = true);
    } finally {
      if (mounted) setState(() { _isSearching = false; _loadingMore = false; });
    }
  }

  // ── 收藏 ─────────────────────────────────────────────────────────

  Future<void> _toggleLike(int index) async {
    final item = _results[index];
    final willCollect = !item.collected;
    try {
      if (willCollect) {
        final res = await ref.read(dioProvider).post(
          FavoriteApi.action,
          data: {'targetType': 1, 'targetId': item.id, 'action': 'COLLECT'},
        );
        final data    = res.data as Map<String, dynamic>?;
        final content = data?['content'] as Map<String, dynamic>?;
        if (content != null && mounted) {
          setState(() {
            _results[index] = item.copyWith(
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
            _results[index] = item.copyWith(collected: false, collectId: '');
          });
        }
      }
    } catch (_) {}
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: Column(
        children: [
          // 顶部搜索栏
          _buildSearchBar(top),
          // 内容区
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(double top) {
    return Container(
      color: const Color(0xFFF3F5F7),
      padding: EdgeInsets.fromLTRB(12, top + 8, 12, 10),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => context.pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: Color(0xFF333333)),
            ),
          ),
          // 搜索框
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, right: 6),
                    child: Icon(Icons.search_rounded,
                        size: 18, color: Color(0xFFAAAAAA)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onInput,
                      onSubmitted: _onSubmit,
                      decoration: const InputDecoration(
                        hintText: '搜索服务、看护师',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Color(0xFFBBBBBB)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF333333)),
                    ),
                  ),
                  // 清除按钮
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: _onClear,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.cancel_rounded,
                            size: 16, color: Color(0xFFCCCCCC)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFFF7E51)),
            SizedBox(height: 12),
            Text('正在为你查找...',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return _buildDefaultView();
    }

    if (_results.isEmpty) {
      return _buildEmpty();
    }

    return _buildResults();
  }

  // ── 默认视图（历史记录） ─────────────────────────────────────────

  Widget _buildDefaultView() {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('最近搜索',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333))),
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _editingHistory = !_editingHistory),
                    child: Text(
                      _editingHistory ? '完成' : '编辑',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF888888)),
                    ),
                  ),
                  if (_editingHistory) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _clearHistory,
                      child: const Text('清空',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFFFF4D4F))),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 历史标签
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history.map((kw) => _HistoryChip(
              keyword: kw,
              editing: _editingHistory,
              onTap: () => _onHistoryTap(kw),
              onDelete: () => _deleteHistoryItem(kw),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ── 搜索结果 ─────────────────────────────────────────────────────

  Widget _buildResults() {
    final total = (_pages > 1 || _results.length > 8)
        ? _results.length
        : _results.length;
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '找到 $total 个结果',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF888888)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => SitterCard(
                item: _results[i],
                onTap: () =>
                    context.push('/provider-detail/${_results[i].id}'),
                onLikeTap: (_) => _toggleLike(i),
              ),
              childCount: _results.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
          ),
        ),
        if (_loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFFF7E51)),
              ),
            ),
          ),
        if (!_loadingMore && _pageNo >= _pages && _results.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('— 已加载全部 —',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFFCCCCCC))),
              ),
            ),
          ),
      ],
    );
  }

  // ── 空结果 ────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('未找到相关结果',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
          const SizedBox(height: 6),
          const Text('换个关键词试试吧',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }
}

// ── 历史记录 chip ─────────────────────────────────────────────────

class _HistoryChip extends StatelessWidget {
  final String keyword;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryChip({
    required this.keyword,
    required this.editing,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 14, color: Color(0xFFAAAAAA)),
            const SizedBox(width: 4),
            Text(keyword,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF555555))),
            if (editing) ...[
              const SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Color(0xFFAAAAAA)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
